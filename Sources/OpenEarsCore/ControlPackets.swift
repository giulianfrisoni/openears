import Foundation

// Protocol adaptations: GalaxyBudsClient (Tim Schneeberger, GPL-3.0),
// SonyHeadphonesClient (mos9527, Amr Satrio and contributors, MIT),
// OpenSCQ30 (Oppzippy and contributors, GPL-3.0). See Vendor/ProtocolReferences.
public struct ControlPacket: Equatable, Sendable {
    public var kind: UInt8
    public var sequence: UInt8
    public var payload: [UInt8]
    public init(kind: UInt8 = 0, sequence: UInt8 = 0, payload: [UInt8]) {
        self.kind = kind; self.sequence = sequence; self.payload = payload
    }
}

public enum ControlWire: Sendable {
    case samsung, sony, soundcore

    public func encode(_ packet: ControlPacket) -> [UInt8] {
        let p = packet.payload
        switch self {
        case .samsung:
            guard !p.isEmpty, p.count <= 1021 else { return [] }
            let length = p.count + 2, crc = Self.crc16(p)
            return [0xfd, UInt8(length & 255), UInt8(length >> 8)] + p + [UInt8(crc & 255), UInt8(crc >> 8), 0xdd]
        case .sony:
            guard p.count <= 4096 else { return [] }
            var inner: [UInt8] = [packet.kind, packet.sequence, 0, 0, UInt8(p.count >> 8), UInt8(p.count & 255)] + p
            inner.append(inner.reduce(0, &+))
            return [0x3e] + inner.flatMap { (0x3c...0x3e).contains($0) ? [0x3d, $0 ^ 0x10] : [$0] } + [0x3c]
        case .soundcore:
            guard p.count >= 2, p.count <= 4096 else { return [] }
            let length = p.count + 8
            var bytes: [UInt8] = [8, 0xee, 0, 0, 0] + Array(p.prefix(2)) + [UInt8(length & 255), UInt8(length >> 8)] + p.dropFirst(2)
            bytes.append(bytes.reduce(0, &+)); return bytes
        }
    }

    /// Streaming decoder: bounded storage, checksum validation, fragmentation and coalescing.
    public func extract(from buffer: inout [UInt8]) -> [ControlPacket] {
        if buffer.count > 16_384 { buffer.removeAll(); return [] }
        var results: [ControlPacket] = []
        let marker: UInt8 = self == .samsung ? 0xfd : self == .sony ? 0x3e : 9
        while !buffer.isEmpty {
            guard let start = buffer.firstIndex(of: marker) else { buffer.removeAll(); break }
            buffer.removeFirst(start)
            if self == .sony {
                guard let end = buffer.dropFirst().firstIndex(of: 0x3c) else { break }
                let raw = Array(buffer[1..<end]); buffer.removeFirst(end + 1)
                var inner: [UInt8] = [], escaped = false, valid = true
                for byte in raw {
                    if escaped {
                        guard (0x2c...0x2e).contains(byte) else { valid = false; break }
                        inner.append(byte ^ 0x10); escaped = false
                    } else if byte == 0x3d { escaped = true }
                    else { inner.append(byte) }
                }
                guard valid, !escaped, inner.count >= 7, inner.dropLast().reduce(0, &+) == inner.last,
                      inner[2] == 0, inner[3] == 0,
                      Int(inner[4]) * 256 + Int(inner[5]) == inner.count - 7,
                      [0, 1, 12].contains(inner[0]), inner[1] <= 1 else { continue }
                results.append(.init(kind: inner[0], sequence: inner[1], payload: Array(inner[6..<(inner.count-1)])))
            } else if self == .samsung {
                guard buffer.count >= 3 else { break }
                let size = Int(buffer[1]) | (Int(buffer[2] & 3) << 8)
                guard size >= 3 else { buffer.removeFirst(); continue }
                let length = size + 4
                guard buffer.count >= length else { break }
                let raw = Array(buffer.prefix(length))
                let p = Array(raw[3..<(length-3)])
                let crc = UInt16(raw[length-3]) | UInt16(raw[length-2]) << 8
                guard raw.last == 0xdd, Self.crc16(p) == crc else { buffer.removeFirst(); continue }
                buffer.removeFirst(length)
                // Fragmented diagnostic messages are outside this driver's scope.
                guard raw[2] & 0x20 == 0 else { continue }
                results.append(.init(payload: p))
            } else {
                guard buffer.count >= 9 else { break }
                guard Array(buffer.prefix(5)) == [9, 255, 0, 0, 1] else { buffer.removeFirst(); continue }
                let length = Int(buffer[7]) | Int(buffer[8]) << 8
                guard (10...4096).contains(length) else { buffer.removeFirst(); continue }
                guard buffer.count >= length else { break }
                let raw = Array(buffer.prefix(length))
                guard raw.dropLast().reduce(0, &+) == raw.last else { buffer.removeFirst(); continue }
                buffer.removeFirst(length)
                results.append(.init(payload: Array(raw[5...6]) + Array(raw[9..<(length-1)])))
            }
        }
        return results
    }

