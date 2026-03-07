import SwiftUI

struct TeamView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var members: [TeamMember] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var successMessage: String? = nil
    @State private var isManager = false
    @State private var currentUserId: String? = nil
    @State private var inviteLink: String? = nil

    @State private var showInviteDialog = false
    @State private var inviteEmail = ""
    @State private var inviteLoading = false

    @State private var roleTarget: TeamMember? = nil
    @State private var removeTarget: TeamMember? = nil

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                title: "Team",
                showBack: true,
                onBack: { dismiss() },
                trailingContent: isManager ? AnyView(
                    Button(action: { showInviteDialog = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(Theme.onPrimary)
                            .font(.system(size: 18))
                    }
                ) : nil
            )

            if let error {
                HStack {
                    Text(error).font(.system(size: 14)).foregroundColor(Theme.error)
                    Spacer()
                    Button("✕") { self.error = nil }.foregroundColor(Theme.textSecondary)
                }
                .padding(12)
                .background(Theme.errorContainer)
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if let successMessage {
                HStack {
                    Text(successMessage).font(.system(size: 14)).foregroundColor(Color(hex: "#16A34A"))
                    Spacer()
                    Button("✕") { self.successMessage = nil }.foregroundColor(Theme.textSecondary)
                }
                .padding(12)
                .background(Color(hex: "#F0FDF4"))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if let inviteLink {
                HStack {
                    Text("Invite link ready")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Button("Copy Link") {
                        UIPasteboard.general.string = inviteLink
                        self.inviteLink = nil
                        successMessage = "Invite link copied!"
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.secondary)
                }
                .padding(12)
                .background(Color(hex: "#EFF6FF"))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.3)
                Spacer()
            } else {
                List {
                    ForEach(members) { member in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name ?? member.email)
                                    .font(.system(size: 16, weight: .medium))
                                if member.name != nil {
                                    Text(member.email)
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Text(member.role.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.primary)
                            }
                            Spacer()
                            if canEdit(member) {
                                Button(action: { roleTarget = member }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(Theme.secondary)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 8)

                                Button(action: { removeTarget = member }) {
                                    Image(systemName: "person.badge.minus")
                                        .foregroundColor(Theme.error)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await load() } }
        .sheet(isPresented: $showInviteDialog) { inviteSheet }
        .confirmationDialog(
            "Change Role",
            isPresented: Binding(get: { roleTarget != nil }, set: { if !$0 { roleTarget = nil } })
        ) {
            ForEach([Role.viewer, Role.assetManager, Role.orgManager], id: \.self) { r in
                Button(r.rawValue) {
                    if let target = roleTarget { Task { await changeRole(target, role: r) } }
                    roleTarget = nil
                }
            }
            Button("Cancel", role: .cancel) { roleTarget = nil }
        }
        .confirmationDialog(
            "Remove member?",
            isPresented: Binding(get: { removeTarget != nil }, set: { if !$0 { removeTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let target = removeTarget { Task { await removeMember(target) } }
                removeTarget = nil
            }
            Button("Cancel", role: .cancel) { removeTarget = nil }
        } message: {
            if let m = removeTarget {
                Text("\(m.name ?? m.email) will be removed from the organization.")
            }
        }
    }

    private var inviteSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email address", text: $inviteEmail)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                if inviteLoading {
                    ProgressView()
                } else {
                    Button("Send Invite") {
                        Task { await sendInvite() }
                    }
                    .disabled(!inviteEmail.contains("@"))
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showInviteDialog = false
                        inviteEmail = ""
                    }
                }
            }
        }
    }

    private func canEdit(_ member: TeamMember) -> Bool {
        isManager && member.id != currentUserId && member.role != .superadmin
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            async let teamTask = NexusAPI.getTeam()
            async let meTask = NexusAPI.getMe()
            let (team, me) = try await (teamTask, meTask)
            await MainActor.run {
                members = team
                currentUserId = me.id
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

    private func sendInvite() async {
        inviteLoading = true
        do {
            let res = try await NexusAPI.inviteMember(email: inviteEmail)
            await MainActor.run {
                showInviteDialog = false
                inviteEmail = ""
                inviteLoading = false
                if let link = res.inviteLink {
                    inviteLink = link
                } else {
                    successMessage = "Invite email sent"
                }
            }
        } catch {
            await MainActor.run {
                showInviteDialog = false
                inviteEmail = ""
                inviteLoading = false
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func removeMember(_ member: TeamMember) async {
        do {
            try await NexusAPI.removeMember(id: member.id)
            await MainActor.run { successMessage = "\(member.name ?? member.email) removed" }
            await load()
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func changeRole(_ member: TeamMember, role: Role) async {
        do {
            _ = try await NexusAPI.updateMemberRole(id: member.id, role: role)
            await MainActor.run { successMessage = "Role updated" }
            await load()
        } catch {
            await MainActor.run {
                self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
