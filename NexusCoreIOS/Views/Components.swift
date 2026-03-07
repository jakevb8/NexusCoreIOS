import SwiftUI

struct StatusChipView: View {
    let status: AssetStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Theme.statusColor(status).opacity(0.12))
            .cornerRadius(6)
    }
}

struct NexusCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Theme.surface)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
    }
}

struct NexusButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDestructive: Bool = false
    var isOutlined: Bool = false

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(isOutlined ? Theme.primary : Theme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
            } else {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isOutlined ? (isDestructive ? Theme.error : Theme.primary) : Theme.onPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .background(
            isOutlined ? Color.clear : (isDestructive ? Theme.error : Theme.primary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOutlined ? (isDestructive ? Theme.error : Theme.primary) : Color.clear, lineWidth: 1.5)
        )
        .cornerRadius(8)
    }
}

struct AppHeaderView: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil
    var trailingContent: AnyView? = nil

    var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.onPrimary)
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(width: 36)
            } else {
                Spacer().frame(width: 36)
            }

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.onPrimary)

            Spacer()

            if let trailing = trailingContent {
                trailing.frame(width: 80, alignment: .trailing)
            } else {
                Spacer().frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.primary)
    }
}
