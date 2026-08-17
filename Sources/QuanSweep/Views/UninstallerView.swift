import SwiftUI

struct UninstallerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedApp: InstalledApp?
    @State private var showUninstallConfirmation = false

    private var totalSize: UInt64 {
        viewModel.displayInstalledApps.reduce(0) { $0 + $1.size }
    }

    private var largestApp: InstalledApp? {
        viewModel.displayInstalledApps.max { $0.size < $1.size }
    }

    private var lastInstalled: InstalledApp? {
        viewModel.displayInstalledApps.max { $0.lastUsedAt < $1.lastUsedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(20)

            if viewModel.displayInstalledApps.isEmpty {
                emptyState
            } else {
                tableView
            }
        }
        .background(AppColors.background)
        .navigationTitle("")
        .sheet(item: $selectedApp) { app in
            AppDetailSheet(app: app)
        }
        .alert("Uninstall selected apps?", isPresented: $showUninstallConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall + Quarantine", role: .destructive) {
                Task { await viewModel.uninstallSelectedApps() }
            }
        } message: {
            Text("This will move \(viewModel.selectedInstalledAppIDs.count) selected apps and related files to Quarantine. You can restore them later if needed.")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uninstaller")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Remove unwanted apps and reclaim valuable space.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(AppColors.textMuted)
                        TextField("Search apps...", text: $viewModel.installedAppSearchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .frame(width: 240)
                    .background(AppColors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("\(viewModel.displayInstalledApps.count) apps installed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    Picker("Sort", selection: .constant(AppViewModel.ScanSortOption.name)) {
                        Text("Date").tag(AppViewModel.ScanSortOption.date)
                        Text("Size").tag(AppViewModel.ScanSortOption.size)
                        Text("Name").tag(AppViewModel.ScanSortOption.name)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }

            HStack(spacing: 12) {
                uninstallerStatCard(
                    icon: "app",
                    color: AppColors.accentCyan,
                    value: "\(viewModel.displayInstalledApps.count)",
                    subtitle: "Apps",
                    label: "Installed Apps"
                )

                uninstallerStatCard(
                    icon: "internaldrive",
                    color: AppColors.accentPurple,
                    value: ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file),
                    subtitle: "Total Size",
                    label: "Total Size"
                )

                uninstallerStatCard(
                    icon: "arrow.up.arrow.down.circle",
                    color: AppColors.accentOrange,
                    value: largestApp?.formattedSize ?? "—",
                    subtitle: largestApp?.name ?? "—",
                    label: "Largest App"
                )

                uninstallerStatCard(
                    icon: "calendar.badge.clock",
                    color: AppColors.accentGreen,
                    value: lastInstalled?.formattedLastUsed ?? "—",
                    subtitle: "Last Installed",
                    label: "Last Installed"
                )
            }
        }
    }

    private func uninstallerStatCard(icon: String, color: Color, value: String, subtitle: String, label: String) -> some View {
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
            Image(systemName: "app.gift")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accentPurple)

            Text("No apps found")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("QuanSweep looks in /Applications and ~/Applications for apps you can uninstall safely.")
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
                    ForEach(viewModel.displayInstalledApps) { app in
                        AppRow(app: app) {
                            selectedApp = app
                        } onUninstall: {
                            viewModel.selectInstalledApp(app.id)
                            showUninstallConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            bottomBar
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { viewModel.displayInstalledApps.allSatisfy { viewModel.selectedInstalledAppIDs.contains($0.id) } && !viewModel.displayInstalledApps.isEmpty },
                set: { isOn in
                    if isOn {
                        viewModel.selectAllVisibleInstalledApps()
                    } else {
                        viewModel.deselectAllInstalledApps()
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 24)

            Text("App Name")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(minWidth: 200, alignment: .leading)

            Spacer()

            Text("Size")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .frame(width: 90, alignment: .trailing)

            Text("Last Used")
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

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Text("\(viewModel.selectedInstalledAppIDs.count) Selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.selectedInstalledAppsSize), countStyle: .file))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                viewModel.selectAllVisibleInstalledApps()
            } label: {
                Text("Select All")
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                viewModel.deselectAllInstalledApps()
            } label: {
                Text("Deselect All")
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                showUninstallConfirmation = true
            } label: {
                Label("Uninstall Selected", systemImage: "trash")
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentRed))
            .disabled(viewModel.selectedInstalledAppIDs.isEmpty)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(LinearGradient(colors: [AppColors.accentPurple.opacity(0.1), AppColors.accentCyan.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1),
            alignment: .top
        )
    }
}

private func appIconView(for path: String, size: CGFloat = 36) -> some View {
    let icon = NSWorkspace.shared.icon(forFile: path)
    return Image(nsImage: icon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 40 ? 14 : 8, style: .continuous))
}

struct AppRow: View {
    let app: InstalledApp
    let onSelect: () -> Void
    let onUninstall: () -> Void
    @EnvironmentObject var viewModel: AppViewModel

    private var isSelected: Binding<Bool> {
        Binding(
            get: { viewModel.selectedInstalledAppIDs.contains(app.id) },
            set: { isOn in
                if isOn {
                    viewModel.selectInstalledApp(app.id)
                } else {
                    viewModel.deselectInstalledApp(app.id)
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .frame(width: 24)

            HStack(spacing: 10) {
                appIconView(for: app.path)

                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(minWidth: 200, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Spacer()

            Text(app.formattedSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 90, alignment: .trailing)

            Text(app.formattedLastUsed)
                .font(.caption)
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 120, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    onUninstall()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentRed, isProminent: false))
                .controlSize(.small)

                Button {
                    onSelect()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))
                .controlSize(.small)
                .help("View related files")
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(10)
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct AppDetailSheet: View {
    let app: InstalledApp
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var residuePaths: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            infoSection

            residueSection

            Spacer()

            actionButtons
        }
        .padding(24)
        .frame(width: 520, height: 600)
        .background(AppColors.background)
        .task {
            residuePaths = InstalledApps.relatedResiduePaths(for: app)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            appIconView(for: app.path, size: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.white)

                Text(app.formattedSize)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Path", value: app.path)
            if !app.version.isEmpty {
                DetailRow(label: "Version", value: app.version)
            }
            if !app.bundleID.isEmpty {
                DetailRow(label: "Bundle ID", value: app.bundleID)
            }
            DetailRow(label: "Last Used", value: app.formattedLastUsed)
        }
        .padding(16)
        .neonCard(color: AppColors.accentBlue.opacity(0.4))
    }

    private var residueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Related files to remove")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(residuePaths.count) found")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if residuePaths.isEmpty {
                Text("No related files found under ~/Library.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(residuePaths, id: \.self) { path in
                            HStack {
                                Text(path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(2)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxHeight: 180)
            }

            Text("Only paths under ~/Library that match this app are shown. System folders and user documents are never touched.")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .neonCard(color: AppColors.accentPurple.opacity(0.4))
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "")
            } label: {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                Task {
                    await viewModel.uninstallApp(app)
                    dismiss()
                }
            } label: {
                Label("Uninstall + Quarantine", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeonButtonStyle(color: AppColors.accentRed))
        }
        .controlSize(.large)
    }
}

