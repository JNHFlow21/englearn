import Foundation

struct GeminiClient {
    func generate(baseURL: String, model: String, apiKey: String, userText: String) async throws -> String {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let base = URL(string: trimmedBase) else { throw LLMError.invalidBaseURL }

        // Official pattern: /v1beta/models/{model}:generateContent?key=...
        var url = base
        if base.path.hasSuffix("/v1beta") {
            url.append(path: "/models/\(model):generateContent")
        } else {
            url.append(path: "/v1beta/models/\(model):generateContent")
        }
        let finalURL = url

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-goog-api-key")

        let payload = GeminiGenerateRequest(
            contents: [
                .init(role: nil, parts: [.init(text: userText)]),
            ],
            generationConfig: .init(temperature: 0.6, maxOutputTokens: 2048)
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        guard let http else { throw LLMError.emptyResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw LLMError.badHTTPStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        let parts = decoded.candidates?.first?.content?.parts ?? []
        let combined = parts.compactMap(\.text).joined()
        let text = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw LLMError.emptyResponse }
        return text
    }
}

private struct GeminiGenerateRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable { let text: String }
        let role: String?
        let parts: [Part]
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let maxOutputTokens: Int
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct GeminiGenerateResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { let text: String? }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}
