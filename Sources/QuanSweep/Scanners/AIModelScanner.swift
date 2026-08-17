import Foundation

/// Detects locally stored AI/ML model files and caches.
/// All findings are marked for manual review and are never auto-selected.
struct AIModelScanner: Scanner {
    let categoryID = "aiModels"
    let name = "AI Models"
    let icon = "brain"
    let description = "Hugging Face, Ollama, LM Studio, and other AI/ML model caches and files."
    let safety: SafetyLevel = .review

    private static let modelExtensions: Set<String> = [
        "gguf", "safetensors", "mlx", "bin", "pt", "pth", "onnx"
    ]
    private static let binThreshold: UInt64 = 50 * 1024 * 1024
    private static let oldThresholdDays = 90

    func scan() async -> CleanupCategory {
        let home = NSHomeDirectory()

        let aiRoots: [(path: String, label: String)] = [
            ("\(home)/.cache/huggingface", "huggingface"),
            ("\(home)/.ollama/models", "ollama"),
            ("\(home)/Library/Application Support/LM Studio/models", "lmstudio"),
            ("\(home)/Library/Caches/llama.cpp", "llamacpp"),
            ("\(home)/Library/Caches/baseRT", "baser")
        ]

        var items: [CleanupItem] = []

        for root in aiRoots where FileSystem.fileExists(at: root.path) {
            items.append(contentsOf: scanKnownRoot(at: root.path, label: root.label))
        }

        items.append(contentsOf: scanDocuments(at: "\(home)/Documents"))

        return makeCategory(items: items.sorted { $0.size > $1.size })
    }

    // MARK: - Known AI cache directories

    private func scanKnownRoot(at path: String, label: String) -> [CleanupItem] {
        let entries = FileSystem.contentsOfDirectory(at: path)
        var items: [CleanupItem] = []

        for entry in entries {
            let fullPath = "\(path)/\(entry)"
            guard !isSymlink(at: fullPath) else { continue }
            if ProtectionList.isSystemProtected(fullPath) { continue }

            let size = FileSystem.directorySize(at: fullPath)
            guard size > 1024 else { continue }

            let modDate = FileSystem.modificationDate(at: fullPath) ?? Date()
            let reason = reasonForKnownRoot(label: label, path: fullPath, modifiedAt: modDate)

            items.append(CleanupItem(
                path: fullPath,
                name: entry,
                size: size,
                modifiedAt: modDate,
                appName: nil,
                categoryID: categoryID,
                safety: .review,
                confidence: 60,
                isLocked: false,
                lockReason: nil,
                reason: reason,
                isSelected: false
            ))
        }

        return items
    }

    private func reasonForKnownRoot(label: String, path: String, modifiedAt: Date) -> String {
        switch label {
        case "huggingface":
            return "Hugging Face cache. May be reused by ML scripts."
        case "ollama":
            return "Ollama model."
        case "lmstudio":
            return "LM Studio model."
        case "llamacpp", "baser":
            return "Local LLM cache."
        default:
            return reasonForAge(modifiedAt: modifiedAt)
        }
    }

    // MARK: - ~/Documents model files

    private func scanDocuments(at path: String) -> [CleanupItem] {
        guard FileSystem.fileExists(at: path) else { return [] }

        var fileInfos: [(path: String, size: UInt64, modifiedAt: Date)] = []
        enumerateModelFiles(at: path, maxDepth: 2, currentDepth: 0) { path, size, modifiedAt in
            fileInfos.append((path, size, modifiedAt))
        }

        return fileInfos.map { info in
            CleanupItem(
                path: info.path,
                name: URL(fileURLWithPath: info.path).lastPathComponent,
                size: info.size,
                modifiedAt: info.modifiedAt,
                appName: nil,
                categoryID: categoryID,
                safety: .review,
                confidence: 60,
                isLocked: false,
                lockReason: nil,
                reason: reasonForAge(modifiedAt: info.modifiedAt),
                isSelected: false
            )
        }
    }

    private func enumerateModelFiles(
        at path: String,
        maxDepth: Int,
        currentDepth: Int,
        visitor: (String, UInt64, Date) -> Void
    ) {
        guard currentDepth <= maxDepth else { return }
        guard FileSystem.fileExists(at: path) else { return }

        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey]),
              values.isSymbolicLink != true else {
            return
        }

        // Allow scanning inside ~/Documents and its immediate subdirectories
        // up to the configured max depth. Only block system paths.
        if ProtectionList.isSystemProtected(path) {
            return
        }

        if values.isDirectory != true {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? UInt64,
               let modifiedAt = attrs[.modificationDate] as? Date,
               isModelFile(path: path, size: size) {
                visitor(path, size, modifiedAt)
            }
            return
        }

        let entries = FileSystem.contentsOfDirectory(at: path)
        for entry in entries {
            enumerateModelFiles(
                at: "\(path)/\(entry)",
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1,
                visitor: visitor
            )
        }
    }

    private func isModelFile(path: String, size: UInt64) -> Bool {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        guard Self.modelExtensions.contains(ext) else { return false }
        if ext == "bin", size <= Self.binThreshold { return false }
        return true
    }

    private func reasonForAge(modifiedAt: Date) -> String {
        let daysOld = Calendar.current.dateComponents([.day], from: modifiedAt, to: Date()).day ?? 0
        if daysOld > Self.oldThresholdDays {
            return "Model file not used recently."
        }
        return "AI/ML model file. Review before removing."
    }

    private func isSymlink(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]),
              let isSymlink = values.isSymbolicLink else {
            return false
        }
        return isSymlink
    }
}
