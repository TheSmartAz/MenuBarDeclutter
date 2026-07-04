import AppKit
import Observation
import SwiftUI

/// Navigation model for the onboarding paged flow. Kept as a small
/// `@Observable` so the window controller and view share a single source of
/// truth for the current step index.
@MainActor
@Observable
final class OnboardingNavigationModel {
    var currentIndex: Int = 0

    var currentStep: OnboardingStep {
        OnboardingStep.allSteps.indices.contains(currentIndex)
            ? OnboardingStep.allSteps[currentIndex]
            : OnboardingStep.allSteps[0]
    }

    var canGoBack: Bool { currentIndex > 0 }
    var canAdvance: Bool { currentIndex < OnboardingStep.allSteps.count - 1 }
    var isLastStep: Bool { currentIndex == OnboardingStep.allSteps.count - 1 }

    func advance() {
        guard canAdvance else { return }
        currentIndex += 1
    }

    func back() {
        guard canGoBack else { return }
        currentIndex -= 1
    }

    func reset() {
        currentIndex = 0
    }
}

/// SwiftUI onboarding root view. Completion is delegated to a closure so the
/// owning controller can dismiss the window and persist `hasCompletedOnboarding`.
struct OnboardingRootView: View {
    @Bindable var navigationModel: OnboardingNavigationModel
    let onComplete: () -> Void
    var onOpenSettings: (() -> Void)? = nil
    var onOpenArrange: (() -> Void)? = nil
    var onOpenWorkspaces: (() -> Void)? = nil
    var onCreateSampleWorkspace: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader()

            Divider()
                .overlay(.primary.opacity(0.10))

            TabView(selection: $navigationModel.currentIndex) {
                ForEach(Array(OnboardingStep.allSteps.enumerated()), id: \.element.id) { index, step in
                    OnboardingStepView(
                        step: step,
                        onOpenSettings: onOpenSettings,
                        onOpenArrange: onOpenArrange,
                        onOpenWorkspaces: onOpenWorkspaces,
                        onCreateSampleWorkspace: onCreateSampleWorkspace
                    )
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .overlay(.primary.opacity(0.10))

            OnboardingFooter(
                navigationModel: navigationModel,
                onComplete: onComplete
            )
        }
        .frame(minWidth: 700, idealWidth: 740, minHeight: 560, idealHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct OnboardingHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 42, height: 42)
                .clipShape(.rect(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(.primary.opacity(0.16), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(AppConstants.displayName)
                    .font(.title2)
                    .bold()

                Text("Setup Assistant")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 18)

            HStack(spacing: 8) {
                ClearGlassBadge(style: .basicMode)
                ClearGlassBadge(style: .privacySafe)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep
    var onOpenSettings: (() -> Void)? = nil
    var onOpenArrange: (() -> Void)? = nil
    var onOpenWorkspaces: (() -> Void)? = nil
    var onCreateSampleWorkspace: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 6)

            OnboardingStepIcon(systemImage: step.symbol)

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(step.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 500)
            }

            OnboardingStepDetail(
                step: step,
                onOpenSettings: onOpenSettings,
                onOpenArrange: onOpenArrange,
                onOpenWorkspaces: onOpenWorkspaces,
                onCreateSampleWorkspace: onCreateSampleWorkspace
            )

            if let callout = step.callout {
                ClearGlassInlineMessage(
                    text: callout,
                    systemImage: "info.circle",
                    style: .info
                )
                .frame(maxWidth: 420)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 42)
        .padding(.vertical, 16)
        .accessibilityIdentifier("onboarding.step.\(step.id)")
    }
}

private struct OnboardingStepIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 32, weight: .regular))
            .foregroundStyle(Color.accentColor)
            .frame(width: 64, height: 64)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

private struct OnboardingStepDetail: View {
    let step: OnboardingStep
    var onOpenSettings: (() -> Void)? = nil
    var onOpenArrange: (() -> Void)? = nil
    var onOpenWorkspaces: (() -> Void)? = nil
    var onCreateSampleWorkspace: (() -> Void)? = nil

    var body: some View {
        switch step.id {
        case "welcome":
            OnboardingMenuStrip()
        case "nativeCleanup":
            OnboardingNativeCleanupSummary()
        case "basicHideReveal":
            OnboardingHideRevealPreview()
        case "arrange":
            OnboardingCommandDragStrip()
        case "findRescue":
            OnboardingFindRescueSummary()
        case "workspaces":
            OnboardingWorkspacePreview()
        case "privacy":
            OnboardingPrivacySummary()
        case "recovery":
            OnboardingRecoverySummary()
        default:
            OnboardingFinishActions(
                onOpenSettings: onOpenSettings,
                onOpenArrange: onOpenArrange,
                onOpenWorkspaces: onOpenWorkspaces,
                onCreateSampleWorkspace: onCreateSampleWorkspace
            )
        }
    }
}

