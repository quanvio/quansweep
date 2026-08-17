import Foundation

struct AppResidueScanner: Scanner {
    let categoryID = "appResidues"
    let name = "App Residues"
    let icon = "archivebox"
    let description = "Leftover files from apps that are no longer installed."
    let safety: SafetyLevel = .review

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let installedBIDs = InstalledApps.bundleIDs()
        let installedNames = InstalledApps.names()

        let searchPaths: [(path: String, label: String)] = [
            ("\(home)/Library/Application Support", "Application Support"),
            ("\(home)/Library/Caches", "Cache"),
            ("\(home)/Library/Preferences", "Preferences"),
            ("\(home)/Library/Preferences/ByHost", "ByHost Preferences"),
            ("\(home)/Library/HTTPStorages", "HTTPStorages"),
            ("\(home)/Library/Logs", "Log"),
            ("\(home)/Library/Saved Application State", "Saved State"),
            ("\(home)/Library/Containers", "Container"),
            ("\(home)/Library/Group Containers", "Group Container"),
            ("\(home)/Library/LaunchAgents", "LaunchAgent")
        ]

        var items: [CleanupItem] = []

        await withTaskGroup(of: [CleanupItem].self) { group in
            for entry in searchPaths {
                group.addTask {
                    scanPath(entry.path, label: entry.label, installedBIDs: installedBIDs, installedNames: installedNames)
                }
            }
            for await result in group {
                items.append(contentsOf: result)
            }
        }

        let sorted = items.sorted { $0.size > $1.size }
        return makeCategory(items: sorted)
    }

    private func scanPath(_ path: String, label: String, installedBIDs: Set<String>, installedNames: Set<String>) -> [CleanupItem] {
        guard FileSystem.fileExists(at: path) else { return [] }

        let entries = FileSystem.contentsOfDirectory(at: path)
        var items: [CleanupItem] = []

        for entry in entries {
            let fullPath = "\(path)/\(entry)"
            if ProtectionList.isProtected(fullPath) { continue }

            let size = FileSystem.directorySize(at: fullPath)
            guard size > 1024 else { continue }

            let (bundleID, appName) = extractIdentifiers(from: entry)
            let (score, reason, safety) = ConfidenceEngine.residueConfidence(
                path: fullPath,
                bundleID: bundleID,
                appName: appName,
                installedBundleIDs: installedBIDs,
                installedAppNames: installedNames
            )

            items.append(CleanupItem(
                path: fullPath,
                name: entry,
                size: size,
                modifiedAt: FileSystem.modificationDate(at: fullPath) ?? Date(),
                appName: appName ?? bundleID,
                categoryID: categoryID,
                safety: safety,
                confidence: score,
                isLocked: safety == .protected,
                lockReason: safety == .protected ? "Protected" : nil,
                reason: reason,
                isSelected: false
            ))
        }

        return items
    }

    private func extractIdentifiers(from name: String) -> (bundleID: String?, appName: String?) {
        if name.contains(".") {
            // Likely a bundle ID like com.company.AppName
            let parts = name.split(separator: ".")
            let appNameGuess = parts.last.map(String.init)
            return (name, appNameGuess)
        } else {
            return (nil, name)
        }
    }
}
