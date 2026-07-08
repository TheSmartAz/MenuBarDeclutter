import SwiftUI

/// A vertical container that inserts a `ClearGlassDivider` *between* each child
/// row (never before the first or after the last), replacing the hand-placed
/// `ClearGlassDivider()` calls that separate a run of uniform control rows.
///
/// NOTE: auto-insertion uses SwiftUI's `_VariadicView` to enumerate the direct
/// children. That is an underscore (unofficial) API — stable in practice and
/// widely used, but not formally supported. It is isolated here so the rest of
/// the DS never touches it. Use this only for a *run of uniform rows*; sections
/// that interleave notices/messages with bespoke divider placement should keep
/// explicit dividers.
struct ClearGlassRowStack<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        _VariadicView.Tree(DividedRowLayout()) {
            content
        }
    }
}

private struct DividedRowLayout: _VariadicView.MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let lastID = children.last?.id
        ForEach(children) { child in
            child
            if child.id != lastID {
                ClearGlassDivider()
            }
        }
    }
}
