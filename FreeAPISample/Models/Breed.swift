import Foundation

struct Breed: Identifiable, Hashable {
    let name: String
    let subbreeds: [String]

    var id: String { name }

    var displayName: String { name.capitalized }

    var subtitle: String {
        subbreeds.isEmpty ? "Single breed" : subbreeds.capitalizedList
    }
}

extension Array where Element == String {
    var capitalizedList: String {
        map(\.capitalized).joined(separator: ", ")
    }
}

struct BreedListResponse: Decodable {
    let message: [String: [String]]
    let status: String
}