import Foundation

/// Errors surfaced by ``NetworkClient``.
public enum NetworkError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)
}

/// Abstraction over a transport that can fetch raw `Data` for a `URL`.
public protocol NetworkClientProtocol {
    func data(for url: URL) async throws -> Data
}

/// Small URLSession-backed networking module.
public final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared,
                decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    /// Fetches raw data, validating the HTTP status code.
    public func data(for url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }
        return data
    }

    /// Fetches and decodes a `Decodable` value.
    public func decode<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let data = try await data(for: url)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }
}
