import Foundation

/// Import/export helpers for icon groups.
nonisolated struct IconGroupImportExport {
    /// Schema version for group export/import.
    static let exportSchemaVersion = 1

    enum ExportRedactionMode: String, Equatable, Sendable {
        case privacySafe
        case unredacted
    }

    enum ImportExportError: Error, Equatable, LocalizedError, Sendable {
        case unsupportedSchemaVersion(Int)
        case validationFailed([IconGroupValidation.ValidationError])

        var errorDescription: String? {
            switch self {
            case let .unsupportedSchemaVersion(version):
                "Unsupported group schema version \(version)."
            case let .validationFailed(errors):
                "Group import failed validation: \(errors.map(\.displayText).joined(separator: " "))"
            }
        }
    }

    enum ImportWarningKind: String, Equatable, Sendable {
        case emptyGroups
        case removedUnmatchableItemRefs
    }

    struct ImportWarning: Equatable, Sendable {
        let kind: ImportWarningKind
        let count: Int

        var displayText: String {
            switch kind {
            case .emptyGroups:
                "\(count) imported group(s) have no matchable items."
            case .removedUnmatchableItemRefs:
                "\(count) item reference(s) without match criteria were skipped."
            }
        }
    }

    struct ImportReport: Equatable, Sendable {
        let groups: [IconGroup]
        let warnings: [ImportWarning]

        var warningSummary: String? {
            let text = warnings
                .filter { $0.count > 0 }
                .map(\.displayText)
                .joined(separator: " ")
            return text.isEmpty ? nil : text
        }
    }

    /// Encode groups to JSON data.
    static func export(
        _ groups: [IconGroup],
        redactionMode: ExportRedactionMode = .privacySafe
    ) throws -> Data {
        let container = IconGroupContainer(
            schemaVersion: exportSchemaVersion,
            groups: groupsForExport(groups, redactionMode: redactionMode)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(container)
    }

    /// Decode groups from JSON data.
    static func importFrom(data: Data) throws -> [IconGroup] {
        try importReport(from: data).groups
    }

    /// Decode groups and return privacy-safe validation warnings for the UI.
    static func importReport(from data: Data) throws -> ImportReport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let container = try decoder.decode(IconGroupContainer.self, from: data)

        guard container.schemaVersion == exportSchemaVersion else {
            throw ImportExportError.unsupportedSchemaVersion(container.schemaVersion)
        }

        let normalized = container.groups.map(normalizedImportedGroup)
        let validationErrors = IconGroupValidation.validate(normalized)
        guard validationErrors.isEmpty else {
            throw ImportExportError.validationFailed(validationErrors)
        }

        let removedItemRefCount = zip(container.groups, normalized).reduce(0) { total, pair in
            total + max(0, pair.0.itemRefs.count - pair.1.itemRefs.count)
        }
        let emptyGroupCount = normalized.filter(\.itemRefs.isEmpty).count
        let warnings = [
            ImportWarning(kind: .removedUnmatchableItemRefs, count: removedItemRefCount),
            ImportWarning(kind: .emptyGroups, count: emptyGroupCount)
        ].filter { $0.count > 0 }

        return ImportReport(
            groups: IconGroupSort.sort(normalized),
            warnings: warnings
        )
    }

    /// Export a single group.
    static func exportGroup(
        _ group: IconGroup,
        redactionMode: ExportRedactionMode = .privacySafe
    ) throws -> Data {
        try export([group], redactionMode: redactionMode)
    }

    /// Return groups prepared for privacy-safe export packages.
    static func groupsForExport(
        _ groups: [IconGroup],
        redactionMode: ExportRedactionMode = .privacySafe
    ) -> [IconGroup] {
        groups.map { group in
            guard redactionMode == .privacySafe, group.isProtected else {
                return group
            }

            return IconGroup(
                id: group.id,
                name: "Protected Group",
                symbolName: group.symbolName,
                colorName: group.colorName,
                notes: nil,
                isEnabled: group.isEnabled,
                isProtected: group.isProtected,
                showInSecondBar: group.showInSecondBar,
                showAsStatusItem: false,
                sortOrder: group.sortOrder,
                itemRefs: [],
                createdAt: group.createdAt,
                updatedAt: group.updatedAt
            )
        }
    }

    private static func normalizedImportedGroup(_ group: IconGroup) -> IconGroup {
        IconGroup(
            id: group.id,
            name: group.name.trimmingCharacters(in: .whitespacesAndNewlines),
            symbolName: cleaned(group.symbolName),
            colorName: cleaned(group.colorName),
            notes: cleaned(group.notes),
            isEnabled: group.isEnabled,
            isProtected: group.isProtected,
            showInSecondBar: group.showInSecondBar,
            showAsStatusItem: group.showAsStatusItem,
            sortOrder: group.sortOrder,
            itemRefs: group.itemRefs
                .map(normalizedImportedItemRef)
                .filter(\.hasMatchableCriteria),
            createdAt: group.createdAt,
            updatedAt: group.updatedAt
        )
    }

    private static func normalizedImportedItemRef(_ ref: IconGroupItemRef) -> IconGroupItemRef {
        IconGroupItemRef(
            id: ref.id,
            bundleIdentifier: cleaned(ref.bundleIdentifier),
            appName: cleaned(ref.appName),
            snapshotStableID: cleaned(ref.snapshotStableID),
            titleContains: cleaned(ref.titleContains),
            zone: ref.zone,
            manualLabel: cleaned(ref.manualLabel)
        )
    }

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

private extension IconGroupValidation.ValidationError {
    nonisolated var displayText: String {
        switch self {
        case .emptyName:
            "Group name is required."
        case .duplicateName:
            "Group names must be unique."
        case .noMatchableItems:
            "At least one item needs match criteria."
        }
    }
}
