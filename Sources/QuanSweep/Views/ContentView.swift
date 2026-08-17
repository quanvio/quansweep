import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            detailView
        }
        .task {
            await viewModel.loadQuarantine()
            await viewModel.loadVersionInfo()
            await viewModel.loadInstalledApps()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(nsImage: appIcon() ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("QuanSweep")
                        .font(.system(size: 16, weight: .semibold))
                    Text("by Quanvio Lab")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            SidebarItem(icon: "gauge.with.dots.needle.67percent", title: "Dashboard", tab: .dashboard, selected: viewModel.selectedTab)
                .onTapGesture { viewModel.selectedTab = .dashboard }

            SidebarItem(icon: "magnifyingglass", title: "Scan", tab: .scan, selected: viewModel.selectedTab)
                .onTapGesture { viewModel.selectedTab = .scan }

            SidebarItem(icon: "arrow.counterclockwise.circle", title: "Quarantine", tab: .quarantine, selected: viewModel.selectedTab)
                .onTapGesture { viewModel.selectedTab = .quarantine }

            SidebarItem(icon: "app.gift", title: "Uninstaller", tab: .uninstaller, selected: viewModel.selectedTab)
                .onTapGesture { viewModel.selectedTab = .uninstaller }

            Spacer()

            if viewModel.isScanning {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            versionFooter
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }

    private var versionFooter: some View {
        HStack(spacing: 0) {
            Text("v\(viewModel.currentVersion)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            if let latest = viewModel.latestVersion, latest != viewModel.currentVersion {
                Button {
                    VersionChecker.shared.openReleasesPage()
                } label: {
                    Text("Update")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Update available: \(latest)")
            } else {
                Text("Up to date")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch viewModel.selectedTab {
        case .dashboard:
            DashboardView()
        case .scan:
            ScanView()
        case .quarantine:
            QuarantineView()
        case .uninstaller:
            UninstallerView()
        }
    }

    private func appIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSImage(named: NSImage.applicationIconName)
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let tab: AppViewModel.Tab
    let selected: AppViewModel.Tab

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 24, height: 24)
                .foregroundStyle(selected == tab ? Color.white : Color.primary)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected == tab ? Color.white : Color.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected == tab ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
