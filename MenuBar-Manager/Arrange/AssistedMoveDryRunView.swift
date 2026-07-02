import SwiftUI

struct AssistedMoveDryRunView: View {
    let plan: AssistedMoveDryRunPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: plan.canExecute ? "checkmark.seal" : "exclamationmark.triangle")
                    .foregroundStyle(plan.canExecute ? .green : .orange)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.summary)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("\(plan.currentZone.displayName) -> \(plan.targetZone.menuBarZone.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ClearGlassStatusValue(
                    text: plan.canExecute ? "Ready" : "Blocked",
                    style: plan.canExecute ? .success : .warning
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                dryRunFact("Source", value: plan.currentZone.displayName)
                dryRunFact("Target", value: plan.targetZone.menuBarZone.displayName)
                dryRunFact("Direction", value: plan.plannedDragDirection)
                dryRunFact("Risk", value: plan.riskReason)
            }

            if plan.gateResult.failures.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.steps, id: \.self) { step in
                        Label(step, systemImage: "checkmark")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.gateResult.failures) { failure in
                        Label(failure.title, systemImage: "exclamationmark.circle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ClearGlassInlineMessage(
                text: "Diagnostics summary is redacted by default: \(plan.diagnosticSummary)",
                systemImage: "lock.shield",
                style: .secondary
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.46), lineWidth: 0.5)
        }
    }

    private func dryRunFact(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
