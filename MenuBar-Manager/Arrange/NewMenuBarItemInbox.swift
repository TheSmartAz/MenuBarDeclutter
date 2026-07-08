import CryptoKit
import Foundation

nonisolated struct NewMenuBarItem: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let firstSeenAt: Date
    let lastSeenAt: Date
    let seenCount: Int

    init(id: String, firstSeenAt: Date, lastSeenAt: Date, seenCount: Int = 1) {
        self.id = id
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.seenCount = seenCount
    }

    func seenAgain(at date: Date) -> NewMenuBarItem {
        NewMenuBarItem(
            id: id,
            firstSeenAt: firstSeenAt,
            lastSeenAt: date,
            seenCount: seenCount + 1
        )
    }
}

nonisolated struct NewMenuBarItemInbox: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var knownItemKeys: Set<String>
    var dismissedItemKeys: Set<String>
    var items: [NewMenuBarItem]

    static let empty = NewMenuBarItemInbox(
        schemaVersion: 1,
        knownItemKeys: [],
        dismissedItemKeys: [],
        items: []
    )

    var reviewCount: Int {
        items.count
    }
}

nonisolated struct NewMenuBarItemInboxUpdate: Equatable, Sendable {
    let inbox: NewMenuBarItemInbox
    let addedItemIDs: Set<String>
}

nonisolated struct NewMenuBarItemInboxReviewRow: Identifiable, Equatable, Sendable {
    let id: String
    let displayIndex: Int
    let firstSeenAt: Date
    let lastSeenAt: Date
    let seenCount: Int
    let actions: [NewMenuBarItemReviewAction]

    init(
        id: String,
        displayIndex: Int,
        firstSeenAt: Date,
        lastSeenAt: Date,
        seenCount: Int,
        actions: [NewMenuBarItemReviewAction] = NewMenuBarItemReviewAction.defaultActions
    ) {
        self.id = id
        self.displayIndex = displayIndex
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.seenCount = seenCount
        self.actions = actions
    }

    var title: String {
        displayIndex == 1 ? "New menu bar item" : "New menu bar item \(displayIndex)"
    }

    var seenCountLabel: String {
        seenCount == 1 ? "Seen once" : "Seen \(seenCount) times"
    }
}

nonisolated enum NewMenuBarItemReviewAction: String, CaseIterable, Identifiable, Sendable {
    case keepVisible
    case hideManually
    case alwaysHideManually
    case reviewLater
    case addToCollection
    case showInFindIcon
    case showInSecondBar
    case arrangeManually
    case dryRunAssistedMove
    case dismiss

    var id: String { rawValue }

    static let defaultActions: [NewMenuBarItemReviewAction] = [
        .keepVisible,
        .hideManually,
        .alwaysHideManually,
        .reviewLater,
        .showInFindIcon,
        .showInSecondBar,
        .addToCollection,
        .arrangeManually,
        .dryRunAssistedMove,
        .dismiss
    ]

    var title: String {
        switch self {
        case .keepVisible:
            "Keep Visible"
        case .hideManually:
            "Hide Manually"
        case .alwaysHideManually:
            "Always Hide Manually"
        case .reviewLater:
            "Review Later"
        case .addToCollection:
            "Add to Collection"
        case .showInFindIcon:
            "Show in Find Icon"
        case .showInSecondBar:
            "Show in Second Bar"
        case .arrangeManually:
            "Arrange Manually"
        case .dryRunAssistedMove:
            "Assisted Move Dry-Run"
        case .dismiss:
            "Dismiss"
        }
    }

    var systemImage: String {
        switch self {
        case .keepVisible:
            "eye"
        case .hideManually:
            "eye.slash"
        case .alwaysHideManually:
            "lock"
        case .reviewLater:
            "tray"
        case .addToCollection:
            "tag"
        case .showInFindIcon:
            "magnifyingglass"
        case .showInSecondBar:
            "rectangle.bottomthird.inset.filled"
        case .arrangeManually:
            "arrow.up.left.and.arrow.down.right"
        case .dryRunAssistedMove:
            "cursorarrow.motionlines"
        case .dismiss:
            "checkmark.circle"
        }
    }

    var placementPreference: PlacementItemPreference? {
        switch self {
        case .keepVisible:
            .keepVisible
        case .hideManually:
            .hide
        case .alwaysHideManually:
            .alwaysHide
        case .reviewLater:
            .reviewLater
        default:
            nil
        }
    }
}

