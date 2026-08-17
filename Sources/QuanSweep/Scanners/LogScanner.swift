import Foundation

struct LogScanner: Scanner {
    let categoryID = "logs"
    let name = "User Logs"
    let icon = "doc.text.magnifyingglass"
    let description = "Application and system logs in your home folder."
    let safety: SafetyLevel = .safe

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let logsPath = "\(home)/Library/Logs"

        guard FileSystem.fileExists(at: logsPath) else {
            return makeCategory(items: [])
        }

        let entries = FileSystem.contentsOfDirectory(at: logsPath)
        let (score, reason, safety) = ConfidenceEngine.logConfidence()

        let items: [CleanupItem] = entries.compactMap { entry in
            let fullPath = "\(logsPath)/\(entry)"
            if ProtectionList.isProtected(fullPath) { return nil }
            let size = FileSystem.directorySize(at: fullPath)
            guard size > 1024 else { return nil }

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
