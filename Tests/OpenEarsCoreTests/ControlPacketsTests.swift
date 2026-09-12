import Foundation
import Testing
@testable import OpenEarsCore

// GPL-3.0 fixture from Tim Schneeberger's GalaxyBudsClient; pinned in Vendor/ProtocolReferences.
private let buds2Status: [UInt8] = [0xfd, 0x31, 0x00, 0x61, 0x0d, 0x04, 0x64, 0x64, 0x01, 0x00, 0x33, 0x58, 0x00, 0x01, 0xbf, 0x22, 0x00, 0x01, 0x46, 0x01, 0x46, 0x01, 0x00, 0x00, 0x03, 0x35, 0x00, 0x03, 0x00, 0x10, 0x01, 0x01, 0x01, 0x01, 0x32, 0x03, 0x01, 0x01, 0x01, 0x00, 0x0c, 0xae, 0x01, 0x00, 0x03, 0x00, 0x01, 0x00, 0x01, 0x01, 0xb6, 0x37, 0xdd]

@Test func samsungRecordedStatusSurvivesEveryFragmentBoundary() throws {
    for split in 0...buds2Status.count {
        var buffer = Array(buds2Status.prefix(split))
        var packets = ControlWire.samsung.extract(from: &buffer)
        buffer += buds2Status.dropFirst(split)
        packets += ControlWire.samsung.extract(from: &buffer)
        #expect(packets.count == 1)
        let packet = try #require(packets.first)
        var state = ClassicControlState()
        state.receive(packet.payload, wire: .samsung, model: "SM-R510")
        #expect(state.battery == ["Left": "100%", "Right": "100%", "Case": "88%"])
        #expect(state.values["eq"] == "Bass boost")
        #expect(state.values["anc"] == "Off")
        #expect(state.command(feature: "eq", value: "Dynamic", wire: .samsung) == [0x86, 3])
        #expect(buffer.isEmpty)
    }
}

@Test func corruptSamsungPacketIsRejectedAndStreamRecovers() {
    var corrupt = buds2Status; corrupt[10] ^= 1
    var buffer = [0, 1, 2] + corrupt + buds2Status + buds2Status
    #expect(ControlWire.samsung.extract(from: &buffer).count == 2)
    #expect(buffer.isEmpty)
}

@Test func sonyEscapingAndLengthValidation() {
    let packet = ControlPacket(kind: 12, sequence: 1, payload: [0x3c, 0x3d, 0x3e])
    let encoded = ControlWire.sony.encode(packet)
    #expect(encoded.contains(0x2c)); #expect(encoded.contains(0x2d)); #expect(encoded.contains(0x2e))
    for split in 0...encoded.count {
        var buffer = Array(encoded.prefix(split))
        var result = ControlWire.sony.extract(from: &buffer)
        buffer += encoded.dropFirst(split)
        result += ControlWire.sony.extract(from: &buffer)
        #expect(result == [packet])
    }
    var corrupt = encoded; corrupt[3] = 1
    #expect(ControlWire.sony.extract(from: &corrupt).isEmpty)
    var trailingEscape: [UInt8] = [0x3e, 0x3d, 0x3c]
    #expect(ControlWire.sony.extract(from: &trailingEscape).isEmpty)
}

@Test func sonyChangesPreserveAmbientParameters() {
    var state = ClassicControlState()
    #expect(state.command(feature: "anc", value: "Off", wire: .sony) == nil)
    state.receive([0x67, 0x19, 1, 1, 0, 1, 17, 1, 2], wire: .sony, model: "WH-1000XM6")
    #expect(state.values["anc"] == "Noise cancelling")
    #expect(state.command(feature: "anc", value: "Transparency", wire: .sony) == [0x68, 0x19, 1, 1, 1, 1, 17, 1, 2])
    state.receive([0x67, 0x17, 1, 0, 0, 0, 20], wire: .sony, model: "WH-1000XM5")
    #expect(state.values["anc"] == "Off")
    #expect(state.command(feature: "anc", value: "Noise cancelling", wire: .sony) == [0x68, 0x17, 1, 1, 0, 0, 20])
    #expect(state.command(feature: "firmware", value: "yes", wire: .sony) == nil)
}

// OpenSCQ30's manually crafted request and mode-notification regression vectors (GPL-3.0).
@Test func soundcoreGoldenPacketsAndPreservedNoiseSettings() {
    #expect(ControlWire.soundcore.encode(.init(payload: [1, 3])) == [8, 0xee, 0, 0, 0, 1, 3, 10, 0, 4])
    var buffer: [UInt8] = [9, 255, 0, 0, 1, 6, 1, 14, 0, 0, 1, 1, 0, 0x20]
    let packets = ControlWire.soundcore.extract(from: &buffer)
    #expect(packets.count == 1)
    var state = ClassicControlState()
    state.receive(packets[0].payload, wire: .soundcore, model: "A3028")
    #expect(state.values["anc"] == "Noise cancelling")
    #expect(state.command(feature: "anc", value: "Off", wire: .soundcore) == [6, 0x81, 2, 1, 1, 0])
    var q45 = [UInt8](repeating: 0, count: 55); q45[0] = 4
    q45.replaceSubrange(49..<55, with: [1, 0x32, 0, 1, 1, 4])
    state.receive([1, 1] + q45, wire: .soundcore, model: "A3040")
    #expect(state.battery["Headset"] == "80%")
    #expect(state.command(feature: "anc", value: "Off", wire: .soundcore) == [6, 0x81, 2, 0x32, 0, 1, 1, 4])
}

@Test func boundedDecodersRejectOversizedAndTruncatedInput() {
    for wire in [ControlWire.sony, .samsung, .soundcore] {
        var oversized = [UInt8](repeating: 0x3e, count: 20_000)
        #expect(wire.extract(from: &oversized).isEmpty)
        #expect(oversized.isEmpty)
        var state = ClassicControlState()
        for length in 0..<7 { state.receive([UInt8](repeating: 0x61, count: length), wire: wire, model: "test") }
        #expect(state.values.isEmpty)
    }
}

@Test func bundledUpgradePreservesCustomProfilesAndAddsNewModels() throws {
    let bundle = try Catalog.bundled()
    let old = Catalog(schemaVersion: 1, revision: 1, profiles: [bundle.profiles[0]])
    let merged = try old.includingBundled(bundle)
    #expect(merged.profiles.count == 15)
    #expect(try merged.includingBundled(bundle).encoded() == merged.encoded())
    #expect(merged.profiles.allSatisfy(DriverRegistry.supports))
    for profile in merged.profiles where profile.driver != DriverRegistry.nothingID {
        #expect(profile.features.allSatisfy { $0.status == .experimental })
        #expect(!DriverRegistry.permits("spatial", profile: profile))
        #expect(!DriverRegistry.options("anc", profile: profile).contains("High"))
    }
}

@Test func sonyNoiseFormatComesFromDeviceCapabilities() {
    var state = ClassicControlState()
    state.receive([7, 0, 2, 0x6b, 0, 0x20, 1], wire: .sony, model: "WH-1000XM5")
    #expect(state.sonyNoiseInquiry == 0x17)
    state.receive([7, 0, 1, 0x6d, 0], wire: .sony, model: "WH-1000XM6")
    #expect(state.sonyNoiseInquiry == 0x19)
    state.receive([7, 0, 1, 0x20, 0], wire: .sony, model: "WH-1000XM6")
    #expect(state.sonyNoiseInquiry == nil)
}
