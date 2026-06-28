//
//  MenuBar_ManagerUITests.swift
//  MenuBar-ManagerUITests
//
//  Created by Yongjun Zhang on 2026-06-28.
//

import XCTest

final class MenuBar_ManagerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDiagnosticsWorkflowShowsHealthControls() throws {
        let app = launchApp(opening: "--ui-testing-show-diagnostics")

        assertButton("Refresh", in: app)
        assertButton("Fix Automatically", in: app)
        assertButton("Reset Basic Mode", in: app)
        assertButton("Disable Pro Mode", in: app)
        assertButton("Export Health Report", in: app)
        assertButton("Safe Mode Next Launch", in: app)
    }

    @MainActor
    func testPrivacyWorkflowKeepsBasicModePermissionFree() throws {
        let app = launchApp(opening: "--ui-testing-show-privacy")

        assertStaticText("Basic Mode (default, fully usable)", in: app)
        assertStaticText("Screen Recording", in: app)
        assertStaticText("Apple Events", in: app)
        assertStaticText("Input Monitoring", in: app)
        assertStaticText("Network Access", in: app)
        assertStaticText("Not Used", in: app)
        assertStaticText("Not Requested", in: app)
    }

    @MainActor
    func testSearchUnavailableStateIsVisibleWithoutProMode() throws {
        let app = launchApp(opening: "--ui-testing-show-search")

        assertStaticText("Pro Mode Required", in: app)
        assertButton("Enable Pro Mode", in: app)
        assertButton("Open Privacy Settings", in: app)
    }

    @MainActor
    func testSecondBarSettingsShowsRequirementsWithoutProMode() throws {
        let app = launchApp(opening: "--ui-testing-show-second-bar-settings")

        assertStaticText("Second Bar", in: app)
        assertStaticText("Second Bar uses Accessibility snapshots and app bundle icons. It does not use Screen Recording or captured menu bar pixels.", in: app)
        app.scrollViews.firstMatch.swipeUp()
        assertStaticText("Pro Mode", in: app)
        assertStaticText("Disabled", in: app)
        assertStaticText("Accessibility Permission", in: app)
        assertButton("Open Privacy Settings", in: app)
    }

    @MainActor
    func testLaunchInUITestingMode() throws {
        let app = launchApp()

        XCTAssertNotEqual(app.state, .notRunning)
    }

    @MainActor
    private func launchApp(opening argument: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + [argument].compactMap(\.self)
        app.launch()
        return app
    }

    @MainActor
    private func assertStaticText(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts[label].waitForExistence(timeout: 5),
            "Expected static text '\(label)' to exist.",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertButton(
        _ label: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.buttons[label].waitForExistence(timeout: 5),
            "Expected button '\(label)' to exist.",
            file: file,
            line: line
        )
    }
}