private struct OnboardingMenuStrip: View {
    private let icons = ["wifi", "battery.100", "icloud", "magnifyingglass", "chevron.right.2", "moon", "display", "speaker.wave.2"]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingNativeCleanupSummary: View {
    var body: some View {
        HStack(spacing: 14) {
            Label("Control Center", systemImage: "switch.2")
                .font(.callout)

            Spacer(minLength: 12)

            Button("Open Menu Bar Settings", systemImage: "arrow.up.forward.app") {
                _ = OnboardingSystemSettingsOpener.openMenuBarSettings()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: 430)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct OnboardingCommandDragStrip: View {
    var body: some View {
        HStack(spacing: 14) {
            Label("Command", systemImage: "command")
            Text("+")
                .foregroundStyle(.secondary)
            Label("Drag", systemImage: "hand.point.up.left")
            Text("+")
                .foregroundStyle(.secondary)
            Label("Separator", systemImage: "chevron.right.2")
        }
        .labelStyle(.titleAndIcon)
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct OnboardingHideRevealPreview: View {
    private let pinnedIcons = ["wifi", "speaker.wave.2"]
    private let collapsibleIcons = ["paperplane", "cloud", "bell", "moon"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OnboardingPreviewLabel("Expanded")

            OnboardingMenuBarPreviewRow {
                OnboardingMenuBarIcon(systemImage: "line.3.horizontal", tint: .accentColor)
                OnboardingSeparatorMarker()

                ForEach(pinnedIcons, id: \.self) { icon in
                    OnboardingMenuBarIcon(systemImage: icon)
                }

                ForEach(collapsibleIcons, id: \.self) { icon in
                    OnboardingMenuBarIcon(systemImage: icon)
                }
            }

            OnboardingPreviewArrow()

            OnboardingPreviewLabel("Collapsed")

            OnboardingMenuBarPreviewRow {
                OnboardingMenuBarIcon(systemImage: "line.3.horizontal", tint: .accentColor)
                OnboardingSeparatorMarker()

                ForEach(pinnedIcons, id: \.self) { icon in
                    OnboardingMenuBarIcon(systemImage: icon)
                }

                OnboardingHiddenItemsCapsule(count: collapsibleIcons.count)
            }
        }
        .padding(12)
        .frame(width: 440)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
        .accessibilityLabel("Diagram showing expanded menu bar items becoming a collapsed group behind the separator.")
    }
}

private struct OnboardingFindRescueSummary: View {
    private let surfaces = [
        ("Find Icon", "magnifyingglass", "Preview"),
        ("Second Bar", "rectangle.bottomthird.inset.filled", "Preview"),
        ("New Items", "tray", "Requires Optional Pro")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(surfaces, id: \.0) { surface in
                VStack(spacing: 5) {
                    Label(surface.0, systemImage: surface.1)
                        .font(.callout)
                    Text(surface.2)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.primary.opacity(0.10), lineWidth: 1)
                }
            }
        }
        .frame(maxWidth: 500)
    }
}

private struct OnboardingWorkspacePreview: View {
    private let workspaces = [
        ("Focus", "timer", ["terminal", "doc.text", "bell.slash"]),
        ("Meeting", "person.2", ["video", "mic", "message"])
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(workspaces, id: \.0) { workspace in
                OnboardingWorkspaceCard(
                    title: workspace.0,
                    systemImage: workspace.1,
                    symbols: workspace.2
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                OnboardingWorkspaceSurface(title: "Function Bar", systemImage: "menubar.rectangle")
                OnboardingWorkspaceSurface(title: "Linked Groups", systemImage: "link")
                OnboardingWorkspaceSurface(title: "Info Strip", systemImage: "info.circle")
            }
        }
        .padding(12)
        .frame(width: 500)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
        .accessibilityLabel("Diagram showing local workspaces feeding app-owned Function Bar, Linked Groups, and Info Strip previews.")
    }
}

private struct OnboardingPreviewLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct OnboardingMenuBarPreviewRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            content
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct OnboardingMenuBarIcon: View {
    let systemImage: String
    var tint: Color = .primary

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: 22, height: 22)
            .background(tint.opacity(0.08), in: .rect(cornerRadius: 5))
    }
}

private struct OnboardingSeparatorMarker: View {
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 4, height: 4)
            Capsule()
                .fill(Color.accentColor.opacity(0.75))
                .frame(width: 4, height: 17)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 4, height: 4)
        }
        .frame(width: 14, height: 26)
        .accessibilityHidden(true)
    }
}

