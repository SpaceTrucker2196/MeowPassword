import XCTest
import AppKit
@testable import MeowPasswordApp

/// The Clipboard helper round-trips strings through NSPasteboard.
final class ClipboardTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Start each test with an empty pasteboard string type.
        NSPasteboard.general.clearContents()
    }

    func testCopyPlacesStringOnPasteboard() {
        let expected = "meow-\(UUID().uuidString)"
        Clipboard.copy(expected)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), expected)
    }

    func testReadReturnsWhatCopyPut() {
        let expected = "purr-\(UUID().uuidString)"
        Clipboard.copy(expected)
        XCTAssertEqual(Clipboard.read(), expected)
    }

    func testCopyOverwritesPrevious() {
        Clipboard.copy("first")
        Clipboard.copy("second")
        XCTAssertEqual(Clipboard.read(), "second")
    }
}
