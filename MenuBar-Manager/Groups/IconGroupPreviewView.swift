import SwiftUI

struct IconGroupPreviewView: View {
    let group: IconGroup
    let snapshots: [MenuBarItemSnapshot]
    var isProtectedRedacted = false

    private let matcher = IconGroupMatcher()

    private var matchResult: IconGroupMatchResult {
        matcher.matchGroup(group, snapshots: snapshots)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: group.symbolName ?? "folder")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.headline)

                    Text("\(matchResult.matchedCount) matched, \(matchResult.unavailableCount) unavailable")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ClearGlassStatusValue(
                    text: group.isEnabled ? "Enabled" : "Disabled",
                    style: group.isEnabled ? .success : .secondary
                )
            }

            if isProtectedRedacted {
                ClearGlassInlineMessage(
                    text: "Protected group item names are redacted here while Private Access group protection is enabled.",
                    systemImage: "lock.fill",
                    style: .info
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                if group.itemRefs.isEmpty {
                    Text("No item references.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(group.itemRefs) { ref in
                        HStack {
                            Image(systemName: ref.hasMatchableCriteria ? "checkmark.circle" : "exclamationmark.triangle")
                                .foregroundStyle(ref.hasMatchableCriteria ? .green : .orange)
                            Text(isProtectedRedacted ? "Protected item" : ref.displayLabel)
                                .lineLimit(1)
                            Spacer()
                            Text(matcher.match(ref: ref, snapshots: snapshots).isEmpty ? "Unavailable" : "Matched")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
    }
}
