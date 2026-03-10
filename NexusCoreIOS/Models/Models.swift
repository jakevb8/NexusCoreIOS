// MARK: - Enums

enum AssetStatus: String, Codable, CaseIterable {
    case available = "AVAILABLE"
    case inUse = "IN_USE"
    case maintenance = "MAINTENANCE"
    case retired = "RETIRED"

    var displayName: String {
        switch self {
        case .available: return "AVAILABLE"
        case .inUse: return "IN USE"
        case .maintenance: return "MAINTENANCE"
        case .retired: return "RETIRED"
        }
    }

    var color: String {
        switch self {
        case .available: return "#16A34A"
        case .inUse: return "#2563EB"
        case .maintenance: return "#D97706"
        case .retired: return "#6B7280"
        }
    }
}

enum Role: String, Codable, CaseIterable {
    case superadmin = "SUPERADMIN"
    case orgManager = "ORG_MANAGER"
    case assetManager = "ASSET_MANAGER"
    case viewer = "VIEWER"
}

enum OrgStatus: String, Codable {
    case pending = "PENDING"
    case active = "ACTIVE"
    case rejected = "REJECTED"
}

enum BackendChoice: String, CaseIterable {
    case js = "JS"
    case dotnet = "DOTNET"

    var label: String {
        switch self {
        case .js: return "NexusCoreJS (Node API)"
        case .dotnet: return "NexusCoreDotNet (.NET API)"
        }
    }

    var baseURL: String {
        switch self {
        case .js: return "https://nexus-coreapi-production.up.railway.app/api/v1"
        case .dotnet: return "https://nexuscoredotnet-production.up.railway.app/api/v1"
        }
    }
}

// MARK: - Response Models

struct AuthUser: Codable {
    let id: String
    let email: String
    let displayName: String?
    let role: Role
    let organizationId: String
    let organization: AuthUserOrganization?

    // Convenience: org status lives inside the nested organization object
    var orgStatus: OrgStatus {
        guard let status = organization?.status else { return .pending }
        return OrgStatus(rawValue: status) ?? .pending
    }
}

struct AuthUserOrganization: Codable {
    let id: String
    let name: String
    let status: String
}

struct Asset: Codable, Identifiable {
    let id: String
    let name: String
    let sku: String
    let description: String?
    let status: AssetStatus
    let assignedTo: String?
    let organizationId: String
    let createdAt: String
    let updatedAt: String?
}

struct PaginatedAssets: Codable {
    let data: [Asset]
    // .NET flat fields
    let total: Int?
    let page: Int?
    let perPage: Int?
    // JS nested meta
    let meta: PaginatedMeta?

    func resolvedTotal() -> Int { meta?.total ?? total ?? 0 }
    func resolvedPage() -> Int { meta?.page ?? page ?? 1 }
}

struct TeamMember: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let role: Role
    let createdAt: String
}

struct InviteResponse: Codable {
    let inviteLink: String?
}

struct StatusBreakdownItem: Codable {
    let status: AssetStatus
    let count: Int
}

struct ReportsData: Codable {
    let totalAssets: Int
    let utilizationRate: Double
    let totalUsers: Int?
    // JS API returns {"AVAILABLE":0,"IN_USE":1,...}, .NET may return an array
    let byStatus: [String: Int]?
    let byStatusArray: [StatusBreakdownItem]?

    // Decode from either shape
    enum CodingKeys: String, CodingKey {
        case totalAssets, utilizationRate, totalUsers, byStatus, byStatusArray
    }

    // Resolved ordered array usable by the view
    func resolvedByStatus() -> [StatusBreakdownItem] {
        if let dict = byStatus {
            return AssetStatus.allCases.compactMap { status in
                guard let count = dict[status.rawValue] else { return nil }
                return StatusBreakdownItem(status: status, count: count)
            }
        }
        return byStatusArray ?? []
    }
}

struct CsvImportResult: Codable {
    let created: Int
    let skipped: Int
    let limitReached: Bool
    let errors: [String]
}

// MARK: - Request Models

struct RegisterRequest: Codable {
    let organizationName: String
    let organizationSlug: String
    let displayName: String?
}

struct CreateAssetRequest: Codable {
    let name: String
    let sku: String
    let description: String?
    let status: AssetStatus
    let assignedTo: String?
}

struct UpdateRoleRequest: Codable {
    let role: Role
}

// MARK: - Events

struct KafkaEvent: Codable, Identifiable {
    let id: String
    let organizationId: String
    let assetId: String?
    let assetName: String?
    let previousStatus: String?
    let newStatus: String?
    let actorId: String?
    let occurredAt: String
    let createdAt: String
}

struct PaginatedEvents: Codable {
    let data: [KafkaEvent]
    // .NET flat fields
    let total: Int?
    let page: Int?
    let perPage: Int?
    // JS nested meta
    let meta: PaginatedMeta?

    func resolvedTotal() -> Int { meta?.total ?? total ?? 0 }
    func resolvedPage() -> Int { meta?.page ?? page ?? 1 }
}

struct PaginatedMeta: Codable {
    let total: Int?
    let page: Int?
    let perPage: Int?
}
