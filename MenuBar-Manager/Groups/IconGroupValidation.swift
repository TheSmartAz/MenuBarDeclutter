import Foundation

/// Validates icon groups for empty names, duplicate names, and other issues.
nonisolated struct IconGroupValidation {
    enum ValidationError: Equatable, Sendable {
        case emptyName
        case duplicateName
        case noMatchableItems
    }

    static func validate(_ groups: [IconGroup]) -> [ValidationError] {
        var errors: [ValidationError] = []

        var seenNames: Set<String> = []
        var hasDuplicate = false
        for group in groups {
            let trimmed = group.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if seenNames.contains(trimmed) {
                hasDuplicate = true
                break
            }
            seenNames.insert(trimmed)
        }

        if hasDuplicate {
            errors.append(.duplicateName)
        }

        if groups.contains(where: { group in
            group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            errors.append(.emptyName)
        }

        return errors
    }

    static func validateSingle(_ group: IconGroup, existingGroups: [IconGroup]) -> [ValidationError] {
        var errors: [ValidationError] = []

        if group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyName)
        }

        let duplicateName = existingGroups.contains { $0.id != group.id && $0.name.lowercased() == group.name.lowercased() }
        if duplicateName {
            errors.append(.duplicateName)
        }

        return errors
    }
}
