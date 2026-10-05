import Alamofire
import Foundation

/// Thin wrapper over Alamofire that adds validation, decoding and
/// cancellation support on top of a single shared session.
struct APIClient {
    private let session: Session

    init(timeout: TimeInterval = 20) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        configuration.requestCachePolicy = .useProtocolCachePolicy
        session = Session(configuration: configuration)
    }

    /// Builds a cancellable request so callers can abandon in-flight work.
    func makeRequest(path: String, parameters: Parameters? = nil) throws -> DataRequest {
        guard let url = URL(string: DogAPI.baseURL + path) else {
            throw APIError.invalidURL
        }
        return session.request(url, method: .get, parameters: parameters)
    }

    func value<T: Decodable>(for request: DataRequest, as type: T.Type) async throws -> T {
        let response = await request
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(type, decoder: JSONDecoder())
            .response

        switch response.result {
        case let .success(value):
            return value
        case let .failure(error):
            if error.isExplicitlyCancelledError {
                throw CancellationError()
            }
            if let code = error.responseCode {
                throw APIError.serverStatus(code: code)
            }
            throw APIError.requestFailed(underlying: error)
        }
    }

    @discardableResult
    func get<T: Decodable>(_ type: T.Type, path: String, parameters: Parameters? = nil) async throws -> T {
        try await value(for: makeRequest(path: path, parameters: parameters), as: type)
    }
}