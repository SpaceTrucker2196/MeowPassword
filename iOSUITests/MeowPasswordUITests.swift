import XCTest

/// Smoke + readability UI tests. Run the suite once with the simulator in
/// **light** appearance and once in **dark** (`fastlane ios ui_tests` after
/// `xcrun simctl ui booted appearance <light|dark>`): because every theme
/// pins its own color scheme (the theme, not the OS, decides), the app must
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

    /// The generator renders readably in every theme, including the dark
    /// Spy Thriller (launched via the DEBUG `-theme` / `-ownAllThemes` args).
    func testGeneratorRendersInEveryTheme() {
        for theme in ["showa", "gameShowClassic", "spyThriller",
                      "kremlinCartoon", "pyongyangPoster"] {
            let app = XCUIApplication()
            app.launchArguments += ["-theme", theme, "-ownAllThemes"]
            app.launch()
            XCTAssertTrue(button(app, contains: "GENERATE").waitForExistence(timeout: 15),
                          "GENERATE! button should render in \(theme)")
            XCTAssertTrue(button(app, contains: "MEOWGRAM").exists,
                          "MEOWGRAM! button should render in \(theme)")
            attach(app, "generator-\(theme)")
            app.terminate()
        }
    }

    /// Theme Studio renders: all five theme cards plus the restore footer.
    func testThemeStudioRenders() {
        let app = XCUIApplication()
        app.launchArguments += ["-openThemeStudio", "-ownAllThemes"]
        app.launch()
        XCTAssertTrue(app.staticTexts["THEME STUDIO"].waitForExistence(timeout: 15),
                      "Theme Studio header should render")
        for name in ["SHŌWA BROADCAST", "GAMESHOW CLASSIC", "SPY THRILLER",
                     "KREMLIN CARTOON", "PYONGYANG POSTER"] {
            XCTAssertTrue(app.staticTexts[name].exists, "\(name) card should render")
        }
        XCTAssertTrue(button(app, contains: "RESTORE").exists,
                      "Restore Purchases must be present (App Review requirement)")
        attach(app, "theme-studio")
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