nonisolated struct NewMenuBarItemInboxDiagnostics: Equatable, Sendable {
    static func metadata(
        update: NewMenuBarItemInboxUpdate,
        inbox: NewMenuBarItemInbox
    ) -> [String: String] {
        [
            "addedCount": "\(update.addedItemIDs.count)",
            "reviewCount": "\(inbox.reviewCount)",
            "knownKeyCount": "\(inbox.knownItemKeys.count)",
            "dismissedKeyCount": "\(inbox.dismissedItemKeys.count)",
            "redacted": "true"
        ]
    }
}

nonisolated struct NewMenuBarItemInboxReviewState: Equatable, Sendable {
    enum Status: String, Equatable, Sendable {
        case unavailable
        case empty
        case ready
    }

    let status: Status
    let rows: [NewMenuBarItemInboxReviewRow]

    init(inbox: NewMenuBarItemInbox, isAvailable: Bool) {
        guard isAvailable else {
            self.status = .unavailable
            self.rows = []
            return
        }

        let rows = inbox.items.enumerated().map { offset, item in
            NewMenuBarItemInboxReviewRow(
                id: item.id,
                displayIndex: offset + 1,
                firstSeenAt: item.firstSeenAt,
                lastSeenAt: item.lastSeenAt,
                seenCount: item.seenCount,
                actions: NewMenuBarItemReviewAction.defaultActions
            )
        }

        self.status = rows.isEmpty ? .empty : .ready
        self.rows = rows
    }
}

