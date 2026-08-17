import Foundation

enum SafetyLevel: String, Codable, CaseIterable {
    case safe = "Safe"
    case review = "Review"
    case advanced = "Advanced"
    case protected = "Protected"

    var color: String {
        switch self {
        case .safe:     return "22C55E"
        case .review:   return "F59E0B"
        case .advanced: return "EF4444"
        case .protected:return "3B82F6"
        }
    }

    var description: String {
        switch self {
        case .safe:
            return "Recreatable files. Safe to remove in most cases."
        case .review:
            return "Review before removing. May affect app behavior."
        case .advanced:
            return "User data or offline content. Only remove if you understand the impact."
        case .protected:
            return "Protected by QuanSweep. Will not be removed."
        }
    }
}

struct CleanupItem: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let modifiedAt: Date
    let appName: String?
    let categoryID: String
    let safety: SafetyLevel
    let confidence: Int
    let isLocked: Bool
    let lockReason: String?
    let reason: String
    var isSelected: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modifiedAt, relativeTo: Date())
    }

    static func bySizeDescending(_ lhs: CleanupItem, _ rhs: CleanupItem) -> Bool {
        lhs.size > rhs.size
    }

    static func byNameAscending(_ lhs: CleanupItem, _ rhs: CleanupItem) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    static func byConfidenceDescending(_ lhs: CleanupItem, _ rhs: CleanupItem) -> Bool {
        lhs.confidence > rhs.confidence
    }

    static func byDateDescending(_ lhs: CleanupItem, _ rhs: CleanupItem) -> Bool {
        lhs.modifiedAt > rhs.modifiedAt
    }
}

struct CleanupCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let safety: SafetyLevel
    let description: String
    var items: [CleanupItem]
    var isSelected: Bool
    var isScanning: Bool
    var errorMessage: String?

    var totalSize: UInt64 {
        items.filter { !$0.isLocked }.reduce(0) { $0 + $1.size }
    }

    var reclaimableSize: UInt64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    var selectedItems: [CleanupItem] {
        items.filter { !$0.isLocked && $0.isSelected }
    }
}

struct ScanSummary: Equatable {
    let totalScanned: UInt64
    let safeToClean: UInt64
    let reviewRequired: UInt64
    let protectedSize: UInt64
    let itemCount: Int
}
