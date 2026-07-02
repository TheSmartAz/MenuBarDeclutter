import ApplicationServices
import CoreGraphics
import Foundation

private struct AXAttributeReadError: Error {
    let code: AXError
}

nonisolated final class AXElementReader {
    private(set) var failureCount = 0
    private(set) var logMessages: [String] = []
    private var failureSummaryCounts: [String: Int] = [:]

    init() {}

    func resetFailureCount() {
        failureCount = 0
        logMessages.removeAll()
        failureSummaryCounts.removeAll()
    }

    var failureSummary: String? {
        guard failureSummaryCounts.isEmpty == false else {
            return nil
        }

        return failureSummaryCounts
            .sorted {
                if $0.value == $1.value {
                    return $0.key < $1.key
                }
                return $0.value > $1.value
            }
            .prefix(4)
            .map { "\($0.key) x\($0.value)" }
            .joined(separator: "; ")
    }

    func readString(_ element: AXUIElement, attribute: String) -> String? {
        switch copyAttributeValue(element, attribute: attribute) {
        case .success(let value):
            return value as? String
        case .failure:
            return nil
        }
    }

    func readOptionalString(_ element: AXUIElement, attribute: String) -> String? {
        switch copyAttributeValue(element, attribute: attribute, countExpectedAbsenceAsFailure: false) {
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
                logMessages.append("AX attribute \(attribute) did not contain an AXUIElement.")
                return nil
            }
            let axElement = unsafeDowncast(value, to: AXUIElement.self)
            return axElement
        case .failure:
            return nil
        }
    }

    func readOptionalElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        switch copyAttributeValue(element, attribute: attribute, countExpectedAbsenceAsFailure: false) {
        case .success(let value):
            guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
                logMessages.append("AX attribute \(attribute) did not contain an AXUIElement.")
                return nil
            }
            let axElement = unsafeDowncast(value, to: AXUIElement.self)
            return axElement
        case .failure:
            return nil
        }
    }

    func readChildren(_ element: AXUIElement) -> [AXUIElement] {
        switch copyAttributeValue(
            element,
            attribute: kAXChildrenAttribute as String,
            countExpectedAbsenceAsFailure: false
        ) {
        case .success(let value):
            return value as? [AXUIElement] ?? []
        case .failure:
            return []
        }
    }

    func readFrame(_ element: AXUIElement) -> CGRect? {
        guard let position = readCGPoint(
            element,
            attribute: kAXPositionAttribute as String,
            countExpectedAbsenceAsFailure: false
        ),
              let size = readCGSize(
                element,
                attribute: kAXSizeAttribute as String,
                countExpectedAbsenceAsFailure: false
              ) else {
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
        attribute: String,
        countExpectedAbsenceAsFailure: Bool = true
    ) -> Result<CFTypeRef, AXAttributeReadError> {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard error == .success, let value else {
            logFailure(
                attribute: attribute,
                error: error,
                countExpectedAbsenceAsFailure: countExpectedAbsenceAsFailure
            )
            return .failure(AXAttributeReadError(code: error))
        }
        return .success(value)
    }

    private func readCGPoint(
        _ element: AXUIElement,
        attribute: String,
        countExpectedAbsenceAsFailure: Bool = true
    ) -> CGPoint? {
        switch copyAttributeValue(
            element,
            attribute: attribute,
            countExpectedAbsenceAsFailure: countExpectedAbsenceAsFailure
        ) {
        case .success(let value):
            guard CFGetTypeID(value) == AXValueGetTypeID() else {
                logMessages.append("AX attribute \(attribute) did not contain an AXValue.")
                return nil
            }

            let axValue = unsafeDowncast(value, to: AXValue.self)
            var point = CGPoint.zero
            guard AXValueGetValue(axValue, .cgPoint, &point) else {
                logMessages.append("AX attribute \(attribute) could not be read as CGPoint.")
                return nil
            }
            return point
        case .failure:
            return nil
        }
    }

    private func readCGSize(
        _ element: AXUIElement,
        attribute: String,
        countExpectedAbsenceAsFailure: Bool = true
    ) -> CGSize? {
        switch copyAttributeValue(
            element,
            attribute: attribute,
            countExpectedAbsenceAsFailure: countExpectedAbsenceAsFailure
        ) {
        case .success(let value):
            guard CFGetTypeID(value) == AXValueGetTypeID() else {
                logMessages.append("AX attribute \(attribute) did not contain an AXValue.")
                return nil
            }

            let axValue = unsafeDowncast(value, to: AXValue.self)
            var size = CGSize.zero
            guard AXValueGetValue(axValue, .cgSize, &size) else {
                logMessages.append("AX attribute \(attribute) could not be read as CGSize.")
                return nil
            }
            return size
        case .failure:
            return nil
        }
    }

    private func logFailure(
        attribute: String,
        error: AXError,
        countExpectedAbsenceAsFailure: Bool = true
    ) {
        guard countExpectedAbsenceAsFailure else {
            return
        }

        failureCount += 1
        let message = "AX read failed for \(attribute): \(error)."
        logMessages.append(message)
        failureSummaryCounts["\(attribute): \(error)", default: 0] += 1
    }
}
