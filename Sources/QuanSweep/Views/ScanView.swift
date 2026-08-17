import SwiftUI

struct ScanView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedItem: CleanupItem?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.categories.isEmpty && !viewModel.isScanning {
                emptyState
            } else {
                categoryList
            }

            bottomBar
        }
        .navigationTitle("Scan Results")
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No scan yet")
                .font(.title2.weight(.semibold))

            Text("Start a scan to see what QuanSweep can safely clean.")
                .foregroundStyle(.secondary)

            Button("Start Scan") {
                Task { await viewModel.scan() }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var categoryList: some View {
        List {
            ForEach($viewModel.categories) { $category in
                Section {
                    ForEach($category.items) { $item in
                        ItemRow(item: $item, selectedItem: $selectedItem)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                } header: {
                    CategoryHeader(category: $category)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected: \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalSelectedSize), countStyle: .file))")
                    .font(.system(size: 14, weight: .semibold))
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.cleanSelected() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Move to Quarantine")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.totalSelectedSize == 0 || viewModel.isScanning)
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
}

struct CategoryHeader: View {
    @Binding var category: CleanupCategory

    private var isOn: Binding<Bool> {
        Binding(
            get: { category.isSelected },
            set: { newValue in
                category.isSelected = newValue
                for index in category.items.indices where !category.items[index].isLocked {
                    category.items[index].isSelected = newValue
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 13, weight: .semibold))
                Text(category.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Toggle("", isOn: isOn)
                .toggleStyle(.checkbox)
                .disabled(category.safety == .safe)
        }
        .padding(.vertical, 6)
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

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ConfidenceBadge(score: item.confidence, safety: item.safety)
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(item.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                selectedItem = item
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Inspect this item")
        }
        .padding(10)
        .background(item.isLocked ? Color.gray.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(item.isLocked ? 0.7 : 1.0)
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
}

struct ConfidenceBadge: View {
    let score: Int
    let safety: SafetyLevel

    var body: some View {
        Text("\(score)%")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch safety {
        case .safe:     return .green
        case .review:   return .orange
        case .advanced: return .red
        case .protected:return .blue
        }
    }
}
