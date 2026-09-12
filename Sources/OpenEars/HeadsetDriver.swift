import Foundation
import OpenEarsCore
import SwiftNothingEar

struct HeadsetState {
    var connected = false
    var status = "Ready to connect"
    var firmware: String?
    var battery: [String: String] = [:]
    var values: [String: String] = [:]
    var pending: String?
    var error: String?
}

@MainActor protocol HeadsetDriver: AnyObject {
    var onChange: ((HeadsetState) -> Void)? { get set }
    func connect()
    func disconnect()
    func refresh()
    func set(_ feature: String, value: String)
}

@MainActor final class NothingDriver: HeadsetDriver {
    var onChange: ((HeadsetState) -> Void)?
    private var state = HeadsetState() { didSet { onChange?(state) } }
    private var device: Device?
    private let profile: DeviceProfile
    private var timeout: Task<Void, Never>?
    private var commandTimeout: Task<Void, Never>?
    private var expected: (String, String)?
    private var wantsConnection = false

    init(profile: DeviceProfile) { self.profile = profile }

    func connect() {
        guard !state.connected else { return }
        wantsConnection = true
        state = HeadsetState(status: "Connecting to your earbuds…")
        if device == nil {
            device = Device(Callback(
                onDiscover: { [weak self] peripheral in
                    guard let self, self.wantsConnection, self.profile.matches(peripheral.name ?? "") else { return }
                    self.device?.connect(to: peripheral)
                },
                onConnect: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let info):
                        guard self.wantsConnection, info.model.code == self.profile.model else {
                            self.state.error = "The detected model does not match this profile."
                            self.disconnect()
                            return
                        }
                        self.timeout?.cancel()
                        self.state.connected = true
                        self.state.status = "Connected"
                        self.state.error = nil
                        self.state.firmware = info.firmwareVersion
                    case .failure(let error): self.fail(error.localizedDescription)
                    }
                },
                onDisconnect: { [weak self] _ in
                    guard let self else { return }
                    let error = self.state.error
                    self.state = HeadsetState(status: "Disconnected", error: error)
                    self.commandTimeout?.cancel()
                    self.expected = nil
                },
                onUpdateBattery: { [weak self] battery in
                    guard let self, self.wantsConnection else { return }
                    func label(_ level: BatteryLevel) -> String {
                        guard level.isConnected, (0...100).contains(level.level) else { return "—" }
                        return "\(level.level)%" + (level.isCharging ? " ⚡" : "")
                    }
                    switch battery {
                    case .budsWithCase(let box, let left, let right):
                        self.state.battery = ["Left": label(left), "Right": label(right), "Case": label(box)]
                    case .single(let level): self.state.battery = ["Headset": label(level)]
                    case nil: self.state.battery = [:]
                    }
                },
                onUpdateANCMode: { [weak self] value in
                    guard let value else { return }
                    let text: String
                    switch value {
                    case .off: text = "Off"
                    case .transparent: text = "Transparency"
                    case .active(let level): text = level.displayName == "Mid" ? "Medium" : level.displayName
                    }
                    self?.received("anc", text)
                },
                onUpdateSpatialAudio: { [weak self] value in
                    if let value { self?.received("spatial", value.displayName) }
                },
                onUpdateEnhancedBass: { _ in },
                onUpdateEQPreset: { [weak self] value in
                    if let value { self?.received("eq", value.displayName) }
                },
                onUpdateDeviceSettings: { _ in },
                onUpdateRingBuds: { _ in },
                onError: { [weak self] error in
                    guard let self else { return }
                    // CoreBluetooth may be initializing. The bounded connection timer remains active.
                    if case .bluetooth(.unavailable) = error, !self.state.connected { return }
                    self.fail(error.localizedDescription)
                }
            ), acceptsName: { [profile] name in profile.matches(name) })
        }
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled, let self, self.wantsConnection else { return }
            self.device?.startScanning()
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, !self.state.connected else { return }
            self.fail("No control connection. Keep the earbuds connected in Bluetooth Settings, then retry.")
            self.disconnect()
        }
    }

    func disconnect() {
        wantsConnection = false
        timeout?.cancel()
        commandTimeout?.cancel()
        expected = nil
        device?.stopScanning()
        device?.disconnect()
        let error = state.error
        state = HeadsetState(status: "Disconnected", error: error)
    }

    func refresh() { if state.connected { device?.refreshControls() } }

    func set(_ feature: String, value: String) {
        guard state.connected, DriverRegistry.permits(feature, profile: profile), state.pending == nil else { return }
        guard let device else { return }
        switch feature {
        case "anc":
            let modes: [String: NoiseCancellationMode] = ["Off": .off, "Transparency": .transparent,
                "Low": .active(.low), "Medium": .active(.mid), "High": .active(.high), "Adaptive": .active(.adaptive)]
            guard let mode = modes[value] else { return }
            begin(feature, value)
            device.setNoiseCancellationMode(mode)
        case "eq":
            let presets: [String: EQPreset] = ["Balanced": .balanced, "Voice": .voice, "More Bass": .moreBass, "More Treble": .moreTreble]
            guard let preset = presets[value] else { return }
            begin(feature, value)
            device.setEQPreset(preset)
        case "spatial":
            guard value == "Off" || value == "Fixed" else { return }
            begin(feature, value)
            device.setSpatialAudioMode(value == "Off" ? .off : .fixed)
        default: return
        }
    }

    private func begin(_ feature: String, _ value: String) {
        expected = (feature, value)
        state.pending = feature
        state.error = nil
        commandTimeout?.cancel()
        commandTimeout = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            self.refresh()
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled, self.expected != nil else { return }
            self.expected = nil
            self.state.pending = nil
            self.state.error = "The earbuds did not confirm the change. Their last reported setting is shown."
        }
    }

    private func received(_ feature: String, _ value: String) {
        guard wantsConnection else { return }
        state.values[feature] = value
        if let expected, expected.0 == feature, expected.1 == value {
            commandTimeout?.cancel()
            self.expected = nil
            state.pending = nil
        }
    }

    private func fail(_ message: String) {
        state.error = message
        state.pending = nil
        expected = nil
        commandTimeout?.cancel()
    }
}
