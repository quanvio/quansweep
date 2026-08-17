import Foundation

/// Scores cleanup candidates from 0 (never touch) to 100 (definitely safe).
enum ConfidenceEngine {

    /// App residue confidence based on installed apps and bundle ID matching.
    static func residueConfidence(
        path: String,
        bundleID: String?,
        appName: String?,
        installedBundleIDs: Set<String>,
        installedAppNames: Set<String>
    ) -> (score: Int, reason: String, safety: SafetyLevel) {
        let lowerPath = path.lowercased()

        // Apple system residues are protected.
        if lowerPath.contains("/com.apple.") || lowerPath.contains("/apple/") {
            return (0, "Apple system data. Never removed.", .protected)
        }

        let bid = bundleID?.lowercased() ?? ""
        let name = appName?.lowercased() ?? ""

        // Exact bundle ID match and app not installed → very safe orphan.
        if !bid.isEmpty, !installedBundleIDs.contains(bid) {
            return (99, "App with bundle ID '\(bid)' is not installed.", .safe)
        }

        // App name match and not installed → likely safe.
        if !name.isEmpty, !installedAppNames.contains(name) {
            return (90, "No installed app matches '\(name)'.", .safe)
        }

        // Installed app → review, could be active data.
        if !bid.isEmpty, installedBundleIDs.contains(bid) {
            return (40, "App is still installed. May be active user data.", .review)
        }

        if !name.isEmpty, installedAppNames.contains(name) {
            return (45, "App is still installed. Review before removing.", .review)
        }

        return (60, "Unknown residue. Review recommended.", .review)
    }

    /// Cache confidence based on owner and running state.
    static func cacheConfidence(
        path: String,
        appName: String?,
        isRunning: Bool
    ) -> (score: Int, reason: String, safety: SafetyLevel) {
        let lowerPath = path.lowercased()

        if lowerPath.contains("/com.apple.") {
            return (0, "Apple cache. Protected.", .protected)
        }

        if isRunning {
            return (30, "Application may be running. Skip to avoid crashes.", .review)
        }

        // Known developer tools caches are regeneratable.
        let developerIds = ["go-build", "node", "npm", "yarn", "pnpm", "bun", "cargo", "pip", "uv", "xcode"]
        for id in developerIds {
            if lowerPath.contains(id) {
                return (95, "Developer tool cache. Regeneratable.", .safe)
            }
        }

        // Known browsers.
        let browsers = ["chrome", "safari", "firefox", "edge", "brave"]
        for browser in browsers {
            if lowerPath.contains(browser) {
                return (90, "Browser cache. Safe to clear when browser is closed.", .safe)
            }
        }

        return (70, "Third-party cache. Likely safe.", .review)
    }

    /// Temporary file confidence.
    static func tempConfidence(modifiedAt: Date) -> (score: Int, reason: String, safety: SafetyLevel) {
        let age = Date().timeIntervalSince(modifiedAt)
        let days = Int(age / 86400)

        if days > 7 {
            return (95, "Temp file is \(days) days old. Likely abandoned.", .safe)
        } else if days > 1 {
            return (80, "Temp file is \(days) days old. Probably safe.", .safe)
        } else {
            return (50, "Temp file is recent. Review if an app is running.", .review)
        }
    }

    /// Log confidence.
    static func logConfidence() -> (score: Int, reason: String, safety: SafetyLevel) {
        return (90, "User logs are safe to remove.", .safe)
    }

    /// Trash confidence.
    static func trashConfidence() -> (score: Int, reason: String, safety: SafetyLevel) {
        return (99, "Items already in Trash.", .safe)
    }

    /// Xcode build data confidence.
    static func xcodeConfidence() -> (score: Int, reason: String, safety: SafetyLevel) {
        return (95, "Xcode build data is regeneratable.", .safe)
    }
}
