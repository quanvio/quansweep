import Foundation

enum ScanEngine {
    static let allScanners: [Scanner] = [
        AppResidueScanner(),
        CacheScanner(),
        TempScanner(),
        LogScanner(),
        TrashScanner(),
        XcodeScanner(),
        DeveloperScanner(),
        DownloadsScanner(),
        LargeFileScanner(),
        AIModelScanner()
    ]

    static func scanAll(progress: ((Int, Int, String) -> Void)? = nil) async -> [CleanupCategory] {
        var categories: [CleanupCategory] = []
        let total = allScanners.count

        await withTaskGroup(of: CleanupCategory.self) { group in
            for (index, scanner) in allScanners.enumerated() {
                group.addTask {
                    progress?(index, total, scanner.name)
                    do {
                        return try await scanner.scanWithSafety()
                    } catch {
                        return CleanupCategory(
                            id: scanner.categoryID,
                            name: scanner.name,
                            icon: scanner.icon,
                            safety: scanner.safety,
                            description: scanner.description,
                            items: [],
                            isSelected: false,
                            isScanning: false,
                            errorMessage: "Scan failed: \(error.localizedDescription)"
                        )
                    }
                }
            }
            for await category in group {
                categories.append(category)
            }
        }

        let order = allScanners.map { $0.categoryID }
        return categories.sorted {
            guard let first = order.firstIndex(of: $0.id),
                  let second = order.firstIndex(of: $1.id) else { return false }
            return first < second
        }
    }

    static func summary(from categories: [CleanupCategory]) -> ScanSummary {
        let total = categories.reduce(0) { $0 + $1.totalSize }
        let safe = categories.reduce(0) { $0 + $1.items.filter { $0.safety == .safe }.reduce(0) { $0 + $1.size } }
        let review = categories.reduce(0) { $0 + $1.items.filter { $0.safety == .review || $0.safety == .advanced }.reduce(0) { $0 + $1.size } }
        let protected = categories.reduce(0) { $0 + $1.items.filter { $0.safety == .protected }.reduce(0) { $0 + $1.size } }
        let count = categories.reduce(0) { $0 + $1.items.count }
        return ScanSummary(totalScanned: total, safeToClean: safe, reviewRequired: review, protectedSize: protected, itemCount: count)
    }
}
