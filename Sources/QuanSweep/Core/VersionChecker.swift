import Foundation
import AppKit

actor VersionChecker {
    static let shared = VersionChecker()

    private let repo = "quanvio/quansweep"
    private let updateURL = URL(string: "https://github.com/quanvio/quansweep/releases/latest")!

    func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    func latestVersion() async -> String? {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["tag_name"] as? String
        } catch {
            return nil
        }
    }

    func isUpdateAvailable() async -> Bool {
        guard let latest = await latestVersion() else { return false }
        let current = currentVersion()
        return latest != current && latest != "Unknown"
    }

    nonisolated func openReleasesPage() {
        NSWorkspace.shared.open(updateURL)
    }
}
