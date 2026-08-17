import SwiftUI

struct QuarantineView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var entryToDelete: QuarantineEntry?
    @State private var showEmptyConfirmation = false
    @State private var showBulkDeleteConfirmation = false

    private var allEntries: [QuarantineEntry] {
        viewModel.displayQuarantineSessions.flatMap { $0.items }
    }

    private var oldestItem: QuarantineEntry? {
        allEntries.min { $0.deletedAt < $1.deletedAt }
    }

    private var largestItem: QuarantineEntry? {
        allEntries.max { $0.size < $1.size }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                statCards
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                bulkActions
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                if viewModel.displayQuarantineSessions.isEmpty {
                    emptyState
                } else {
                    tableContainer(in: geo)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("")
        .alert("Empty Quarantine?", isPresented: $showEmptyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Empty", role: .destructive) {
                Task { await viewModel.emptyQuarantine() }
            }
        } message: {
            Text("This will permanently delete all quarantined items. They cannot be restored.")
        }
        .alert("Delete permanently?", isPresented: Binding(
            get: { entryToDelete != nil },
            set: { if !$0 { entryToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { entryToDelete = nil }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    Task { await viewModel.deletePermanently(entry: entry) }
                }
                entryToDelete = nil
            }
        } message: {
            Text("This will permanently remove \(entryToDelete?.name ?? ""). It cannot be restored.")
        }
        .alert("Delete selected items?", isPresented: $showBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteSelectedQuarantineEntries() }
            }
        } message: {
            Text("This will permanently delete \(viewModel.selectedQuarantineEntryIDs.count) selected items. They cannot be restored.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.accentCyan)
                        .frame(width: 34, height: 34)
                        .background(AppColors.accentCyan.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text("Quarantine")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Securely isolated items. They can't harm your system.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    TextField("Search quarantine...", text: $viewModel.quarantineSearchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(width: 200)
                .background(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                sortButtons
            }
        }
    }

    private var sortButtons: some View {
        HStack(spacing: 0) {
            ForEach(AppViewModel.QuarantineSortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.quarantineSortOption = option
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(viewModel.quarantineSortOption == option ? .white : AppColors.textSecondary)
                        .background(viewModel.quarantineSortOption == option ? AppColors.accentBlue.opacity(0.25) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 12) {
            quarantineStatCard(
                icon: "archivebox",
                color: AppColors.accentCyan,
                value: ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalQuarantineSize), countStyle: .file),
                subtitle: "\(allEntries.count) items",
                label: "Total Quarantined"
            )

            quarantineStatCard(
                icon: "calendar",
                color: AppColors.accentGreen,
                value: oldestItem?.deletedAt.formatted(date: .abbreviated, time: .omitted) ?? "—",
                subtitle: "30 days remaining",
                label: "Oldest Item"
            )

            quarantineStatCard(
                icon: "doc.text.magnifyingglass",
                color: AppColors.accentPurple,
                value: largestItem.map { $0.formattedSize } ?? "—",
                subtitle: largestItem?.name ?? "—",
                label: "Largest Item"
            )

            quarantineStatCard(
                icon: "timer",
                color: AppColors.accentOrange,
                value: "On",
                subtitle: "After 30 days",
                label: "Auto Cleanup"
            )
        }
    }

    private func quarantineStatCard(icon: String, color: Color, value: String, subtitle: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                Text(label)
                    .captionLabel()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Bulk Actions

    private var bulkActions: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.selectAllVisibleQuarantineEntries()
            } label: {
                Text("Select All")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                viewModel.deselectAllQuarantineEntries()
            } label: {
                Text("Deselect")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                showBulkDeleteConfirmation = true
            } label: {
                Label("Delete Selected", systemImage: "trash")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
            .disabled(viewModel.selectedQuarantineEntryIDs.isEmpty)

            Spacer()

            Button {
                showEmptyConfirmation = true
            } label: {
                Label("Empty All", systemImage: "trash")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
        }
    }

    // MARK: - Table

    private func tableContainer(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            tableHeader(in: geo)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.displayQuarantineSessions) { session in
                        Section {
                            ForEach(session.items) { entry in
                                QuarantineEntryRow(
                                    entry: entry,
                                    totalWidth: geo.size.width - 40,
                                    onRestore: {
                                        Task { await viewModel.restore(entry: entry) }
                                    },
                                    onDelete: {
                                        entryToDelete = entry
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Text(session.createdAt, style: .date)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(session.totalSize), countStyle: .file))
                                    .font(.system(size: 10).monospacedDigit())
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.02))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            bottomBar
        }
    }

    private func tableHeader(in geo: GeometryProxy) -> some View {
        let widths = Self.columnWidths(for: geo.size.width - 40)

        return HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { allEntries.allSatisfy { viewModel.selectedQuarantineEntryIDs.contains($0.id) } && !allEntries.isEmpty },
                set: { isOn in
                    if isOn {
                        viewModel.selectAllVisibleQuarantineEntries()
                    } else {
                        viewModel.deselectAllQuarantineEntries()
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

            Text("File Path")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Size")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.size, alignment: .trailing)

            Text("Date Modified")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.date, alignment: .leading)

            Text("Actions")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.actions, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }

    struct ColumnWidths {
        let checkbox: CGFloat
        let name: CGFloat
        let size: CGFloat
        let date: CGFloat
        let actions: CGFloat
    }

    static func columnWidths(for totalWidth: CGFloat) -> ColumnWidths {
        let minWidth: CGFloat = 800
        let width = max(totalWidth, minWidth)
        let checkbox: CGFloat = 24
        let actions: CGFloat = max(140, width * 0.14)
        let size: CGFloat = 70
        let date: CGFloat = max(100, width * 0.12)
        let name: CGFloat = width * 0.22
        return ColumnWidths(checkbox: checkbox, name: max(name, 140), size: size, date: date, actions: actions)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accentGreen)

            Text("Quarantine is empty")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("Cleaned items appear here for 30 days so you can restore them if needed.")
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 14) {
            Text("\(viewModel.selectedQuarantineEntryIDs.count) selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.selectedQuarantineSize), countStyle: .file))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
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

// MARK: - Quarantine Entry Row

struct QuarantineEntryRow: View {
    let entry: QuarantineEntry
    let totalWidth: CGFloat
    @EnvironmentObject var viewModel: AppViewModel
    let onRestore: () -> Void
    let onDelete: () -> Void

    private var isSelected: Binding<Bool> {
        Binding(
            get: { viewModel.selectedQuarantineEntryIDs.contains(entry.id) },
            set: { _ in viewModel.toggleQuarantineEntrySelection(entry.id) }
        )
    }

    var body: some View {
        let widths = QuarantineView.columnWidths(for: totalWidth)
        let safety = safetyFor(entry)

        HStack(spacing: 12) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .frame(width: widths.checkbox)

            HStack(spacing: 8) {
                Image(systemName: iconFor(entry))
                    .font(.system(size: 14))
                    .foregroundStyle(safetyColor(safety))
                    .frame(width: 28, height: 28)
                    .background(safetyColor(safety).opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    SafetyBadge(safety: safety)
                }
            }
            .frame(width: widths.name, alignment: .leading)

            Text(entry.originalPath)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.formattedSize)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: widths.size, alignment: .trailing)
                .lineLimit(1)

            Text(entry.deletedAt, style: .date)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
                .frame(width: widths.date, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentGreen, isProminent: false))
                .fixedSize(horizontal: true, vertical: false)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
                .help("Delete permanently")
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: widths.actions, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func safetyFor(_ entry: QuarantineEntry) -> SafetyLevel {
        switch entry.categoryID {
        case "caches", "temp", "trash": return .safe
        case "logs", "downloads", "xcode", "developer": return .review
        case "large-files", "ai-models": return .advanced
        default: return .review
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

    private func iconFor(_ entry: QuarantineEntry) -> String {
        switch entry.categoryID {
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
        default: return "doc.on.doc"
        }
    }
}
