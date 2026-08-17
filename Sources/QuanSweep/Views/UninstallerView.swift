import SwiftUI

struct UninstallerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedApp: InstalledApp?
    @State private var appToUninstall: InstalledApp?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.displayInstalledApps.isEmpty {
                emptyState
            } else {
                appList
            }
        }
        .navigationTitle("Uninstaller")
        .sheet(item: $selectedApp) { app in
            AppDetailSheet(app: app)
        }
        .alert("Uninstall \(appToUninstall?.name ?? "")?", isPresented: Binding(
            get: { appToUninstall != nil },
            set: { if !$0 { appToUninstall = nil } }
        )) {
            Button("Cancel", role: .cancel) { appToUninstall = nil }
            Button("Uninstall + Quarantine", role: .destructive) {
                if let app = appToUninstall {
                    Task { await viewModel.uninstallApp(app) }
                }
                appToUninstall = nil
            }
        } message: {
            Text("This will move the app and its related files to Quarantine. You can restore them later if needed.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.gift")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No apps found")
                .font(.title2.weight(.semibold))

            Text("QuanSweep looks in /Applications and ~/Applications for apps you can uninstall safely.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var appList: some View {
        List {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Search apps", text: $viewModel.installedAppSearchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Text("\(viewModel.displayInstalledApps.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            ForEach(viewModel.displayInstalledApps) { app in
                AppRow(app: app) {
                    selectedApp = app
                } onUninstall: {
                    appToUninstall = app
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct AppRow: View {
    let app: InstalledApp
    let onSelect: () -> Void
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))

                HStack(spacing: 8) {
                    Text(app.formattedSize)
                    Text("·")
                    Text("Last used \(app.formattedLastUsed)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onUninstall()
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)

            Button {
                onSelect()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("View related files")
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
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
        .task {
            residuePaths = InstalledApps.relatedResiduePaths(for: app)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "app.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
                .frame(width: 80, height: 80)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)

                Text(app.formattedSize)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var residueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Related files to remove")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(residuePaths.count) found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if residuePaths.isEmpty {
                Text("No related files found under ~/Library.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(residuePaths, id: \.self) { path in
                            HStack {
                                Text(path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "")
            } label: {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                Task {
                    await viewModel.uninstallApp(app)
                    dismiss()
                }
            } label: {
                Label("Uninstall + Quarantine", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .controlSize(.large)
    }
}
