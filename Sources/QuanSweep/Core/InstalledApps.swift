import Foundation

struct InstalledApp: Equatable {
    let name: String
    let bundleID: String
    let path: String
}

enum InstalledApps {
    static func all() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let searchPaths = ["/Applications", "\(NSHomeDirectory())/Applications"]

        for base in searchPaths {
            let entries = (try? FileManager.default.contentsOfDirectory(atPath: base)) ?? []
            for entry in entries where entry.hasSuffix(".app") {
                let appPath = "\(base)/\(entry)"
                let infoPath = "\(appPath)/Contents/Info.plist"
                let name = entry.replacingOccurrences(of: ".app", with: "")
                var bundleID = ""

                if let dict = NSDictionary(contentsOfFile: infoPath) as? [String: Any],
                   let bid = dict["CFBundleIdentifier"] as? String {
                    bundleID = bid
                }

                apps.append(InstalledApp(name: name, bundleID: bundleID, path: appPath))
            }
        }

        return apps
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
}