private struct OnboardingHiddenItemsCapsule: View {
    let count: Int

    var body: some View {
        Label("\(count) hidden", systemImage: "eye.slash")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(Color.secondary.opacity(0.10), in: .capsule)
    }
}

private struct OnboardingPreviewArrow: View {
    var body: some View {
        Image(systemName: "arrow.down")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }
}

private struct OnboardingWorkspaceCard: View {
    let title: String
    let systemImage: String
    let symbols: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: systemImage)
                .font(.callout)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                ForEach(symbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: 6))
                }
            }

            Capsule()
                .fill(Color.accentColor.opacity(0.22))
                .frame(width: 56, height: 5)
        }
        .padding(10)
        .frame(width: 122, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct OnboardingWorkspaceSurface: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(width: 150, height: 32, alignment: .leading)
            .background(Color(nsColor: .windowBackgroundColor), in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

private struct OnboardingPrivacySummary: View {
    var body: some View {
        PrivacyTrustBoundarySummary(
            maximumWidth: 540,
            accessibilityIdentifier: "onboarding.privacyBoundary"
        )
    }
}

private struct OnboardingRecoverySummary: View {
    private let actions = [
        ("Safe Mode", "lifepreserver"),
        ("Reset Layout", "arrow.counterclockwise"),
        ("Diagnostics", "waveform.path.ecg")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(actions, id: \.0) { action in
                Label(action.0, systemImage: action.1)
                    .font(.callout)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(.primary.opacity(0.10), lineWidth: 1)
                    }
            }
        }
    }
}

private struct OnboardingFinishActions: View {
    var onOpenSettings: (() -> Void)? = nil
    var onOpenArrange: (() -> Void)? = nil
    var onOpenWorkspaces: (() -> Void)? = nil
    var onCreateSampleWorkspace: (() -> Void)? = nil

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                finishButtons
            }

            VStack(alignment: .center, spacing: 8) {
                HStack(spacing: 10) {
                    openSettingsButton
                    openArrangeButton
                }

                HStack(spacing: 10) {
                    openWorkspacesButton
                    createSampleWorkspaceButton
                }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    @ViewBuilder
    private var finishButtons: some View {
        openSettingsButton
        openArrangeButton
        openWorkspacesButton
        createSampleWorkspaceButton
    }

    private var openSettingsButton: some View {
        Button("Open Settings", systemImage: "gearshape") {
            onOpenSettings?()
        }
    }

    private var openArrangeButton: some View {
        Button("Open Arrange", systemImage: "arrow.up.left.and.arrow.down.right") {
            onOpenArrange?()
        }
    }

    private var openWorkspacesButton: some View {
        Button("Open Workspaces", systemImage: "rectangle.3.group") {
            onOpenWorkspaces?()
        }
    }

    private var createSampleWorkspaceButton: some View {
        Button("Create Sample Workspace", systemImage: "plus.rectangle.on.rectangle") {
            onCreateSampleWorkspace?()
        }
    }
}

private struct OnboardingFooter: View {
    @Bindable var navigationModel: OnboardingNavigationModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            OnboardingProgressSummary(
                count: OnboardingStep.allSteps.count,
                current: navigationModel.currentIndex,
                currentStep: navigationModel.currentStep
            )

            HStack(spacing: 12) {
                Button("Back", systemImage: "chevron.left") { navigationModel.back() }
                    .disabled(!navigationModel.canGoBack)
                    .keyboardShortcut(.leftArrow, modifiers: [.command])

                Spacer()

                if navigationModel.isLastStep {
                    Button("Get Started", systemImage: "checkmark") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Continue", systemImage: "arrow.right") {
                        navigationModel.advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct OnboardingProgressSummary: View {
    let count: Int
    let current: Int
    let currentStep: OnboardingStep

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("Step \(current + 1) of \(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentStep.title)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)

                Spacer(minLength: 12)
            }

            ProgressView(value: Double(current + 1), total: Double(count))
                .controlSize(.small)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Onboarding progress, step \(current + 1) of \(count), \(currentStep.title)")
        .accessibilityIdentifier("onboarding.progress")
    }
}

#Preview {
    OnboardingRootView(
        navigationModel: OnboardingNavigationModel(),
        onComplete: {}
    )
}
