import Foundation

/// Scores cleanup candidates from 0 (never touch) to 100 (definitely safe).
enum ConfidenceEngine {

    private static let protectedVendors: Set<String> = [
        "apple", "com.apple",
        "google", "com.google",
        "microsoft", "com.microsoft"
    ]

    private static let knownDeveloperPrefixes = [
        "go-build", "node", "npm", "yarn", "pnpm", "bun", "cargo", "pip", "uv", "xcode"
    ]

    /// App residue confidence based on installed apps and bundle ID matching.
    static func residueConfidence(
        path: String,
        bundleID: String?,
        appName: String?,
        installedBundleIDs: Set<String>,
        installedAppNames: Set<String>,
        modifiedAt: Date
    ) -> (score: Int, reason: String, safety: SafetyLevel) {
        let lowerPath = path.lowercased()

        // Apple system residues are protected.
        if lowerPath.contains("/com.apple.") || lowerPath.contains("/apple/") {
            return (0, "Apple system data. Never removed.", .protected)
        }

        let bid = bundleID?.lowercased() ?? ""
        let name = appName?.lowercased() ?? ""
        let ageDays = Int(Date().timeIntervalSince(modifiedAt) / 86400)

        // Vendor umbrella folders (e.g. "Google", "Microsoft") are risky because they
        // can hold data for multiple apps. Only safe if no app from that vendor is installed.
        if protectedVendors.contains(name) || protectedVendors.contains(bid) {
            let vendorApps = installedAppNames.filter { installed in
                protectedVendors.contains { installed.lowercased().contains($0) || $0.contains(installed.lowercased()) }
            }
            if vendorApps.isEmpty {
                return (70, "Vendor folder for uninstalled apps. Review before removing.", .review)
            }
            return (10, "Vendor folder may contain data for installed apps.", .review)
        }

        // Exact bundle ID match and app not installed → orphan.
        if !bid.isEmpty {
            if installedBundleIDs.contains(bid) {
                return (40, "App is still installed. This may be active user data.", .review)
            } else {
                if ageDays > 30 {
                    return (99, "Orphan residue. App not installed and untouched for \(ageDays) days.", .safe)
                } else if ageDays > 7 {
                    return (95, "Orphan residue. App not installed.", .safe)
                } else {
                    return (85, "Orphan residue but modified recently. Review if unsure.", .review)
                }
            }
        }

        // Plain app name match.
        if !name.isEmpty {
            if installedAppNames.contains(name) {
                return (45, "App is still installed. Review before removing.", .review)
            }
            // Name is similar to an installed app?
            let similar = installedAppNames.first { $0.contains(name) || name.contains($0) }
            if let similar = similar {
                return (30, "Looks like '\(similar)', which is installed. Review.", .review)
            }
            return (75, "No installed app matches this name.", .review)
        }

        return (50, "Unknown residue. Review recommended.", .review)
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

        let name = appName?.lowercased() ?? ""
        if protectedVendors.contains(name) {
            return (25, "Vendor cache folder may contain data for multiple apps.", .review)
        }

        if isRunning {
            return (30, "Application may be running. Skip to avoid crashes.", .review)
        }

        // Known developer tools caches are regeneratable.
        for id in knownDeveloperPrefixes {
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
