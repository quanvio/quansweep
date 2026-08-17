import SwiftUI

struct ItemDetailView: View {
    let item: CleanupItem
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            infoSection

            reasonSection

            Spacer()

            actionButtons
        }
        .padding(24)
        .frame(width: 480, height: 520)
        .alert("Delete permanently?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.deletePermanently(item: item)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently remove \(item.name). It cannot be restored from Quarantine.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForCategory(item.categoryID))
                .font(.system(size: 32))
                .foregroundStyle(colorForSafety(item.safety))
                .frame(width: 64, height: 64)
                .background(colorForSafety(item.safety).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)

                Text(item.formattedSize)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Path", value: item.path)
            DetailRow(label: "Modified", value: item.formattedDate)
            if let appName = item.appName, !appName.isEmpty {
                DetailRow(label: "Associated app", value: appName)
            }
            DetailRow(label: "Confidence", value: "\(item.confidence)%")
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SafetyBadge(safety: item.safety)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Why this score?")
                    .font(.system(size: 13, weight: .semibold))

                Text(item.reason)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Text(actionExplanation)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionExplanation: String {
        switch item.safety {
        case .safe:
            return "QuanSweep considers this safe to move to Quarantine. It can be restored at any time from the Quarantine tab."
        case .review:
            return "This item looks like leftover data, but QuanSweep is not 100% sure. Review it, reveal it in Finder, then choose Move to Quarantine or Delete Permanently."
        case .advanced:
            return "This item may contain user data or belong to an active application. Only advanced users should remove it."
        case .protected:
            return "This item is protected. QuanSweep will not move or delete it unless you unlock it."
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.quarantine(item: item); dismiss() }
                } label: {
                    Label("Move to Quarantine", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(item.isLocked)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Permanently", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(item.isLocked)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.revealInFinder(item: item)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.ignore(item: item)
                    dismiss()
                } label: {
                    Label("Ignore", systemImage: "eye.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
    }

    private func iconForCategory(_ id: String) -> String {
        switch id {
        case "appResidues": return "archivebox"
        case "caches": return "square.3.layers.3d.down.forward"
        case "temp": return "clock.arrow.circlepath"
        case "logs": return "doc.text.magnifyingglass"
        case "trash": return "trash"
        case "xcode": return "hammer.fill"
        case "developer": return "hammer.circle.fill"
        case "downloads": return "arrow.down.circle.fill"
        case "largeFiles": return "doc.text.magnifyingglass"
        case "aiModels": return "brain"
        default: return "doc"
        }
    }

    private func colorForSafety(_ safety: SafetyLevel) -> Color {
        switch safety {
        case .safe: return .green
        case .review: return .orange
        case .advanced: return .red
        case .protected: return .blue
        }
    }
}


