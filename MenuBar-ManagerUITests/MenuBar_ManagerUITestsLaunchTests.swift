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
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.page.general"].waitForExistence(timeout: 10),
            "Expected Settings to open on the General page for launch screenshot capture."
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
