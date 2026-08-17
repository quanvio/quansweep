import Foundation

struct InstalledApp: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String
    let path: String
    let version: String
    let size: UInt64
    let lastUsedAt: Date

    var displayName: String { name }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var formattedLastUsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsedAt, relativeTo: Date())
    }
}

enum InstalledApps {
    static func all() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let searchPaths = ["/Applications", "\(NSHomeDirectory())/Applications"]

        for base in searchPaths {
            let entries = (try? FileManager.default.contentsOfDirectory(atPath: base)) ?? []
            for entry in entries where entry.hasSuffix(".app") {
                let appPath = "\(base)/\(entry)"
                apps.append(app(at: appPath))
            }
        }

        return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func app(at path: String) -> InstalledApp {
        let infoPath = "\(path)/Contents/Info.plist"
        let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        var bundleID = ""
        var version = ""

        if let dict = NSDictionary(contentsOfFile: infoPath) as? [String: Any] {
            bundleID = dict["CFBundleIdentifier"] as? String ?? ""
            version = dict["CFBundleShortVersionString"] as? String ?? ""
        }

        let size = FileSystem.directorySize(at: path)
        let lastUsed = lastUsedDate(for: path)

        return InstalledApp(
            name: name,
            bundleID: bundleID,
            path: path,
            version: version,
            size: size,
            lastUsedAt: lastUsed
        )
    }

    static func bundleIDs() -> Set<String> {
        Set(all().map { $0.bundleID.lowercased() }.filter { !$0.isEmpty })
    }

    static func names() -> Set<String> {
        Set(all().map { $0.name.lowercased() })
    }

    static func nameForBundleID(_ bundleID: String) -> String? {
        all().first { $0.bundleID.lowercased() == bundleID.lowercased() }?.name
    }

    /// Returns safe residue paths under ~/Library that match the app by bundle ID or name.
    static func relatedResiduePaths(for app: InstalledApp) -> [String] {
        let home = NSHomeDirectory()
        let basePaths = [
            "\(home)/Library/Application Support",
            "\(home)/Library/Caches",
            "\(home)/Library/Preferences",
            "\(home)/Library/Preferences/ByHost",
            "\(home)/Library/HTTPStorages",
            "\(home)/Library/Logs",
            "\(home)/Library/Saved Application State",
            "\(home)/Library/Containers",
            "\(home)/Library/Group Containers",
            "\(home)/Library/LaunchAgents"
        ]

        // Build a set of candidate identifiers. Bundle IDs are the safest signal.
        // Short names must be at least 4 characters to avoid matching common words.
        var identifiers: [String] = []
        if !app.bundleID.isEmpty {
            identifiers.append(app.bundleID.lowercased())
            let parts = app.bundleID.split(separator: ".")
            if let last = parts.last, last.count >= 4 {
                identifiers.append(String(last).lowercased())
            }
        }
        if !app.name.isEmpty, app.name.count >= 4 {
            identifiers.append(app.name.lowercased())
        }

        var matches: [String] = []
        for base in basePaths {
            guard FileSystem.fileExists(at: base) else { continue }
            let entries = FileSystem.contentsOfDirectory(at: base)
            for entry in entries {
                let fullPath = "\(base)/\(entry)"
                guard !ProtectionList.isProtected(fullPath) else { continue }

                let loweredEntry = entry.lowercased()
                let matched = identifiers.contains { identifier in
                    // Entry must contain the identifier (e.g., "com.microsoft.teams" or "Teams").
                    // We do NOT match in reverse, so "Microsoft" won't match every Microsoft app.
                    loweredEntry.contains(identifier)
                }

                if matched {
                    matches.append(fullPath)
                }
            }
        }

        return matches
    }

    // MARK: - Private

    private static func lastUsedDate(for path: String) -> Date {
        // Use the bundle's content modification date as a proxy for last use.
        if let date = FileSystem.modificationDate(at: path) {
            return date
        }
        return Date.distantPast
    }
}
