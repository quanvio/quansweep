import Foundation

protocol Scanner {
    var categoryID: String { get }
    var name: String { get }
    var icon: String { get }
    var description: String { get }
    var safety: SafetyLevel { get }

    func scan() async -> CleanupCategory
}

extension Scanner {
    func scanWithSafety() async throws -> CleanupCategory {
        return await scan()
    }

    func makeCategory(items: [CleanupItem]) -> CleanupCategory {
        let selectable = items.map { item -> CleanupItem in
            var copy = item
            copy.isSelected = item.safety == .safe && !item.isLocked
            return copy
        }
        return CleanupCategory(
            id: categoryID,
            name: name,
            icon: icon,
            safety: safety,
            description: description,
            items: selectable,
            isSelected: safety == .safe,
            isScanning: false,
            errorMessage: nil
        )
    }
}
