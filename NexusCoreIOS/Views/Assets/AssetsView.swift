import SwiftUI
import UniformTypeIdentifiers

struct AssetsView: View {
    @Binding var path: NavigationPath
    @State private var assets: [Asset] = []
    @State private var total = 0
    @State private var page = 1
    @State private var search = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var isManager = false
    @State private var importResult: CsvImportResult? = nil
    @State private var successMessage: String? = nil
    @State private var deleteTarget: Asset? = nil
    @State private var showMenu = false
    @State private var showFilePicker = false

    private let pageSize = 20

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                title: "Assets",
                showBack: true,
                onBack: { path.removeLast() },
                trailingContent: isManager ? AnyView(headerActions) : nil
            )

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textSecondary)
                TextField("Search assets...", text: $search)
                    .onChange(of: search) { _ in
                        page = 1
                        Task { await load() }
                    }
            }
            .padding(12)
            .background(Theme.surface)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.divider))
            .padding(12)

            if let error {
                HStack {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.error)
                    Spacer()
                }
                .padding(12)
                .background(Theme.errorContainer)
                .cornerRadius(8)
                .padding(.horizontal, 12)
            }

            if let importResult {
                HStack {
                    Text("Import: \(importResult.created) created, \(importResult.skipped) skipped\(importResult.limitReached ? " (limit reached)" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Button("✕") { self.importResult = nil }
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(12)
                .background(Color(hex: "#EFF6FF"))
                .cornerRadius(8)
                .padding(.horizontal, 12)
            }

            if let successMessage {
                HStack {
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#16A34A"))
                    Spacer()
                    Button("✕") { self.successMessage = nil }
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(12)
                .background(Color(hex: "#F0FDF4"))
                .cornerRadius(8)
                .padding(.horizontal, 12)
            }

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else {
                List {
                    ForEach(assets) { asset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.name)
                                    .font(.system(size: 16, weight: .medium))
                                Text(asset.sku)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            StatusChipView(status: asset.status)
                            if isManager {
                                Button(action: { path.append(AppRoute.assetDetail(asset.id)) }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(Theme.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)

                                Button(action: { deleteTarget = asset }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(Theme.error)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)

                if total > pageSize {
                    HStack(spacing: 24) {
                        Button("Prev") {
                            page -= 1
                            Task { await load() }
                        }
                        .disabled(page == 1)
                        .foregroundColor(page == 1 ? Theme.textSecondary : Theme.secondary)

                        Text("Page \(page)")
                            .font(.system(size: 14))

                        Button("Next") {
                            page += 1
                            Task { await load() }
                        }
                        .disabled(page * pageSize >= total)
                        .foregroundColor(page * pageSize >= total ? Theme.textSecondary : Theme.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
        .confirmationDialog("Delete asset?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    Task { await performDelete(target) }
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog("Options", isPresented: $showMenu) {
            Button("Import CSV") { showFilePicker = true }
            Button("Download Sample CSV") { Task { await downloadSample() } }
            Button("Cancel", role: .cancel) {}
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.commaSeparatedText, .text]) { result in
            switch result {
            case .success(let url):
                Task { await performImport(url) }
            case .failure(let err):
                error = err.localizedDescription
            }
        }
    }

    private var headerActions: some View {
        HStack(spacing: 12) {
            Button(action: { showMenu = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(Theme.onPrimary)
                    .font(.system(size: 18))
            }
            Button(action: { path.append(AppRoute.assetDetail(nil)) }) {
                Image(systemName: "plus")
                    .foregroundColor(Theme.onPrimary)
                    .font(.system(size: 18))
            }
        }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            async let assetsTask = NexusAPI.getAssets(page: page, search: search.isEmpty ? nil : search)
            async let meTask = NexusAPI.getMe()
            let (result, me) = try await (assetsTask, meTask)
            await MainActor.run {
                assets = result.data
                total = result.resolvedTotal()
                isManager = me.role == .orgManager || me.role == .superadmin
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }

    private func performDelete(_ asset: Asset) async {
        do {
            try await NexusAPI.deleteAsset(id: asset.id)
            await MainActor.run { successMessage = "\"\(asset.name)\" deleted" }
            await load()
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func performImport(_ url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let result = try await NexusAPI.importCsv(data: data, fileName: url.lastPathComponent)
            await MainActor.run { importResult = result }
            await load()
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func downloadSample() async {
        do {
            let data = try await NexusAPI.downloadSampleCsv()
            await MainActor.run {
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("nexuscore_sample.csv")
                try? data.write(to: tmpURL)
                let av = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let vc = scene.windows.first?.rootViewController {
                    vc.present(av, animated: true)
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to download sample CSV"
            }
        }
    }
}
