import Foundation

struct TriggerRuleEvaluator {
    func matches(rule: TriggerRule, context: TriggerEvaluationContext) -> Bool {
        switch rule {
        case .externalDisplayConnected(let minimumDisplayCount):
            context.displayCount >= minimumDisplayCount
        case .appLaunched(let bundleIdentifier):
            context.runningBundleIdentifiers.contains(bundleIdentifier)
        case .frontmostApp(let bundleIdentifier):
            context.frontmostBundleIdentifier == bundleIdentifier
        case .batteryLow(let thresholdPercent):
            if let batteryPercent = context.batteryPercent {
                batteryPercent <= thresholdPercent
            } else {
                false
            }
        case .timeOfDay(let hour, let minute):
            context.dateComponents.hour == hour && context.dateComponents.minute == minute
        case .focusModePlaceholder:
            context.focusModeActive == true
        case .wifiSSID(let ssid):
            context.wifiSSID == ssid
        }
    }

    func shouldFire(
        trigger: TriggerModel,
        context: TriggerEvaluationContext,
        now: Date
    ) -> Bool {
        guard trigger.isEnabled, matches(rule: trigger.rule, context: context) else {
            return false
        }

        guard let lastFiredAt = trigger.lastFiredAt else {
            return true
        }

        return now.timeIntervalSince(lastFiredAt) >= trigger.debounceSeconds
    }
}
