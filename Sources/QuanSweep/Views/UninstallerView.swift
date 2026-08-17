import SwiftUI

struct UninstallerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedApp: InstalledApp?
    @State private var showUninstallConfirmation = false
    @State private var sortOption: AppViewModel.ScanSortOption = .name

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
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                statCards
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if viewModel.displayInstalledApps.isEmpty {
                    emptyState
                } else {
                    tableContainer(in: geo)
                }
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.accentRed)
                        .frame(width: 34, height: 34)
                        .background(AppColors.accentRed.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text("Uninstaller")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Remove unwanted apps and reclaim valuable space.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    TextField("Search apps...", text: $viewModel.installedAppSearchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(width: 200)
                .background(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(viewModel.displayInstalledApps.count) apps installed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                sortButtons
            }
        }
    }

    private var sortButtons: some View {
        HStack(spacing: 0) {
            ForEach([AppViewModel.ScanSortOption.date, .size, .name], id: \.self) { option in
                Button {
                    sortOption = option
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(sortOption == option ? .white : AppColors.textSecondary)
                        .background(sortOption == option ? AppColors.accentBlue.opacity(0.25) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 12) {
            uninstallerStatCard(
                icon: "square.grid.2x2",
                color: AppColors.accentCyan,
                value: "\(viewModel.displayInstalledApps.count)",
                subtitle: "Installed Apps"
            )

            uninstallerStatCard(
                icon: "internaldrive",
                color: AppColors.accentPurple,
                value: ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file),
                subtitle: "Total Size"
            )

            uninstallerStatCard(
                icon: "arrow.up.circle",
                color: AppColors.accentOrange,
                value: largestApp?.formattedSize ?? "—",
                subtitle: largestApp?.name ?? "Largest App"
            )

            uninstallerStatCard(
                icon: "calendar.badge.clock",
                color: AppColors.accentGreen,
                value: lastInstalled?.formattedLastUsed ?? "—",
                subtitle: "Last Installed"
            )
        }
    }

    private func uninstallerStatCard(icon: String, color: Color, value: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Table

    private func tableContainer(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            tableHeader(in: geo)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.displayInstalledApps) { app in
                        AppRow(app: app, totalWidth: geo.size.width - 40) {
                            selectedApp = app
                        } onUninstall: {
                            viewModel.selectInstalledApp(app.id)
                            showUninstallConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            bottomBar
        }
    }

    private func tableHeader(in geo: GeometryProxy) -> some View {
        let widths = Self.columnWidths(for: geo.size.width - 40)

        return HStack(spacing: 12) {
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
            .frame(width: widths.checkbox)

            Text("App Name")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.name, alignment: .leading)

            Spacer()

            Text("Size")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.size, alignment: .trailing)

            Text("Last Used")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.lastUsed, alignment: .leading)

            Text("Actions")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textMuted)
                .textCase(.uppercase)
                .frame(width: widths.actions, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }

    struct ColumnWidths {
        let checkbox: CGFloat
        let name: CGFloat
        let size: CGFloat
        let lastUsed: CGFloat
        let actions: CGFloat
    }

    static func columnWidths(for totalWidth: CGFloat) -> ColumnWidths {
        let minWidth: CGFloat = 700
        let width = max(totalWidth, minWidth)
        let checkbox: CGFloat = 24
        let actions: CGFloat = max(150, width * 0.15)
        let size: CGFloat = 80
        let lastUsed: CGFloat = max(90, width * 0.12)
        let name: CGFloat = width - checkbox - actions - size - lastUsed - 60
        return ColumnWidths(checkbox: checkbox, name: max(name, 160), size: size, lastUsed: lastUsed, actions: actions)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "app.gift")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accentPurple)

            Text("No apps found")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("QuanSweep looks in /Applications and ~/Applications for apps you can uninstall safely.")
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                Text("\(viewModel.selectedInstalledAppIDs.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                Text("Selected · \(ByteCountFormatter.string(fromByteCount: Int64(viewModel.selectedInstalledAppsSize), countStyle: .file))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .lineLimit(1)

            Spacer()

            Button {
                viewModel.selectAllVisibleInstalledApps()
            } label: {
                Text("Select All")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                viewModel.deselectAllInstalledApps()
            } label: {
                Text("Deselect All")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                showUninstallConfirmation = true
            } label: {
                Label("Uninstall Selected", systemImage: "trash")
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentRed))
            .disabled(viewModel.selectedInstalledAppIDs.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - App Icon View

private func appIconView(for path: String, size: CGFloat = 34) -> some View {
    let icon = NSWorkspace.shared.icon(forFile: path)
    return Image(nsImage: icon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 40 ? 11 : 8, style: .continuous))
}

// MARK: - App Row

struct AppRow: View {
    let app: InstalledApp
    let totalWidth: CGFloat
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
        let widths = UninstallerView.columnWidths(for: totalWidth)

        HStack(spacing: 12) {
            Toggle("", isOn: isSelected)
                .toggleStyle(.checkbox)
                .frame(width: widths.checkbox)

            HStack(spacing: 10) {
                appIconView(for: app.path)

                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(width: widths.name, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Spacer()

            Text(app.formattedSize)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: widths.size, alignment: .trailing)
                .lineLimit(1)

            Text(app.formattedLastUsed)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
                .frame(width: widths.lastUsed, alignment: .leading)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button {
                    onUninstall()
                } label: {
                    Label("Uninstall", systemImage: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentRed, isProminent: false))
                .fixedSize(horizontal: true, vertical: false)

                Button {
                    onSelect()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))
                .help("View related files")
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: widths.actions, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 1.0, opacity: 0.05), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }
}

// MARK: - App Detail Sheet

struct AppDetailSheet: View {
    let app: InstalledApp
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var residuePaths: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            infoSection

            residueSection

            Spacer()

            actionButtons
        }
        .padding(20)
        .frame(width: 480, height: 540)
        .background(AppColors.background)
        .task {
            residuePaths = InstalledApps.relatedResiduePaths(for: app)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            appIconView(for: app.path, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.white)

                Text(app.formattedSize)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.textMuted)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailRow(label: "Path", value: app.path)
            if !app.version.isEmpty {
                DetailRow(label: "Version", value: app.version)
            }
            if !app.bundleID.isEmpty {
                DetailRow(label: "Bundle ID", value: app.bundleID)
            }
            DetailRow(label: "Last Used", value: app.formattedLastUsed)
        }
        .padding(14)
        .glassCard()
    }

    private var residueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Related files to remove")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(residuePaths.count) found")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
            }

            if residuePaths.isEmpty {
                Text("No related files found under ~/Library.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
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
                .frame(maxHeight: 160)
            }

            Text("Only paths under ~/Library that match this app are shown. System folders and user documents are never touched.")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .glassCard()
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "")
            } label: {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentBlue, isProminent: false))

            Button {
                Task {
                    await viewModel.uninstallApp(app)
                    dismiss()
                }
            } label: {
                Label("Uninstall + Quarantine", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(color: AppColors.accentRed))
        }
    }
}
