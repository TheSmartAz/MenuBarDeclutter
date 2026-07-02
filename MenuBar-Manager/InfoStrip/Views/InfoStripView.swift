import SwiftUI

struct InfoStripView: View {
    @Bindable var viewModel: InfoStripViewModel

    var body: some View {
        HStack(spacing: 10) {
            if let tile = viewModel.currentTile {
                InfoTileView(tile: tile, onAction: viewModel.performAction)
            } else {
                InfoStripUnavailableView(message: viewModel.unavailableMessage ?? "Info Strip has no available tiles.")
            }

            Spacer(minLength: 8)

            Button("Function Bar", systemImage: "menubar.rectangle") {
                viewModel.onShowFunctionBar?()
            }
            .labelStyle(.iconOnly)
            .help("Show Function Bar")

            Button("Next", systemImage: "forward") {
                viewModel.onNextTile?()
            }
            .labelStyle(.iconOnly)
            .help("Next tile")

            Button("Close", systemImage: "xmark") {
                viewModel.onClose?()
            }
            .labelStyle(.iconOnly)
            .help("Close Info Strip")
        }
        .padding(12)
        .frame(minWidth: 360, idealWidth: 420, minHeight: 62)
        .onHover { hovering in
            if hovering && viewModel.showFunctionBarOnHover {
                viewModel.onShowFunctionBar?()
            }
        }
        .accessibilityIdentifier("infoStrip.preview")
    }
}

struct InfoTileView: View {
    let tile: InfoTileSnapshot
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: tile.iconName)
                .foregroundStyle(severityColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(tile.title)
                    .font(.callout)
                    .lineLimit(1)
                if let subtitle = tile.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if let action = tile.action {
                Button(action.label, action: onAction)
                    .font(.caption)
            }
        }
        .accessibilityLabel(tile.title)
    }

    private var severityColor: Color {
        switch tile.severity {
        case .normal: .secondary
        case .info: .blue
        case .warning: .orange
        case .critical: .red
        }
    }
}

struct InfoStripUnavailableView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "info.circle")
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}

struct InfoStripPreviewView: View {
    let tile: InfoTileSnapshot?

    var body: some View {
        if let tile {
            InfoTileView(tile: tile) {}
        } else {
            InfoStripUnavailableView(message: "No tile selected.")
        }
    }
}
