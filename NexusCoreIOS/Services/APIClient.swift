import Foundation
import FirebaseAuth

enum APIError: Error, LocalizedError {
    case noUser
    case invalidURL
    case httpError(Int, String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noUser: return "Not signed in"
        case .invalidURL: return "Invalid URL"
        case .httpError(let code, let msg): return msg ?? "HTTP error \(code)"
        case .decodingError(let err): return "Decode error: \(err.localizedDescription)"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

struct APIErrorResponse: Codable {
    let message: String?
}

class APIClient {
    static var shared: APIClient = {
        let choice = BackendPreference.shared.current
        return APIClient(baseURL: choice.baseURL)
    }()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        decoder = JSONDecoder()
    }

    static func reset() {
        let choice = BackendPreference.shared.current
        shared = APIClient(baseURL: choice.baseURL)
    }

    private func authToken() async throws -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        return try await user.getIDToken(forcingRefresh: false)
    }

    private func makeRequest(path: String, method: String, body: Data? = nil) async throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = try await authToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let req = try await makeRequest(path: path, method: "GET")
        return try await perform(req)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        let req = try await makeRequest(path: path, method: "POST", body: data)
        return try await perform(req)
    }

    /// POST that discards the response body (treats any 2xx as success).
    func post<B: Encodable>(_ path: String, body: B) async throws {
        let data = try JSONEncoder().encode(body)
        let req = try await makeRequest(path: path, method: "POST", body: data)
        let _: EmptyResponse = try await perform(req)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        let req = try await makeRequest(path: path, method: "PUT", body: data)
        return try await perform(req)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        let req = try await makeRequest(path: path, method: "PATCH", body: data)
        return try await perform(req)
    }

    func delete(_ path: String) async throws {
        let req = try await makeRequest(path: path, method: "DELETE")
        let _: EmptyResponse = try await perform(req)
    }

    func postMultipart<T: Decodable>(_ path: String, fileData: Data, fileName: String, mimeType: String, fieldName: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = try await authToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        return try await perform(req)
    }

    func downloadData(_ path: String) async throws -> Data {
        let req = try await makeRequest(path: path, method: "GET")
        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let msg = (try? decoder.decode(APIErrorResponse.self, from: data))?.message
                throw APIError.httpError(http.statusCode, msg)
            }
            return data
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
                print("[APIClient] HTTP \(http.statusCode) \(request.httpMethod ?? "") \(request.url?.path ?? "") — \(body)")
                let msg = (try? decoder.decode(APIErrorResponse.self, from: data))?.message
                throw APIError.httpError(http.statusCode, msg)
            }
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
                print("[APIClient] Decode error for \(T.self) from \(request.url?.path ?? "")")
                print("[APIClient] Response body: \(body)")
                if let de = error as? DecodingError {
                    switch de {
                    case .keyNotFound(let key, let ctx):
                        print("[APIClient] Missing key '\(key.stringValue)' — \(ctx.debugDescription)")
                    case .typeMismatch(let type, let ctx):
                        print("[APIClient] Type mismatch (\(type)) — \(ctx.debugDescription)")
                    case .valueNotFound(let type, let ctx):
                        print("[APIClient] Value not found (\(type)) — \(ctx.debugDescription)")
                    case .dataCorrupted(let ctx):
                        print("[APIClient] Data corrupted — \(ctx.debugDescription)")
                    @unknown default:
                        print("[APIClient] Unknown decode error: \(error)")
                    }
                } else {
                    print("[APIClient] Non-decoding error: \(error)")
                }
                throw APIError.decodingError(error)
            }
        } catch let err as APIError {
            throw err
        } catch {
            print("[APIClient] Network error \(request.httpMethod ?? "") \(request.url?.absoluteString ?? ""): \(error)")
            throw APIError.networkError(error)
        }
    }
}

private struct EmptyResponse: Codable {}
