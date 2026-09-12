import Foundation
@preconcurrency import IOBluetooth
import OpenEarsCore

/// OpenEars RFCOMM transport using Apple's public API. Protocol lineage in ControlPackets.swift.
/// Opens only a paired, already audio-connected device and its advertised control service.
@MainActor final class ClassicHeadsetDriver: NSObject, HeadsetDriver, @preconcurrency IOBluetoothRFCOMMChannelDelegate {
    var onChange: ((HeadsetState) -> Void)?
    private var state = HeadsetState() { didSet { onChange?(state) } }
    private let profile: DeviceProfile
    private let wire: ControlWire
    private var device: IOBluetoothDevice?
    private var channel: IOBluetoothRFCOMMChannel?
    private var active = false
    private var buffer: [UInt8] = []
    private var controls = ClassicControlState()
    private var deadline: Task<Void, Never>?
    private var commandDeadline: Task<Void, Never>?
    private var queueTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var expected: (String, String)?
    private var queue: [[UInt8]] = []
    private var sequence: UInt8 = 0
    private var awaitingACK = false

    init(profile: DeviceProfile) {
        self.profile = profile
        wire = profile.driver == DriverRegistry.samsungID ? .samsung : profile.driver == DriverRegistry.sonyID ? .sony : .soundcore
        super.init()
    }

    func connect() {
        guard !active else { return }
        let candidates = ((IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []).filter {
            profile.matches($0.name ?? "") && $0.isConnected()
        }
        guard candidates.count == 1, let device = candidates.first else {
            state.error = candidates.count > 1 ? "More than one matching headset is connected. Disconnect one before continuing." : "Connect this model in Bluetooth Settings first. Its Bluetooth name must match the profile."
            return
        }
        active = true; self.device = device
        state = HeadsetState(status: "Opening headset controls…")
        deadline = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, let self, !self.state.connected else { return }
            self.stop("The headset did not provide supported control data. Check the model and close other headphone control apps, then retry.")
        }
        let result = device.performSDPQuery(self)
        if result != kIOReturnSuccess { stop("Bluetooth service discovery failed (\(result)).") }
    }

