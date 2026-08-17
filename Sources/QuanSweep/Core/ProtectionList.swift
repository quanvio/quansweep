import Foundation

/// Paths that QuanSweep must never touch.
enum ProtectionList {
    static let systemPaths: [String] = [
        "/System",
        "/Library",
        "/private",
        "/usr",
        "/bin",
        "/sbin",
        "/opt",
        "/dev",
        "/etc",
        "/var",
        "/Applications"
    ]

    static let userCriticalPaths: [String] = {
        let home = NSHomeDirectory()
        return [
            "\(home)/Documents",
            "\(home)/Desktop",
            "\(home)/Pictures",
            "\(home)/Movies",
            "\(home)/Music",
            "\(home)/.ssh",
            "\(home)/.gitconfig",
            "\(home)/.aws",
            "\(home)/.docker",
            "\(home)/Library/Keychains",
            "\(home)/Library/Messages",
            "\(home)/Library/Mail",
            "\(home)/Library/Photos",
            "\(home)/Library/Safari",
            "\(home)/Library/Application Support/Google/Chrome/Default",
            "\(home)/Library/Application Support/Firefox"
        ]
    }()

    /// Returns true if the path is protected and must not be scanned for cleanup.
    static func isProtected(_ path: String) -> Bool {
        let resolved = (path as NSString).standardizingPath

        for protected in systemPaths {
            if resolved == protected || resolved.hasPrefix(protected + "/") {
                return true
            }
        }

        for protected in userCriticalPaths {
            if resolved == protected || resolved.hasPrefix(protected + "/") {
                return true
            }
        }

        return false
    }
}
