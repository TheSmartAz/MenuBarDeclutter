import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("UnlockSession")
@MainActor
struct UnlockSessionTests {
    @Test func isActiveAfterUnlock() {
        var currentTime = Date(timeIntervalSince1970: 1000)
        let session = UnlockSession(
            durationProvider: { 300 },
            now: { currentTime }
        )

        #expect(!session.isActive)

        session.unlock()
        #expect(session.isActive)

        // Move forward 200 seconds (within 300s window)
        currentTime = currentTime.addingTimeInterval(200)
        #expect(session.isActive)
    }

    @Test func expiresAfterDuration() {
        var currentTime = Date(timeIntervalSince1970: 1000)
        let session = UnlockSession(
            durationProvider: { 300 },
            now: { currentTime }
        )

        session.unlock()
        #expect(session.isActive)

        // Move forward 400 seconds (past 300s window)
        currentTime = currentTime.addingTimeInterval(400)
        #expect(!session.isActive)
    }

    @Test func clearResetsSession() {
        let session = UnlockSession(durationProvider: { 300 })
        session.unlock()
        #expect(session.isActive)

        session.clear()
        #expect(!session.isActive)
    }

    @Test func remainingSecondsCalculatesCorrectly() {
        var currentTime = Date(timeIntervalSince1970: 1000)
        let session = UnlockSession(
            durationProvider: { 300 },
            now: { currentTime }
        )

        session.unlock()
        #expect(session.remainingSeconds == 300)

        currentTime = currentTime.addingTimeInterval(100)
        #expect(session.remainingSeconds == 200)
    }
}

@Suite("PrivateAccessPolicy")
@MainActor
struct PrivateAccessPolicyTests {
    @Test func disabledPolicyProtectsNothing() {
        let suiteName = "pa-policy-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = false
        store.privateAccessProtectIconMoving = true

        let policy = PrivateAccessPolicy(store: store)
        #expect(!policy.isProtected(.iconMoving))
    }

    @Test func enabledPolicyProtectsConfiguredResources() {
        let suiteName = "pa-policy-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.privateAccessEnabled = true
        store.privateAccessProtectIconMoving = true
        store.privateAccessProtectSpacingLabs = true

        let policy = PrivateAccessPolicy(store: store)
        #expect(policy.isProtected(.iconMoving))
        #expect(policy.isProtected(.layoutSpacingLabs))
        #expect(!policy.isProtected(.revealAll))
    }

    @Test func defaultsAreSafe() {
        let suiteName = "pa-defaults-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let policy = PrivateAccessPolicy(store: store)

        #expect(!policy.isEnabled)
        #expect(policy.protectIconMoving) // true by default
        #expect(policy.protectSpacingLabs) // true by default
        #expect(!policy.protectAlwaysHidden)
        #expect(!policy.protectSecondBar)
        #expect(!policy.protectFindIcon)
    }
}
