import SwiftUI

struct ScanView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedItem: CleanupItem?
    @State private var showReviewSheet = false
    @State private var showNewScanConfirmation = false

    private var reviewSize: UInt64 {
        viewModel.categories.reduce(0) { $0 + $1.items.filter { $0.safety == .review }.reduce(0) { $0 + $1.size } }
    }

    private var advancedSize: UInt64 {
        viewModel.categories.reduce(0) { $0 + $1.items.filter { $0.safety == .advanced }.reduce(0) { $0 + $1.size } }
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                leftPanel
                    .frame(width: leftPanelWidth(for: geo.size.width))

                Divider()
                    .background(AppColors.divider)

                rightPanel(in: geo)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .background(AppColors.background)
        .navigationTitle("")
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
        .sheet(isPresented: $showReviewSheet) {
            ReviewSelectedSheet()
                .frame(minWidth: 600, minHeight: 500)
        }
        .alert("Start a new scan?", isPresented: $showNewScanConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Scan") {
                Task { await viewModel.scan() }
            }
        } message: {
            Text("This will replace the current scan results. Any selections will be lost.")
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Scan Results")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Smart Scan Completed")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SpeedometerGauge(
                    value: Double(viewModel.summary.totalScanned),
                    maxValue: max(Double(viewModel.summary.totalScanned) * 1.15, 1),
                    title: "Total Found",
                    subtitle: "\(viewModel.summary.itemCount) Items Scanned"
                )
                .frame(height: 210)

                HStack(spacing: 8) {
                    summaryPill(label: "Safe", value: viewModel.summary.safeToClean, color: AppColors.accentGreen)
                    summaryPill(label: "Review", value: reviewSize, color: AppColors.accentOrange)
                }

                HStack(spacing: 8) {
                    summaryPill(label: "Advanced", value: advancedSize, color: AppColors.accentRed)
                    summaryPill(label: "Protected", value: viewModel.summary.protectedSize, color: AppColors.accentBlue)
                }

                HStack(spacing: 8) {
                    StatCard(
                        title: "Reclaimable",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean + viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Can be reclaimed",
                        color: AppColors.accentBlue,
                        history: randomSparkline()
                    )

                    StatCard(
                        title: "Safe to Clean",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean), countStyle: .file),
                        subtitle: "High confidence",
                        color: AppColors.accentGreen,
                        history: randomSparkline()
                    )
                }

                HStack(spacing: 8) {
                    StatCard(
                        title: "Needs Review",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Review recommended",
                        color: AppColors.accentOrange,
                        history: randomSparkline()
                    )

                    StatCard(
                        title: "Items Scanned",
                        value: "\(viewModel.summary.itemCount)",
                        subtitle: "Files & entries",
                        color: AppColors.accentPurple,
                        history: randomSparkline()
                    )
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Last Scan")
                            .captionLabel()
                        Text(viewModel.lastResult?.createdAt ?? Date(), style: .relative)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.accentCyan)
                        Text(viewModel.lastResult?.createdAt ?? Date(), style: .time)
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Scan Type")
                            .captionLabel()
                        Text("Smart Scan")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.accentPurple)
                        Text("Deep analysis enabled")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .background(AppColors.background)
    }

    private func summaryPill(label: String, value: UInt64, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .captionLabel()
                Text(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(color.opacity(0.18), lineWidth: 1))
    }

    private func randomSparkline() -> [Double] {
        (0..<12).map { _ in Double.random(in: 0.2...0.9) }
    }

    // MARK: - Right Panel

    private func rightPanel(in geo: GeometryProxy) -> some View {
        let rightWidth = geo.size.width - leftPanelWidth(for: geo.size.width)
        let tableWidth = max(rightWidth - 56, 240)

        return VStack(spacing: 0) {
            rightHeader
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)

            if viewModel.displayCategories.isEmpty && !viewModel.isScanning {
                emptyState
            } else {
                tableHeader(totalWidth: tableWidth)
                    .padding(.horizontal, 16)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach($viewModel.displayCategories) { $category in
                            ScanCategorySection(
                                category: $category,
                                totalWidth: tableWidth,
                                onSelectItem: { item in
                                    selectedItem = item
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .frame(maxHeight: .infinity)

                bottomBar
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    private func leftPanelWidth(for total: CGFloat) -> CGFloat {
        min(max(280, total * 0.28), 340)
    }

    private var rightHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Scan Results")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    TextField("Search items...", text: $viewModel.scanSearchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(minWidth: 100, idealWidth: 160, maxWidth: 180)
                .background(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                sortMenu

                Button {
                    showNewScanConfirmation = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.accentCyan)
                        .frame(width: 30, height: 30)
                        .background(AppColors.accentCyan.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.accentCyan.opacity(0.30), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("New Scan")
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AppViewModel.ScanSortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    viewModel.scanSortOption = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.scanSortOption.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppColors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(AppColors.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Table

    private func tableHeader(totalWidth: CGFloat) -> some View {
        let widths = Self.columnWidths(for: totalWidth)

        return HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: {
                    let allSelectable = viewModel.displayCategories.flatMap { $0.items.filter { !$0.isLocked } }
                    return !allSelectable.isEmpty && allSelectable.allSatisfy { viewModel.selectedScanItemIDs.contains($0.id) }
                },
                set: { isOn in
                    if isOn {
                        viewModel.selectAllVisibleScanItems()
                    } else {
                        viewModel.deselectAllScanItems()
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .frame(width: widths.checkbox)

            Text("Item Name")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.name, alignment: .leading)
                .lineLimit(1)

            Spacer()

            Text("Confidence")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.confidence, alignment: .leading)
                .lineLimit(1)

            Text("Size")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.size, alignment: .trailing)
                .lineLimit(1)

            Text("Items")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.items, alignment: .trailing)
                .lineLimit(1)

            Color.clear
                .frame(width: widths.actions)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }

    struct ColumnWidths {
        let checkbox: CGFloat
        let name: CGFloat
        let confidence: CGFloat
        let size: CGFloat
        let items: CGFloat
        let actions: CGFloat
    }

    static func columnWidths(for totalWidth: CGFloat) -> ColumnWidths {
        let checkbox: CGFloat = 24
        let confidence: CGFloat = 86
        let size: CGFloat = 62
        let items: CGFloat = 44
        let actions: CGFloat = 36
        let spacing: CGFloat = 56
        let name = max(totalWidth - checkbox - confidence - size - items - actions - spacing, 120)
        return ColumnWidths(checkbox: checkbox, name: name, confidence: confidence, size: size, items: items, actions: actions)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 360

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)

                    ZStack {
                        Circle()
                            .fill(AppColors.accentCyan.opacity(0.08))
                            .frame(width: isCompact ? 110 : 140, height: isCompact ? 110 : 140)
                            .blur(radius: 20)

                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: isCompact ? 48 : 64, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accentCyan, AppColors.accentBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AppColors.accentCyan.opacity(0.5), radius: 18, x: 0, y: 0)
                    }
                    .padding(.bottom, 24)

                    Text("No scan yet")
                        .font(.system(size: isCompact ? 18 : 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)

                    Text("Start a scan to see what QuanSweep can safely clean. Nothing is deleted permanently — items are moved to Quarantine first.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: min(460, geo.size.width - 40))
                        .padding(.bottom, 28)

                    Button {
                        Task { await viewModel.scan() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Start Smart Scan")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [AppColors.accentCyan.opacity(0.18), AppColors.accentBlue.opacity(0.12)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(AppColors.accentCyan)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppColors.accentCyan.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 14) {
            Button {
                showReviewSheet = true
            } label: {
                Label("Review Selected", systemImage: "eye")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))
            .disabled(viewModel.selectedScanItemIDs.isEmpty)

            Button {
                Task { await viewModel.cleanSelected() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "shield")
                    Text("Move to Quarantine")
                }
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentCyan))
            .disabled(viewModel.totalSelectedSize == 0 || viewModel.isScanning)

            Spacer()

            HStack(spacing: 5) {
                Text("\(viewModel.selectedScanItemIDs.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                Text("Selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSelectedSize), countStyle: .file))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .lineLimit(1)
        }
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Scan Category Section

struct ScanCategorySection: View {
    @Binding var category: CleanupCategory
    let totalWidth: CGFloat
    let onSelectItem: (CleanupItem) -> Void
    @EnvironmentObject var viewModel: AppViewModel

    private var isExpanded: Bool {
        viewModel.expandedCategoryIDs.contains(category.id)
    }

    private var allItemsSelected: Binding<Bool> {
        Binding(
            get: {
                let selectable = category.items.filter { !$0.isLocked }
                return !selectable.isEmpty && selectable.allSatisfy { viewModel.selectedScanItemIDs.contains($0.id) }
            },
            set: { isOn in
                if isOn {
                    viewModel.selectAllVisibleItems(in: category.id)
                } else {
                    viewModel.deselectAllVisibleItems(in: category.id)
                }
            }
        )
    }

    private var aggregate: (safety: SafetyLevel, confidence: Int) {
        let unlocked = category.items.filter { !$0.isLocked }
        if unlocked.isEmpty { return (.protected, 0) }

        let totalSize = max(unlocked.reduce(0) { $0 + $1.size }, 1)
        let weightedConfidence = unlocked.reduce(0) { $0 + Double($1.confidence) * Double($1.size) } / Double(totalSize)

        let safetyOrder: [SafetyLevel] = [.protected, .safe, .review, .advanced]
        let worstSafety = unlocked.map(\.safety).max { safetyOrder.firstIndex(of: $0)! < safetyOrder.firstIndex(of: $1)! } ?? .safe

        return (worstSafety, Int(round(weightedConfidence)))
    }

    var body: some View {
        let widths = ScanView.columnWidths(for: totalWidth)
        let color = safetyColor(aggregate.safety)

        VStack(spacing: 0) {
            Button {
                toggleExpanded(category.id)
            } label: {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(color)
                        .frame(width: 3)

                    HStack(spacing: 12) {
                        Toggle("", isOn: allItemsSelected)
                            .toggleStyle(.checkbox)
                            .frame(width: widths.checkbox)

                        HStack(spacing: 10) {
                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(color)
                                .frame(width: 34, height: 34)
                                .background(color.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(category.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(category.description)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: widths.name, alignment: .leading)

                        Spacer()

                        HStack(spacing: 6) {
                            Text("\(aggregate.confidence)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(color)

                            Text(aggregate.safety.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
                        .frame(width: widths.confidence, alignment: .leading)

                        Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: widths.size, alignment: .trailing)
                            .lineLimit(1)

                        Text("\(category.items.count)")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(AppColors.textMuted)
                            .frame(width: widths.items, alignment: .trailing)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .frame(width: widths.actions, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.18), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                LazyVStack(spacing: 4) {
                    ForEach($category.items) { $item in
                        ScanItemRow(
                            item: $item,
                            totalWidth: totalWidth,
                            onSelect: { onSelectItem(item) }
                        )
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 20)
            }
        }
    }

    private func toggleExpanded(_ id: String) {
        if viewModel.expandedCategoryIDs.contains(id) {
            viewModel.expandedCategoryIDs.remove(id)
        } else {
            viewModel.expandedCategoryIDs.insert(id)
        }
    }

    private func safetyColor(_ safety: SafetyLevel) -> Color {
        switch safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }
}

// MARK: - Scan Item Row

struct ScanItemRow: View {
    @Binding var item: CleanupItem
    let totalWidth: CGFloat
    let onSelect: () -> Void
    @EnvironmentObject var viewModel: AppViewModel

    private var isSelected: Binding<Bool> {
        Binding(
            get: { viewModel.selectedScanItemIDs.contains(item.id) },
            set: { _ in viewModel.toggleScanItemSelection(item.id) }
        )
    }

    private var realIcon: NSImage? {
        let fm = FileManager.default
        var path = item.path
        if !fm.fileExists(atPath: path) {
            if let appPath = item.appName.flatMap({ appName -> String? in
                let candidates = [
                    "/Applications/\(appName).app",
                    NSHomeDirectory() + "/Applications/\(appName).app"
                ]
                return candidates.first { fm.fileExists(atPath: $0) }
            }) {
                path = appPath
            }
        }
        return fm.fileExists(atPath: path) ? NSWorkspace.shared.icon(forFile: path) : nil
    }

    var body: some View {
        let widths = ScanView.columnWidths(for: totalWidth)
        let color = safetyColor(item.safety)

        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(color.opacity(item.isLocked ? 0.35 : 1.0))
                .frame(width: 3)

            HStack(spacing: 12) {
                Toggle("", isOn: isSelected)
                    .toggleStyle(.checkbox)
                    .disabled(item.isLocked)
                    .frame(width: widths.checkbox)

                HStack(spacing: 10) {
                    iconView(color: color)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(item.isLocked ? AppColors.textMuted : .white)
                            .lineLimit(1)

                        Text(item.reason)
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: widths.name, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !item.isLocked { onSelect() }
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("\(item.confidence)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)

                    Text(item.safety.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color.opacity(0.30), lineWidth: 1))
                .frame(width: widths.confidence, alignment: .leading)

                Text(item.formattedSize)
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: widths.size, alignment: .trailing)
                    .lineLimit(1)

                Text("1")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: widths.items, alignment: .trailing)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Button {
                        onSelect()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Inspect this item")
                }
                .frame(width: widths.actions, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .background(item.isLocked ? Color.white.opacity(0.02) : AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(item.isLocked ? 0.6 : 1.0)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func iconView(color: Color) -> some View {
        if let image = realIcon {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Image(systemName: iconForCategory)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func safetyColor(_ safety: SafetyLevel) -> Color {
        switch safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }

    private var iconForCategory: String {
        switch item.categoryID {
        case "app-residues": return "app.dashed"
        case "caches": return "externaldrive.badge.icloud"
        case "temp": return "folder.badge.gear"
        case "logs": return "doc.text"
        case "trash": return "trash"
        case "xcode": return "hammer"
        case "developer": return "terminal"
        case "downloads": return "arrow.down.circle"
        case "large-files": return "doc.badge.arrow.up"
        case "ai-models": return "brain"
        default: return "doc"
        }
    }
}

// MARK: - Review Selected Sheet

struct ReviewSelectedSheet: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private var selectedItems: [CleanupItem] {
        viewModel.categories.flatMap { $0.items.filter { viewModel.selectedScanItemIDs.contains($0.id) } }
            .sorted { $0.size > $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Review Selected")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(selectedItems.count) items · \(ByteCountFormatter.string(fromByteCount: Int64(selectedItems.reduce(0) { $0 + $1.size }), countStyle: .file))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .overlay(Rectangle().fill(AppColors.divider).frame(height: 1), alignment: .bottom)

            if selectedItems.isEmpty {
                Spacer()
                Text("No items selected")
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(selectedItems) { item in
                            HStack(spacing: 12) {
                                Image(systemName: iconFor(item.categoryID))
                                    .font(.system(size: 12))
                                    .foregroundStyle(safetyColor(item.safety))
                                    .frame(width: 28, height: 28)
                                    .background(safetyColor(item.safety).opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(item.path)
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppColors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(item.formattedSize)
                                    .font(.system(size: 11).monospacedDigit())
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(10)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(16)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.textMuted, isProminent: false))

                Spacer()

                Button {
                    Task {
                        await viewModel.cleanSelected()
                        dismiss()
                    }
                } label: {
                    Label("Move to Quarantine", systemImage: "shield")
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentCyan))
            }
            .padding(16)
            .background(AppColors.cardBackground)
            .overlay(Rectangle().fill(AppColors.divider).frame(height: 1), alignment: .top)
        }
        .frame(minWidth: 520, minHeight: 420)
        .background(AppColors.background)
    }

    private func safetyColor(_ safety: SafetyLevel) -> Color {
        switch safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }

    private func iconFor(_ categoryID: String) -> String {
        switch categoryID {
        case "app-residues": return "app.dashed"
        case "caches": return "externaldrive.badge.icloud"
        case "temp": return "folder.badge.gear"
        case "logs": return "doc.text"
        case "trash": return "trash"
        case "xcode": return "hammer"
        case "developer": return "terminal"
        case "downloads": return "arrow.down.circle"
        case "large-files": return "doc.badge.arrow.up"
        case "ai-models": return "brain"
        default: return "doc"
        }
    }
}
