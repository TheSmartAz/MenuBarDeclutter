import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HealthReport")
@MainActor
struct HealthReportTests {
    @Test func emptyReportIsHealthyAndPlainTextStatesNoIssues() {
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 0),
            issues: []
        )

        #expect(report.status == .ok)
        #expect(report.isHealthy)
        #expect(report.sortedIssues.isEmpty)
        #expect(report.plainText() == """
        MenuBarDeclutter Health Report
        Generated: 1970-01-01T00:00:00Z
        Status: OK

        No health issues detected.
        """)
    }

    @Test func warningIssuesProduceWarningStatus() {
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 1),
            issues: [
                Self.issue(
                    code: "warning.issue",
                    severity: .warning,
                    title: "Warning issue"
                )
            ]
        )

        #expect(report.status == .warning)
        #expect(report.isHealthy == false)
    }

    @Test func plainTextIncludesDogfoodRunIDWhenPresent() {
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 0),
            issues: [],
            dogfoodRunID: "dogfood-2026-06-28-120000"
        )

        #expect(report.plainText().contains("Dogfood Run ID: dogfood-2026-06-28-120000"))
    }

    @Test func criticalIssuesTakePrecedenceOverWarnings() {
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 1),
            issues: [
                Self.issue(code: "warning.issue", severity: .warning, title: "Warning issue"),
                Self.issue(code: "critical.issue", severity: .critical, title: "Critical issue")
            ]
        )

        #expect(report.status == .critical)
        #expect(report.isHealthy == false)
    }

    @Test func sortedIssuesOrderBySeverityThenTitle() {
        let alphaWarning = Self.issue(code: "warning.alpha", severity: .warning, title: "Alpha warning")
        let betaCritical = Self.issue(code: "critical.beta", severity: .critical, title: "Beta critical")
        let alphaCritical = Self.issue(code: "critical.alpha", severity: .critical, title: "Alpha critical")
        let betaWarning = Self.issue(code: "warning.beta", severity: .warning, title: "Beta warning")
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 1),
            issues: [alphaWarning, betaCritical, alphaCritical, betaWarning]
        )

        #expect(report.sortedIssues == [alphaCritical, betaCritical, alphaWarning, betaWarning])
    }

    @Test func plainTextListsSortedIssueDetailsAndRecoveryActions() {
        let warningWithoutRecovery = Self.issue(
            code: "warning.no-recovery",
            severity: .warning,
            title: "Warning without recovery",
            detail: "No direct recovery is available."
        )
        let criticalWithRecovery = Self.issue(
            code: "critical.with-recovery",
            severity: .critical,
            title: "Critical with recovery",
            detail: "The critical detail.",
            recoveryAction: .recreateStatusItems
        )
        let report = HealthReport(
            generatedAt: Date(timeIntervalSince1970: 0),
            issues: [warningWithoutRecovery, criticalWithRecovery]
        )

        #expect(report.plainText() == """
        MenuBarDeclutter Health Report
        Generated: 1970-01-01T00:00:00Z
        Status: Critical

        Issues:
        - [Critical] Critical with recovery
          Code: critical.with-recovery
          Detail: The critical detail.
          Suggested Recovery: Recreate status items
        - [Warning] Warning without recovery
          Code: warning.no-recovery
          Detail: No direct recovery is available.
        """)
    }

    private static func issue(
        code: String,
        severity: HealthSeverity,
        title: String,
        detail: String = "Issue detail.",
        recoveryAction: HealthRecoveryAction? = nil
    ) -> HealthIssue {
        HealthIssue(
            code: code,
            severity: severity,
            title: title,
            detail: detail,
            recoveryAction: recoveryAction
        )
    }
}
