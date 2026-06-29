import AppKit
import SwiftUI

struct SearchResultRowView: View {
    let result: MenuBarSearchResult
    let isSelected: Bool

    private let iconCache: AppIconCache

    @State private var appIcon: NSImage

    private var iconLookup: AppIconCache.Lookup {
        AppIconCache.Lookup(snapshot: result.snapshot)
    }

    @MainActor
    init(
        result: MenuBarSearchResult,
        isSelected: Bool,
        iconCache: AppIconCache = .shared
    ) {
        self.result = result
        self.isSelected = isSelected
        self.iconCache = iconCache
        _appIcon = State(initialValue: iconCache.cachedIcon(for: result.snapshot) ?? iconCache.placeholderIcon)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: 34, height: 34)
                .clipShape(.rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? .white.opacity(0.22) : .primary.opacity(0.10), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(result.displayTitle)
                        .font(.body)
                        .bold()
                        .lineLimit(1)

                    SearchZoneBadge(
                        title: result.snapshot.zone.displayName,
                        color: zoneColor,
                        isSelected: isSelected
                    )
                }

                HStack(spacing: 8) {
                    Text(result.matchReason.displayName)
                        .lineLimit(1)

                    Text(result.displaySubtitle)
                        .lineLimit(1)

                    Text(result.snapshot.scanTimestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: .rect(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(rowStroke, lineWidth: 1)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .contentShape(.rect)
        .task(id: iconLookup) { @MainActor in
            let resolvedIcon = iconCache.icon(for: result.snapshot)
            if appIcon !== resolvedIcon {
                appIcon = resolvedIcon
            }
        }
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor : Color.primary.opacity(0.035)
    }

    private var rowStroke: Color {
        isSelected ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.08)
    }

    private var zoneColor: Color {
        switch result.snapshot.zone {
        case .visible:
            .green
        case .hidden:
            .orange
        case .alwaysHidden:
            .red
        case .unknown:
            .secondary
        }
    }
}

private struct SearchZoneBadge: View {
    let title: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeFill, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(badgeStroke, lineWidth: 1)
            }
            .foregroundStyle(badgeForeground)
    }

    private var badgeFill: Color {
        isSelected ? .white.opacity(0.18) : color.opacity(0.14)
    }

    private var badgeStroke: Color {
        isSelected ? .white.opacity(0.26) : color.opacity(0.28)
    }

    private var badgeForeground: Color {
        isSelected ? .white : color
    }
}

#Preview {
    let snapshot = MenuBarItemSnapshot(
        title: "Sync Complete",
        role: "AXMenuBarItem",
        subrole: nil,
        frame: .zero,
        owningProcessIdentifier: nil,
        owningApplicationName: "Example",
        bundleIdentifier: "com.example.app",
        zone: .hidden,
        isLikelySystemItem: false,
        scanTimestamp: Date()
    )
    SearchResultRowView(
        result: MenuBarSearchResult(snapshot: snapshot, score: 1000, matchReason: .prefix),
        isSelected: true
    )
    .padding()
    .frame(width: 480)
}
