import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detailView
        }
        .background(AppColors.background)
        .task {
            await viewModel.loadQuarantine()
            await viewModel.loadVersionInfo()
            await viewModel.loadInstalledApps()
            viewModel.startSystemMonitoring()

            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "QuanSweepHasLaunchedBefore")
            if !hasLaunchedBefore {
                UserDefaults.standard.set(true, forKey: "QuanSweepHasLaunchedBefore")
                await viewModel.scan()
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoHeader
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20)

            VStack(spacing: 2) {
                SidebarItem(icon: "gauge.with.dots.needle.67percent", title: "Dashboard", tab: .dashboard, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .dashboard }

                SidebarItem(icon: "magnifyingglass", title: "Scan", tab: .scan, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .scan }

                SidebarItem(icon: "arrow.counterclockwise.circle", title: "Quarantine", tab: .quarantine, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .quarantine }

                SidebarItem(icon: "app.gift", title: "Uninstaller", tab: .uninstaller, selected: viewModel.selectedTab)
                    .onTapGesture { viewModel.selectedTab = .uninstaller }
            }
            .padding(.horizontal, 10)

            Spacer()

            VStack(spacing: 10) {
                protectionCard
                engineCard
            }
            .padding(.horizontal, 12)

            versionFooter
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(AppColors.background)
    }

    private var logoHeader: some View {
        HStack(spacing: 10) {
            Image(nsImage: appIcon() ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("QuanSweep")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("by Quanvio Lab")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    private var protectionCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.accentCyan)
                .frame(width: 34, height: 34)
                .background(AppColors.accentCyan.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("100%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                Text("System Protection")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                Text("Your Mac is protected")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()
        }
        .padding(10)
        .glassCard()
    }

    private var engineCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.accentPurple)
                .frame(width: 34, height: 34)
                .background(AppColors.accentPurple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("QuanSweep Engine")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Text("AI Powered · Deep Scan")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(10)
        .glassCard()
    }

    private var versionFooter: some View {
        HStack(spacing: 0) {
            Text("v\(viewModel.currentVersion)")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)

            Spacer()

            if let latest = viewModel.latestVersion, latest != viewModel.currentVersion {
                Button {
                    VersionChecker.shared.openReleasesPage()
                } label: {
                    Text("Update")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.accentGreen.opacity(0.12))
                        .foregroundStyle(AppColors.accentGreen)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColors.accentGreen.opacity(0.30), lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Update available: \(latest)")
            } else {
                Text("Up to date")
                    .font(.system(size: 10))
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
                    .transition(.opacity)
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
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 22, height: 22)
                .foregroundStyle(isSelected ? AppColors.accentCyan : AppColors.textSecondary)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.accentCyan.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColors.accentCyan.opacity(0.18), lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(AppColors.accentCyan)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                }
            }
        )
        .contentShape(Rectangle())
    }
}
