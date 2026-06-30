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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(groupColor.opacity(0.12))

                    Image(systemName: group.symbolName ?? "folder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(groupColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.title3)
                        .lineLimit(1)

                    Text(group.notes?.isEmpty == false ? group.notes ?? "" : "Local group")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    ClearGlassStatusValue(
                        text: group.isEnabled ? "Enabled" : "Disabled",
                        style: group.isEnabled ? .success : .secondary
                    )

                    if group.isProtected {
                        GroupDetailBadge(text: "Protected", systemImage: "lock.fill", color: .secondary)
                    }
                }
            }

            HStack(spacing: 8) {
                GroupMetricView(value: "\(group.itemCount)", label: "Items")
                GroupMetricView(value: "\(matchResult.matchedCount)", label: "Matched", valueColor: .green)
                GroupMetricView(
                    value: "\(matchResult.unavailableCount)",
                    label: "Unavailable",
                    valueColor: matchResult.unavailableCount == 0 ? .primary : .orange
                )
            }

            if isProtectedRedacted {
                ClearGlassInlineMessage(
                    text: "Protected group item names are redacted here while Private Access group protection is enabled.",
                    systemImage: "lock.fill",
                    style: .info
                )
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Item References")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if group.showAsStatusItem {
                        GroupDetailBadge(text: "Menu Bar", systemImage: "menubar.rectangle", color: .secondary)
                    }

                    if group.showInSecondBar {
                        GroupDetailBadge(text: "Second Bar", systemImage: "rectangle.bottomthird.inset.filled", color: .secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Divider()

                if group.itemRefs.isEmpty {
                    Text("No item references.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 78)
                } else {
                    ForEach(Array(group.itemRefs.enumerated()), id: \.element.id) { index, ref in
                        GroupReferencePreviewRow(
                            ref: ref,
                            matchedCount: matcher.match(ref: ref, snapshots: snapshots).count,
                            isProtectedRedacted: isProtectedRedacted
                        )

                        if index != group.itemRefs.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }

    private var groupColor: Color {
        switch group.colorName {
        case "blue":
            .blue
        case "green":
            .green
        case "orange":
            .orange
        case "purple":
            .purple
        case "red":
            .red
        default:
            .secondary
        }
    }
}

private struct GroupMetricView: View {
    let value: String
    let label: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline)
                .foregroundStyle(valueColor)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minWidth: 84, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
        }
    }
}

private struct GroupReferencePreviewRow: View {
    let ref: IconGroupItemRef
    let matchedCount: Int
    let isProtectedRedacted: Bool

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(
                bundleIdentifier: ref.bundleIdentifier,
                applicationName: ref.appName,
                size: 24,
                cornerRadius: 6
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(isProtectedRedacted ? "Protected item" : ref.displayLabel)
                    .lineLimit(1)

                Text(criteriaText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            GroupDetailBadge(
                text: statusText,
                systemImage: statusImage,
                color: statusColor
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var criteriaText: String {
        if !ref.hasMatchableCriteria {
            return "No match criteria"
        }

        var parts: [String] = []
        if ref.bundleIdentifier?.isEmpty == false {
            parts.append("Bundle ID")
        }
        if ref.appName?.isEmpty == false {
            parts.append("App")
        }
        if ref.titleContains?.isEmpty == false {
            parts.append("Title")
        }
        if ref.snapshotStableID?.isEmpty == false {
            parts.append("Snapshot")
        }
        if ref.zone != nil {
            parts.append("Zone")
        }
        return parts.joined(separator: ", ")
    }

    private var statusText: String {
        if !ref.hasMatchableCriteria {
            return "Needs Criteria"
        }
        return matchedCount == 0 ? "Unavailable" : "Matched"
    }

    private var statusImage: String {
        if !ref.hasMatchableCriteria {
            return "exclamationmark.triangle"
        }
        return matchedCount == 0 ? "minus.circle" : "checkmark.circle"
    }

    private var statusColor: Color {
        if !ref.hasMatchableCriteria {
            return .orange
        }
        return matchedCount == 0 ? .secondary : .green
    }
}

private struct GroupDetailBadge: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.22), lineWidth: 0.5)
            }
    }
}
