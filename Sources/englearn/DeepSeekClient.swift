import Foundation

struct DeepSeekClient {
    func generate(baseURL: String, model: String, apiKey: String, systemText: String, userText: String) async throws -> String {
        let trimmedBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let base = URL(string: trimmedBase) else { throw LLMError.invalidBaseURL }

        // DeepSeek is OpenAI-compatible for chat completions.
        var url = base
        url.append(path: "/v1/chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = DeepSeekChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemText),
                .init(role: "user", content: userText),
            ],
            temperature: 0.6
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        guard let http else { throw LLMError.emptyResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw LLMError.badHTTPStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(DeepSeekChatResponse.self, from: data)
        let text = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else { throw LLMError.emptyResponse }
        return text
    }
}

private struct DeepSeekChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
}

private struct DeepSeekChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String? }
        let message: Message?
    }
    let choices: [Choice]?
}
