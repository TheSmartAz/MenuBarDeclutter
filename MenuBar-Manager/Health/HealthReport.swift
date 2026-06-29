import Foundation

enum HealthStatus: String, CaseIterable, Codable, Sendable {
    case ok
    case warning
    case critical

    var displayName: String {
        switch self {
        case .ok:
            "OK"
        case .warning:
            "Warning"
        case .critical:
            "Critical"
        }
    }
}

struct HealthReport: Equatable, Codable, Sendable {
    let generatedAt: Date
    let issues: [HealthIssue]
    let dogfoodRunID: String?

    init(
        generatedAt: Date,
        issues: [HealthIssue],
        dogfoodRunID: String? = nil
    ) {
        self.generatedAt = generatedAt
        self.issues = issues
        self.dogfoodRunID = dogfoodRunID
    }

    var status: HealthStatus {
        if issues.contains(where: { $0.severity == .critical }) {
            return .critical
        }
        if issues.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .ok
    }

    var isHealthy: Bool {
        status == .ok
    }

    var sortedIssues: [HealthIssue] {
        issues.sorted {
            if $0.severity.sortRank != $1.severity.sortRank {
                return $0.severity.sortRank < $1.severity.sortRank
            }
            return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }

    func plainText() -> String {
        let formatter = ISO8601DateFormatter()
        var lines: [String] = [
            "MenuBarDeclutter Health Report",
            "Generated: \(formatter.string(from: generatedAt))",
            "Status: \(status.displayName)"
        ]

        if let dogfoodRunID {
            lines.append("Dogfood Run ID: \(dogfoodRunID)")
        }

        lines.append("")

        if sortedIssues.isEmpty {
            lines.append("No health issues detected.")
        } else {
            lines.append("Issues:")
            for issue in sortedIssues {
                lines.append("- [\(issue.severity.displayName)] \(issue.title)")
                lines.append("  Code: \(issue.code)")
                lines.append("  Detail: \(issue.detail)")
                if let action = issue.recoveryAction {
                    lines.append("  Suggested Recovery: \(action.displayName)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
