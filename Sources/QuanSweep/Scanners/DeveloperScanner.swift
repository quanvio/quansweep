import Foundation

/// Detects developer tool caches that are regeneratable.
/// Only well-known cache folders are scanned; user projects and source code are never touched.
struct DeveloperScanner: Scanner {
    let categoryID = "developer"
    let name = "Developer Caches"
    let icon = "hammer.fill"
    let description = "Regeneratable caches for Go, Node, Python, Rust, Swift, Homebrew, and more."
    let safety: SafetyLevel = .safe

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()

        let candidates: [(path: String, tool: String, description: String)] = [
            // Go
            ("\(home)/Library/Caches/go-build", "Go", "Go build cache. Rebuilt on next compile."),

            // Node / npm / pnpm / yarn
            ("\(home)/.npm", "Node", "npm cache. Packages are re-downloaded when needed."),
            ("\(home)/.cache/npm", "Node", "npm cache directory."),
            ("\(home)/.pnpm-store", "pnpm", "pnpm global store. Project dependencies remain intact."),
            ("\(home)/.cache/yarn", "Yarn", "Yarn cache."),
            ("\(home)/.cache/node-gyp", "Node", "node-gyp build artifacts."),

            // Bun
            ("\(home)/.bun/install/cache", "Bun", "Bun package cache."),

            // Python
            ("\(home)/.cache/pip", "Python", "pip download cache."),
            ("\(home)/.cache/uv", "Python", "uv package cache."),
            ("\(home)/Library/Caches/pip", "Python", "pip cache under Library."),

            // Rust
            ("\(home)/.cargo/registry", "Rust", "Cargo crate registry cache. Re-downloaded on build."),
            ("\(home)/.cargo/git", "Rust", "Cargo git dependencies cache."),

            // Swift / Xcode
            ("\(home)/Library/Developer/Xcode/DerivedData", "Xcode", "Xcode build output. Projects rebuild from source."),
            ("\(home)/Library/Developer/Xcode/Archives", "Xcode", "Xcode archives."),
            ("\(home)/Library/Caches/com.apple.dt.Xcode", "Xcode", "Xcode caches."),
            ("\(home)/Library/Caches/org.swift.swiftpm", "Swift", "Swift Package Manager cache."),
            ("\(home)/Library/Caches/com.github.swiftformat", "Swift", "SwiftFormat cache."),

            // Homebrew
            ("\(home)/Library/Caches/Homebrew", "Homebrew", "Homebrew download cache. Re-downloaded on install."),

            // Playwright
            ("\(home)/Library/Caches/ms-playwright", "Playwright", "Playwright browser binaries. Re-downloaded on next run."),

            // Docker Desktop
            ("\(home)/Library/Containers/com.docker.docker/Data/vms", "Docker", "Docker Desktop VM data. Only clear if you understand the impact."),

            // JetBrains
            ("\(home)/Library/Caches/JetBrains", "JetBrains", "JetBrains IDE caches. Indexes rebuild on launch."),
            ("\(home)/Library/Logs/JetBrains", "JetBrains", "JetBrains IDE logs."),

            // Android
            ("\(home)/Library/Android/sdk/.temp", "Android", "Android SDK temporary files."),
            ("\(home)/.gradle/caches", "Gradle", "Gradle dependency cache. Re-downloaded on build."),
        ]

        var items: [CleanupItem] = []

        for candidate in candidates {
            guard FileSystem.fileExists(at: candidate.path) else { continue }
            if ProtectionList.isProtected(candidate.path) { continue }

            let size = FileSystem.directorySize(at: candidate.path)
            guard size > 1024 else { continue }

            let modDate = FileSystem.modificationDate(at: candidate.path) ?? Date()
            let name = URL(fileURLWithPath: candidate.path).lastPathComponent

            items.append(CleanupItem(
                path: candidate.path,
                name: "\(candidate.tool): \(name)",
                size: size,
                modifiedAt: modDate,
                appName: candidate.tool,
                categoryID: categoryID,
                safety: candidate.tool == "Docker" ? .advanced : .safe,
                confidence: candidate.tool == "Docker" ? 70 : 95,
                isLocked: false,
                lockReason: nil,
                reason: candidate.description,
                isSelected: false
            ))
        }

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }
}
