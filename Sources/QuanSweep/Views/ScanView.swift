import SwiftUI

struct ScanView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedItem: CleanupItem?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.displayCategories.isEmpty && !viewModel.isScanning {
                emptyState
            } else {
                HStack(spacing: 0) {
                    leftPanel
                        .frame(width: 380)
                        .padding(.trailing, 16)

                    Divider()
                        .background(Color.white.opacity(0.08))

                    rightPanel
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("")
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accentCyan)

            Text("No scan yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("Start a scan to see what QuanSweep can safely clean.\nNothing is deleted permanently — items are moved to Quarantine first.")
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Start Scan") {
                Task { await viewModel.scan() }
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentCyan))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var leftPanel: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Results")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Smart Scan Completed")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                GaugeView(
                    value: Double(viewModel.summary.totalScanned),
                    maxValue: max(Double(viewModel.summary.totalScanned) * 1.2, 1),
                    title: "Total Found",
                    subtitle: "\(viewModel.summary.itemCount) Items Scanned",
                    colors: [AppColors.accentCyan, AppColors.accentBlue, AppColors.accentPurple, AppColors.accentOrange]
                )
                .frame(height: 220)

                HStack(spacing: 8) {
                    summaryPill(label: "Safe", value: viewModel.summary.safeToClean, color: AppColors.accentGreen)
                    summaryPill(label: "Review", value: viewModel.summary.reviewRequired, color: AppColors.accentOrange)
                }

                HStack(spacing: 8) {
                    summaryPill(label: "Advanced", value: viewModel.summary.reviewRequired, color: AppColors.accentRed)
                    summaryPill(label: "Protected", value: viewModel.summary.protectedSize, color: AppColors.accentBlue)
                }

                HStack(spacing: 12) {
                    StatCard(
                        title: "Reclaimable",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean + viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Can be reclaimed",
                        color: AppColors.accentBlue,
                        history: []
                    )

                    StatCard(
                        title: "Safe to Clean",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.safeToClean), countStyle: .file),
                        subtitle: "High confidence",
                        color: AppColors.accentGreen,
                        history: []
                    )
                }

                HStack(spacing: 12) {
                    StatCard(
                        title: "Needs Review",
                        value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.summary.reviewRequired), countStyle: .file),
                        subtitle: "Review recommended",
                        color: AppColors.accentOrange,
                        history: []
                    )

                    StatCard(
                        title: "Items Scanned",
                        value: "\(viewModel.summary.itemCount)",
                        subtitle: "Files & entries",
                        color: AppColors.accentPurple,
                        history: []
                    )
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Scan")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .textCase(.uppercase)
                        Text(viewModel.lastResult?.createdAt ?? Date(), style: .relative)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.accentCyan)
                        Text(viewModel.lastResult?.createdAt ?? Date(), style: .time)
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neonCard(color: AppColors.accentCyan.opacity(0.5))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan Type")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .textCase(.uppercase)
                        Text("Smart Scan")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.accentPurple)
                        Text("Deep analysis enabled")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neonCard(color: AppColors.accentPurple.opacity(0.5))
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(AppColors.background)
    }

    private func summaryPill(label: String, value: UInt64, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .glowText(color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                Text(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(color.opacity(0.25), lineWidth: 1))
    }

    private var rightPanel: some View {
        VStack(spacing: 0) {
            rightHeader
                .padding(16)

            ScrollView {
                LazyVStack(spacing: 8, pinnedViews: []) {
                    ForEach($viewModel.displayCategories) { $category in
                        expandableCategorySection(category: $category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            bottomBar
        }
        .background(AppColors.background)
    }

    private var rightHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(AppColors.textMuted)
                TextField("Search items...", text: $viewModel.scanSearchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
            }
            .padding(10)
            .background(AppColors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(width: 240)

            Picker("Sort", selection: $viewModel.scanSortOption) {
                ForEach(AppViewModel.ScanSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)

            Spacer()

            Button {
                Task { await viewModel.scan() }
            } label: {
                Label("New Scan", systemImage: "arrow.clockwise")
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentCyan, isProminent: false))
        }
    }

    private func expandableCategorySection(category: Binding<CleanupCategory>) -> some View {
        let cat = category.wrappedValue
        let isExpanded = viewModel.expandedCategoryIDs.contains(cat.id)

        return VStack(spacing: 0) {
            Button {
                toggleExpanded(cat.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(categoryColor(cat))
                        .frame(width: 36, height: 36)
                        .background(categoryColor(cat).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cat.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text(cat.description)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(ByteCountFormatter.string(fromByteCount: Int64(cat.totalSize), countStyle: .file))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppColors.textSecondary)

                    Text("\(cat.items.count) items")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textMuted)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(12)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(categoryColor(cat).opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(category.items) { $item in
                        ItemRow(item: $item, selectedItem: $selectedItem)
                    }
                }
                .padding(.top, 6)
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

    private func categoryColor(_ category: CleanupCategory) -> Color {
        switch category.safety {
        case .safe: return AppColors.accentGreen
        case .review: return AppColors.accentOrange
        case .advanced: return AppColors.accentRed
        case .protected: return AppColors.accentBlue
        }
    }

    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected: \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSelectedSize), countStyle: .file))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.cleanSelected() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "shield")
                    Text("Move to Quarantine")
                }
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentCyan))
            .disabled(viewModel.totalSelectedSize == 0 || viewModel.isScanning)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(LinearGradient(colors: [AppColors.accentCyan.opacity(0.1), AppColors.accentPurple.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct ItemRow: View {
    @Binding var item: CleanupItem
    @Binding var selectedItem: CleanupItem?

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: selectedBinding)
                .toggleStyle(.checkbox)
                .disabled(item.isLocked)

            Image(systemName: iconForCategory)
                .font(.system(size: 16))
                .foregroundStyle(safetyColor)
                .frame(width: 32, height: 32)
                .background(safetyColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    SafetyBadge(safety: item.safety)
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(item.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)

            Button {
                selectedItem = item
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
            .help("Inspect this item")
        }
        .padding(10)
        .background(item.isLocked ? Color.white.opacity(0.03) : AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 1.0, opacity: 0.06), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(item.isLocked ? 0.6 : 1.0)
    }

    private var selectedBinding: Binding<Bool> {
        Binding(
            get: { item.isSelected && !item.isLocked },
            set: { newValue in
                guard !item.isLocked else { return }
                item.isSelected = newValue
            }
        )
    }

    private var safetyColor: Color {
        switch item.safety {
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
