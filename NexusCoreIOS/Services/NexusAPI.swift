import Foundation

struct NexusAPI {
    // MARK: - Auth
    static func getMe() async throws -> AuthUser {
        try await APIClient.shared.get("/auth/me")
    }

    // POST /auth/register — response body omits the nested organization object,
    // so we discard it. OnboardingView navigates to PendingApproval on success.
    static func register(_ request: RegisterRequest) async throws {
        try await APIClient.shared.post("/auth/register", body: request)
    }

    static func deleteAccount() async throws {
        try await APIClient.shared.delete("/auth/me")
    }

    // MARK: - Assets
    static func getAssets(page: Int = 1, search: String? = nil) async throws -> PaginatedAssets {
        var path = "/assets?page=\(page)"
        if let search, !search.isEmpty {
            let encoded = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search
            path += "&search=\(encoded)"
        }
        return try await APIClient.shared.get(path)
    }

    static func createAsset(_ request: CreateAssetRequest) async throws -> Asset {
        try await APIClient.shared.post("/assets", body: request)
    }

    static func updateAsset(id: String, request: CreateAssetRequest) async throws -> Asset {
        try await APIClient.shared.put("/assets/\(id)", body: request)
    }

    static func deleteAsset(id: String) async throws {
        try await APIClient.shared.delete("/assets/\(id)")
    }

    static func importCsv(data: Data, fileName: String) async throws -> CsvImportResult {
        try await APIClient.shared.postMultipart(
            "/assets/import/csv",
            fileData: data,
            fileName: fileName,
            mimeType: "text/csv",
            fieldName: "file"
        )
    }

    // MARK: - Team
    static func getTeam() async throws -> [TeamMember] {
        try await APIClient.shared.get("/users")
    }

    static func inviteMember(email: String) async throws -> InviteResponse {
        struct InviteReq: Codable { let email: String }
        return try await APIClient.shared.post("/users/invite", body: InviteReq(email: email))
    }

    static func removeMember(id: String) async throws {
        try await APIClient.shared.delete("/users/\(id)")
    }

    static func updateMemberRole(id: String, role: Role) async throws -> TeamMember {
        try await APIClient.shared.patch("/users/\(id)/role", body: UpdateRoleRequest(role: role))
    }

    // MARK: - Reports
    static func getReports() async throws -> ReportsData {
        try await APIClient.shared.get("/reports/stats")
    }

    // MARK: - Events
    static func getEvents(page: Int = 1) async throws -> PaginatedEvents {
        try await APIClient.shared.get("/events?page=\(page)")
    }
}
