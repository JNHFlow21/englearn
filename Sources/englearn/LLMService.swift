import Foundation

struct LLMService {
    func generate(
        provider: LLMProvider,
        baseURL: String,
        model: String,
        apiKey: String,
        system: String,
        user: String
    ) async throws -> String {
        switch provider {
        case .gemini:
            return try await GeminiClient().generate(
                baseURL: baseURL,
                model: model,
                apiKey: apiKey,
                userText: system + "\n\n" + user
            )
        case .deepseek:
            return try await DeepSeekClient().generate(
                baseURL: baseURL,
                model: model,
                apiKey: apiKey,
                systemText: system,
                userText: user
            )
        }
    }
}

enum LLMError: LocalizedError {
    case invalidBaseURL
    case badHTTPStatus(Int, String?)
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: return "Invalid Base URL."
        case .badHTTPStatus(let code, let body):
            let snippet = (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if snippet.isEmpty { return "HTTP \(code)." }
            let limited = String(snippet.prefix(220))
            return "HTTP \(code): \(limited)"
        case .emptyResponse: return "Empty response."
        case .decodingFailed: return "Failed to decode response."
        }
    }
}
