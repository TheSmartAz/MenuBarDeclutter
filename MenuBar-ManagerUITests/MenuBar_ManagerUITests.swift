//
//  MenuBar_ManagerUITests.swift
//  MenuBar-ManagerUITests
//
//  Created by Yongjun Zhang on 2026-06-28.
//

import XCTest

final class MenuBar_ManagerUITests: XCTestCase {
    private struct VisualSmokePage {
        let name: String
        let arguments: [String]
        let pageIdentifier: String
        let expectedText: String
    }

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

        assertElement("privacy.basicMode.section", in: app)
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

        assertStaticText("Find Icon Disabled", in: app)
        assertButton("Enable Find Icon", in: app)
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
    func testRedesignedSettingsPagesVisualSmoke() throws {
        let pages = [
            VisualSmokePage(
                name: "General",
                arguments: ["--ui-testing-show-general"],
                pageIdentifier: "settings.page.general",
                expectedText: "General"
            ),
            VisualSmokePage(
                name: "Behavior",
                arguments: ["--ui-testing-show-behavior"],
                pageIdentifier: "settings.page.behavior",
                expectedText: "Behavior"
            ),
            VisualSmokePage(
                name: "Layout",
                arguments: ["--ui-testing-show-layout", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.layout",
                expectedText: "Layout"
            ),
            VisualSmokePage(
                name: "Menu Bar Items",
                arguments: ["--ui-testing-show-menu-bar-items", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.menuBarItems",
                expectedText: "Menu Bar Items"
            ),
            VisualSmokePage(
                name: "Search",
                arguments: ["--ui-testing-show-search-settings"],
                pageIdentifier: "settings.page.search",
                expectedText: "Search"
            ),
            VisualSmokePage(
                name: "Second Bar",
                arguments: ["--ui-testing-show-second-bar-settings", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.secondBar",
                expectedText: "Second Bar"
            ),
            VisualSmokePage(
                name: "Groups",
                arguments: ["--ui-testing-show-groups", "--ui-testing-seed-groups", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.groups",
                expectedText: "Groups"
            ),
            VisualSmokePage(
                name: "Hotkeys",
                arguments: ["--ui-testing-show-hotkeys", "--ui-testing-seed-groups", "--ui-testing-seed-profiles"],
                pageIdentifier: "settings.page.hotkeys",
                expectedText: "Hotkeys"
            ),
            VisualSmokePage(
                name: "Profiles",
                arguments: ["--ui-testing-show-profiles", "--ui-testing-seed-profiles", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.profiles",
                expectedText: "Profiles"
            ),
            VisualSmokePage(
                name: "Automation",
                arguments: ["--ui-testing-show-automation"],
                pageIdentifier: "settings.page.automation",
                expectedText: "Automation"
            ),
            VisualSmokePage(
                name: "Privacy",
                arguments: ["--ui-testing-show-privacy"],
                pageIdentifier: "settings.page.privacy",
                expectedText: "Privacy"
            ),
            VisualSmokePage(
                name: "Private Access",
                arguments: ["--ui-testing-show-private-access"],
                pageIdentifier: "settings.page.privateAccess",
                expectedText: "Private Access"
            ),
            VisualSmokePage(
                name: "Import Export",
                arguments: ["--ui-testing-show-import-export", "--ui-testing-seed-groups", "--ui-testing-seed-profiles"],
                pageIdentifier: "settings.page.importExport",
                expectedText: "Import / Export"
            ),
            VisualSmokePage(
                name: "Diagnostics",
                arguments: ["--ui-testing-show-diagnostics"],
                pageIdentifier: "settings.page.diagnostics",
                expectedText: "Diagnostics"
            ),
            VisualSmokePage(
                name: "Advanced",
                arguments: ["--ui-testing-show-advanced"],
                pageIdentifier: "settings.page.advanced",
                expectedText: "Advanced"
            )
        ]

        for page in pages {
            XCTContext.runActivity(named: "Visual smoke: \(page.name)") { _ in
                let app = launchApp(opening: page.arguments)
                defer { app.terminate() }

                let window = assertSettingsWindow(in: app)
                assertElement(page.pageIdentifier, in: app, timeout: 10)
                assertStaticText(page.expectedText, in: app, timeout: 5)

                let attachment = XCTAttachment(screenshot: window.screenshot())
                attachment.name = "Settings - \(page.name)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor
    func testSettingsSearchFieldFocusAndFiltering() throws {
        let app = launchApp(opening: "--ui-testing-show-settings")
        let window = assertSettingsWindow(in: app)
        assertElement("settings.page.general", in: app, timeout: 10)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Expected the Settings search field to exist.")
        searchField.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).click()
        app.typeText("privacy")

        XCTAssertTrue(
            app.staticTexts["Privacy"].waitForExistence(timeout: 5),
            "Expected focused Settings search to reveal the Privacy sidebar result."
        )
        assertElement("settings.sidebar.privacy", in: app, timeout: 5)
        XCTAssertFalse(
            app.descendants(matching: .any)["settings.sidebar.general"].exists,
            "Expected focused Settings search to filter non-matching sidebar rows."
        )

        let value = String(describing: searchField.value ?? "")
        XCTAssertTrue(
            value.localizedStandardContains("privacy"),
            "Expected typing to land in Settings search, got value: \(value)."
        )

        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = "Settings - Keyboard Search Focus"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSearchPanelEscapeDismisses() throws {
        let app = launchApp(opening: "--ui-testing-show-search")

        assertStaticText("Find Icon Disabled", in: app)
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])

        XCTAssertFalse(
            app.staticTexts["Find Icon Disabled"].waitForExistence(timeout: 3),
            "Expected Escape to dismiss the floating Find Icon panel."
        )
    }

    @MainActor
    func testSettingsWindowSizingAndAdvancedContentStructure() throws {
        let app = launchApp(opening: "--ui-testing-show-advanced")
        let window = assertSettingsWindow(in: app)

        XCTAssertGreaterThanOrEqual(window.frame.width, 980)
        XCTAssertGreaterThanOrEqual(window.frame.height, 620)
        assertElement("settings.page.advanced", in: app, timeout: 10)
        assertStaticText("Separator Geometry", in: app)

        let developerNotes = app.staticTexts["Developer Notes"]
        XCTAssertTrue(developerNotes.exists, "Expected Advanced page bottom content to exist.")

        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = "Settings - Advanced Window Structure"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func launchApp(opening argument: String? = nil) -> XCUIApplication {
        launchApp(opening: [argument].compactMap(\.self))
    }

    @MainActor
    private func launchApp(opening arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + arguments
        app.launch()
        return app
    }

    @MainActor
    private func assertStaticText(
        _ label: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts[label].waitForExistence(timeout: timeout),
            "Expected static text '\(label)' to exist.",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertButton(
        _ label: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.buttons[label].waitForExistence(timeout: timeout),
            "Expected button '\(label)' to exist.",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertElement(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout),
            "Expected element '\(identifier)' to exist.",
            file: file,
            line: line
        )
    }

    @MainActor
    @discardableResult
    private func assertSettingsWindow(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = app.windows.firstMatch
        XCTAssertTrue(
            window.waitForExistence(timeout: 10),
            "Expected the Settings window to exist.",
            file: file,
            line: line
        )
        return window
    }
}
