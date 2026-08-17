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
                .padding(20)

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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quarantine")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Securely isolated items. They can't harm your system.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                        TextField("Search quarantine...", text: $viewModel.quarantineSearchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .frame(width: 240)
                    .background(AppColors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Picker("Sort", selection: $viewModel.quarantineSortOption) {
                        ForEach(AppViewModel.QuarantineSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }

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

            HStack(spacing: 12) {
                Button {
                    viewModel.selectAllVisibleQuarantineEntries()
                } label: {
                    Text("Select All")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))

                Button {
                    viewModel.deselectAllQuarantineEntries()
                } label: {
                    Text("Deselect")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))

                Button {
                    showBulkDeleteConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentRed, isProminent: false))
                .disabled(viewModel.selectedQuarantineEntryIDs.isEmpty)

                Spacer()

                Button {
                    showEmptyConfirmation = true
                } label: {
                    Label("Empty All", systemImage: "trash")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentRed, isProminent: false))
            }
        }
    }

    private func quarantineStatCard(icon: String, color: Color, value: String, subtitle: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(.uppercase)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .neonCard(color: color.opacity(0.4))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accentGreen)

            Text("Quarantine is empty")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("Cleaned items appear here for 30 days so you can restore them if needed.")
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
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
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(session.totalSize), countStyle: .file))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.03))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            HStack {
                Text("\(viewModel.selectedQuarantineEntryIDs.count) selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.selectedQuarantineSize), countStyle: .file))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding(14)
            .background(AppColors.cardBackground)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
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
            .frame(width: 24)

            Text("Item Name")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(minWidth: 160, alignment: .leading)

            Spacer()

            Text("File Path")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(minWidth: 200, alignment: .leading)

            Text("Size")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(width: 90, alignment: .trailing)

            Text("Date Modified")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(width: 120, alignment: .leading)

            Text("Actions")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
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
        HStack(spacing: 12) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .frame(width: 24)

            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.accentCyan)
                    .frame(width: 28, height: 28)
                    .background(AppColors.accentCyan.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    SafetyBadge(safety: safetyFor(entry))
                }
            }
            .frame(minWidth: 160, alignment: .leading)

            Spacer()

            Text(entry.originalPath)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .frame(minWidth: 200, alignment: .leading)

            Text(entry.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 90, alignment: .trailing)

            Text(entry.deletedAt, style: .date)
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 120, alignment: .leading)

            HStack(spacing: 8) {
                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentGreen, isProminent: false))
                .controlSize(.small)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentRed, isProminent: false))
                .controlSize(.small)
                .help("Delete permanently")
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(10)
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 1.0, opacity: 0.06), lineWidth: 1))
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
}
