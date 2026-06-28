import AppKit
import Foundation
import Testing
@testable import MenuBar_Manager

@Suite("SafeModeService")
@MainActor
struct SafeModeServiceTests {
    @Test func previousCrashMarkerTriggersSafeBehavior() throws {
        let tempRoot = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let service = SafeModeService(
            appSupportPaths: AppSupportPaths(baseURL: tempRoot)
        )
        try service.writeRunningMarker()

        let state = service.detectLaunchState(modifierFlags: [])

        #expect(state.isSafeModeActive == true)
        #expect(state.shouldStartExpanded == true)
        #expect(state.reasons.contains(.previousCrash))
    }

    @Test func safeModeLaunchFlagIsConsumed() throws {
        let tempRoot = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let service = SafeModeService(
            appSupportPaths: AppSupportPaths(baseURL: tempRoot)
        )
        try service.requestSafeModeOnNextLaunch()

        let state = service.detectLaunchState(modifierFlags: [])

        #expect(state.isSafeModeActive == true)
        #expect(state.reasons.contains(.launchFlag))
        #expect(FileManager.default.fileExists(atPath: service.safeModeFlagURL.path) == false)
    }

    @Test func cleanTerminationClearsCrashMarker() throws {
        let tempRoot = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let service = SafeModeService(
            appSupportPaths: AppSupportPaths(baseURL: tempRoot)
        )
        try service.writeRunningMarker()
        try service.clearRunningMarker()

        let state = service.detectLaunchState(modifierFlags: [])

        #expect(state.isSafeModeActive == false)
        #expect(FileManager.default.fileExists(atPath: service.crashMarkerURL.path) == false)
    }

    @Test func optionModifierTriggersSafeMode() throws {
        let tempRoot = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let service = SafeModeService(
            appSupportPaths: AppSupportPaths(baseURL: tempRoot)
        )

        let state = service.detectLaunchState(modifierFlags: [.option])

        #expect(state.isSafeModeActive == true)
        #expect(state.reasons.contains(.modifierHeld))
    }

    private static func makeTempRoot() throws -> URL {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("SafeModeServiceTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        return tempRoot
    }
}
