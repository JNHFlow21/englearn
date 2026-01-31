import Foundation

struct ParsedOutput: Equatable {
    let spoken: String
    let formal: String
    let notes: [String]
}

enum OutputParser {
    static func parse(rawText: String) -> ParsedOutput {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let tagged = parseTagged(from: trimmed) {
            return tagged
        }

        if let decoded = decodeJSON(from: trimmed) {
            return ParsedOutput(
                spoken: decoded.spoken.trimmingCharacters(in: .whitespacesAndNewlines),
                formal: decoded.formal.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: decoded.notes ?? []
            )
        }

        // Fallback: try to split by headings
        let lower = trimmed.lowercased()
        if lower.contains("spoken") && lower.contains("formal") {
            let spoken = extractSection(from: trimmed, headerCandidates: ["spoken", "spoken script"])
            let formal = extractSection(from: trimmed, headerCandidates: ["formal", "formal writing"])
            if !spoken.isEmpty || !formal.isEmpty {
                return ParsedOutput(spoken: spoken, formal: formal, notes: [])
            }
        }

        return ParsedOutput(spoken: trimmed, formal: "", notes: [])
    }

    private static func parseTagged(from text: String) -> ParsedOutput? {
        let spoken = extractTag("spoken", from: text)
        let formal = extractTag("formal", from: text)
        if spoken == nil && formal == nil { return nil }

        let notesText = extractTag("notes", from: text) ?? ""
        let notes = notesText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasPrefix("-") ? String($0.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) : $0 }
            .filter { !$0.isEmpty }

        return ParsedOutput(
            spoken: (spoken ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            formal: (formal ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes
        )
    }

    private static func extractTag(_ name: String, from text: String) -> String? {
        let open = "[\(name)]"
        let close = "[/\(name)]"
        guard let openRange = text.range(of: open) else { return nil }
        guard let closeRange = text.range(of: close, range: openRange.upperBound..<text.endIndex) else { return nil }
        return String(text[openRange.upperBound..<closeRange.lowerBound])
    }

    private static func decodeJSON(from text: String) -> LLMGenerated? {
        if let data = text.data(using: .utf8), let decoded = try? JSONDecoder().decode(LLMGenerated.self, from: data) {
            return decoded
        }

        // Strip code fences / wrapper text, then try again.
        guard let jsonSubstring = extractFirstJSONObject(from: text) else { return nil }
        guard let data = jsonSubstring.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LLMGenerated.self, from: data)
    }

    private static func extractFirstJSONObject(from text: String) -> String? {
        guard let first = text.firstIndex(of: "{"), let last = text.lastIndex(of: "}") else { return nil }
        guard first < last else { return nil }
        return String(text[first...last])
    }

    private static func extractSection(from text: String, headerCandidates: [String]) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var indices: [Int] = []
        for (idx, line) in lines.enumerated() {
            let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if headerCandidates.contains(where: { normalized == $0 || normalized.hasPrefix($0 + ":") || normalized.hasPrefix("# " + $0) || normalized.hasPrefix("## " + $0) }) {
                indices.append(idx)
            }
        }
        guard let startLineIndex = indices.first else { return "" }
        let start = startLineIndex + 1
        let end = (indices.dropFirst().first ?? lines.count) - 1
        if start >= lines.count { return "" }
        let slice = lines[start...max(start, end)]
        return slice.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct LLMGenerated: Decodable {
    let spoken: String
    let formal: String
    let notes: [String]?
}
