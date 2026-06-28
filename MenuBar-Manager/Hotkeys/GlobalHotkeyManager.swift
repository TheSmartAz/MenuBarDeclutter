import AppKit
import Carbon
import Carbon.HIToolbox
import Foundation
import Synchronization

/// Owns Carbon `RegisterEventHotKey` registrations for app-level global hotkeys.
///
/// Phase 5 adds named registrations so the Basic visibility toggle and the
/// optional Find Icon search hotkey can coexist. Carbon callbacks cannot
/// capture Swift context, so a shared mutex stores the active manager and the
/// callback forwards the pressed hotkey ID back to `MainActor`.
@MainActor
final class GlobalHotkeyManager {
    enum RegistrationIdentifier: String, CaseIterable, Hashable, Sendable {
        case visibilityToggle
        case findIcon

        var displayName: String {
            switch self {
            case .visibilityToggle:
                "Visibility Toggle"
            case .findIcon:
                "Find Icon"
            }
        }
    }

    private struct ActiveRegistration {
        let identifier: RegistrationIdentifier
        let hotkey: HotkeyModel
        let carbonID: UInt32
        let action: () -> Void
    }

    private nonisolated static let activeManagerMutex: Mutex<WeakReference<GlobalHotkeyManager>?> = Mutex(nil)

    private let diagnosticsLogger: DiagnosticsLogger

    private nonisolated let carbonResources = CarbonHotkeyResources()
    private var isInvalidated = false
    private var currentHotkeyIDCounter: UInt32 = 0
    private var registrationsByIdentifier: [RegistrationIdentifier: ActiveRegistration] = [:]
    private var identifierByCarbonID: [UInt32: RegistrationIdentifier] = [:]

    /// Backward-compatible visibility-toggle hotkey accessor.
    var registeredHotkey: HotkeyModel? {
        registeredHotkey(identifier: .visibilityToggle)
    }

    var isRegistered: Bool {
        !registrationsByIdentifier.isEmpty
    }

    /// Closure invoked when the visibility-toggle hotkey fires. Always called
    /// on the main actor. Kept so Phase 2 call sites do not need to know about
    /// named registrations.
    var onTrigger: (() -> Void)?

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
        installApplicationEventHandler()
        Self.activate(self)
    }

    deinit {
        Self.clearActiveManager(self)
        carbonResources.takeAll().perform()
    }

    /// Updates the visibility-toggle hotkey. Passing `nil` unregisters.
    func register(hotkey: HotkeyModel?) {
        register(identifier: .visibilityToggle, hotkey: hotkey) { [weak self] in
            self?.onTrigger?()
        }
    }

    /// Updates a named hotkey registration. Passing `nil` unregisters that
    /// identifier. Failures are logged but never crash the app.
    func register(
        identifier: RegistrationIdentifier,
        hotkey: HotkeyModel?,
        action: @escaping () -> Void
    ) {
        guard !isInvalidated else {
            diagnosticsLogger.log(
                "Ignoring \(identifier.displayName) hotkey registration after manager teardown.",
                level: .warning
            )
            return
        }

        unregister(identifier: identifier)

        guard let hotkey else {
            diagnosticsLogger.log("\(identifier.displayName) hotkey cleared.", level: .debug)
            return
        }

        guard !hotkey.hasNoModifiers else {
            diagnosticsLogger.log(
                "Refusing to register \(identifier.displayName) hotkey with no modifiers.",
                level: .warning
            )
            return
        }

        currentHotkeyIDCounter &+= 1
        let carbonID = currentHotkeyIDCounter
        let id = EventHotKeyID(signature: AppConstants.hotkeyIDSignature, id: carbonID)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiersRaw,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr, let ref {
            carbonResources.storeHotKeyRef(ref, carbonID: carbonID)
            registrationsByIdentifier[identifier] = ActiveRegistration(
                identifier: identifier,
                hotkey: hotkey,
                carbonID: carbonID,
                action: action
            )
            identifierByCarbonID[carbonID] = identifier
            diagnosticsLogger.log("Registered \(identifier.displayName) hotkey \(hotkey.displayName).")
        } else {
            diagnosticsLogger.log(
                "Failed to register \(identifier.displayName) hotkey (keyCode=\(hotkey.keyCode), status=\(status)).",
                level: .warning
            )
        }
    }

    func unregister(identifier: RegistrationIdentifier) {
        guard let registration = registrationsByIdentifier.removeValue(forKey: identifier) else {
            return
        }

        if let token = carbonResources.takeHotKeyRef(carbonID: registration.carbonID) {
            token.unregister()
        }
        identifierByCarbonID.removeValue(forKey: registration.carbonID)
        diagnosticsLogger.log("Unregistered \(identifier.displayName) hotkey.", level: .debug)
    }

    /// Unregisters every active hotkey.
    func unregister() {
        for identifier in Array(registrationsByIdentifier.keys) {
            unregister(identifier: identifier)
        }
    }

    func isRegistered(identifier: RegistrationIdentifier) -> Bool {
        registrationsByIdentifier[identifier] != nil
    }

    func registeredHotkey(identifier: RegistrationIdentifier) -> HotkeyModel? {
        registrationsByIdentifier[identifier]?.hotkey
    }

    /// Explicit shutdown path used by app termination. `deinit` keeps a
    /// last-resort cleanup for tests or unusual ownership paths, but normal
    /// Carbon teardown should happen through this main-actor method.
    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        unregister()
        if let token = carbonResources.takeEventHandler() {
            token.remove()
        }
        Self.clearActiveManager(self)
    }

    private func handleHotKeyPressed(carbonID: UInt32?) {
        let resolver = HotkeyCallbackResolver(
            identifierByCarbonID: identifierByCarbonID,
            registeredIdentifiers: Set(registrationsByIdentifier.keys)
        )

        let identifier: RegistrationIdentifier
        switch resolver.resolve(carbonID: carbonID) {
        case let .matched(resolvedIdentifier, .carbonID):
            identifier = resolvedIdentifier
        case let .matched(resolvedIdentifier, .singleRegistrationFallback):
            diagnosticsLogger.log(
                "Global hotkey callback did not include a Carbon ID; using single-registration fallback.",
                level: .warning
            )
            identifier = resolvedIdentifier
        case let .unknown(reason):
            diagnosticsLogger.log(
                "Received unknown global hotkey callback (\(reason.logDescription)).",
                level: .warning
            )
            return
        }

        guard let registration = registrationsByIdentifier[identifier] else {
            diagnosticsLogger.log("Received global hotkey callback for stale registration.", level: .warning)
            return
        }

        diagnosticsLogger.log("\(registration.identifier.displayName) hotkey fired.")
        registration.action()
    }

    // MARK: Carbon event handler installation

    private func installApplicationEventHandler() {
        guard !carbonResources.hasEventHandler else { return }

        var spec = EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var eventHandler: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                GlobalHotkeyManager.dispatchHotkeyFromCallback(event)
                return noErr
            },
            1,
            &spec,
            nil,
            &eventHandler
        )

        if status == noErr, let eventHandler {
            carbonResources.storeEventHandler(eventHandler)
            diagnosticsLogger.log("Global hotkey event handler installed.", level: .debug)
        } else {
            diagnosticsLogger.log(
                "Failed to install global hotkey event handler (status=\(status)).",
                level: .warning
            )
        }
    }

    nonisolated static func dispatchHotkeyFromCallback(_ event: EventRef?) {
        let carbonID = carbonHotkeyID(from: event)
        let manager = Self.activeManagerMutex.withLock { $0?.value }
        guard let manager else { return }

        Task { @MainActor in
            manager.handleHotKeyPressed(carbonID: carbonID)
        }
    }

    private nonisolated static func carbonHotkeyID(from event: EventRef?) -> UInt32? {
        guard let event else { return nil }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else { return nil }
        return hotkeyID.id
    }

    private static func activate(_ manager: GlobalHotkeyManager) {
        activeManagerMutex.withLock { activeManager in
            activeManager = WeakReference(manager)
        }
    }

    private nonisolated static func clearActiveManager(_ manager: GlobalHotkeyManager) {
        activeManagerMutex.withLock { activeManager in
            if activeManager?.value === manager || activeManager?.value == nil {
                activeManager = nil
            }
        }
    }
}

