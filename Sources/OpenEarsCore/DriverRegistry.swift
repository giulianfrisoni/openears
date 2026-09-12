import Foundation

/// Protocol identity facts from the pinned swift-nothing-ear dependency (see ACKNOWLEDGMENTS.md).
/// Inclusion means the driver knows the model; it does not mean OpenEars has hardware-verified it.
public struct DriverModel: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let vendor: String
    public let features: [String]
    public var driver: String { vendor == "Samsung" ? DriverRegistry.samsungID : vendor == "Sony" ? DriverRegistry.sonyID : vendor == "Soundcore" ? DriverRegistry.soundcoreID : DriverRegistry.nothingID }
    public var source: String { DriverRegistry.source(driver) }
    public var authors: [String] { DriverRegistry.authors(driver) }
}

public enum DriverRegistry {
    public static let samsungID = "samsung-spp-v1"
    public static let sonyID = "sony-mdr-v2"
    public static let soundcoreID = "soundcore-spp-v1"
    public static let nothingID = "nothing-ble-v1"
    public static let models: [DriverModel] = [
        .init(id: "B173", name: "Nothing Ear (3)", vendor: "Nothing", features: ["battery", "anc", "eq", "spatial"]),
        .init(id: "B155", name: "Nothing Ear (2)", vendor: "Nothing", features: ["battery", "anc", "eq"]),
        .init(id: "B171", name: "Nothing Ear", vendor: "Nothing", features: ["battery", "anc", "eq"]),
        .init(id: "B162", name: "Nothing Ear (a)", vendor: "Nothing", features: ["battery", "anc", "eq"]),
        .init(id: "B170", name: "Nothing Headphone (1)", vendor: "Nothing", features: ["battery", "anc", "eq", "spatial"]),
        .init(id: "B172", name: "CMF Buds Pro 2", vendor: "CMF", features: ["battery", "anc", "eq", "spatial"]),
        .init(id: "SM-R630", name: "Samsung Galaxy Buds3 Pro", vendor: "Samsung", features: ["battery", "anc", "eq"]),
        .init(id: "SM-R510", name: "Samsung Galaxy Buds2 Pro", vendor: "Samsung", features: ["battery", "anc", "eq"]),
        .init(id: "SM-R400", name: "Samsung Galaxy Buds FE", vendor: "Samsung", features: ["battery", "anc", "eq"]),
        .init(id: "WH-1000XM6", name: "Sony WH-1000XM6", vendor: "Sony", features: ["battery", "anc"]),
        .init(id: "WF-1000XM6", name: "Sony WF-1000XM6", vendor: "Sony", features: ["battery", "anc"]),
        .init(id: "WH-1000XM5", name: "Sony WH-1000XM5", vendor: "Sony", features: ["battery", "anc"]),
        .init(id: "WF-1000XM5", name: "Sony WF-1000XM5", vendor: "Sony", features: ["battery", "anc"]),
        .init(id: "WH-CH720N", name: "Sony WH-CH720N", vendor: "Sony", features: ["battery", "anc"]),
        .init(id: "A3040", name: "Soundcore Space Q45", vendor: "Soundcore", features: ["battery", "anc"]),
        .init(id: "A3028", name: "Soundcore Life Q30", vendor: "Soundcore", features: ["battery", "anc"]),
        .init(id: "A3027", name: "Soundcore Life Q35", vendor: "Soundcore", features: ["battery", "anc"])
    ]
    public static let featureNames = ["battery": "Battery", "anc": "Noise control", "eq": "EQ presets", "spatial": "Spatial audio"]
    public static func source(_ driver: String) -> String {
        switch driver {
        case samsungID: "https://github.com/timschneeb/GalaxyBudsClient"
        case sonyID: "https://github.com/mos9527/SonyHeadphonesClient"
        case soundcoreID: "https://github.com/Oppzippy/OpenSCQ30"
        default: "https://github.com/bestK1ngArthur/swift-nothing-ear"
        }
    }
    public static func authors(_ driver: String) -> [String] {
        switch driver {
        case samsungID: ["Tim Schneeberger (timschneeb / ThePBone) and contributors"]
        case sonyID: ["mos9527", "Amr Satrio", "SonyHeadphonesClient contributors"]
        case soundcoreID: ["Oppzippy and OpenSCQ30 contributors"]
        default: ["bestK1ngArthur and contributors", "Ear (web) contributors"]
        }
    }
    public static func options(_ feature: String, profile: DeviceProfile) -> [String] {
        guard permits(feature, profile: profile) else { return [] }
        if feature == "anc" {
            if profile.driver == nothingID { return ["Off", "Transparency", "Low", "Medium", "High", "Adaptive"] }
            let basic = ["Off", "Noise cancelling", "Transparency"]
            return basic + (profile.model == "SM-R630" ? ["Adaptive"] : [])
        }
        if feature == "eq" {
            return profile.driver == samsungID ? ["Balanced", "Bass boost", "Soft", "Dynamic", "Clear", "Treble boost"] : ["Balanced", "More Bass", "More Treble", "Voice"]
        }
        return feature == "spatial" ? ["Off", "Fixed"] : []
    }
    public static func supports(_ profile: DeviceProfile) -> Bool {
        models.contains { $0.id == profile.model && $0.driver == profile.driver && $0.vendor == profile.vendor }
    }
    public static func permits(_ feature: String, profile: DeviceProfile) -> Bool {
        supports(profile) && profile.permits(feature) && models.first { $0.id == profile.model }?.features.contains(feature) == true
    }
}
