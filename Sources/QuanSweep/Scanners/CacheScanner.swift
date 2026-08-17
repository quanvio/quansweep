import Foundation
import AppKit

struct CacheScanner: Scanner {
    let categoryID = "caches"
    let name = "App Caches"
    let icon = "square.3.layers.3d.down.forward"
    let description = "Third-party application caches. Apple and running-app caches are protected."
    let safety: SafetyLevel = .review

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let cachesPath = "\(home)/Library/Caches"
        let running = runningAppNames()

        guard FileSystem.fileExists(at: cachesPath) else {
            return makeCategory(items: [])
        }

        let entries = FileSystem.contentsOfDirectory(at: cachesPath)
        var items: [CleanupItem] = []

        for entry in entries {
            let fullPath = "\(cachesPath)/\(entry)"
            if ProtectionList.isProtected(fullPath) { continue }

            let size = FileSystem.directorySize(at: fullPath)
            guard size > 1024 else { continue }

            let appName = appNameFromBundleID(entry)
            let isRunning = running.contains(appName.lowercased()) || running.contains(entry.lowercased())
            let (score, reason, safety) = ConfidenceEngine.cacheConfidence(path: fullPath, appName: appName, isRunning: isRunning)

            items.append(CleanupItem(
                path: fullPath,
                name: entry,
                size: size,
                modifiedAt: FileSystem.modificationDate(at: fullPath) ?? Date(),
                appName: appName,
                categoryID: categoryID,
                safety: safety,
                confidence: score,
                isLocked: isRunning,
                lockReason: isRunning ? "App may be running" : nil,
                reason: reason,
                isSelected: false
            ))
        }

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }

    private func runningAppNames() -> Set<String> {
        var names: Set<String> = []
        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName?.lowercased() {
                names.insert(name)
            }
            if let bundle = app.bundleIdentifier {
                names.insert(bundle.lowercased())
                names.insert(appNameFromBundleID(bundle).lowercased())
            }
        }
        return names
    }

    private func appNameFromBundleID(_ bundleID: String) -> String {
        let parts = bundleID.split(separator: ".")
        return parts.last.map(String.init) ?? bundleID
    }
}
