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
    func testRecoveryWorkflowShowsLostIconControls() throws {
        let app = launchApp(opening: "--ui-testing-show-recovery")

        assertStaticText("I can't find my icons", in: app)
        assertElement("recovery.lostIcons.actions", in: app)
        assertButton("Expand", in: app)
        assertButton("Reveal All", in: app)
        assertButton("Reset Layout", in: app)
        assertButton("Open Guide", in: app)
        assertButton("Refresh", in: app)
        assertButton("Fix Automatically", in: app)
        assertButton("Recreate", in: app)
        assertButton("Reset Basic Mode", in: app)
        assertButton("Disable Pro Mode", in: app)
        assertButton("Export Diagnostics", in: app)
        assertButton("Safe Mode Next Launch", in: app)
    }

    @MainActor
    func testPrivacyWorkflowKeepsBasicModePermissionFree() throws {
        let app = launchApp(opening: "--ui-testing-show-privacy")

        assertElement("privacy.basicMode.section", in: app)
        assertStaticText("Screen Recording", in: app)
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Expected Privacy settings to scroll.")
        scrollView.swipeUp()
        assertStaticText("Apple Events", in: app)
        assertStaticText("Input Monitoring", in: app)
        assertStaticText("Not Requested", in: app)
        assertStaticText("Network Access", in: app)
        assertStaticText("Not Used", in: app)
    }

    @MainActor
    func testPrivacyProDiscoverySetupStaysExplicit() throws {
        let app = launchApp(opening: "--ui-testing-show-privacy")
        let scrollView = app.scrollViews["settings.page.privacy"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Expected Privacy settings to scroll.")

        for _ in 0..<2 {
            if scrollView.waitForExistence(timeout: 2) {
                scrollView.swipeUp()
            }
        }

        assertStaticText("Optional Pro Discovery", in: app)
        assertButton("Enable Pro Mode", in: app, scrolling: scrollView)
        assertStaticText("Accessibility Discovery", in: app)
        assertStaticText("Accessibility Permission", in: app)

        let requestPermission = app.buttons["Request Permission"]
        XCTAssertTrue(requestPermission.waitForExistence(timeout: 5), "Expected explicit Request Permission button.")
        XCTAssertFalse(requestPermission.isEnabled, "Request Permission should stay disabled until Pro Mode is explicitly enabled.")

        let enableProMode = app.buttons["Enable Pro Mode"]
        XCTAssertTrue(enableProMode.waitForExistence(timeout: 5), "Expected Enable Pro Mode button before clicking.")
        enableProMode.click()
        assertStaticText("Pro Mode is on, but discovery is disabled. Pro features degrade to their unavailable state until discovery is enabled.", in: app)
        XCTAssertFalse(
            requestPermission.isEnabled,
            "The UI-test harness has no permission service, so Pro Mode alone must not make a system prompt path active."
        )
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
    func testArrangePageShowsGuidedManualFlow() throws {
        let app = launchApp(opening: ["--ui-testing-show-arrange", "--ui-testing-seed-menu-bar-items"])
        let scrollView = app.scrollViews["settings.page.arrange"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Expected Arrange settings page to scroll.")

        assertStaticText("How menu bar hiding works", in: app)
        assertElement("arrange.step.dragControl", in: app, scrolling: scrollView)
        assertElement("arrange.step.dragSeparator", in: app, scrolling: scrollView)
        assertButton("Expand", in: app, scrolling: scrollView)
        assertButton("Collapse", in: app, scrolling: scrollView)
        assertButton("Reveal All", in: app, scrolling: scrollView)
        assertButton("Reset Layout", in: app, scrolling: scrollView)
        assertButton("Show Drag Hint", in: app, scrolling: scrollView)
    }

    @MainActor
    func testFindAndRescuePageShowsPrimaryActionsAndGateReasons() throws {
        let app = launchApp(opening: ["--ui-testing-show-find-rescue", "--ui-testing-seed-menu-bar-items"])

        assertStaticText("Find & Rescue", in: app)
        assertButton("Open Find Icon", in: app)
        assertButton("Show Second Bar", in: app)
        assertButton("Open Inspector", in: app)

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Expected the Find & Rescue settings page to scroll.")
        scrollView.swipeUp()

        assertStaticText("Find Icon", in: app)
        assertStaticText("Second Bar", in: app)
        assertStaticText("Crowded menu rescue", in: app)
        assertStaticText("This command requires Pro Mode. Gate: Pro Mode.", in: app)
        XCTAssertFalse(
            app.staticTexts["Command Center: Find Icon"].exists,
            "Find & Rescue should not expose internal Command Center terminology."
        )
    }

    @MainActor
    func testLaunchInUITestingMode() throws {
        let app = launchApp()

        XCTAssertNotEqual(app.state, .notRunning)
    }

    @MainActor
    func testSettingsSidebarUsesFocusedSections() throws {
        let app = launchApp(opening: "--ui-testing-show-general")
        assertSettingsWindow(in: app)

        let expectedSidebarIDs = [
            "settings.sidebar.general",
            "settings.sidebar.hideReveal",
            "settings.sidebar.arrange",
            "settings.sidebar.findRescue",
            "settings.sidebar.workspacesPreview",
            "settings.sidebar.privacy",
            "settings.sidebar.recovery",
            "settings.sidebar.advanced"
        ]

        for identifier in expectedSidebarIDs {
            assertElement(identifier, in: app)
        }

        let hiddenHeavySectionIDs = [
            "settings.sidebar.privateAccess",
            "settings.sidebar.groups",
            "settings.sidebar.hotkeys",
            "settings.sidebar.profiles",
            "settings.sidebar.automation",
            "settings.sidebar.importExport",
            "settings.sidebar.menuBarItems",
            "settings.sidebar.layout"
        ]

        for identifier in hiddenHeavySectionIDs {
            XCTAssertFalse(
                app.descendants(matching: .any)[identifier].exists,
                "Expected heavy surface '\(identifier)' to stay out of the top-level Settings sidebar."
            )
        }
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
                name: "Hide & Reveal",
                arguments: ["--ui-testing-show-hide-reveal"],
                pageIdentifier: "settings.page.hideReveal",
                expectedText: "Hide & Reveal"
            ),
            VisualSmokePage(
                name: "Arrange",
                arguments: ["--ui-testing-show-arrange", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.arrange",
                expectedText: "Arrange"
            ),
            VisualSmokePage(
                name: "Find & Rescue",
                arguments: ["--ui-testing-show-find-rescue", "--ui-testing-seed-menu-bar-items"],
                pageIdentifier: "settings.page.findRescue",
                expectedText: "Find & Rescue"
            ),
            VisualSmokePage(
                name: "Workspaces",
                arguments: ["--ui-testing-show-workspaces"],
                pageIdentifier: "settings.page.workspacesPreview",
                expectedText: "Workspaces"
            ),
            VisualSmokePage(
                name: "Privacy",
                arguments: ["--ui-testing-show-privacy"],
                pageIdentifier: "settings.page.privacy",
                expectedText: "Privacy"
            ),
            VisualSmokePage(
                name: "Recovery",
                arguments: ["--ui-testing-show-recovery"],
                pageIdentifier: "settings.page.recovery",
                expectedText: "Recovery"
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
                defer { terminateApplication(app) }

                let window = assertSettingsWindow(in: app)
                assertElement(page.pageIdentifier, in: app, timeout: 15)
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
        let app = launchApp(opening: "--ui-testing-show-general")
        let window = assertSettingsWindow(in: app)
        assertElement("settings.page.general", in: app, timeout: 10)
        app.activate()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Expected the Settings search field to exist.")
        searchField.click()
        searchField.typeText("privacy")

        XCTAssertTrue(
            app.staticTexts["Privacy"].waitForExistence(timeout: 5),
            "Expected focused Settings search to reveal the Privacy sidebar result."
        )
        assertElement("settings.sidebar.privacy", in: app, timeout: 5)

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
    func testFloatingPanelsVisualSmoke() throws {
        let searchApp = launchApp(opening: "--ui-testing-show-search")
        assertStaticText("Find Icon Disabled", in: searchApp)
        assertButton("Enable Find Icon", in: searchApp)

        let searchAttachment = XCTAttachment(screenshot: searchApp.screenshot())
        searchAttachment.name = "Floating Panel - Find Icon Disabled"
        searchAttachment.lifetime = .keepAlways
        add(searchAttachment)
        terminateApplication(searchApp)

        let secondBarApp = launchApp(opening: "--ui-testing-show-second-bar")
        assertStaticText("Pro Mode Required", in: secondBarApp, timeout: 10)
        assertStaticText(
            "Second Bar uses the optional Accessibility discovery index. Basic Mode still works without permissions.",
            in: secondBarApp
        )
        assertButton("Enable Pro Mode", in: secondBarApp)

        let secondBarAttachment = XCTAttachment(screenshot: secondBarApp.screenshot())
        secondBarAttachment.name = "Floating Panel - Second Bar Unavailable"
        secondBarAttachment.lifetime = .keepAlways
        add(secondBarAttachment)
    }

    @MainActor
    func testSettingsWindowSizingAndAdvancedContentStructure() throws {
        let app = launchApp(opening: "--ui-testing-show-advanced")
        let window = assertSettingsWindow(in: app)

        XCTAssertGreaterThanOrEqual(window.frame.width, 820)
        XCTAssertGreaterThanOrEqual(window.frame.height, 620)
        assertElement("settings.page.advanced", in: app, timeout: 10)
        let scrollView = app.scrollViews["settings.page.advanced"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Expected Advanced settings page to scroll.")
        assertElement("advanced.featureDirectory", in: app, scrolling: scrollView, maxSwipes: 2)
        assertElement("advanced.separatorGeometry", in: app, scrolling: scrollView, maxSwipes: 12)
        assertElement("advanced.labs", in: app, scrolling: scrollView, maxSwipes: 12)
        assertElement("advanced.developerNotes", in: app, scrolling: scrollView, maxSwipes: 12)

        let developerNotes = app.descendants(matching: .any)["advanced.developerNotes"]
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
        terminateApplication(app)
        app.launch()
        XCTAssertTrue(
            waitForApplication(app, toReach: .runningForeground, timeout: 10)
            || waitForApplication(app, toReach: .runningBackground, timeout: 2),
            "Expected MenuBarDeclutter to launch for UI testing."
        )
        app.activate()
        return app
    }

    @MainActor
    private func terminateApplication(_ app: XCUIApplication) {
        app.terminate()
        _ = waitForApplication(app, toReach: .notRunning, timeout: 5)
    }

    @MainActor
    private func waitForApplication(
        _ app: XCUIApplication,
        toReach state: XCUIApplication.State,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if app.state == state {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return app.state == state
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
    private func assertStaticText(
        _ label: String,
        in app: XCUIApplication,
        scrolling scrollView: XCUIElement,
        maxSwipes: Int = 6,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let text = app.staticTexts[label]
        let fallbackElement = app.descendants(matching: .any)[label]
        if text.waitForExistence(timeout: 1) || fallbackElement.waitForExistence(timeout: 1) {
            return
        }

        for _ in 0..<maxSwipes {
            if scrollView.waitForExistence(timeout: 1) {
                scrollDownOneStep(scrollView)
            }

            if text.waitForExistence(timeout: 1) || fallbackElement.waitForExistence(timeout: 1) {
                return
            }
        }

        XCTFail(
            "Expected static text '\(label)' to exist after scrolling.",
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
    private func assertButton(
        _ label: String,
        in app: XCUIApplication,
        scrolling scrollView: XCUIElement,
        maxSwipes: Int = 6,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons[label]
        let fallbackElement = app.descendants(matching: .any)[label]
        if button.waitForExistence(timeout: 1) || fallbackElement.waitForExistence(timeout: 1) {
            return
        }

        for _ in 0..<maxSwipes {
            if scrollView.waitForExistence(timeout: 1) {
                scrollDownOneStep(scrollView)
            }

            if button.waitForExistence(timeout: 1) || fallbackElement.waitForExistence(timeout: 1) {
                return
            }
        }

        XCTFail(
            "Expected button '\(label)' to exist after scrolling.",
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
    private func assertElement(
        _ identifier: String,
        in app: XCUIApplication,
        scrolling scrollView: XCUIElement,
        maxSwipes: Int = 6,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)[identifier]
        if element.waitForExistence(timeout: 1) {
            return
        }

        for _ in 0..<maxSwipes {
            if scrollView.waitForExistence(timeout: 1) {
                scrollDownOneStep(scrollView)
            }

            if element.waitForExistence(timeout: 1) {
                return
            }
        }

        XCTFail(
            "Expected element '\(identifier)' to exist after scrolling.",
            file: file,
            line: line
        )
    }

    @MainActor
    private func scrollDownOneStep(_ scrollView: XCUIElement) {
        scrollView.swipeUp()
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
