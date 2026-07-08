import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("AXMenuBarScanner Live Fixture")
@MainActor
struct AXMenuBarScannerLiveFixtureTests {
    @Test func scannerReadsRunningFixtureWhenExplicitlyEnabled() async throws {
        guard ProcessInfo.processInfo.environment["MBD_LIVE_FIXTURE_TEST"] == "1" else {
            return
        }

        let fixtureApp = try #require(
            NSWorkspace.shared.runningApplications.first { application in
                application.localizedName == "MenuBarFixtureApp"
            }
        )

        let scanner = AXMenuBarScanner(
            diagnosticsLogger: DiagnosticsLogger(),
            now: { Date(timeIntervalSince1970: 100) }
        )
        let context = MenuBarScanContext(
            primarySeparatorFrame: CGRect(x: 1_000, y: 4, width: 24, height: 24),
            alwaysHiddenSeparatorFrame: nil,
            screenFrames: NSScreen.screens.map(\.frame),
            runningApplications: [
                RunningApplicationSnapshot(
                    processIdentifier: fixtureApp.processIdentifier,
                    bundleIdentifier: fixtureApp.bundleIdentifier,
                    localizedName: fixtureApp.localizedName
                )
            ]
        )

        let result = await scanner.scan(context: context)

        #expect(result.snapshots.count >= 10)
        #expect(result.snapshots.contains { $0.title == "Fixture Icon 1" })
        #expect(result.snapshots.contains { $0.title == "Fixture Long Menu" })
    }

    @Test func scannerFindsFixtureDuringFullApplicationSweepWhenExplicitlyEnabled() async throws {
        guard ProcessInfo.processInfo.environment["MBD_LIVE_FIXTURE_TEST"] == "1" else {
            return
        }

        let fixtureApp = try #require(
            NSWorkspace.shared.runningApplications.first { application in
                application.localizedName == "MenuBarFixtureApp"
            }
        )

        let scanner = AXMenuBarScanner(
            diagnosticsLogger: DiagnosticsLogger(),
            now: { Date(timeIntervalSince1970: 100) }
        )
        let context = MenuBarScanContext(
            primarySeparatorFrame: CGRect(x: 1_000, y: 4, width: 24, height: 24),
            alwaysHiddenSeparatorFrame: nil,
            screenFrames: NSScreen.screens.map(\.frame),
            runningApplications: NSWorkspace.shared.runningApplications
                .filter { $0.isTerminated == false }
                .map {
                    RunningApplicationSnapshot(
                        processIdentifier: $0.processIdentifier,
                        bundleIdentifier: $0.bundleIdentifier,
                        localizedName: $0.localizedName
                    )
                }
        )

        let result = await scanner.scan(context: context)
        let fixtureSnapshots = result.snapshots.filter {
            $0.owningProcessIdentifier == fixtureApp.processIdentifier
        }

        #expect(fixtureSnapshots.count >= 10)
        #expect(fixtureSnapshots.contains { $0.title == "Fixture Icon 1" })
        #expect(fixtureSnapshots.contains { $0.title == "Fixture Long Menu" })
        #expect(result.axFailuresCount < 3)
    }

    @Test func directActivationUsesShowMenuFallbackForFixtureMenuWhenExplicitlyEnabled() async throws {
        guard ProcessInfo.processInfo.environment["MBD_LIVE_FIXTURE_TEST"] == "1" else {
            return
        }

        let fixtureApp = try #require(
            NSWorkspace.shared.runningApplications.first { application in
                application.localizedName == "MenuBarFixtureApp"
            }
        )

        let scanner = AXMenuBarScanner(
            diagnosticsLogger: DiagnosticsLogger(),
            now: { Date(timeIntervalSince1970: 100) }
        )
        let context = MenuBarScanContext(
            primarySeparatorFrame: CGRect(x: 1_000, y: 4, width: 24, height: 24),
            alwaysHiddenSeparatorFrame: nil,
            screenFrames: NSScreen.screens.map(\.frame),
            runningApplications: [
                RunningApplicationSnapshot(
                    processIdentifier: fixtureApp.processIdentifier,
                    bundleIdentifier: fixtureApp.bundleIdentifier,
                    localizedName: fixtureApp.localizedName
                )
            ]
        )

        let scanResult = await scanner.scan(context: context)
        let menuSnapshot = try #require(scanResult.snapshots.first { $0.title == "Fixture Menu 1" })
        let activationService = MenuBarItemDirectActivationService(
            diagnosticsLogger: DiagnosticsLogger(),
            runningApplicationsProvider: {
                [
                    RunningApplicationSnapshot(
                        processIdentifier: fixtureApp.processIdentifier,
                        bundleIdentifier: fixtureApp.bundleIdentifier,
                        localizedName: fixtureApp.localizedName
                    )
                ]
            }
        )

        let activationResult = activationService.activate(snapshot: menuSnapshot)
        sendEscapeKey()

        #expect(activationResult.didActivate)
        #expect(activationResult.matrixOutcome == .pass)
    }

    private func sendEscapeKey() {
        CGEvent(
            keyboardEventSource: nil,
            virtualKey: 53,
            keyDown: true
        )?.post(tap: .cghidEventTap)
        CGEvent(
            keyboardEventSource: nil,
            virtualKey: 53,
            keyDown: false
        )?.post(tap: .cghidEventTap)
    }
}
