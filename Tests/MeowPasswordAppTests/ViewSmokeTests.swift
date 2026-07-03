import XCTest
import SwiftUI
import AppKit
@testable import MeowPasswordApp

/// UI smoke tests. These don't drive interaction — they mount each
/// view in an NSHostingView so SwiftUI actually runs its layout pass.
/// A crash, unresolved binding, or missing environment object will
/// surface here rather than at runtime.
@MainActor
final class ViewSmokeTests: XCTestCase {

    // MARK: - ContentView

    func testContentViewLaysOutWithFreshModel() {
        let model = GenerationModel()
        let root = ContentView().environmentObject(model)
        let host = NSHostingView(rootView: root)
        host.setFrameSize(NSSize(width: 500, height: 640))
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.frame.width, 0)
        XCTAssertGreaterThan(host.frame.height, 0)
    }

    func testContentViewLaysOutWithPopulatedModel() {
        let model = GenerationModel()
        model.bestPassword = "Cats!123@"
        model.bestScore = 8.5
        model.candidates = [
            .init(password: "Cats!123@", score: 8.5),
            .init(password: "Meow$4567", score: 7.9)
        ]
        model.analysisText = "Meow Complexity Analysis:\n- Overall Relavency: 8.50/10.0"

        let root = ContentView().environmentObject(model)
        let host = NSHostingView(rootView: root)
        host.setFrameSize(NSSize(width: 600, height: 800))
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.frame.height, 0)
    }

    func testContentViewSurfacesErrorState() {
        let model = GenerationModel()
        model.lastError = "meowpass binary not found."

        let root = ContentView().environmentObject(model)
        let host = NSHostingView(rootView: root)
        host.setFrameSize(NSSize(width: 500, height: 640))
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.frame.height, 0)
    }

    // MARK: - Menu bar

    func testMenuBarViewLaysOutInAllStates() {
        // Fresh model — no best password yet, so "Copy Best" should be hidden.
        do {
            let model = GenerationModel()
            let host = NSHostingView(rootView: MenuBarView().environmentObject(model))
            host.layoutSubtreeIfNeeded()
        }

        // Populated — best password present, "Copy Best" visible.
        do {
            let model = GenerationModel()
            model.bestPassword = "Kitten99!"
            let host = NSHostingView(rootView: MenuBarView().environmentObject(model))
            host.layoutSubtreeIfNeeded()
        }
    }

    // MARK: - Help

    func testHelpViewLaysOutAndReportsUsefulSize() {
        let host = NSHostingView(rootView: HelpView())
        host.setFrameSize(NSSize(width: 620, height: 700))
        host.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.fittingSize.width, 400)
        XCTAssertGreaterThan(host.fittingSize.height, 400)
    }
}
