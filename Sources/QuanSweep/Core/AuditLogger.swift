import Foundation

actor AuditLogger {
    static let shared = AuditLogger()

    private let logURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("QuanSweep/audit-log.json")
    }()

    func log(action: String, path: String, size: UInt64, details: String) async {
        var entries = await load()
        entries.append(CleanupLogEntry(
            id: UUID(),
            timestamp: Date(),
            action: action,
            path: path,
            size: size,
            details: details
        ))
        await save(entries)
    }

    func logs() async -> [CleanupLogEntry] {
        await load()
    }

    private func load() async -> [CleanupLogEntry] {
        do {
            let data = try Data(contentsOf: logURL)
            return try JSONDecoder().decode([CleanupLogEntry].self, from: data)
        } catch {
            return []
        }
    }

    private func save(_ entries: [CleanupLogEntry]) async {
        do {
            try? FileManager.default.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(entries)
            try data.write(to: logURL, options: .atomic)
        } catch {
            print("Failed to save audit log: \(error)")
        }
    }
}
