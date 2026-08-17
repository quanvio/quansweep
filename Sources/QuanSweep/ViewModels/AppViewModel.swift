import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var categories: [CleanupCategory] = []
    @Published var summary = ScanSummary(totalScanned: 0, safeToClean: 0, reviewRequired: 0, protectedSize: 0, itemCount: 0)
    @Published var isScanning = false
    @Published var statusMessage = "Ready to scan"
    @Published var quarantineSessions: [QuarantineSession] = []
    @Published var selectedTab: Tab = .dashboard
    @Published var lastResult: QuarantineSession?
    @Published var showPermissionAlert = false

    enum Tab {
        case dashboard, scan, quarantine
    }

    private let quarantine = QuarantineManager.shared

    var totalSelectedSize: UInt64 {
        categories.reduce(0) { $0 + $1.selectedItems.reduce(0) { $0 + $1.size } }
    }

    var hasSafeItems: Bool {
        categories.contains { $0.items.contains { $0.safety == .safe && !$0.isLocked } }
    }

    func scan() async {
        isScanning = true
        statusMessage = "Scanning your Mac..."
        categories = []

        let result = await ScanEngine.scanAll { [weak self] name in
            Task { @MainActor [weak self] in
                self?.statusMessage = "Scanning \(name)..."
            }
        }

        categories = result
        summary = ScanEngine.summary(from: result)
        isScanning = false
        statusMessage = "Scan complete. \(summary.itemCount) items found."
        selectedTab = .scan

        await loadQuarantine()
    }

    func toggleCategorySelection(id: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].isSelected.toggle()
    }

    func cleanSelected() async {
        let items = categories.flatMap { $0.selectedItems }
        guard !items.isEmpty else { return }
        await quarantine(items: items)
    }

    func restore(session: QuarantineSession) async {
        statusMessage = "Restoring session..."
        _ = await quarantine.restore(session: session)
        await loadQuarantine()
        await rescanCategories()
        statusMessage = "Restore complete."
    }

    func loadQuarantine() async {
        quarantineSessions = await quarantine.sessions()
    }

    func cleanAllSafe() async {
        let safeItems = categories.flatMap { $0.items.filter { $0.safety == .safe && !$0.isLocked } }
        guard !safeItems.isEmpty else { return }
        await quarantine(items: safeItems)
    }

    func quarantine(item: CleanupItem) async {
        await quarantine(items: [item])
    }

    func deletePermanently(item: CleanupItem) async -> Bool {
        let url = URL(fileURLWithPath: item.path)
        do {
            try FileManager.default.removeItem(at: url)
            await AuditLogger.shared.log(action: "delete", path: item.path, size: item.size, details: "Permanently deleted from \(item.categoryID)")
            await rescanCategories()
            return true
        } catch {
            statusMessage = "Could not delete: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func revealInFinder(item: CleanupItem) -> Bool {
        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
        return true
    }

    func ignore(item: CleanupItem) {
        for catIndex in categories.indices {
            if let idx = categories[catIndex].items.firstIndex(where: { $0.id == item.id }) {
                categories[catIndex].items[idx].isSelected = false
            }
        }
        statusMessage = "Ignored \(item.name)"
    }

    // MARK: - Private

    private func quarantine(items: [CleanupItem]) async {
        statusMessage = "Moving \(items.count) items to quarantine..."
        let session = await quarantine.quarantine(items: items)
        lastResult = session
        statusMessage = "Moved \(ByteCountFormatter.string(fromByteCount: Int64(session.totalSize), countStyle: .file)) to quarantine."
        await rescanCategories()
        await loadQuarantine()
    }

    private func rescanCategories() async {
        var updated = categories
        for index in updated.indices {
            updated[index] = await updated[index].rescan()
        }
        categories = updated
        summary = ScanEngine.summary(from: categories)
    }
}

private extension CleanupCategory {
    func rescan() async -> CleanupCategory {
        // Rescanning the whole category can be slow; instead just remove items that no longer exist.
        let existing = items.filter { FileManager.default.fileExists(atPath: $0.path) }
        var copy = self
        copy.items = existing
        return copy
    }
}
