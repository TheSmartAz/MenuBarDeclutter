import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("RehideController")
@MainActor
struct RehideControllerTests {
    @Test func firesWhenElapsed() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        controller.onRehide = { fired += 1 }

        controller.startCountdown(delay: 5)

        // Tick before deadline: should not fire.
        let deadline = Date() // start countdown captures fireDeadline at this moment
        _ = deadline
        controller.processTick(
            now: Date().addingTimeInterval(3),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )
        #expect(fired == 0)

        // Tick after deadline: should fire and unschedule.
        controller.processTick(
            now: Date().addingTimeInterval(6),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )
        #expect(fired == 1)
        #expect(controller.isScheduled == false)
        #expect(controller.lastReason == .timerExpired)
    }

    @Test func runtimeTaskFiresWithoutManualTick() async throws {
        let logger = DiagnosticsLogger()
        let controller = RehideController(
            diagnosticsLogger: logger,
            pollInterval: .milliseconds(10)
        )

        var fired = 0
        controller.onRehide = {
            fired += 1
            controller.markRehideFired()
        }

        controller.startCountdown(delay: 0.02)
        let timeout = Date().addingTimeInterval(5)
        while fired == 0 && Date() < timeout {
            try await Task.sleep(for: .milliseconds(50))
            await Task.yield()
        }

        #expect(fired == 1)
        #expect(controller.isScheduled == false)
        #expect(controller.lastReason == .timerExpired)
    }

    @Test func postponesWhenConditionsChange() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        controller.onRehide = { fired += 1 }
        controller.startCountdown(delay: 5)

        let start = Date()
        let nowAtTick1 = start.addingTimeInterval(4)

        // Mouse is in the menu bar band; deadline should extend.
        controller.processTick(
            now: nowAtTick1,
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions(mouseInMenuBarBand: true)
        )

        #expect(fired == 0)
        #expect(controller.lastReason == .postponedMouseInMenuBar)
        #expect(controller.isScheduled == true)

        // After extension, the new effective deadline is nowAtTick1 + 5s.
        // A tick at nowAtTick1 + 6s should fire.
        controller.processTick(
            now: nowAtTick1.addingTimeInterval(6),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )
        #expect(fired == 1)
    }

    @Test func userCollapsedCancelsCountdown() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        controller.onRehide = { fired += 1 }
        controller.startCountdown(delay: 5)
        #expect(controller.isScheduled == true)

        controller.markUserCollapsed()
        #expect(controller.isScheduled == false)
        #expect(controller.lastReason == .userCollapsed)

        // Tick after deadline: nothing should fire because countdown was cancelled.
        controller.processTick(
            now: Date().addingTimeInterval(6),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )
        #expect(fired == 0)
    }

    @Test func disabledSettingCancelsOnNextTick() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        controller.onRehide = { fired += 1 }
        controller.startCountdown(delay: 5)

        controller.processTick(
            now: Date(),
            autoRehideEnabled: false,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )
        #expect(fired == 0)
        #expect(controller.isScheduled == false)
        #expect(controller.lastReason == .cancelled)
    }

    @Test func statusChangeCallbackFiresForSchedulePostponeAndCancel() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var statusChanges = 0
        controller.onStatusChange = { statusChanges += 1 }

        controller.startCountdown(delay: 5)
        #expect(statusChanges == 1)

        controller.processTick(
            now: Date().addingTimeInterval(4),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions(mouseInMenuBarBand: true)
        )
        #expect(statusChanges == 2)

        controller.cancel()
        #expect(statusChanges == 3)
        #expect(controller.lastReason == .cancelled)
    }

    @Test func statusChangeCallbackFiresOnceWhenAutoRehideFires() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        var statusChanges = 0
        controller.onStatusChange = { statusChanges += 1 }
        controller.onRehide = {
            fired += 1
            controller.markUserCollapsed()
            controller.markRehideFired()
        }

        controller.startCountdown(delay: 5)
        #expect(statusChanges == 1)

        controller.processTick(
            now: Date().addingTimeInterval(6),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions()
        )

        #expect(fired == 1)
        #expect(statusChanges == 2)
        #expect(controller.isScheduled == false)
        #expect(controller.lastReason == .timerExpired)
    }

    @Test func settingsWindowPostpones() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)
        var fired = 0
        controller.onRehide = { fired += 1 }
        controller.startCountdown(delay: 5)

        controller.processTick(
            now: Date().addingTimeInterval(4),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions(settingsWindowKey: true)
        )
        #expect(fired == 0)
        #expect(controller.lastReason == .postponedSettingsWindow)
    }

    @Test func menuOpenPostpones() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)
        var fired = 0
        controller.onRehide = { fired += 1 }
        controller.startCountdown(delay: 5)

        controller.processTick(
            now: Date().addingTimeInterval(4),
            autoRehideEnabled: true,
            autoRehideDelay: 5,
            conditions: RehidePostponementConditions(statusItemMenuOpen: true)
        )
        #expect(fired == 0)
        #expect(controller.lastReason == .postponedMenuOpen)
    }

    @Test func zeroDelayFiresImmediately() {
        let logger = DiagnosticsLogger()
        let controller = RehideController(diagnosticsLogger: logger)

        var fired = 0
        controller.onRehide = { fired += 1 }

        controller.startCountdown(delay: 0)
        #expect(fired == 1)
        #expect(controller.lastReason == .timerExpired)
    }
}
