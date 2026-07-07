import XCTest

/// Smoke + readability UI tests. Run the suite once with the simulator in
/// **light** appearance and once in **dark** (`fastlane ios ui_tests` after
/// `xcrun simctl ui booted appearance <light|dark>`): because the app
/// pins its game-show palette to `.preferredColorScheme(.light)`, it must
/// render the same readable UI in either device appearance — the screenshots
/// attached here are the evidence that nothing lands white-on-white.
final class MeowPasswordUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func button(_ app: XCUIApplication, contains text: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Generator screen renders and its controls exist.
    func testGeneratorRenders() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(button(app, contains: "GENERATE").waitForExistence(timeout: 15),
                      "GENERATE! button should render")
        XCTAssertTrue(button(app, contains: "MEOWGRAM").exists, "MEOWGRAM! button should render")
        attach(app, "generator")
    }

    /// MeowGram compose + decode render (launched straight into MeowGram).
    func testMeowGramRenders() {
        let app = XCUIApplication()
        app.launchArguments += ["-openMeowGram"]
        app.launch()

        XCTAssertTrue(button(app, contains: "COMPOSE").waitForExistence(timeout: 15),
                      "MeowGram COMPOSE should render")
        XCTAssertTrue(button(app, contains: "EMBED").exists, "EMBED! should render")
        attach(app, "meowgram-compose")

        button(app, contains: "DECODE").tap()
        XCTAssertTrue(button(app, contains: "PHOTOS").waitForExistence(timeout: 10),
                      "Decode controls should render")
        attach(app, "meowgram-decode")
    }
}
