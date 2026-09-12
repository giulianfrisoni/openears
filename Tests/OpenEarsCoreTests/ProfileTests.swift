import Foundation
import Testing
@testable import OpenEarsCore

private func newProfile(id: String = "nothing-ear-2", names: [String] = ["Nothing Ear (2)"], credited: Bool = true) -> DeviceProfile {
    DeviceProfile(id: id, name: "Nothing Ear (2)", vendor: "Nothing", driver: "nothing-ble-v1", model: "B155", names: names,
        features: [.init(id: "anc", name: "Noise control", status: .experimental, note: "Not hardware-tested")],
        attribution: credited ? .init(authors: ["Test contributor"], source: "https://example.com/protocol", license: "GPL-3.0", notes: "Test fixture") : nil)
}

@Test func addingProfilePreservesExistingAndIncrementsRevision() throws {
    let original = try Catalog.bundled()
    let updated = try original.adding([newProfile()])
    #expect(updated.profiles.count == original.profiles.count + 1)
    #expect(updated.revision == original.revision + 1)
    #expect(updated.profile(named: "Nothing Ear (3)")?.id == "nothing-ear-3")
    #expect(original.profiles.count == 15)
}

@Test func rejectsCollidingImportWithoutChangingCatalog() throws {
    let original = try Catalog.bundled()
    #expect(throws: (any Error).self) { try original.adding([newProfile(names: ["nothing ear (3)"])]) }
    #expect(throws: (any Error).self) { try original.adding([newProfile(id: "nothing-ear-3")]) }
    #expect(original.profiles.count == 15)
}

@Test func newProfilesRequireCreditAndValidIdentity() throws {
    let catalog = try Catalog.bundled()
    #expect(throws: (any Error).self) { try catalog.adding([newProfile(credited: false)]) }
    #expect(throws: (any Error).self) { try catalog.adding([newProfile(id: "../bad")]) }
    #expect(throws: (any Error).self) { try catalog.adding([newProfile(names: ["   "])]) }
}

@Test func exportedProfileCanBeImportedWithoutLosingCredit() throws {
    let profile = newProfile()
    let data = try JSONEncoder().encode(ProfileDocument(profile: profile))
    let imported = try ProfileDocument.decode(data)
    let updated = try Catalog.bundled().adding([imported.profile])
    #expect(updated.profile(named: "Nothing Ear (2)")?.attribution?.authors == ["Test contributor"])
}

@Test func registryDoesNotEnableUnsupportedFeatures() throws {
    let profile = newProfile()
    #expect(DriverRegistry.supports(profile))
    #expect(DriverRegistry.permits("anc", profile: profile))
    #expect(!DriverRegistry.permits("firmware", profile: profile))
    #expect(!DriverRegistry.permits("spatial", profile: profile))
    let unknown = DeviceProfile(id: "other", name: "Other", vendor: "Other", driver: "unavailable", model: "X1", names: ["Other"], features: [])
    #expect(!DriverRegistry.supports(unknown))
}

@Test func oversizedProfileDocumentsAreRejected() {
    #expect(throws: (any Error).self) { try ProfileDocument.decode(Data(repeating: 0, count: 1_048_577)) }
}

@Test func appIncludesAuthorAcknowledgments() throws {
    let credits = try Credits.text()
    #expect(credits.contains("bestK1ngArthur"))
    #expect(credits.contains("RapidZapper"))
    #expect(credits.contains("Bendix"))
}

@Test func documentedExampleImportsIntoBundledCatalog() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let example = try ProfileDocument.decode(Data(contentsOf: root.appendingPathComponent("profiles/nothing-ear-2.example.json")))
    let updated = try Catalog.bundled().adding([example.profile])
    #expect(updated.profile(named: "Nothing Ear (2)")?.model == "B155")
}
