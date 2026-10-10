import XCTest
@testable import Network

final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: NetworkError.invalidResponse)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class NetworkClientTests: XCTestCase {
    private func makeClient() -> NetworkClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return NetworkClient(session: URLSession(configuration: config))
    }

    func testDecodesStubbedJSON() async throws {
        struct Payload: Codable, Equatable {
            let id: Int
            let name: String
        }
        let expected = Payload(id: 1, name: "Amit")
        StubURLProtocol.handler = { request in
            let data = try JSONEncoder().encode(expected)
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, data)
        }

        let value = try await makeClient().decode(Payload.self,
                                                  from: URL(string: "https://example.com/payload")!)
        XCTAssertEqual(value, expected)
    }

    func testThrowsOnNon2xxStatus() async {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 500,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await makeClient().data(for: URL(string: "https://example.com/boom")!)
            XCTFail("Expected NetworkError.httpStatus")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .httpStatus(500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
