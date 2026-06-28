import ApplicationServices
import CoreGraphics
import Foundation

private struct AXAttributeReadError: Error {
    let code: AXError
}

final class AXElementReader {
    private let diagnosticsLogger: DiagnosticsLogger
    private(set) var failureCount = 0

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    func resetFailureCount() {
        failureCount = 0
    }

    func readString(_ element: AXUIElement, attribute: String) -> String? {
        switch copyAttributeValue(element, attribute: attribute) {
        case .success(let value):
            return value as? String
        case .failure:
            return nil
        }
    }

    func readElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        switch copyAttributeValue(element, attribute: attribute) {
        case .success(let value):
            guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
                diagnosticsLogger.log("AX attribute \(attribute) did not contain an AXUIElement.", level: .debug)
                return nil
            }
            let axElement = unsafeDowncast(value, to: AXUIElement.self)
            return axElement
        case .failure:
            return nil
        }
    }

    func readChildren(_ element: AXUIElement) -> [AXUIElement] {
        switch copyAttributeValue(element, attribute: kAXChildrenAttribute as String) {
        case .success(let value):
            return value as? [AXUIElement] ?? []
        case .failure:
            return []
        }
    }

    func readFrame(_ element: AXUIElement) -> CGRect? {
        guard let position = readCGPoint(element, attribute: kAXPositionAttribute as String),
              let size = readCGSize(element, attribute: kAXSizeAttribute as String) else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    func readProcessIdentifier(_ element: AXUIElement) -> pid_t? {
        var pid: pid_t = 0
        let error = AXUIElementGetPid(element, &pid)
        guard error == .success else {
            logFailure(attribute: "AXProcessIdentifier", error: error)
            return nil
        }
        return pid
    }

    @discardableResult
    private func copyAttributeValue(
        _ element: AXUIElement,
        attribute: String
    ) -> Result<CFTypeRef, AXAttributeReadError> {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            logFailure(attribute: attribute, error: error)
            return .failure(AXAttributeReadError(code: error))
        }
        return .success(value)
    }

    private func readCGPoint(_ element: AXUIElement, attribute: String) -> CGPoint? {
        switch copyAttributeValue(element, attribute: attribute) {
        case .success(let value):
            guard CFGetTypeID(value) == AXValueGetTypeID() else {
                diagnosticsLogger.log("AX attribute \(attribute) did not contain an AXValue.", level: .debug)
                return nil
            }

            let axValue = unsafeDowncast(value, to: AXValue.self)
            var point = CGPoint.zero
            guard AXValueGetValue(axValue, .cgPoint, &point) else {
                diagnosticsLogger.log("AX attribute \(attribute) could not be read as CGPoint.", level: .debug)
                return nil
            }
            return point
        case .failure:
            return nil
        }
    }

    private func readCGSize(_ element: AXUIElement, attribute: String) -> CGSize? {
        switch copyAttributeValue(element, attribute: attribute) {
        case .success(let value):
            guard CFGetTypeID(value) == AXValueGetTypeID() else {
                diagnosticsLogger.log("AX attribute \(attribute) did not contain an AXValue.", level: .debug)
                return nil
            }

            let axValue = unsafeDowncast(value, to: AXValue.self)
            var size = CGSize.zero
            guard AXValueGetValue(axValue, .cgSize, &size) else {
                diagnosticsLogger.log("AX attribute \(attribute) could not be read as CGSize.", level: .debug)
                return nil
            }
            return size
        case .failure:
            return nil
        }
    }

    private func logFailure(attribute: String, error: AXError) {
        failureCount += 1
        diagnosticsLogger.log("AX read failed for \(attribute): \(error).", level: .debug)
    }
}
