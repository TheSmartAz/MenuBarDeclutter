//
//  MenuBar_ManagerUITestsLaunchTests.swift
//  MenuBar-ManagerUITests
//
//  Created by Yongjun Zhang on 2026-06-28.
//

import XCTest

final class MenuBar_ManagerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-show-general"]
        app.terminate()
        _ = waitForApplication(app, toReach: .notRunning, timeout: 5)
        app.launch()
        XCTAssertTrue(
            waitForApplication(app, toReach: .runningForeground, timeout: 10)
            || waitForApplication(app, toReach: .runningBackground, timeout: 2),
            "Expected MenuBarDeclutter to launch for screenshot capture."
        )
        app.activate()

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
}