    public static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 { crc = crc & 0x8000 != 0 ? (crc << 1) ^ 0x1021 : crc << 1 }
        }
        return crc
    }
}

/// Only recognized, returned state can be used as the basis for a setting write.
public struct ClassicControlState: Sendable {
    public private(set) var battery: [String: String] = [:]
    public private(set) var values: [String: String] = [:]
    public private(set) var sonyNoiseInquiry: UInt8?
    private var noiseParameters: [UInt8]?
    public init() {}

    public mutating func receive(_ p: [UInt8], wire: ControlWire, model: String) {
        func level(_ value: UInt8) -> String { value <= 100 ? "\(value)%" : "—" }
        switch wire {
        case .samsung:
            guard let command = p.first else { return }
            let b = Array(p.dropFirst())
            if command == 0x60, b.count >= 7 {
                battery = ["Left": level(b[1]), "Right": level(b[2]), "Case": level(b[6])]
            } else if command == 0x61, b.count >= 13 {
                battery = ["Left": level(b[2]), "Right": level(b[3]), "Case": level(b[7])]
                if let value = Self.samsungEQ[b[9]] { values["eq"] = value }
                if let value = Self.samsungANC[b[12]] { values["anc"] = value }
            } else if command == 0x77, let value = b.first.flatMap({ Self.samsungANC[$0] }) { values["anc"] = value }
        case .sony:
            guard p.count >= 2 else { return }
            if p[0] == 7, p.count >= 3, p[1] == 0, p.count == 3 + Int(p[2]) * 2 {
                let functions = stride(from: 3, to: p.count, by: 2).map { p[$0] }
                sonyNoiseInquiry = functions.contains(0x6d) ? 0x19 : functions.contains(0x6b) ? 0x17 : nil
            } else if [0x23, 0x25].contains(p[0]) {
                if p[1] == 0, p.count >= 4 { battery["Headset"] = level(p[2]) }
                if p[1] == 1, p.count >= 6 { battery["Left"] = level(p[2]); battery["Right"] = level(p[4]) }
                if p[1] == 2, p.count >= 4 { battery["Case"] = level(p[2]) }
            } else if [0x67, 0x69].contains(p[0]), [0x17, 0x19].contains(p[1]), p.count == (p[1] == 0x19 ? 9 : 7), p[3] <= 1, p[4] <= 1 {
                noiseParameters = p
                values["anc"] = p[3] == 0 ? "Off" : p[4] == 1 ? "Transparency" : "Noise cancelling"
            }
        case .soundcore:
            guard p.count >= 3 else { return }
            let command = Array(p.prefix(2)), b = Array(p.dropFirst(2))
            if command == [1, 3] || command == [1, 1] {
                battery["Headset"] = b[0] <= 5 ? "\(Int(b[0]) * 20)%" : "—"
            }
            let width = model == "A3040" ? 6 : 4
            var noise: [UInt8]?
            if command == [6, 1], b.count == width { noise = b }
            if command == [1, 1] {
                // Q30/Q35: battery(2), EQ(10), gender/age(2), HearID(21).
                // Q45: battery(2), firmware(5), serial(16), EQ(12), DRC(10), unknown(2), button(1), cycle(1).
                let offset = model == "A3040" ? 49 : 35
                if b.count >= offset + width { noise = Array(b[offset..<(offset+width)]) }
            }
            if let noise, let value = Self.soundcoreANC[noise[0]] {
                noiseParameters = noise; values["anc"] = value
            }
        }
    }

    public func command(feature: String, value: String, wire: ControlWire) -> [UInt8]? {
        guard values[feature] != nil else { return nil }
        switch wire {
        case .samsung:
            let map = feature == "anc" ? Self.samsungANC : feature == "eq" ? Self.samsungEQ : [:]
            guard let key = map.first(where: { $0.value == value })?.key else { return nil }
            return [feature == "anc" ? 0x78 : 0x86, key]
        case .sony:
            guard feature == "anc", var p = noiseParameters, ["Off", "Transparency", "Noise cancelling"].contains(value) else { return nil }
            p[0] = 0x68; p[2] = 1; p[3] = value == "Off" ? 0 : 1; p[4] = value == "Transparency" ? 1 : 0
            return p
        case .soundcore:
            guard feature == "anc", var p = noiseParameters,
                  let key = Self.soundcoreANC.first(where: { $0.value == value })?.key else { return nil }
            p[0] = key; return [6, 0x81] + p
        }
    }
    public static let samsungANC: [UInt8: String] = [0: "Off", 1: "Noise cancelling", 2: "Transparency", 3: "Adaptive"]
    public static let samsungEQ: [UInt8: String] = [0: "Balanced", 1: "Bass boost", 2: "Soft", 3: "Dynamic", 4: "Clear", 5: "Treble boost"]
    public static let soundcoreANC: [UInt8: String] = [0: "Noise cancelling", 1: "Transparency", 2: "Off"]
}
