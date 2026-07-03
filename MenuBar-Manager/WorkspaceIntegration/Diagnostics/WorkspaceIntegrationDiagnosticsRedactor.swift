import Foundation

nonisolated enum WorkspaceIntegrationDiagnosticsRedactor {
    static func redactedAssignmentStatus(_ result: WorkspaceAssignmentResult) -> String {
        switch result.status {
        case .success: "success"
        case .noChange: "noChange"
        case .unavailable: "unavailable"
        case .requiresPro: "requiresPro"
        case .missingWorkspace: "missingWorkspace"
        case .missingGroup: "missingGroup"
        case .validationFailed: "validationFailed"
        case .blockedBySafeMode: "blockedBySafeMode"
        case .failed: "failed"
        }
    }

    static func redactedDecision(_ decision: CrowdedRevealDecision) -> String {
        switch decision {
        case .inlineReveal: "inlineReveal"
        case .secondBar: "secondBar"
        case .functionBar: "functionBar"
        case .functionBarThenSecondBar: "functionBarThenSecondBar"
        case .askFunctionBarOrSecondBar: "askFunctionBarOrSecondBar"
        case .fullMenuBarMode: "fullMenuBarMode"
        case .showLayoutSuggestion: "showLayoutSuggestion"
        case .noOp: "noOp"
        }
    }
}
