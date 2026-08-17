import Foundation

struct TempScanner: Scanner {
    let categoryID = "temp"
    let name = "Temporary Files"
    let icon = "clock.arrow.circlepath"
    let description = "Temporary files in /tmp and your user temp folder. Older files are safer."
    let safety: SafetyLevel = .review

    func scan() async -> CleanupCategory {
        let userTemp = FileManager.default.temporaryDirectory.path
        let paths = ["/tmp", userTemp]

        var items: [CleanupItem] = []

        for base in paths {
            guard FileSystem.fileExists(at: base) else { continue }
            let entries = FileSystem.contentsOfDirectory(at: base)
            for entry in entries {
                let fullPath = "\(base)/\(entry)"
                if ProtectionList.isProtected(fullPath) { continue }

                let size = FileSystem.directorySize(at: fullPath)
                guard size > 1024 else { continue }

                let modDate = FileSystem.modificationDate(at: fullPath) ?? Date()
                let (score, reason, safety) = ConfidenceEngine.tempConfidence(modifiedAt: modDate)

                items.append(CleanupItem(
                    path: fullPath,
                    name: entry,
                    size: size,
                    modifiedAt: modDate,
                    appName: nil,
                    categoryID: categoryID,
                    safety: safety,
                    confidence: score,
                    isLocked: false,
                    lockReason: nil,
                    reason: reason,
                    isSelected: false
                ))
            }
        }

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }
}
