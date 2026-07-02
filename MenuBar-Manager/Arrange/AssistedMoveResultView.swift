import SwiftUI

struct AssistedMoveRecoveryActions {
    var revealAll: (() -> Void)?
    var resetLayout: (() -> Void)?
    var retryDryRun: (() -> Void)?
    var openManualArrange: (() -> Void)?
}

struct AssistedMoveResultView: View {
    let result: IconMoveResult
    let commandResult: MenuBarCommandResult?
    let recoveryActions: AssistedMoveRecoveryActions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: result.outcome == .succeeded ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundStyle(result.outcome == .succeeded ? .green : .orange)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if let commandResult {
                        Text(commandResult.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let dragPlanSummary = result.dragPlanSummary {
                resultRow("Drag plan", value: dragPlanSummary)
            }
            if let verificationSummary = result.verificationSummary {
                resultRow("Verification", value: verificationSummary)
            }

            if result.outcome != .succeeded {
                HStack(spacing: 8) {
                    Button("Reveal All", systemImage: "rectangle.expand.vertical") {
                        recoveryActions.revealAll?()
                    }
                    Button("Reset Layout", systemImage: "arrow.counterclockwise") {
                        recoveryActions.resetLayout?()
                    }
                    Button("Retry Dry Run", systemImage: "doc.text.magnifyingglass") {
                        recoveryActions.retryDryRun?()
                    }
                    Button("Open Recovery", systemImage: "cross.case") {
                        recoveryActions.openManualArrange?()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.46), lineWidth: 0.5)
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
