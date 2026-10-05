import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(underlying: Error)
    case serverStatus(code: Int)
    case apiStatus(String)
    case decoding(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build the request URL."
        case let .requestFailed(underlying):
            return "Network error: \(underlying.localizedDescription)"
        case let .serverStatus(code):
            return "The server responded with HTTP \(code)."
        case let .apiStatus(status):
            return "The API reported status \"\(status)\"."
        case let .decoding(underlying):
            return "The response could not be read: \(underlying.localizedDescription)"
        }
    }
}