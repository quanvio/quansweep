import Foundation

actor QuarantineManager {
    static let shared = QuarantineManager()

    let quarantineFolder: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("QuanSweep/Quarantine", isDirectory: true)
    }()

    private let manifestURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("QuanSweep/quarantine-manifest.json")
    }()

    private let retentionDays: TimeInterval = 30

    func quarantine(items: [CleanupItem]) async -> QuarantineSession {
        try? FileManager.default.createDirectory(at: quarantineFolder, withIntermediateDirectories: true)

        let sessionId = UUID()
        let batchFolder = quarantineFolder.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: batchFolder, withIntermediateDirectories: true)

        var entries: [QuarantineEntry] = []
        for item in items {
            let originalURL = URL(fileURLWithPath: item.path)
            let destination = uniqueURL(at: batchFolder.appendingPathComponent(originalURL.lastPathComponent))

            do {
                try FileManager.default.moveItem(at: originalURL, to: destination)
                entries.append(QuarantineEntry(
                    id: UUID(),
                    originalPath: item.path,
                    quarantinePath: destination.path,
                    categoryID: item.categoryID,
                    name: item.name,
                    size: item.size,
                    deletedAt: Date()
                ))
            } catch {
                // If move fails, skip this item.
                continue
            }
        }

        let session = QuarantineSession(id: sessionId, createdAt: Date(), items: entries)
        await appendSession(session)
        await AuditLogger.shared.log(action: "quarantine", path: "session:\(session.id.uuidString)", size: session.totalSize, details: "Quarantined \(entries.count) items")
        await purgeExpired()

        return session
    }

    func restore(entry: QuarantineEntry) async -> Bool {
        let originalURL = URL(fileURLWithPath: entry.originalPath)
        let quarantineURL = URL(fileURLWithPath: entry.quarantinePath)

        do {
            let parent = originalURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: quarantineURL, to: originalURL)
            await removeEntry(entry)
            await AuditLogger.shared.log(action: "restore", path: entry.originalPath, size: entry.size, details: "Restored from quarantine")
            return true
        } catch {
            return false
        }
    }

    func restore(session: QuarantineSession) async -> QuarantineSession {
        var restored: [QuarantineEntry] = []
        for entry in session.items {
            if await restore(entry: entry) {
                restored.append(entry)
            }
        }
        return QuarantineSession(id: session.id, createdAt: session.createdAt, items: restored)
    }

    func deletePermanently(entry: QuarantineEntry) async -> Bool {
        let quarantineURL = URL(fileURLWithPath: entry.quarantinePath)
        do {
            try FileManager.default.removeItem(at: quarantineURL)
            await removeEntry(entry)
            await AuditLogger.shared.log(action: "delete", path: entry.originalPath, size: entry.size, details: "Permanently deleted from quarantine")
            return true
        } catch {
            return false
        }
    }

    func emptyQuarantine() async -> UInt64 {
        let sessions = await loadManifest()
        var freed: UInt64 = 0
        for session in sessions {
            for entry in session.items {
                try? FileManager.default.removeItem(atPath: entry.quarantinePath)
                freed += entry.size
            }
        }
        try? FileManager.default.removeItem(at: quarantineFolder)
        await saveManifest([])
        await AuditLogger.shared.log(action: "empty", path: quarantineFolder.path, size: freed, details: "Emptied quarantine")
        return freed
    }

    func sessions() async -> [QuarantineSession] {
        await loadManifest()
    }

    func totalSize() async -> UInt64 {
        let sessions = await loadManifest()
        return sessions.reduce(0) { $0 + $1.totalSize }
    }

    // MARK: - Private

    private func loadManifest() async -> [QuarantineSession] {
        do {
            let data = try Data(contentsOf: manifestURL)
            return try JSONDecoder().decode([QuarantineSession].self, from: data)
        } catch {
            return []
        }
    }

    private func saveManifest(_ sessions: [QuarantineSession]) async {
        do {
            try? FileManager.default.createDirectory(at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            print("Failed to save quarantine manifest: \(error)")
        }
    }

    private func appendSession(_ session: QuarantineSession) async {
        var sessions = await loadManifest()
        sessions.append(session)
        await saveManifest(sessions)
    }

    private func removeEntry(_ entry: QuarantineEntry) async {
        var sessions = await loadManifest()
        for i in sessions.indices {
            sessions[i].items.removeAll { $0.id == entry.id }
        }
        sessions.removeAll { $0.items.isEmpty }
        await saveManifest(sessions)
    }

    private func purgeExpired() async {
        let cutoff = Date().addingTimeInterval(-retentionDays * 24 * 60 * 60)
        var sessions = await loadManifest()

        for session in sessions {
            if session.createdAt < cutoff {
                for entry in session.items {
                    try? FileManager.default.removeItem(atPath: entry.quarantinePath)
                }
            }
        }

        sessions.removeAll { $0.createdAt < cutoff }
        await saveManifest(sessions)
    }

    private func uniqueURL(at url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dir = url.deletingLastPathComponent()
        var counter = 1
        var candidate = dir.appendingPathComponent("\(base)-\(counter)\(ext.isEmpty ? "" : ".\(ext)")")
        while FileManager.default.fileExists(atPath: candidate.path) {
            counter += 1
            candidate = dir.appendingPathComponent("\(base)-\(counter)\(ext.isEmpty ? "" : ".\(ext)")")
        }
        return candidate
    }
}
