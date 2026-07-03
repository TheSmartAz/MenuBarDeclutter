//
//  MenuBar_ManagerUITestsLaunchTests.swift
//  MenuBar-ManagerUITests
//
//  Created by Yongjun Zhang on 2026-06-28.
//

import XCTest

final class MenuBar_ManagerUITestsLaunchTests: XCTestCase {
    private static let targetBundleIdentifier = "Yongjun-Zhang.MenuBarDeclutter"

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        terminateAnyRunningTargetApplication()
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-show-general"]
        terminateApplication(app)
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        app.launch()
        XCTAssertTrue(
            waitForApplicationToRun(app, timeout: 15),
            "Expected MenuBarDeclutter to launch for screenshot capture."
        )
        app.activate()
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.page.general"].waitForExistence(timeout: 15),
            "Expected Settings to open on the General page for launch screenshot capture."
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func terminateApplication(_ app: XCUIApplication) {
        app.terminate()
        _ = waitForApplication(app, toReach: .notRunning, timeout: 5)
        let runningApp = XCUIApplication(bundleIdentifier: Self.targetBundleIdentifier)
        if runningApp.state != .notRunning {
            runningApp.terminate()
            _ = waitForApplication(runningApp, toReach: .notRunning, timeout: 5)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
    }

    @MainActor
    private func terminateAnyRunningTargetApplication() {
        let runningApp = XCUIApplication(bundleIdentifier: Self.targetBundleIdentifier)
        if runningApp.state != .notRunning {
            runningApp.terminate()
            _ = waitForApplication(runningApp, toReach: .notRunning, timeout: 5)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
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
    private func waitForApplicationToRun(
        _ app: XCUIApplication,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            switch app.state {
            case .runningForeground, .runningBackground:
                return true
            default:
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }

        return app.state == .runningForeground || app.state == .runningBackground
    }
}
