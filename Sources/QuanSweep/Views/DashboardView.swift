import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard

                HStack(spacing: 16) {
                    statCard(title: "Reclaimable Now", value: viewModel.summary.safeToClean + viewModel.summary.reviewRequired, color: .blue)
                    statCard(title: "Safe to Clean", value: viewModel.summary.safeToClean, color: .green)
                    statCard(title: "Needs Review", value: viewModel.summary.reviewRequired, color: .orange)
                }

                categoriesSection

                Spacer(minLength: 40)
            }
            .padding(28)
        }
        .background(Color(.windowBackgroundColor).opacity(0.3))
        .navigationTitle("Dashboard")
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            Text("Reclaim Space. Stay Safe.")
                .font(.system(size: 28, weight: .bold))

            Text("QuanSweep scans your Mac for leftover files, caches, and temporary data. Only items with high confidence are cleaned by default.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            HStack(spacing: 12) {
                Button(action: {
                    Task { await viewModel.scan() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        Text(viewModel.isScanning ? "Scanning..." : "Start Scan")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isScanning)

                Button(action: {
                    Task { await viewModel.cleanAllSafe() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Clean All Safe")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.summary.safeToClean == 0 || viewModel.isScanning)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statCard(title: String, value: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.system(size: 18, weight: .semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 12) {
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

struct CategoryMiniCard: View {
    let category: CleanupCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: category.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(category.totalSize), countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
