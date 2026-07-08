import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Pro Second Bar Setup Plan")
struct ProSecondBarSetupPlanTests {
    @Test func setupPlanAdvancesThroughRequiredStepsInOrder() {
        var input = ProSecondBarReadinessInput(
            entitlement: .basic,
            accessibilityDiscoveryEnabled: false,
            accessibilityPermission: .notRequested,
            accurateIconsEnabled: false,
            screenCapturePermission: .notGranted
        )

        var plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .missingEntitlement)
        #expect(plan.firstAction == .enableProMode)
        #expect(plan.steps.map(\.state) == [.current, .waiting, .waiting, .waiting, .waiting])

        input.entitlement = .licensed
        plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .accessibilityDiscoveryDisabled)
        #expect(plan.firstAction == .enableAccessibilityDiscovery)
        #expect(plan.steps.map(\.state) == [.complete, .current, .waiting, .waiting, .waiting])

        input.accessibilityDiscoveryEnabled = true
        plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .accessibilityPermissionMissing)
        #expect(plan.firstAction == .requestAccessibilityPermission)
        #expect(plan.steps.map(\.state) == [.complete, .complete, .current, .waiting, .waiting])

        input.accessibilityPermission = .granted
        plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .accurateIconsDisabled)
        #expect(plan.firstAction == .enableAccurateIcons)
        #expect(plan.steps.map(\.state) == [.complete, .complete, .complete, .current, .waiting])

        input.accurateIconsEnabled = true
        plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .screenRecordingMissing)
        #expect(plan.firstAction == .requestScreenRecordingPermission)
        #expect(plan.steps.map(\.state) == [.complete, .complete, .complete, .complete, .current])

        input.screenCapturePermission = .granted
        plan = ProSecondBarSetupPlan.evaluate(input)
        #expect(plan.readiness.state == .ready)
        #expect(plan.firstAction == nil)
        #expect(plan.steps.map(\.state) == [.complete, .complete, .complete, .complete, .complete])
    }

    @Test func setupPlanCarriesNativePermissionStatusLabels() {
        let deniedAccessibility = ProSecondBarSetupPlan.evaluate(ProSecondBarReadinessInput(
            entitlement: .licensed,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermission: .denied,
            accurateIconsEnabled: false,
            screenCapturePermission: .notGranted
        ))
        #expect(deniedAccessibility.steps[2].statusText == "Denied")

        let missingScreenRecording = ProSecondBarSetupPlan.evaluate(ProSecondBarReadinessInput(
            entitlement: .licensed,
            accessibilityDiscoveryEnabled: true,
            accessibilityPermission: .granted,
            accurateIconsEnabled: true,
            screenCapturePermission: .notGranted
        ))
        #expect(missingScreenRecording.steps[4].statusText == "Not Granted")
    }
}
