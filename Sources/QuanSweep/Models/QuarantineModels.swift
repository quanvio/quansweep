import Foundation

struct QuarantineSession: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var items: [QuarantineEntry]

    var totalSize: UInt64 {
        items.reduce(0) { $0 + $1.size }
    }
}

struct QuarantineEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let originalPath: String
    let quarantinePath: String
    let categoryID: String
    let name: String
    let size: UInt64
    let deletedAt: Date

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct CleanupLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let action: String
    let path: String
    let size: UInt64
    let details: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}
