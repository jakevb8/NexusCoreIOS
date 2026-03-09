import SwiftUI

struct EventsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var events: [KafkaEvent] = []
    @State private var total = 0
    @State private var currentPage = 1
    @State private var isLoading = true
    @State private var error: String? = nil

    private let pageSize = 50

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(title: "Events", showBack: true, onBack: { dismiss() })

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
            } else if events.isEmpty {
                Spacer()
                Text("No events yet.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
            } else {
                List(events) { event in
                    EventRow(event: event)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparatorTint(Theme.divider)
                }
                .listStyle(.plain)
                .background(Theme.background)

                if total > pageSize {
                    HStack(spacing: 24) {
                        Button("Prev") { Task { await load(page: currentPage - 1) } }
                            .disabled(currentPage <= 1)
                            .foregroundColor(currentPage <= 1 ? Theme.textSecondary : Theme.primary)
                            .font(.system(size: 14, weight: .semibold))

                        Text("Page \(currentPage)")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.onBackground)

                        Button("Next") { Task { await load(page: currentPage + 1) } }
                            .disabled(currentPage * pageSize >= total)
                            .foregroundColor(currentPage * pageSize >= total ? Theme.textSecondary : Theme.primary)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Theme.divider),
                        alignment: .top
                    )
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load(page: 1) } }
    }

    private func load(page: Int) async {
        isLoading = true
        error = nil
        do {
            let result = try await NexusAPI.getEvents(page: page)
            await MainActor.run {
                events = result.data
                total = result.resolvedTotal()
                currentPage = result.resolvedPage()
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

private struct EventRow: View {
    let event: KafkaEvent

    private var statusColor: Color {
        switch event.newStatus {
        case "AVAILABLE": return Color(hex: "#16A34A")
        case "IN_USE": return Color(hex: "#2563EB")
        case "MAINTENANCE": return Color(hex: "#D97706")
        case "RETIRED": return Color(hex: "#6B7280")
        default: return Color(hex: "#6B7280")
        }
    }

    private var statusChange: String {
        let p = event.previousStatus?.replacingOccurrences(of: "_", with: " ") ?? "?"
        let n = event.newStatus?.replacingOccurrences(of: "_", with: " ") ?? "?"
        return "\(p) → \(n)"
    }

    private var formattedTime: String {
        let s = event.occurredAt
        return String(s.prefix(19)).replacingOccurrences(of: "T", with: " ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(event.assetName ?? event.assetId ?? "Unknown asset")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.onBackground)
                Text(statusChange)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                Text(formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            if let status = event.newStatus {
                Text(status.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
    }
}
