import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var appeared = false

    private var userName: String {
        let name = ProcessInfo.processInfo.environment["USER"] ?? "User"
        return name.capitalized
    }

    private var deviceName: String {
        let name = ProcessInfo.processInfo.environment["COMPUTERNAME"] ?? ProcessInfo.processInfo.hostName
        return name.replacingOccurrences(of: ".local", with: "")
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

    private var engineStatus: (text: String, color: Color) {
        if viewModel.isScanning { return ("Scanning", AppColors.accentOrange) }
        return ("Optimal", AppColors.accentGreen)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar

                HStack(spacing: 16) {
                    reclaimableCard
                        .frame(maxWidth: .infinity)

                    gaugeSection
                        .frame(maxWidth: .infinity)

                    safeToCleanCard
                        .frame(maxWidth: .infinity)

                    scanningIntelligencePanel
                        .frame(width: 260)
                }
                .frame(minHeight: 320)

                actionRow

                categoriesSection

                HStack(alignment: .top, spacing: 16) {
                    systemOverviewSection
                        .frame(maxWidth: .infinity)

                    realTimeActivityPanel
                        .frame(width: 300)
                }

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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back, \(userName) 👋")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Here's what's happening on your Mac")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    Text(deviceName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 6) {
                    Circle()
                        .fill(engineStatus.color)
                        .frame(width: 6, height: 6)
                        .shadow(color: engineStatus.color.opacity(0.6), radius: 4, x: 0, y: 0)
                    Text(engineStatus.text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(engineStatus.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(engineStatus.color.opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(engineStatus.color.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Side Cards

    private var reclaimableCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reclaimable")
                .captionLabel()

            Text(ByteCountFormatter.string(fromByteCount: Int64(reclaimable), countStyle: .file))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.accentCyan)

            Text("Can be reclaimed")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)

            Spacer()

            Text("Found in \(viewModel.summary.itemCount) items")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary)

            sparkline(data: viewModel.categories.map { Double($0.totalSize) }.sorted(), color: AppColors.accentCyan)
                .frame(height: 32)
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .glassCard()
    }

    private var safeToCleanCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Safe to Clean")
                .captionLabel()

            Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean), countStyle: .file))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.accentGreen)

            Text("High confidence")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)

            Spacer()

            Text("Safe to clean")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary)

            sparkline(data: viewModel.categories.filter { $0.safety == .safe }.map { Double($0.totalSize) }, color: AppColors.accentGreen)
                .frame(height: 32)
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .glassCard()
    }

    // MARK: - Gauge Section

    private var gaugeSection: some View {
        VStack(spacing: 16) {
            SpeedometerGauge(
                value: cleanliness,
                maxValue: 100,
                title: "System Cleanliness",
                subtitle: cleanliness > 80 ? "CLEAN" : "NEEDS ATTENTION",
                showScaleLabels: true
            )
            .frame(maxHeight: 220)

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
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Scanning Intelligence

    private var scanningIntelligencePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accentPurple)
                Text("Scanning Intelligence")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Deep AI Mode")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)

            Divider()
                .background(AppColors.divider)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.categories.prefix(8)) { category in
                    HStack(spacing: 8) {
                        Image(systemName: categoryIconState(category))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(categoryDone(category) ? AppColors.accentGreen : AppColors.textMuted)
                            .frame(width: 18)

                        Text(category.name)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                            .font(.system(size: 10, weight: .medium).monospacedDigit())
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

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Needs Review")
                        .captionLabel()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.reviewRequired), countStyle: .file))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accentOrange)
                }

                Spacer()

                sparkline(data: viewModel.categories.filter { $0.safety == .review || $0.safety == .advanced }.map { Double($0.totalSize) }, color: AppColors.accentOrange)
                    .frame(width: 80, height: 28)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glassCard()

            Button {
                Task { await viewModel.scan() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("START SMART SCAN")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppColors.accentCyan.opacity(0.22), AppColors.accentBlue.opacity(0.16)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.accentCyan.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isScanning)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Scan")
                        .captionLabel()
                    Text(viewModel.lastResult?.createdAt ?? Date(), style: .relative)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.accentCyan)
                    Text(viewModel.lastResult?.createdAt ?? Date(), style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Scan Type")
                        .captionLabel()
                    Text("Smart Scan")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.accentPurple)
                    Text("Deep analysis")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glassCard()
        }
    }

    // MARK: - Categories

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

    // MARK: - System Overview

    private var systemOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Overview")
                .sectionTitle()

            HStack(spacing: 0) {
                systemRing(
                    progress: viewModel.systemStats.cpuPercent / 100,
                    color: AppColors.accentCyan,
                    icon: "cpu",
                    title: "CPU",
                    subtitle: "\(Int(viewModel.systemStats.cpuPercent))%",
                    detail: cpuDetail
                )

                Divider()
                    .background(AppColors.divider)

                systemRing(
                    progress: memoryProgress,
                    color: AppColors.accentPurple,
                    icon: "memorychip",
                    title: "Memory",
                    subtitle: "\(Int(memoryProgress * 100))%",
                    detail: memoryDetail
                )

                Divider()
                    .background(AppColors.divider)

                systemRing(
                    progress: storageProgress,
                    color: AppColors.accentOrange,
                    icon: "internaldrive",
                    title: "Storage",
                    subtitle: "\(Int(storageProgress * 100))%",
                    detail: storageDetail
                )

                Divider()
                    .background(AppColors.divider)

                systemRing(
                    progress: temperatureProgress,
                    color: AppColors.accentRed,
                    icon: "thermometer",
                    title: "Temp",
                    subtitle: viewModel.systemStats.temperature,
                    detail: temperatureState
                )

                Divider()
                    .background(AppColors.divider)

                systemRing(
                    progress: fanProgress,
                    color: AppColors.accentGreen,
                    icon: "fanblades",
                    title: "Fan",
                    subtitle: fanSpeedValue,
                    detail: viewModel.systemStats.fanSpeed
                )

                Divider()
                    .background(AppColors.divider)

                systemRing(
                    progress: networkProgress,
                    color: AppColors.accentBlue,
                    icon: "network",
                    title: "Network",
                    subtitle: viewModel.systemStats.networkPeak,
                    detail: "Peak"
                )
            }
            .padding(.vertical, 14)
            .glassCard()
        }
    }

    private func systemRing(progress: Double, color: Color, icon: String, title: String, subtitle: String, detail: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 44, height: 44)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(color)
                    .lineLimit(1)

                Text(detail)
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var cpuDetail: String {
        let count = ProcessInfo.processInfo.processorCount
        return count > 1 ? "\(count) cores" : "Mac"
    }

    private var memoryProgress: Double {
        guard viewModel.systemStats.memoryTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.memoryUsed) / Double(viewModel.systemStats.memoryTotal), 1)
    }

    private var memoryDetail: String {
        ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.memoryUsed), countStyle: .file)
    }

    private var storageProgress: Double {
        guard viewModel.systemStats.storageTotal > 0 else { return 0 }
        return min(Double(viewModel.systemStats.storageUsed) / Double(viewModel.systemStats.storageTotal), 1)
    }

    private var storageDetail: String {
        ByteCountFormatter.string(fromByteCount: Int64(viewModel.systemStats.storageUsed), countStyle: .file)
    }

    private var temperatureProgress: Double {
        let celsius = viewModel.systemStats.temperatureValue
        guard celsius > 0 else { return 0 }
        return min(max((celsius - 30) / 70, 0), 1)
    }

    private var temperatureState: String {
        switch viewModel.systemStats.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        @unknown default: return "N/A"
        }
    }

    private var fanProgress: Double {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return 0.25
        case .fair: return 0.45
        case .serious: return 0.75
        case .critical: return 1.0
        @unknown default: return 0.25
        }
    }

    private var fanSpeedValue: String {
        let components = viewModel.systemStats.fanSpeed.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let digits = components.joined()
        return digits.isEmpty ? "—" : "\(Int(digits) ?? 0)"
    }

    private var networkProgress: Double {
        let peak = viewModel.systemStats.networkPeak
        if peak.contains("GB") {
            return 0.85
        } else if peak.contains("MB") {
            return 0.55
        } else if peak.contains("KB") {
            return 0.25
        }
        return 0.1
    }

    // MARK: - Real-Time Activity

    private var realTimeActivityPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Real-Time Activity")
                    .sectionTitle()

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.accentGreen)
                        .frame(width: 5, height: 5)
                    Text("Live")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.accentGreen)
                }
            }

            if recentActivities.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.textMuted)
                    Text("No activity yet")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentActivities.prefix(5), id: \.self) { activity in
                        HStack(spacing: 10) {
                            Image(systemName: activity.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(activity.color)
                                .frame(width: 26, height: 26)
                                .background(activity.color.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(activity.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(activity.detail)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(activity.time)
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }
            }

            Spacer()

            Button("View Full Log") { }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(minHeight: 180)
        .glassCard()
    }

    private var recentActivities: [ActivityItem] {
        viewModel.quarantineSessions.prefix(5).flatMap { session in
            session.items.prefix(1).map { entry in
                ActivityItem(
                    icon: "shield.fill",
                    title: "\(entry.name) moved",
                    detail: ByteCountFormatter.string(fromByteCount: Int64(entry.size), countStyle: .file),
                    time: session.createdAt.formatted(date: .omitted, time: .shortened),
                    color: AppColors.accentCyan
                )
            }
        }
    }

    // MARK: - Sparkline

    private func sparkline(data: [Double], color: Color) -> some View {
        GeometryReader { geo in
            if data.count >= 2 {
                let points = data.normalized()
                Path { path in
                    let stepX = geo.size.width / CGFloat(points.count - 1)
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat(point) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .overlay(
                    Path { path in
                        let stepX = geo.size.width / CGFloat(points.count - 1)
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for (index, point) in points.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height - (CGFloat(point) * geo.size.height)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    }
                    .fill(color.opacity(0.08))
                )
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.06))
            }
        }
    }
}

// MARK: - Supporting Types

private struct ActivityItem: Hashable {
    let icon: String
    let title: String
    let detail: String
    let time: String
    let color: Color
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
                            .shadow(color: safetyColor.opacity(0.5), radius: 2, x: 0, y: 0)
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

private extension Array where Element == Double {
    func normalized() -> [Double] {
        guard let min = self.min(), let max = self.max(), max > min else {
            return map { _ in 0.5 }
        }
        return map { ($0 - min) / (max - min) }
    }
}