    @objc func sdpQueryComplete(_ queriedDevice: IOBluetoothDevice!, status: IOReturn) {
        guard active, queriedDevice == device else { return }
        guard status == kIOReturnSuccess, let device else { stop("Bluetooth service discovery failed."); return }
        let service = wire == .sony ? "956c7b26-d49a-4ba8-b03f-b17d393cb6e2" : wire == .samsung ? "2e73a4ad-332d-41fc-90e2-16bef06523f2" : "00001101-0000-1000-8000-00805f9b34fb"
        guard var uuid = UUID(uuidString: service)?.uuid else { stop("Invalid control service."); return }
        let sdp = withUnsafeBytes(of: &uuid) { IOBluetoothSDPUUID(bytes: $0.baseAddress, length: $0.count) }
        var identifier: BluetoothRFCOMMChannelID = 0
        guard let record = device.getServiceRecord(for: sdp), record.getRFCOMMChannelID(&identifier) == kIOReturnSuccess, identifier != 0 else {
            stop("This headset did not advertise the expected control service. This profile may not match its firmware."); return
        }
        let result = device.openRFCOMMChannelAsync(&channel, withChannelID: identifier, delegate: self)
        if result != kIOReturnSuccess { stop("Could not open headset controls (\(result)).") }
    }

    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        guard active, rfcommChannel == channel else { return }
        guard error == kIOReturnSuccess else { stop("Could not open headset controls (\(error))."); return }
        state.status = "Reading headset settings…"
        if wire == .sony { enqueue([[0, 0]]) }
        refresh()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled, let self, self.active else { return }
                if self.expected == nil { self.refresh() }
            }
        }
    }

    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        guard active, rfcommChannel == channel, let dataPointer, dataLength > 0, dataLength <= 16_384 else { return }
        buffer.append(contentsOf: UnsafeBufferPointer(start: dataPointer.assumingMemoryBound(to: UInt8.self), count: dataLength))
        for packet in wire.extract(from: &buffer) {
            if wire == .sony {
                if packet.kind == 1 {
                    if awaitingACK, packet.sequence == sequence ^ 1 {
                        sequence = packet.sequence; awaitingACK = false
                    }
                    continue
                }
                send(wire.encode(.init(kind: 1, sequence: packet.sequence ^ 1, payload: [])))
            }
            controls.receive(packet.payload, wire: wire, model: profile.model)
            if wire == .sony, packet.payload.first == 7, let inquiry = controls.sonyNoiseInquiry { enqueue([[0x66, inquiry]]) }
            state.battery = controls.battery; state.values = controls.values
            // A channel open alone is not a verified control connection.
            if !controls.battery.isEmpty || !controls.values.isEmpty {
                state.connected = true; state.status = "Connected · experimental"; deadline?.cancel()
            }
            if let expected, state.values[expected.0] == expected.1 {
                self.expected = nil; commandDeadline?.cancel(); state.pending = nil; state.error = nil
            }
        }
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        guard rfcommChannel == channel else { return }
        stop("Headset controls disconnected. Reconnect to continue.")
    }

    func refresh() {
        guard active, channel != nil else { return }
        switch wire {
        case .samsung: enqueue([[0x61]])
        case .sony:
            let noise: [UInt8] = controls.sonyNoiseInquiry.map { [0x66, $0] } ?? [6, 0]
            enqueue(profile.model.hasPrefix("WF-") ? [[0x22, 1], [0x22, 2], noise] : [[0x22, 0], noise])
        case .soundcore: enqueue([[1, 1]])
        }
    }

    func set(_ feature: String, value: String) {
        guard state.connected, state.pending == nil, DriverRegistry.permits(feature, profile: profile),
              DriverRegistry.options(feature, profile: profile).contains(value),
              let payload = controls.command(feature: feature, value: value, wire: wire) else { return }
        expected = (feature, value); state.pending = feature; state.error = nil
        enqueue([payload])
        commandDeadline = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, let self else { return }
            self.refresh()
            try? await Task.sleep(for: .seconds(7))
            guard !Task.isCancelled, self.expected != nil else { return }
            self.expected = nil; self.state.pending = nil
            self.state.error = "The headset did not confirm this change. Its last reported setting is shown."
        }
    }

    private func enqueue(_ payloads: [[UInt8]]) {
        guard queue.count + payloads.count <= 32 else { return }
        queue += payloads
        guard queueTask == nil else { return }
        queueTask = Task { [weak self] in
            guard let self else { return }
            while self.active, !self.queue.isEmpty, !Task.isCancelled {
                let payload = self.queue.removeFirst()
                self.awaitingACK = self.wire == .sony
                self.send(self.wire.encode(.init(kind: self.wire == .sony ? 12 : 0, sequence: self.sequence, payload: payload)))
                if self.wire == .sony {
                    let until = Date().addingTimeInterval(3)
                    while self.awaitingACK, Date() < until, !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(40))
                    }
                    if self.awaitingACK, !Task.isCancelled { self.stop("The Sony control channel stopped responding. Reconnect to retry."); return }
                } else { try? await Task.sleep(for: .milliseconds(180)) }
            }
            self.queueTask = nil
        }
    }

    private func send(_ bytes: [UInt8]) {
        guard active, let channel else { return }
        guard !bytes.isEmpty, bytes.count <= Int(channel.getMTU()) else { stop("The control packet exceeds this connection’s capacity."); return }
        var data = bytes
        let result = data.withUnsafeMutableBytes { channel.writeSync($0.baseAddress, length: UInt16($0.count)) }
        if result != kIOReturnSuccess { stop("Bluetooth could not send the control command (\(result)).") }
    }

    func disconnect() {
        active = false; deadline?.cancel(); commandDeadline?.cancel(); queueTask?.cancel(); pollTask?.cancel()
        queueTask = nil; expected = nil; queue.removeAll(); buffer.removeAll(); controls = ClassicControlState()
        awaitingACK = false; sequence = 0
        let old = channel; channel = nil; old?.setDelegate(nil); old?.close()
        device = nil; state = HeadsetState(status: "Disconnected")
    }
    private func stop(_ error: String) { disconnect(); state.error = error }
}
