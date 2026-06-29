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

/// SwiftUI onboarding root view. Phase 3 version: linear paged flow with
/// Back / Continue / Get Started buttons. Completion is delegated to a closure
/// so the owning controller can dismiss the window and persist
/// `hasCompletedOnboarding`.
struct OnboardingRootView: View {
    @Bindable var navigationModel: OnboardingNavigationModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader()

            Divider()
                .overlay(.primary.opacity(0.10))

            TabView(selection: $navigationModel.currentIndex) {
                ForEach(Array(OnboardingStep.allSteps.enumerated()), id: \.element.id) { index, step in
                    OnboardingStepView(step: step)
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
        .frame(minWidth: 620, idealWidth: 680, minHeight: 500, idealHeight: 590)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .padding(18)
        .background {
            Rectangle()
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(.ultraThinMaterial)
                .ignoresSafeArea()
        }
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

                Text("Onboarding")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 18)

            HStack(spacing: 8) {
                ClearGlassBadge(style: .privacySafe)
                ClearGlassBadge(style: .diagnostics)
                ClearGlassBadge(style: .experimental)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
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

            OnboardingStepDetail(step: step)

            if let callout = step.callout {
                ClearGlassInlineMessage(
                    text: callout,
                    systemImage: "exclamationmark.bubble",
                    style: .info
                )
                .frame(maxWidth: 420)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 42)
        .padding(.vertical, 18)
    }
}

private struct OnboardingStepIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 38, weight: .regular))
            .foregroundStyle(.blue)
            .frame(width: 78, height: 78)
            .background(.quaternary, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

private struct OnboardingStepDetail: View {
    let step: OnboardingStep

    var body: some View {
        switch step.id {
        case "intro":
            OnboardingMenuStrip()
        case "nativeCleanup":
            OnboardingNativeCleanupSummary()
        case "commandDrag":
            OnboardingCommandDragStrip()
        case "hiddenVsAlwaysHidden":
            OnboardingZoneSummary()
        case "hotkeyAutoRehide":
            OnboardingShortcutSummary()
        case "privacy":
            OnboardingPrivacySummary()
        default:
            OnboardingMacOSNoteSummary()
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
        .background(.quaternary, in: .rect(cornerRadius: 8))
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
        .background(.quaternary.opacity(0.7), in: .rect(cornerRadius: 8))
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
        .background(.quaternary, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct OnboardingZoneSummary: View {
    var body: some View {
        HStack(spacing: 12) {
            OnboardingZoneCard(title: "Hidden", systemImage: "eye.slash", tint: .blue)
            OnboardingZoneCard(title: "Always-Hidden", systemImage: "lock", tint: .orange)
        }
        .frame(maxWidth: 430)
    }
}

private struct OnboardingZoneCard: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(0.10), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            }
            .foregroundStyle(tint)
    }
}

private struct OnboardingShortcutSummary: View {
    var body: some View {
        HStack(spacing: 10) {
            Label("Option", systemImage: "option")
            Label("Command", systemImage: "command")
            Text("B")
                .font(.system(.callout, design: .monospaced))
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.quaternary, in: .rect(cornerRadius: 6))
            ClearGlassBadge(style: .basicMode)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.7), in: .rect(cornerRadius: 8))
    }
}

private struct OnboardingPrivacySummary: View {
    private let permissions = [
        "Accessibility",
        "Screen Recording",
        "Apple Events",
        "Input Monitoring",
        "Network Access"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(permissions.enumerated()), id: \.offset) { index, permission in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(permission)

                    Spacer()

                    Text("Not Requested")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if index < permissions.count - 1 {
                    Divider()
                        .overlay(.primary.opacity(0.08))
                }
            }
        }
        .frame(maxWidth: 430)
        .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct OnboardingMacOSNoteSummary: View {
    var body: some View {
        ClearGlassInlineMessage(
            text: "Separator appearance is adjustable without changing the Basic Mode permission boundary.",
            systemImage: "slider.horizontal.3",
            style: .secondary
        )
        .frame(maxWidth: 430)
    }
}

private struct OnboardingFooter: View {
    @Bindable var navigationModel: OnboardingNavigationModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            PageControl(
                count: OnboardingStep.allSteps.count,
                current: navigationModel.currentIndex
            )

            HStack(spacing: 12) {
                Button("Back") { navigationModel.back() }
                    .disabled(!navigationModel.canGoBack)

                Spacer()

                if navigationModel.isLastStep {
                    Button("Get Started") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Continue") {
                        navigationModel.advance()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct PageControl: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: index == current ? 18 : 7, height: 7)
                    .animation(.snappy(duration: 0.18), value: current)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingRootView(
        navigationModel: OnboardingNavigationModel(),
        onComplete: {}
    )
}
