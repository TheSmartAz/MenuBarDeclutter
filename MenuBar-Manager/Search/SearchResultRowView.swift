import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SearchResultRowView: View {
    let result: MenuBarSearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(result.displayTitle)
                        .font(.body)
                        .lineLimit(1)

                    Text(result.snapshot.zone.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(zoneColor.opacity(0.14), in: .capsule)
                        .foregroundStyle(zoneColor)
                }

                HStack(spacing: 8) {
                    Text(result.displaySubtitle)
                        .lineLimit(1)

                    Text(result.matchReason.displayName)
                        .lineLimit(1)

                    Text(result.snapshot.scanTimestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: .rect(cornerRadius: 8))
        .contentShape(.rect)
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.16) : Color.clear
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

    private var appIcon: NSImage {
        if let processIdentifier = result.snapshot.owningProcessIdentifier,
           let icon = NSRunningApplication(processIdentifier: processIdentifier)?.icon {
            return icon
        }

        if let bundleIdentifier = result.snapshot.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return NSWorkspace.shared.icon(for: .application)
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
