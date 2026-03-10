import SwiftUI

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var data: ReportsData? = nil
    @State private var isLoading = true
    @State private var error: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(title: "Reports", showBack: true, onBack: { dismiss() })

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else if let error {
                Spacer()
                Text(error)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.error)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else if let data {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Stat cards
                        HStack(spacing: 12) {
                            NexusCard {
                                VStack(spacing: 4) {
                                    Text("Total Assets")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                    Text("\(data.totalAssets)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(Theme.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            NexusCard {
                                VStack(spacing: 4) {
                                    Text("Utilization")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                    Text("\(Int(data.utilizationRate.rounded()))%")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(Theme.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("Assets by Status")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.top, 8)

                        let maxCount = data.resolvedByStatus().map(\.count).max() ?? 1
                        ForEach(data.resolvedByStatus(), id: \.status) { item in
                            NexusCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        StatusChipView(status: item.status)
                                        Spacer()
                                        Text("\(item.count)")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Theme.divider)
                                                .frame(height: 8)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Theme.primary)
                                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            let result = try await NexusAPI.getReports()
            await MainActor.run {
                data = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}
