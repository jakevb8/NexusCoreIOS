import SwiftUI

struct AssetDetailView: View {
    let assetId: String?
    @Binding var path: NavigationPath

    @State private var name = ""
    @State private var sku = ""
    @State private var description = ""
    @State private var assignedTo = ""
    @State private var status: AssetStatus = .available
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var error: String? = nil

    private var isNew: Bool { assetId == nil }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                title: isNew ? "New Asset" : "Edit Asset",
                showBack: true,
                onBack: { path.removeLast() },
                trailingContent: AnyView(
                    Button(action: handleSave) {
                        Text("Save")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor((isSaving || name.isEmpty || sku.isEmpty) ? Theme.onPrimary.opacity(0.5) : Theme.onPrimary)
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty || sku.trimmingCharacters(in: .whitespaces).isEmpty)
                )
            )

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let error {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.error)
                        }

                        fieldLabel("Name *")
                        TextField("Asset name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        fieldLabel("SKU *")
                        TextField("SKU", text: $sku)
                            .textFieldStyle(.roundedBorder)

                        fieldLabel("Description")
                        TextField("Optional description", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)

                        fieldLabel("Assigned To")
                        TextField("Optional assignee", text: $assignedTo)
                            .textFieldStyle(.roundedBorder)

                        fieldLabel("Status")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AssetStatus.allCases, id: \.self) { s in
                                    Button(action: { status = s }) {
                                        Text(s.displayName)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(status == s ? Theme.onPrimary : Theme.primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(status == s ? Theme.primary : Color.clear)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Theme.primary, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }

                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            if !isNew, let id = assetId {
                Task { await loadAsset(id: id) }
            }
        }
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
    }

    private func loadAsset(id: String) async {
        isLoading = true
        do {
            let result = try await NexusAPI.getAssets(page: 1, search: nil)
            if let found = result.data.first(where: { $0.id == id }) {
                await MainActor.run {
                    name = found.name
                    sku = found.sku
                    description = found.description ?? ""
                    assignedTo = found.assignedTo ?? ""
                    status = found.status
                    isLoading = false
                }
            } else {
                await MainActor.run { isLoading = false }
            }
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }

    private func handleSave() {
        isSaving = true
        error = nil
        let req = CreateAssetRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            sku: sku.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            status: status,
            assignedTo: assignedTo.trimmingCharacters(in: .whitespaces).isEmpty ? nil : assignedTo.trimmingCharacters(in: .whitespaces)
        )
        Task {
            do {
                if isNew {
                    _ = try await NexusAPI.createAsset(req)
                } else if let id = assetId {
                    _ = try await NexusAPI.updateAsset(id: id, request: req)
                }
                await MainActor.run { path.removeLast() }
            } catch {
                await MainActor.run {
                    self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
