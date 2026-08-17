import SwiftUI

struct QuarantineView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var entryToDelete: QuarantineEntry?
    @State private var showEmptyConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.displayQuarantineSessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Quarantine")
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
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.8))

            Text("Quarantine is empty")
                .font(.title2.weight(.semibold))

            Text("Cleaned items appear here for 30 days so you can restore them if needed.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionList: some View {
        List {
            headerSection

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
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: Int64(session.totalSize), countStyle: .file))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quarantine Folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.quarantineFolderPath)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .help(viewModel.quarantineFolderPath)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalQuarantineSize), countStyle: .file))
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Search quarantine", text: $viewModel.quarantineSearchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Picker("Sort", selection: $viewModel.quarantineSortOption) {
                    ForEach(AppViewModel.QuarantineSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                Spacer()

                Button {
                    showEmptyConfirmation = true
                } label: {
                    Label("Empty Quarantine", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text("Items are kept for 30 days")
                    .font(.caption2)
                Spacer()
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
}

struct QuarantineEntryRow: View {
    let entry: QuarantineEntry
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(entry.originalPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(entry.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button("Restore") {
                onRestore()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
            .help("Delete permanently")
        }
        .padding(.vertical, 4)
    }
}
