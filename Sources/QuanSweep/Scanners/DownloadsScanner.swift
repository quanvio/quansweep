import Foundation

/// Detects installers and archives in the Downloads folder that are likely stale.
/// Only the user's Downloads directory is scanned; nothing outside it is touched.
struct DownloadsScanner: Scanner {
    let categoryID = "downloads"
    let name = "Downloads & Installers"
    let icon = "arrow.down.circle.fill"
    let description = "Old installers, disk images, and archives sitting in Downloads."
    let safety: SafetyLevel = .review

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()
        let downloadsPath = "\(home)/Downloads"

        guard FileSystem.fileExists(at: downloadsPath) else {
            return makeCategory(items: [])
        }

        let entries = FileSystem.contentsOfDirectory(at: downloadsPath)
        var items: [CleanupItem] = []

        for entry in entries {
            let fullPath = "\(downloadsPath)/\(entry)"
            guard isCandidate(fullPath) else { continue }
            if ProtectionList.isProtected(fullPath) { continue }

            let size = FileSystem.directorySize(at: fullPath)
            guard size > 1024 else { continue }

            let modDate = FileSystem.modificationDate(at: fullPath) ?? Date()
            let daysOld = Calendar.current.dateComponents([.day], from: modDate, to: Date()).day ?? 0
            let fileName = URL(fileURLWithPath: fullPath).lastPathComponent
            let baseName = baseNameFor(fileName)
            let isInstaller = isInstallerFile(fileName)
            let isAppBundle = fileName.hasSuffix(".app") && isStandaloneAppBundle(fullPath)

            // Skip .app bundles that are not standalone application bundles (e.g. user projects).
            if fileName.hasSuffix(".app") && !isAppBundle { continue }

            let isInstalled = isAppInstalled(baseName: baseName)
            let (safety, confidence, reason) = classification(
                fileName: fileName,
                isInstaller: isInstaller,
                isAppBundle: isAppBundle,
                isInstalled: isInstalled,
                daysOld: daysOld
            )

            items.append(CleanupItem(
                path: fullPath,
                name: fileName,
                size: size,
                modifiedAt: modDate,
                appName: baseName,
                categoryID: categoryID,
                safety: safety,
                confidence: confidence,
                isLocked: false,
                lockReason: nil,
                reason: reason,
                isSelected: false
            ))
        }

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }

    // MARK: - Candidate detection

    private func isCandidate(_ path: String) -> Bool {
        let name = path.lowercased()
        return name.hasSuffix(".dmg")
            || name.hasSuffix(".pkg")
            || name.hasSuffix(".zip")
            || name.hasSuffix(".tar.gz")
            || name.hasSuffix(".tgz")
            || name.hasSuffix(".bz2")
            || name.hasSuffix(".iso")
            || name.hasSuffix(".app")
    }

    private func isInstallerFile(_ fileName: String) -> Bool {
        let lowered = fileName.lowercased()
        return lowered.hasSuffix(".dmg") || lowered.hasSuffix(".pkg")
    }

    private func isStandaloneAppBundle(_ path: String) -> Bool {
        let infoPath = "\(path)/Contents/Info.plist"
        guard FileSystem.fileExists(at: infoPath),
              let dict = NSDictionary(contentsOfFile: infoPath) as? [String: Any] else {
            return false
        }
        return dict["CFBundleIdentifier"] as? String != nil
    }

    private func baseNameFor(_ fileName: String) -> String {
        let url = URL(fileURLWithPath: fileName)
        let name = url.deletingPathExtension().lastPathComponent

        // Handle compound extensions like .tar.gz.
        if name.lowercased().hasSuffix(".tar"), let withoutTar = name.range(of: ".tar", options: [.caseInsensitive, .backwards]) {
            return String(name[..<withoutTar.lowerBound])
        }
        return name
    }

    // MARK: - Installed-app check

    private func isAppInstalled(baseName: String) -> Bool {
        guard !baseName.isEmpty else { return false }

        // Check the literal app name in /Applications and ~/Applications.
        let candidates = [
            "/Applications/\(baseName).app",
            "\(NSHomeDirectory())/Applications/\(baseName).app"
        ]
        for candidate in candidates where FileSystem.fileExists(at: candidate) {
            return true
        }

        // Also recognize common suffixes such as "Postman-10.0.1.dmg" -> "Postman".
        let stripped = stripVersionSuffix(from: baseName)
        if stripped != baseName {
            let strippedCandidates = [
                "/Applications/\(stripped).app",
                "\(NSHomeDirectory())/Applications/\(stripped).app"
            ]
            for candidate in strippedCandidates where FileSystem.fileExists(at: candidate) {
                return true
            }
        }

        return false
    }

    private func stripVersionSuffix(from name: String) -> String {
        let patterns: [String] = [
            #"-[\d\.]+[a-zA-Z]?$"#,
            #"_[\d\.]+[a-zA-Z]?$"#,
            #"\s[\d\.]+[a-zA-Z]?$"#
        ]
        for pattern in patterns {
            if let range = name.range(of: pattern, options: .regularExpression) {
                return String(name[..<range.lowerBound])
            }
        }
        return name
    }

    // MARK: - Classification

    private func classification(
        fileName: String,
        isInstaller: Bool,
        isAppBundle: Bool,
        isInstalled: Bool,
        daysOld: Int
    ) -> (SafetyLevel, Int, String) {
        if isAppBundle {
            return (.review, 70, "App bundle in Downloads; review before deleting.")
        }

        if isInstaller {
            if isInstalled && daysOld > 30 {
                return (
                    .safe,
                    95,
                    "\(displayName(for: fileName)) is installed and this installer is \(daysOld) days old."
                )
            } else if isInstalled {
                return (
                    .review,
                    70,
                    "\(displayName(for: fileName)) is installed, but this installer is recent."
                )
            } else {
                return (
                    .review,
                    70,
                    "Installer not recognized as installed; review before deleting."
                )
            }
        }

        return (.review, 70, "Old archive; review before deleting.")
    }

    private func displayName(for fileName: String) -> String {
        let base = baseNameFor(fileName)
        return base.replacingOccurrences(of: "-", with: " ")
                   .replacingOccurrences(of: "_", with: " ")
                   .trimmingCharacters(in: .whitespaces)
    }
}
