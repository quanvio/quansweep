import Foundation

struct XcodeScanner: Scanner {
    let categoryID = "xcode"
    let name = "Xcode Build Data"
    let icon = "hammer.fill"
    let description = "Derived Data, Archives, and iOS Device Logs. Fully regeneratable."
    let safety: SafetyLevel = .safe

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let paths: [(path: String, name: String)] = [
            ("\(home)/Library/Developer/Xcode/DerivedData", "Derived Data"),
            ("\(home)/Library/Developer/Xcode/Archives", "Archives"),
            ("\(home)/Library/Developer/Xcode/iOS Device Logs", "iOS Device Logs")
        ]

        let (score, reason, safety) = ConfidenceEngine.xcodeConfidence()

        let items: [CleanupItem] = paths.compactMap { entry in
            guard FileSystem.fileExists(at: entry.path) else { return nil }
            let size = FileSystem.directorySize(at: entry.path)
            guard size > 1024 else { return nil }

            return CleanupItem(
                path: entry.path,
                name: entry.name,
                size: size,
                modifiedAt: FileSystem.modificationDate(at: entry.path) ?? Date(),
                appName: "Xcode",
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
