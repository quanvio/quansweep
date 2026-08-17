import Foundation

struct TrashScanner: Scanner {
    let categoryID = "trash"
    let name = "Trash"
    let icon = "trash"
    let description = "Items already in the Trash. The safest cleanup of all."
    let safety: SafetyLevel = .safe

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let trashPath = "\(home)/.Trash"

        guard FileSystem.fileExists(at: trashPath) else {
            return makeCategory(items: [])
        }

        let entries = FileSystem.contentsOfDirectory(at: trashPath)
        let (score, reason, safety) = ConfidenceEngine.trashConfidence()

        let items: [CleanupItem] = entries.compactMap { entry in
            let fullPath = "\(trashPath)/\(entry)"
            let size = FileSystem.directorySize(at: fullPath)
            guard size > 0 else { return nil }

            return CleanupItem(
                path: fullPath,
                name: entry,
                size: size,
                modifiedAt: FileSystem.modificationDate(at: fullPath) ?? Date(),
                appName: nil,
                categoryID: categoryID,
                safety: safety,
                confidence: score,
                isLocked: false,
                lockReason: nil,
                reason: reason,
                isSelected: false
            )
        }

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }
}
