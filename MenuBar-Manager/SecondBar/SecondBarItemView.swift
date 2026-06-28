import AppKit
import SwiftUI

struct SecondBarItemView: View {
    let snapshot: MenuBarItemSnapshot
    let iconSize: Double
    let showLabels: Bool
    let isSelected: Bool

    private let iconCache: AppIconCache

    @State private var appIcon: NSImage

    private var iconLookup: AppIconCache.Lookup {
        AppIconCache.Lookup(snapshot: snapshot)
    }

    @MainActor
    init(
        snapshot: MenuBarItemSnapshot,
        iconSize: Double,
        showLabels: Bool,
        isSelected: Bool,
        iconCache: AppIconCache = .shared
    ) {
        self.snapshot = snapshot
        self.iconSize = iconSize
        self.showLabels = showLabels
        self.isSelected = isSelected
        self.iconCache = iconCache
        _appIcon = State(initialValue: iconCache.cachedIcon(for: snapshot) ?? iconCache.placeholderIcon)
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .clipShape(.rect(cornerRadius: min(8, iconSize / 4)))
                .overlay(alignment: .topTrailing) {
                    ZoneBadge(zone: snapshot.zone)
                        .offset(x: 5, y: -5)
                }

            if showLabels {
                VStack(spacing: 1) {
                    Text(displayTitle)
                        .font(.caption)
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: max(72, iconSize + 36))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: max(72, iconSize + 28), minHeight: showLabels ? 92 : iconSize + 22)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear, in: .rect(cornerRadius: 8))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(snapshot.zone.displayName)")
        .task(id: iconLookup) { @MainActor in
            let resolvedIcon = iconCache.icon(for: snapshot)
            if appIcon !== resolvedIcon {
                appIcon = resolvedIcon
            }
        }
    }

    private var displayTitle: String {
        firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }

    private var subtitle: String? {
        firstNonEmpty([
            snapshot.title,
            snapshot.bundleIdentifier
        ].filter { $0 != displayTitle })
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }
            .first
    }
}

private struct ZoneBadge: View {
    let zone: MenuBarZone

    var body: some View {
        Text(badgeText)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(zoneColor, in: .capsule)
            .foregroundStyle(.white)
    }

    private var badgeText: String {
        switch zone {
        case .hidden:
            "H"
        case .alwaysHidden:
            "A"
        case .visible:
            "V"
        case .unknown:
            "?"
        }
    }

    private var zoneColor: Color {
        switch zone {
        case .hidden:
            .orange
        case .alwaysHidden:
            .red
        case .visible:
            .green
        case .unknown:
            .secondary
        }
    }
}

#Preview {
    SecondBarItemView(
        snapshot: MenuBarItemSnapshot(
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
        ),
        iconSize: 32,
        showLabels: true,
        isSelected: true
    )
    .padding()
}
