import Foundation

public struct Feature: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: Status
    public let note: String
    public init(id: String, name: String, status: Status, note: String) {
        self.id = id; self.name = name; self.status = status; self.note = note
    }
    public enum Status: String, Codable, Sendable { case experimental, planned, verified }
}

public struct ProfileAttribution: Codable, Sendable {
    public let authors: [String]
    public let source: String
    public let license: String
    public let notes: String
    public init(authors: [String], source: String, license: String, notes: String) {
        self.authors = authors; self.source = source; self.license = license; self.notes = notes
    }
}

public struct DeviceProfile: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let vendor: String
    public let driver: String
    public let model: String
    public let names: [String]
    public let features: [Feature]
    public let attribution: ProfileAttribution?

    public init(id: String, name: String, vendor: String, driver: String, model: String,
                names: [String], features: [Feature], attribution: ProfileAttribution? = nil) {
        self.id = id; self.name = name; self.vendor = vendor; self.driver = driver
        self.model = model; self.names = names; self.features = features; self.attribution = attribution
    }

    public func matches(_ name: String) -> Bool {
        names.contains { $0.caseInsensitiveCompare(name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame }
    }
    public func permits(_ feature: String) -> Bool {
        features.contains { $0.id == feature && $0.status != .planned }
    }
}

public struct Catalog: Codable, Sendable {
    public let schemaVersion: Int
    public let revision: Int
    public let profiles: [DeviceProfile]

    public static func decode(_ data: Data) throws -> Catalog {
        guard data.count <= 1_048_576 else { throw CatalogError.tooLarge }
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        guard catalog.schemaVersion == 1, catalog.revision > 0, !catalog.profiles.isEmpty else {
            throw CatalogError.invalidVersion
        }
        var ids = Set<String>()
        var names = Set<String>()
        for profile in catalog.profiles {
            guard profile.id.range(of: "^[a-z0-9][a-z0-9-]{0,63}$", options: .regularExpression) != nil,
                  ids.insert(profile.id).inserted, !profile.names.isEmpty,
                  !profile.name.trimmingCharacters(in: .whitespaces).isEmpty,
                  !profile.vendor.trimmingCharacters(in: .whitespaces).isEmpty,
                  !profile.driver.isEmpty, !profile.model.isEmpty else {
                throw CatalogError.invalidProfile
            }
            if let credit = profile.attribution {
                guard !credit.authors.isEmpty, credit.authors.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                      let url = URL(string: credit.source), url.scheme == "https", url.host != nil,
                      !credit.license.trimmingCharacters(in: .whitespaces).isEmpty else { throw CatalogError.invalidAttribution }
            }
            var features = Set<String>()
            for name in profile.names {
                let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !key.isEmpty, names.insert(key).inserted else { throw CatalogError.ambiguousName }
            }
            for feature in profile.features {
                guard !feature.id.isEmpty, features.insert(feature.id).inserted else { throw CatalogError.invalidProfile }
            }
        }
        return catalog
    }

    public static func bundled() throws -> Catalog {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    public func profile(named name: String) -> DeviceProfile? { profiles.first { $0.matches(name) } }

    public func adding(_ additions: [DeviceProfile]) throws -> Catalog {
        guard additions.allSatisfy({ $0.attribution != nil }) else { throw CatalogError.invalidAttribution }
        return try Self.decode(JSONEncoder().encode(Catalog(schemaVersion: 1, revision: revision + 1, profiles: profiles + additions)))
    }

    /// Keep user profiles intact. Add bundled profiles only when both ID and aliases are free.
    public func includingBundled(_ bundled: Catalog) throws -> Catalog {
        var merged = self
        for profile in bundled.profiles {
            if merged.profiles.contains(where: { $0.id == profile.id || $0.names.contains(where: profile.matches) }) { continue }
            merged = try merged.adding([profile])
        }
        return merged
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

public struct ProfileDocument: Codable, Sendable {
    public let schemaVersion: Int
    public let profile: DeviceProfile
    public init(profile: DeviceProfile) { schemaVersion = 1; self.profile = profile }
    public static func decode(_ data: Data) throws -> ProfileDocument {
        guard data.count <= 1_048_576 else { throw CatalogError.tooLarge }
        let document = try JSONDecoder().decode(Self.self, from: data)
        guard document.schemaVersion == 1 else { throw CatalogError.invalidVersion }
        return document
    }
}

public enum CatalogError: Error, LocalizedError {
    case invalidVersion, invalidProfile, ambiguousName, missingResource, invalidAttribution, tooLarge
    public var errorDescription: String? {
        switch self {
        case .invalidVersion: "Unsupported schema version or catalog revision."
        case .invalidProfile: "Each profile needs a unique lowercase ID, a name, vendor, driver, model code and unique feature IDs."
        case .ambiguousName: "A Bluetooth name already belongs to another profile. Names must be unique, ignoring case."
        case .missingResource: "A bundled resource is missing."
        case .invalidAttribution: "New profiles need author names, an HTTPS source link and a license."
        case .tooLarge: "Profile files must be no larger than 1 MB."
        }
    }
}
