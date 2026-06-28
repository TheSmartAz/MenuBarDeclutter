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
            TabView(selection: $navigationModel.currentIndex) {
                ForEach(OnboardingStep.allSteps) { step in
                    OnboardingStepView(step: step)
                        .tag(OnboardingStep.allSteps.firstIndex(of: step) ?? 0)
                }
            }
            .tabViewStyle(.automatic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            OnboardingFooter(
                navigationModel: navigationModel,
                onComplete: onComplete
            )
        }
        .frame(minWidth: 540, idealWidth: 600, minHeight: 440, idealHeight: 520)
        .padding()
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: step.symbol)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            Text(step.title)
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)

            Text(step.body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)

            if let callout = step.callout {
                Label(callout, systemImage: "exclamationmark.bubble")
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: .rect(cornerRadius: 10))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

private struct OnboardingFooter: View {
    @Bindable var navigationModel: OnboardingNavigationModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            PageControl(
                count: OnboardingStep.allSteps.count,
                current: navigationModel.currentIndex
            )

            HStack(spacing: 12) {
                if navigationModel.canGoBack {
                    Button("Back") { navigationModel.back() }
                }

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
    }
}

private struct PageControl: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
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
