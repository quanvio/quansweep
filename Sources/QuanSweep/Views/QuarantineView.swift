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
        VStack(spacing: 0) {
            header
                .padding(16)

            if viewModel.displayQuarantineSessions.isEmpty {
                emptyState
            } else {
                tableView
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

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quarantine")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Securely isolated items. They can't harm your system.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textMuted)
                        TextField("Search quarantine...", text: $viewModel.quarantineSearchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .font(.system(size: 12))
                    }
                    .padding(8)
                    .frame(width: 200)
                    .background(AppColors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Picker("Sort", selection: $viewModel.quarantineSortOption) {
                        ForEach(AppViewModel.QuarantineSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }

            HStack(spacing: 10) {
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
    }

    private func quarantineStatCard(icon: String, color: Color, value: String, subtitle: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                Text(label)
                    .captionLabel()
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

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

    private var tableView: some View {
        VStack(spacing: 0) {
            tableHeader

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.displayQuarantineSessions) { session in
                        Section {
                            ForEach(session.items) { entry in
                                QuarantineEntryRow(
                                    entry: entry,
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
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            HStack {
                Text("\(viewModel.selectedQuarantineEntryIDs.count) selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.selectedQuarantineSize), countStyle: .file))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding(12)
            .background(AppColors.cardBackground)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 10) {
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
            .frame(width: 22)

            Text("Item Name")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: 160, alignment: .leading)

            Text("File Path")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Size")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: 70, alignment: .trailing)

            Text("Date Modified")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: 100, alignment: .leading)

            Text("Actions")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
    }
}

struct QuarantineEntryRow: View {
    let entry: QuarantineEntry
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
        HStack(spacing: 10) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .frame(width: 22)

            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accentCyan)
                    .frame(width: 26, height: 26)
                    .background(AppColors.accentCyan.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    SafetyBadge(safety: safetyFor(entry))
                }
            }
            .frame(width: 160, alignment: .leading)

            Text(entry.originalPath)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.formattedSize)
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 70, alignment: .trailing)

            Text(entry.deletedAt, style: .date)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 100, alignment: .leading)

            HStack(spacing: 6) {
                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentGreen, isProminent: false))

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
                .help("Delete permanently")
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(8)
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func safetyFor(_ entry: QuarantineEntry) -> SafetyLevel {
        switch entry.categoryID {
        case "caches", "temp", "trash": return .safe
        case "logs", "downloads", "xcode", "developer": return .review
        case "large-files", "ai-models": return .advanced
        default: return .review
        }
    }
}