nonisolated private final class WeakReference<Object: AnyObject>: @unchecked Sendable {
    weak var value: Object?

    init(_ value: Object) {
        self.value = value
    }
}

nonisolated private final class CarbonHotkeyResources: @unchecked Sendable {
    private struct State {
        var eventHandler: CarbonEventHandlerToken?
        var hotKeyRefs: [UInt32: CarbonHotKeyToken] = [:]
    }

    private let state = Mutex(State())

    var hasEventHandler: Bool {
        state.withLock { $0.eventHandler != nil }
    }

    func storeEventHandler(_ eventHandler: EventHandlerRef) {
        let token = CarbonEventHandlerToken(eventHandler)
        state.withLock { $0.eventHandler = token }
    }

    func takeEventHandler() -> CarbonEventHandlerToken? {
        state.withLock { state in
            let eventHandler = state.eventHandler
            state.eventHandler = nil
            return eventHandler
        }
    }

    func storeHotKeyRef(_ ref: EventHotKeyRef, carbonID: UInt32) {
        let token = CarbonHotKeyToken(ref)
        state.withLock { $0.hotKeyRefs[carbonID] = token }
    }

    func takeHotKeyRef(carbonID: UInt32) -> CarbonHotKeyToken? {
        state.withLock { $0.hotKeyRefs.removeValue(forKey: carbonID) }
    }

    func takeAll() -> CarbonHotkeyTeardown {
        state.withLock { state in
            let teardown = CarbonHotkeyTeardown(
                eventHandler: state.eventHandler,
                hotKeyRefs: Array(state.hotKeyRefs.values)
            )
            state.eventHandler = nil
            state.hotKeyRefs.removeAll()
            return teardown
        }
    }
}

nonisolated private struct CarbonHotkeyTeardown {
    let eventHandler: CarbonEventHandlerToken?
    let hotKeyRefs: [CarbonHotKeyToken]

    func perform() {
        for token in hotKeyRefs {
            token.unregister()
        }
        if let eventHandler {
            eventHandler.remove()
        }
    }
}

nonisolated private struct CarbonEventHandlerToken: @unchecked Sendable {
    private let ref: EventHandlerRef

    init(_ ref: EventHandlerRef) {
        self.ref = ref
    }

    func remove() {
        RemoveEventHandler(ref)
    }
}

nonisolated private struct CarbonHotKeyToken: @unchecked Sendable {
    private let ref: EventHotKeyRef

    init(_ ref: EventHotKeyRef) {
        self.ref = ref
    }

    func unregister() {
        UnregisterEventHotKey(ref)
    }
}

nonisolated private extension HotkeyCallbackResolver.UnknownReason {
    var logDescription: String {
        switch self {
        case .missingCarbonIDWithoutSingleRegistration:
            "missing Carbon ID"
        case let .unregisteredCarbonID(carbonID):
            "unregistered Carbon ID \(carbonID)"
        }
    }
}
