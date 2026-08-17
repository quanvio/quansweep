import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } detail: {
            detailView
        }
        .background(AppColors.background)
        .task {
            await viewModel.loadQuarantine()
            await viewModel.loadVersionInfo()
            await viewModel.loadInstalledApps()
            viewModel.startSystemMonitoring()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoHeader
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 24)

            VStack(spacing: 4) {
                SidebarItem(icon: "gauge.with.dots.needle.67percent", title: "Dashboard", tab: .dashboard, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .dashboard }

                SidebarItem(icon: "magnifyingglass", title: "Scan", tab: .scan, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .scan }

                SidebarItem(icon: "arrow.counterclockwise.circle", title: "Quarantine", tab: .quarantine, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .quarantine }

                SidebarItem(icon: "app.gift", title: "Uninstaller", tab: .uninstaller, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .uninstaller }
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(spacing: 12) {
                protectionCard
                engineCard
            }
            .padding(.horizontal, 14)

            versionFooter
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
        }
        .background(
            AppColors.background
                .overlay(
                    LinearGradient(
                        colors: [AppColors.accentBlue.opacity(0.04), AppColors.accentPurple.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    private var logoHeader: some View {
        HStack(spacing: 12) {
            Image(nsImage: appIcon() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: AppColors.accentCyan.opacity(0.25), radius: 12, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text("QuanSweep")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("by Quanvio Lab")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var protectionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 24))
                .foregroundStyle(AppColors.accentCyan)
                .frame(width: 44, height: 44)
                .background(AppColors.accentCyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("100%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                Text("System Protection")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                Text("Your Mac is protected")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()
        }
        .padding(12)
        .neonCard(color: AppColors.accentCyan)
    }

    private var engineCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 24))
                .foregroundStyle(AppColors.accentPurple)
                .frame(width: 44, height: 44)
                .background(AppColors.accentPurple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("QuanSweep Engine")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text("AI Powered · Deep Scan")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .neonCard(color: AppColors.accentPurple)
    }

    private var versionFooter: some View {
        HStack(spacing: 0) {
            Text("v\(viewModel.currentVersion)")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            if let latest = viewModel.latestVersion, latest != viewModel.currentVersion {
                Button {
                    VersionChecker.shared.openReleasesPage()
                } label: {
                    Text("Update")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.accentGreen.opacity(0.15))
                        .foregroundStyle(AppColors.accentGreen)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Update available: \(latest)")
            } else {
                Text("Up to date")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

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

            if viewModel.isScanning {
                ScanningOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
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

    var isSelected: Bool { selected == tab }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? AppColors.accentCyan : AppColors.textSecondary)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.accentCyan.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppColors.accentCyan.opacity(0.25), lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.accentCyan)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                        .glowText(color: AppColors.accentCyan)
                }
            }
        )
        .contentShape(Rectangle())
    }
}