nonisolated struct NewMenuBarItemInboxDetector {
    func update(
        inbox: NewMenuBarItemInbox,
        snapshots: [MenuBarItemSnapshot],
        now: Date,
        isScanningAllowed: Bool
    ) -> NewMenuBarItemInboxUpdate {
        guard isScanningAllowed else {
            return NewMenuBarItemInboxUpdate(inbox: inbox, addedItemIDs: [])
        }

        var next = inbox
        var itemsByID = Dictionary(uniqueKeysWithValues: next.items.map { ($0.id, $0) })
        var added = Set<String>()

        for snapshot in snapshots {
            let reviewID = Self.reviewID(for: snapshot)
            let keys = Self.storageKeys(for: snapshot)

            if !keys.isDisjoint(with: next.dismissedItemKeys) {
                next.dismissedItemKeys.formUnion(keys)
                continue
            }

            if !keys.isDisjoint(with: next.knownItemKeys) {
                next.knownItemKeys.formUnion(keys)
                if let existing = existingItem(in: itemsByID, reviewID: reviewID, keys: keys) {
                    itemsByID[existing.id] = nil
                    itemsByID[reviewID] = NewMenuBarItem(
                        id: reviewID,
                        firstSeenAt: existing.firstSeenAt,
                        lastSeenAt: now,
                        seenCount: existing.seenCount + 1
                    )
                }
                continue
            }

            next.knownItemKeys.formUnion(keys)
            let item = itemsByID[reviewID]?.seenAgain(at: now) ?? NewMenuBarItem(
                id: reviewID,
                firstSeenAt: now,
                lastSeenAt: now
            )
            itemsByID[reviewID] = item
            added.insert(snapshot.id)
        }

        next.items = itemsByID.values.sorted { lhs, rhs in
            if lhs.lastSeenAt == rhs.lastSeenAt {
                lhs.id < rhs.id
            } else {
                lhs.lastSeenAt > rhs.lastSeenAt
            }
        }

        return NewMenuBarItemInboxUpdate(inbox: next, addedItemIDs: added)
    }

    func dismiss(itemID: String, in inbox: NewMenuBarItemInbox) -> NewMenuBarItemInbox {
        var next = inbox
        next.dismissedItemKeys.insert(itemID)
        next.items.removeAll { $0.id == itemID }
        return next
    }

    func reset(_ inbox: NewMenuBarItemInbox) -> NewMenuBarItemInbox {
        NewMenuBarItemInbox(
            schemaVersion: inbox.schemaVersion,
            knownItemKeys: [],
            dismissedItemKeys: [],
            items: []
        )
    }

    static func storageKey(for snapshot: MenuBarItemSnapshot) -> String {
        hashedKey(snapshot.id)
    }

    static func reviewID(for snapshot: MenuBarItemSnapshot) -> String {
        guard canUseStableReviewID(for: snapshot) else {
            return storageKey(for: snapshot)
        }

        let ownerComponent: String
        if let bundleIdentifier = snapshot.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !bundleIdentifier.isEmpty {
            ownerComponent = "bundle:\(bundleIdentifier.lowercased())"
        } else {
            ownerComponent = snapshot.owningProcessIdentifier.map { "pid:\($0)" } ?? "owner:nil"
        }

        return hashedKey([
            "new-item-review-v1",
            ownerComponent,
            normalized(snapshot.role),
            normalized(snapshot.subrole)
        ].joined(separator: "|"))
    }

    static func storageKeys(for snapshot: MenuBarItemSnapshot) -> Set<String> {
        [storageKey(for: snapshot), reviewID(for: snapshot)]
    }

    private func existingItem(
        in itemsByID: [String: NewMenuBarItem],
        reviewID: String,
        keys: Set<String>
    ) -> NewMenuBarItem? {
        if let item = itemsByID[reviewID] {
            return item
        }
        return keys.lazy.compactMap { itemsByID[$0] }.first
    }

    private static func canUseStableReviewID(for snapshot: MenuBarItemSnapshot) -> Bool {
        snapshot.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || snapshot.owningProcessIdentifier != nil
    }

    private static func normalized(_ value: String?) -> String {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return "nil"
        }
        return trimmed.lowercased()
    }

    private static func hashedKey(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
final class NewMenuBarItemInboxStore {
    private let store: CodableFileStore<NewMenuBarItemInbox>?
    private(set) var inbox: NewMenuBarItemInbox

    init(
        fileURL: URL?,
        fileManager: FileManager = .default
    ) {
        let store: CodableFileStore<NewMenuBarItemInbox>?
        if let fileURL {
            // Preserve the original numeric (`.deferredToDate`) date format for
            // `firstSeenAt`/`lastSeenAt`: pass a plain encoder rather than the
            // ISO8601 CodableFileStore default so existing files still decode.
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            store = CodableFileStore(
                fileURL: fileURL,
                fileManager: fileManager,
                encoder: encoder,
                decoder: JSONDecoder()
            )
        } else {
            store = nil
        }
        self.store = store
        self.inbox = Self.load(from: store)
    }

    @discardableResult
    func apply(update: NewMenuBarItemInboxUpdate) -> NewMenuBarItemInbox {
        guard update.inbox != inbox else { return inbox }
        inbox = update.inbox
        save()
        return inbox
    }

    func dismiss(itemID: String) {
        let next = NewMenuBarItemInboxDetector().dismiss(itemID: itemID, in: inbox)
        guard next != inbox else { return }
        inbox = next
        save()
    }

    func reset() {
        inbox = NewMenuBarItemInboxDetector().reset(inbox)
        save()
    }

    private func save() {
        guard let store else { return }

        do {
            try store.write(inbox)
        } catch {
            // Inbox state is a convenience layer; failing closed keeps the app usable.
        }
    }

    private static func load(from store: CodableFileStore<NewMenuBarItemInbox>?) -> NewMenuBarItemInbox {
        guard let store else { return .empty }

        do {
            guard let inbox = try store.read() else {
                return .empty
            }
            guard inbox.schemaVersion == NewMenuBarItemInbox.empty.schemaVersion else {
                return .empty
            }
            return inbox
        } catch {
            return .empty
        }
    }
}
