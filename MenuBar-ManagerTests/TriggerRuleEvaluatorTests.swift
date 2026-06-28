import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("TriggerRuleEvaluator")
@MainActor
struct TriggerRuleEvaluatorTests {
    private let evaluator = TriggerRuleEvaluator()

    @Test func matchesExternalDisplayRule() {
        let context = TriggerEvaluationContext(displayCount: 2)
        #expect(evaluator.matches(rule: .externalDisplayConnected(minimumDisplayCount: 2), context: context))
    }

    @Test func matchesFrontmostAppRule() {
        let context = TriggerEvaluationContext(frontmostBundleIdentifier: "com.example.editor")
        #expect(evaluator.matches(rule: .frontmostApp(bundleIdentifier: "com.example.editor"), context: context))
    }

    @Test func matchesBatteryLowRuleOnlyWhenBatteryAvailable() {
        #expect(evaluator.matches(
            rule: .batteryLow(thresholdPercent: 20),
            context: TriggerEvaluationContext(batteryPercent: 15)
        ))
        #expect(!evaluator.matches(
            rule: .batteryLow(thresholdPercent: 20),
            context: TriggerEvaluationContext(batteryPercent: nil)
        ))
    }

    @Test func matchesTimeOfDayRule() {
        let components = DateComponents(hour: 9, minute: 30)
        #expect(evaluator.matches(
            rule: .timeOfDay(hour: 9, minute: 30),
            context: TriggerEvaluationContext(dateComponents: components)
        ))
    }

    @Test func debouncePreventsRepeatedFire() {
        let profileID = UUID()
        let trigger = TriggerModel(
            name: "Display",
            profileID: profileID,
            rule: .externalDisplayConnected(minimumDisplayCount: 2),
            debounceSeconds: 60,
            lastFiredAt: Date(timeIntervalSince1970: 100)
        )
        let context = TriggerEvaluationContext(displayCount: 2)

        #expect(!evaluator.shouldFire(
            trigger: trigger,
            context: context,
            now: Date(timeIntervalSince1970: 120)
        ))
        #expect(evaluator.shouldFire(
            trigger: trigger,
            context: context,
            now: Date(timeIntervalSince1970: 180)
        ))
    }
}
