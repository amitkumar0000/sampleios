import Foundation

enum DogAPI {
    static let baseURL = "https://dog.ceo/api"
}

struct DogService {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    /// GET /breeds/list/all
    func allBreeds() async throws -> [Breed] {
        let response: BreedListResponse = try await client.get(BreedListResponse.self, path: "/breeds/list/all")
        guard response.status == "success" else {
            throw APIError.apiStatus(response.status)
        }
        return response.message
            .map { Breed(name: $0.key, subbreeds: $0.value) }
            .sorted { $0.name < $1.name }
    }

    /// GET /breed/{breed}/images/random/{count}
    func randomImages(for breed: Breed, count: Int) async throws -> [URL] {
        let response: BreedImagesResponse = try await client.get(
            BreedImagesResponse.self,
            path: "/breed/\(breed.name)/images/random/\(count)"
        )
        guard response.status == "success" else {
            throw APIError.apiStatus(response.status)
        }
        return response.message.compactMap(URL.init(string:))
    }

    /// GET /breed/{breed}/images/random
    func randomImages(for breed: Breed) async throws -> [URL] {
        let response: SingleImageResponse = try await client.get(
            SingleImageResponse.self,
            path: "/breed/\(breed.name)/images/random"
        )
        guard response.status == "success" else {
            throw APIError.apiStatus(response.status)
        }
        return [response.message.url].compactMap(URL.init(string:))
    }
}

private struct SingleImageResponse: Decodable {
    struct Payload: Decodable {
        let url: String
        let width: Int
        let height: Int
    }

    let message: Payload
    let status: String
}