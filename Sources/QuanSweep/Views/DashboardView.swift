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
            VStack(spacing: 20) {
                topBar

                HStack(spacing: 16) {
                    StatCard(
                        title: "Reclaimable",
                        value: ByteCountFormatter.string(fromByteCount: Int64(reclaimable), countStyle: .file),
                        subtitle: "Can be reclaimed",
                        color: AppColors.accentBlue,
                        history: viewModel.categories.map { Double($0.totalSize) }.sorted()
                    )
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)

                    StatCard(
                        title: "Safe to Clean",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean), countStyle: .file),
                        subtitle: "High confidence",
                        color: AppColors.accentGreen,
                        history: viewModel.categories.filter { $0.safety == .safe }.map { Double($0.totalSize) }
                    )
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

                    StatCard(
                        title: "Needs Review",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Review recommended",
                        color: AppColors.accentOrange,
                        history: viewModel.categories.filter { $0.safety == .review || $0.safety == .advanced }.map { Double($0.totalSize) }
                    )
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
                }

                HStack(spacing: 20) {
                    gaugeSection
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        realTimeActivity
                    }
                    .frame(width: 260)
                }

                categoriesSection

                systemOverviewSection

                Spacer(minLength: 40)
            }
            .padding(24)
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Here's what's happening on your Mac")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "desktopcomputer")
                        .foregroundStyle(AppColors.textSecondary)
                    Text(deviceName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen)
                        .frame(width: 6, height: 6)
                        .glowText(color: viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen)
                    Text(viewModel.isScanning ? "Scanning" : "Optimal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen).opacity(0.12)
                )
                .clipShape(Capsule())
                .overlay(Capsule().stroke((viewModel.isScanning ? AppColors.accentOrange : AppColors.accentGreen).opacity(0.35), lineWidth: 1))
            }
        }
    }

    private var gaugeSection: some View {
        VStack(spacing: 16) {
            GaugeView(
                value: cleanliness,
                maxValue: 100,
                title: "System Cleanliness",
                subtitle: cleanliness > 80 ? "CLEAN" : "NEEDS ATTENTION"
            )
            .frame(maxHeight: 320)

            Button {
                Task { await viewModel.scan() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(viewModel.isScanning ? "Scanning..." : "Start Smart Scan")
                }
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentCyan))
            .disabled(viewModel.isScanning)

            Text("AI will find what's safe to clean")
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(24)
        .neonCard(color: AppColors.accentCyan.opacity(0.5))
    }

    private var realTimeActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.accentGreen)
                    .frame(width: 6, height: 6)
                Text("Live")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.accentGreen)
                    .textCase(.uppercase)
            }

            VStack(alignment: .leading, spacing: 10) {
                activityRow(icon: "checkmark.shield", text: "System Junk Cleaned", value: "2.45 GB")
                activityRow(icon: "checkmark.shield", text: "User Caches", value: "4.31 GB")
                activityRow(icon: "checkmark.shield", text: "Downloads", value: "3.30 GB")
                activityRow(icon: "checkmark.shield", text: "Xcode Junk", value: "1.21 GB")
                activityRow(icon: "clock", text: "Logs & Reports", value: "Scanning...")
                activityRow(icon: "clock", text: "Language Files", value: "Pending")
            }

            Spacer()

            Button("View Full Log") { }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .neonCard(color: AppColors.accentPurple.opacity(0.5))
    }

    private func activityRow(icon: String, text: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.accentCyan)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.categories) { category in
                    CategoryMiniCard(category: category) {
                        viewModel.selectedCategoryID = category.id
                        viewModel.selectedTab = .scan
                    }
                }
            }
        }
    }

    private var systemOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Overview")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
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
                    subtitle: "\(ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.memoryUsed), countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.memoryTotal), countStyle: .file))"
                )

                RingView(
                    progress: storageProgress,
                    color: AppColors.accentOrange,
                    icon: "internaldrive",
                    title: "Storage",
                    subtitle: "\(ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.storageUsed), countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.storageTotal), countStyle: .file))"
                )

                RingView(
                    progress: temperatureProgress,
                    color: AppColors.accentRed,
                    icon: "thermometer",
                    title: "Temperature",
                    subtitle: viewModel.systemStats.temperature
                )

                RingView(
                    progress: 0.25,
                    color: AppColors.accentGreen,
                    icon: "fanblades",
                    title: "Fan Speed",
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
            .padding(18)
            .neonCard(color: AppColors.accentBlue.opacity(0.4))
        }
    }

    private var memoryProgress: Double {
        guard viewModel.systemStats.memoryTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.memoryUsed) / Double(viewModel.systemStats.memoryTotal), 1)
    }

    private var storageProgress: Double {
        guard viewModel.systemStats.storageTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.storageUsed) / Double(viewModel.systemStats.storageTotal), 1)
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
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(safetyColor)
                        .frame(width: 42, height: 42)
                        .background(safetyColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(safetyColor)
                            .frame(width: geo.size.width * min(progress, 1), height: 4)
                            .shadow(color: safetyColor.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 4)
            }
            .padding(14)
            .neonCard(color: safetyColor.opacity(0.4))
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
