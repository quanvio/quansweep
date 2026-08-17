import Foundation

/// Finds individual files larger than 100 MB in common user directories.
/// All findings are marked for manual review and are never auto-selected.
struct LargeFileScanner: Scanner {
    let categoryID = "largeFiles"
    let name = "Large Files"
    let icon = "doc.text.magnifyingglass"
    let description = "Individual files over 100 MB in Downloads, Documents, Desktop, and media folders."
    let safety: SafetyLevel = .review

    private static let sizeThreshold: UInt64 = 100 * 1024 * 1024
    private static let maxResults = 100

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let roots: [(path: String, maxDepth: Int)] = [
            ("\(home)/Downloads", 100),
            ("\(home)/Documents", 2),
            ("\(home)/Desktop", 2),
            ("\(home)/Movies", 2),
            ("\(home)/Pictures", 2),
            ("\(home)/Music", 2)
        ]

        var fileInfos: [(path: String, size: UInt64, modifiedAt: Date)] = []

        for root in roots where FileSystem.fileExists(at: root.path) {
            enumerateFiles(
                at: root.path,
                maxDepth: root.maxDepth,
                currentDepth: 0
            ) { path, size, modifiedAt in
                guard size > Self.sizeThreshold else { return }
                fileInfos.append((path, size, modifiedAt))
            }
        }

        let topFiles = fileInfos
            .sorted { $0.size > $1.size }
            .prefix(Self.maxResults)

        let items = topFiles.map { info in
            CleanupItem(
                path: info.path,
                name: URL(fileURLWithPath: info.path).lastPathComponent,
                size: info.size,
                modifiedAt: info.modifiedAt,
                appName: nil,
                categoryID: categoryID,
                safety: .review,
                confidence: 50,
                isLocked: false,
                lockReason: nil,
                reason: "Large file. Review before removing.",
                isSelected: false
            )
        }

        return makeCategory(items: items)
    }

    private func enumerateFiles(
        at path: String,
        maxDepth: Int,
        currentDepth: Int,
        visitor: (String, UInt64, Date) -> Void
    ) {
        guard currentDepth <= maxDepth else { return }
        guard FileSystem.fileExists(at: path) else { return }

        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey]),
              values.isSymbolicLink != true else {
            return
        }

        // The scan roots themselves are user directories that are intentionally
        // scanned. Only block system paths, not user documents.
        if ProtectionList.isSystemProtected(path) {
            return
        }

        if values.isDirectory != true {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? UInt64,
               let modifiedAt = attrs[.modificationDate] as? Date {
                visitor(path, size, modifiedAt)
            }
            return
        }

        let entries = FileSystem.contentsOfDirectory(at: path)
        for entry in entries {
            enumerateFiles(
                at: "\(path)/\(entry)",
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1,
                visitor: visitor
            )
        }
    }
}
