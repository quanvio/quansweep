import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var appeared = false

    private var userName: String {
        ProcessInfo.processInfo.environment["USER"] ?? "User"
    }

    private var deviceName: String {
        ProcessInfo.processInfo.environment["COMPUTERNAME"] ?? ProcessInfo.processInfo.hostName
    }

    private var cleanliness: Double {
        let total = Double(viewModel.summary.totalScanned)
        let safe = Double(viewModel.summary.safeToClean)
        guard total > 0 else { return 84 }
        return min(max((safe / total) * 100, 0), 100)
    }

    private var reclaimable: UInt64 {
        viewModel.summary.safeToClean + viewModel.summary.reviewRequired
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topBar

                HStack(spacing: 12) {
                    StatCard(
                        title: "Reclaimable",
                        value: ByteCountFormatter.string(fromByteCount: Int64(reclaimable), countStyle: .file),
                        subtitle: "Can be reclaimed",
                        color: AppColors.accentBlue,
                        history: viewModel.categories.map { Double($0.totalSize) }.sorted()
                    )

                    StatCard(
                        title: "Safe to Clean",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean), countStyle: .file),
                        subtitle: "High confidence",
                        color: AppColors.accentGreen,
                        history: viewModel.categories.filter { $0.safety == .safe }.map { Double($0.totalSize) }
                    )

                    StatCard(
                        title: "Needs Review",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Review recommended",
                        color: AppColors.accentOrange,
                        history: viewModel.categories.filter { $0.safety == .review || $0.safety == .advanced }.map { Double($0.totalSize) }
                    )
                }

                HStack(spacing: 16) {
                    gaugeSection
                        .frame(maxWidth: .infinity)

                    scanningIntelligencePanel
                        .frame(width: 240)
                }

                categoriesSection

                systemOverviewSection

                Spacer(minLength: 30)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("")
        .onAppear {
            appeared = true
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back, \(userName) 👋")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("Here's what's happening on your Mac")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    Text(deviceName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen)
                        .frame(width: 5, height: 5)
                    Text(viewModel.isScanning ? "Scanning" : "Optimal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen).opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().stroke((viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen).opacity(0.25), lineWidth: 1))
            }
        }
    }

    private var gaugeSection: some View {
        VStack(spacing: 14) {
            GaugeView(
                value: cleanliness,
                maxValue: 100,
                title: "System Cleanliness",
                subtitle: cleanliness > 80 ? "CLEAN" : "NEEDS ATTENTION"
            )
            .frame(maxHeight: 260)

            Button {
                Task { await viewModel.scan() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(viewModel.isScanning ? "Scanning..." : "Start Smart Scan")
                }
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentCyan))
            .disabled(viewModel.isScanning)

            Text("AI will find what's safe to clean")
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(20)
        .glassCard()
    }

    private var scanningIntelligencePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accentPurple)
                Text("Scanning Intelligence")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Deep AI Mode")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)

            Divider()
                .background(AppColors.divider)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.categories.prefix(6)) { category in
                    HStack(spacing: 6) {
                        Image(systemName: categoryIconState(category))
                            .font(.system(size: 10))
                            .foregroundStyle(categoryDone(category) ? AppColors.accentGreen : AppColors.textMuted)

                        Text(category.name)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }

            Spacer()

            Button("View Full Log") { }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxHeight: .infinity)
        .glassCard()
    }

    private func categoryIconState(_ category: CleanupCategory) -> String {
        categoryDone(category) ? "checkmark.circle.fill" : "clock"
    }

    private func categoryDone(_ category: CleanupCategory) -> Bool {
        category.totalSize > 0 || !viewModel.isScanning
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .sectionTitle()

            if viewModel.categories.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textMuted)
                        Text("No scan data yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                        Text("Start a Smart Scan to discover cleanup categories")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(24)
                    Spacer()
                }
                .glassCard()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        CategoryMiniCard(category: category) {
                            viewModel.selectedCategoryID = category.id
                            viewModel.selectedTab = .scan
                        }
                    }
                }
            }
        }
    }

    private var systemOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Overview")
                .sectionTitle()

            HStack(spacing: 12) {
                RingView(
                    progress: viewModel.systemStats.cpuPercent / 100,
                    color: AppColors.accentCyan,
                    icon: "cpu",
                    title: "CPU",
                    subtitle: "\(Int(viewModel.systemStats.cpuPercent))%"
                )

                RingView(
                    progress: memoryProgress,
                    color: AppColors.accentPurple,
                    icon: "memorychip",
                    title: "Memory",
                    subtitle: memorySubtitle
                )

                RingView(
                    progress: storageProgress,
                    color: AppColors.accentOrange,
                    icon: "internaldrive",
                    title: "Storage",
                    subtitle: storageSubtitle
                )

                RingView(
                    progress: temperatureProgress,
                    color: AppColors.accentRed,
                    icon: "thermometer",
                    title: "Temp",
                    subtitle: viewModel.systemStats.temperature
                )

                RingView(
                    progress: 0.25,
                    color: AppColors.accentGreen,
                    icon: "fanblades",
                    title: "Fan",
                    subtitle: viewModel.systemStats.fanSpeed
                )

                RingView(
                    progress: 0.78,
                    color: AppColors.accentBlue,
                    icon: "network",
                    title: "Network",
                    subtitle: viewModel.systemStats.networkPeak
                )
            }
            .padding(14)
            .glassCard()
        }
    }

    private var memoryProgress: Double {
        guard viewModel.systemStats.memoryTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.memoryUsed) / Double(viewModel.systemStats.memoryTotal), 1)
    }

    private var memorySubtitle: String {
        let used = ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.memoryUsed), countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.memoryTotal), countStyle: .file)
        return "\(used)\n/ \(total)"
    }

    private var storageProgress: Double {
        guard viewModel.systemStats.storageTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.storageUsed) / Double(viewModel.systemStats.storageTotal), 1)
    }

    private var storageSubtitle: String {
        let used = ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.storageUsed), countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.storageTotal), countStyle: .file)
        return "\(used)\n/ \(total)"
    }

    private var temperatureProgress: Double {
        let celsius = viewModel.systemStats.temperatureValue
        guard celsius > 0 else { return 0 }
        return min(max((celsius - 30) / 70, 0), 1)
    }
}

struct CategoryMiniCard: View {
    let category: CleanupCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(safetyColor)
                        .frame(width: 36, height: 36)
                        .background(safetyColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textMuted)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(safetyColor)
                            .frame(width: geo.size.width * min(progress, 1), height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(12)
            .glassCard(border: false)
            .background(AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(safetyColor.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var progress: CGFloat {
        let max = category.items.map { $0.size }.max() ?? 1
        guard max > 0 else { return 0 }
        let avg = CGFloat(category.totalSize) / CGFloat(max)
        return min(avg, 1)
    }

    private var safetyColor: Color {
        switch category.safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }
}
