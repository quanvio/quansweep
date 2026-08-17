import SwiftUI

struct QuarantineView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.quarantineSessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Quarantine")
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
            ForEach(viewModel.quarantineSessions) { session in
                Section {
                    ForEach(session.items) { entry in
                        QuarantineEntryRow(entry: entry, session: session)
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
}

struct QuarantineEntryRow: View {
    let entry: QuarantineEntry
    let session: QuarantineSession
    @EnvironmentObject var viewModel: AppViewModel

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
                Task {
                    await viewModel.restore(session: session)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
