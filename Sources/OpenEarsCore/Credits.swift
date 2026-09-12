import Foundation

public enum Credits {
    public static func text() throws -> String {
        guard let url = Bundle.module.url(forResource: "ACKNOWLEDGMENTS", withExtension: "md") else {
            throw CatalogError.missingResource
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
