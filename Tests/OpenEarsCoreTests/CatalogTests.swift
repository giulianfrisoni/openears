import Foundation
import Testing
@testable import OpenEarsCore

@Test func identifiesEarThreeWithoutMatchingOtherModels() throws {
    let catalog = try Catalog.bundled()
    #expect(catalog.profile(named: " Nothing EAR (3) ")?.model == "B173")
    #expect(catalog.profile(named: "Nothing Ear")?.model == "B171")
    #expect(catalog.profile(named: "Nothing Ear (3a)") == nil)
    #expect(catalog.profile(named: "Unrelated headset") == nil)
}

@Test func plannedFeaturesCannotBeEnabled() throws {
    let profile = try #require(Catalog.bundled().profiles.first)
    #expect(profile.permits("anc"))
    #expect(!profile.permits("firmware"))
    #expect(!profile.permits("unknown"))
}

@Test func rejectsFutureSchemasAndDuplicateProfiles() throws {
    let catalog = try Catalog.bundled()
    let encoded = try JSONEncoder().encode(catalog)
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    json["schemaVersion"] = 2
    #expect(throws: (any Error).self) { try Catalog.decode(JSONSerialization.data(withJSONObject: json)) }
    json["schemaVersion"] = 1
    let profiles = try #require(json["profiles"] as? [[String: Any]])
    json["profiles"] = profiles + profiles
    #expect(throws: (any Error).self) { try Catalog.decode(JSONSerialization.data(withJSONObject: json)) }
}

@Test func rejectsAmbiguousDeviceNames() throws {
    let encoded = try JSONEncoder().encode(Catalog.bundled())
    var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    var profiles = try #require(json["profiles"] as? [[String: Any]])
    var duplicate = profiles[0]
    duplicate["id"] = "different-profile"
    duplicate["names"] = ["NOTHING EAR (3)"]
    profiles.append(duplicate)
    json["profiles"] = profiles
    #expect(throws: (any Error).self) { try Catalog.decode(JSONSerialization.data(withJSONObject: json)) }
}
