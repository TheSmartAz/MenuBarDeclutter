import Foundation

nonisolated struct ArrangeStep: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let isOptional: Bool

    static let guidedManualSteps: [ArrangeStep] = [
        ArrangeStep(
            id: "showControls",
            title: "How menu bar hiding works",
            detail: "MenuBarDeclutter hides the items placed past its separator while keeping the control item reachable.",
            systemImage: "menubar.rectangle",
            isOptional: false
        ),
        ArrangeStep(
            id: "dragControl",
            title: "Step 1: place the control item",
            detail: "Hold Command and drag the control item where you want the visible toggle to live.",
            systemImage: "hand.draw",
            isOptional: false
        ),
        ArrangeStep(
            id: "dragSeparator",
            title: "Step 2: place the separator",
            detail: "Hold Command and drag the separator to mark the boundary between visible and hidden items.",
            systemImage: "parallelpipe",
            isOptional: false
        ),
        ArrangeStep(
            id: "placeHidden",
            title: "Step 3: move clutter into the hidden area",
            detail: "Anything on the hidden side disappears when the bar is collapsed.",
            systemImage: "eye.slash",
            isOptional: false
        ),
        ArrangeStep(
            id: "testCollapse",
            title: "Step 4: test collapse",
            detail: "Collapse hidden items and confirm the visible side still feels right.",
            systemImage: "rectangle.compress.vertical",
            isOptional: false
        ),
        ArrangeStep(
            id: "testReveal",
            title: "Step 5: test reveal",
            detail: "Reveal all items to make sure hidden items are still reachable.",
            systemImage: "rectangle.expand.vertical",
            isOptional: false
        ),
        ArrangeStep(
            id: "alwaysHidden",
            title: "Optional: always-hidden area",
            detail: "Use the second separator only for items that should stay tucked away during normal reveal.",
            systemImage: "lock",
            isOptional: true
        ),
        ArrangeStep(
            id: "reset",
            title: "Need help? Reset layout or open Recovery",
            detail: "Use reset and Safe Mode recovery if the menu bar becomes confusing.",
            systemImage: "arrow.counterclockwise",
            isOptional: false
        )
    ]
}
