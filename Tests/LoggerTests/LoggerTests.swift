import XCTest
@testable import Logger

final class LoggerTests: XCTestCase {
    private final class SpySink: LogSink {
        private(set) var messages: [(String, LogLevel)] = []
        func write(_ message: String, level: LogLevel) {
            messages.append((message, level))
        }
    }

    func testRespectsMinimumLevel() {
        let logger = Logger(minimumLevel: .warning)
        let sink = SpySink()
        logger.addSink(sink)

        logger.log("debug message", level: .debug)
        logger.log("warn message", level: .warning)

        XCTAssertEqual(sink.messages.count, 1)
        XCTAssertEqual(sink.messages.first?.0, "warn message")
        XCTAssertEqual(sink.messages.first?.1, .warning)
    }

    func testLevelOrdering() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
    }
}
