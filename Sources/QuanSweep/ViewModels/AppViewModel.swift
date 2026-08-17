import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var categories: [CleanupCategory] = []
    @Published var displayCategories: [CleanupCategory] = []
    @Published var summary = ScanSummary(totalScanned: 0, safeToClean: 0, reviewRequired: 0, protectedSize: 0, itemCount: 0)
    @Published var isScanning = false
    @Published var statusMessage = "Ready to scan"
    @Published var quarantineSessions: [QuarantineSession] = []
    @Published var displayQuarantineSessions: [QuarantineSession] = []
    @Published var selectedTab: Tab = .dashboard
    @Published var selectedCategoryID: String? = nil {
        didSet { updateDisplayCategories() }
    }
    @Published var lastResult: QuarantineSession?
    @Published var showPermissionAlert = false
    @Published var currentVersion = ""
    @Published var latestVersion: String?

    // Scan filtering / sorting
    @Published var scanSearchText = "" {
        didSet { updateDisplayCategories() }
    }
    @Published var scanSortOption: ScanSortOption = .size {
        didSet { updateDisplayCategories() }
    }

    // Quarantine filtering / sorting
    @Published var quarantineSearchText = "" {
        didSet { updateDisplayQuarantineSessions() }
    }
    @Published var quarantineSortOption: QuarantineSortOption = .date {
        didSet { updateDisplayQuarantineSessions() }
    }
    @Published var quarantineFolderPath = ""
    @Published var selectedQuarantineEntryIDs: Set<UUID> = []

    var selectedQuarantineEntries: [QuarantineEntry] {
        quarantineSessions.flatMap { $0.items }.filter { selectedQuarantineEntryIDs.contains($0.id) }
    }

    var selectedQuarantineSize: UInt64 {
        selectedQuarantineEntries.reduce(0) { $0 + $1.size }
    }

    // Uninstaller
    @Published var installedApps: [InstalledApp] = []
    @Published var displayInstalledApps: [InstalledApp] = []
    @Published var installedAppSearchText = "" {
        didSet { updateDisplayInstalledApps() }
    }

    enum Tab {
        case dashboard, scan, quarantine, uninstaller
    }

    enum ScanSortOption: String, CaseIterable, Identifiable {
        case size = "Size"
        case name = "Name"
        case confidence = "Confidence"
        case date = "Date Modified"

        var id: String { rawValue }
    }

    enum QuarantineSortOption: String, CaseIterable, Identifiable {
        case date = "Date"
        case size = "Size"
        case name = "Name"

        var id: String { rawValue }
    }

    private let quarantine = QuarantineManager.shared

    var totalSelectedSize: UInt64 {
        categories.reduce(0) { $0 + $1.selectedItems.reduce(0) { $0 + $1.size } }
    }

    var hasSafeItems: Bool {
        categories.contains { $0.items.contains { $0.safety == .safe && !$0.isLocked } }
    }

    var totalQuarantineSize: UInt64 {
        quarantineSessions.reduce(0) { $0 + $1.totalSize }
    }

    // MARK: - Scanning

    func scan() async {
        isScanning = true
        statusMessage = "Scanning your Mac..."
        categories = []
        selectedCategoryID = nil
        scanSearchText = ""

        let result = await ScanEngine.scanAll { [weak self] name in
            Task { @MainActor [weak self] in
                self?.statusMessage = "Scanning \(name)..."
            }
        }

        categories = result
        updateDisplayCategories()
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

    // MARK: - Cleanup

    func cleanSelected() async {
        let items = categories.flatMap { $0.selectedItems }
        guard !items.isEmpty else { return }
        await quarantine(items: items)
    }

    func cleanAllSafe() async {
        let safeItems = categories.flatMap { $0.items.filter { $0.safety == .safe && !$0.isLocked } }
        guard !safeItems.isEmpty else { return }
        await quarantine(items: safeItems)
    }

    func quarantine(item: CleanupItem) async {
        await quarantine(items: [item])
    }

    @discardableResult
    func deletePermanently(item: CleanupItem) async -> Bool {
        // Only allowed for items already in quarantine. Regular scan items must be quarantined first.
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

    // MARK: - Quarantine

    func restore(entry: QuarantineEntry) async {
        statusMessage = "Restoring \(entry.name)..."
        _ = await quarantine.restore(entry: entry)
        await loadQuarantine()
        await rescanCategories()
        statusMessage = "Restored \(entry.name)."
    }

    func restore(session: QuarantineSession) async {
        statusMessage = "Restoring session..."
        _ = await quarantine.restore(session: session)
        await loadQuarantine()
        await rescanCategories()
        statusMessage = "Restore complete."
    }

    func deletePermanently(entry: QuarantineEntry) async {
        statusMessage = "Deleting \(entry.name)..."
        _ = await quarantine.deletePermanently(entry: entry)
        await loadQuarantine()
        statusMessage = "Deleted \(entry.name) permanently."
    }

    func emptyQuarantine() async {
        statusMessage = "Emptying quarantine..."
        let freed = await quarantine.emptyQuarantine()
        selectedQuarantineEntryIDs.removeAll()
        await loadQuarantine()
        statusMessage = "Freed \(ByteCountFormatter.string(fromByteCount: Int64(freed), countStyle: .file)) from quarantine."
    }

    func deleteSelectedQuarantineEntries() async {
        let entries = selectedQuarantineEntries
        guard !entries.isEmpty else { return }
        statusMessage = "Deleting \(entries.count) items..."
        var freed: UInt64 = 0
        for entry in entries {
            if await quarantine.deletePermanently(entry: entry) {
                freed += entry.size
            }
        }
        selectedQuarantineEntryIDs.removeAll()
        await loadQuarantine()
        statusMessage = "Deleted \(ByteCountFormatter.string(fromByteCount: Int64(freed), countStyle: .file)) permanently."
    }

    func toggleQuarantineEntrySelection(_ id: UUID) {
        if selectedQuarantineEntryIDs.contains(id) {
            selectedQuarantineEntryIDs.remove(id)
        } else {
            selectedQuarantineEntryIDs.insert(id)
        }
    }

    func selectAllVisibleQuarantineEntries() {
        let ids = displayQuarantineSessions.flatMap { $0.items.map { $0.id } }
        selectedQuarantineEntryIDs.formUnion(ids)
    }

    func deselectAllQuarantineEntries() {
        selectedQuarantineEntryIDs.removeAll()
    }

    func loadQuarantine() async {
        quarantineSessions = await quarantine.sessions()
        updateDisplayQuarantineSessions()
        quarantineFolderPath = quarantine.quarantineFolder.path
    }

    func loadVersionInfo() async {
        currentVersion = await VersionChecker.shared.currentVersion()
        latestVersion = await VersionChecker.shared.latestVersion()
    }

    // MARK: - Uninstaller

    func loadInstalledApps() async {
        installedApps = InstalledApps.all()
        updateDisplayInstalledApps()
    }

    func uninstallApp(_ app: InstalledApp) async {
        guard FileSystem.fileExists(at: app.path) else {
            statusMessage = "App not found at \(app.path)"
            return
        }

        statusMessage = "Uninstalling \(app.name)..."

        var items: [CleanupItem] = []

        // The app bundle itself.
        items.append(CleanupItem(
            path: app.path,
            name: app.name,
            size: app.size,
            modifiedAt: app.lastUsedAt,
            appName: app.bundleID.isEmpty ? nil : app.bundleID,
            categoryID: "uninstaller",
            safety: .review,
            confidence: 100,
            isLocked: false,
            lockReason: nil,
            reason: "Application bundle selected for uninstall.",
            isSelected: false
        ))

        // Related residues under ~/Library.
        let residuePaths = InstalledApps.relatedResiduePaths(for: app)
        for path in residuePaths where FileSystem.fileExists(at: path) {
            let size = FileSystem.directorySize(at: path)
            let modDate = FileSystem.modificationDate(at: path) ?? Date()
            let name = URL(fileURLWithPath: path).lastPathComponent
            items.append(CleanupItem(
                path: path,
                name: name,
                size: size,
                modifiedAt: modDate,
                appName: app.name,
                categoryID: "uninstaller",
                safety: .review,
                confidence: 95,
                isLocked: false,
                lockReason: nil,
                reason: "Related file for \(app.name).",
                isSelected: false
            ))
        }

        let session = await quarantine.quarantine(items: items)
        await AuditLogger.shared.log(
            action: "uninstall",
            path: app.path,
            size: session.totalSize,
            details: "Uninstalled \(app.name) and moved \(items.count) items to quarantine session \(session.id.uuidString)"
        )
        lastResult = session
        statusMessage = "Moved \(app.name) and related files to quarantine."
        await loadQuarantine()
        await loadInstalledApps()
    }

    // MARK: - Utilities

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
        updateDisplayCategories()
        summary = ScanEngine.summary(from: categories)
    }

    private func updateDisplayCategories() {
        let base = selectedCategoryID.flatMap { id in
            categories.filter { $0.id == id }
        } ?? categories

        let search = scanSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        displayCategories = base.map { category in
            var copy = category
            if !search.isEmpty {
                copy.items = copy.items.filter {
                    $0.name.lowercased().contains(search) || $0.path.lowercased().contains(search)
                }
            }
            copy.items = sortedItems(copy.items, by: scanSortOption)
            return copy
        }
        .filter { !$0.items.isEmpty }
    }

    private func updateDisplayQuarantineSessions() {
        let search = quarantineSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sortedSessions = quarantineSessions.sorted { $0.createdAt > $1.createdAt }

        displayQuarantineSessions = sortedSessions.map { session in
            var copy = session
            if !search.isEmpty {
                copy.items = copy.items.filter {
                    $0.name.lowercased().contains(search) || $0.originalPath.lowercased().contains(search)
                }
            }
            copy.items = sortedQuarantineEntries(copy.items, by: quarantineSortOption)
            return copy
        }
        .filter { !$0.items.isEmpty }
    }

    private func updateDisplayInstalledApps() {
        let search = installedAppSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        if search.isEmpty {
            displayInstalledApps = installedApps
        } else {
            displayInstalledApps = installedApps.filter {
                $0.name.lowercased().contains(search) || $0.bundleID.lowercased().contains(search)
            }
        }
    }

    private func sortedItems(_ items: [CleanupItem], by option: ScanSortOption) -> [CleanupItem] {
        switch option {
        case .size:       return items.sorted(by: CleanupItem.bySizeDescending)
        case .name:       return items.sorted(by: CleanupItem.byNameAscending)
        case .confidence: return items.sorted(by: CleanupItem.byConfidenceDescending)
        case .date:       return items.sorted(by: CleanupItem.byDateDescending)
        }
    }

    private func sortedQuarantineEntries(_ entries: [QuarantineEntry], by option: QuarantineSortOption) -> [QuarantineEntry] {
        switch option {
        case .date:
            return entries.sorted { $0.deletedAt > $1.deletedAt }
        case .size:
            return entries.sorted { $0.size > $1.size }
        case .name:
            return entries.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
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
