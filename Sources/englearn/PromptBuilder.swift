import Foundation

struct PromptBuilder {
    struct Prompt {
        let system: String
        let user: String
    }

    static func build(for input: String, config: AppConfig) -> Prompt {
        let isChinese = LanguageDetect.containsChineseCharacters(input)

        let domains = config.domains.isEmpty ? "" : config.domains.map(\.displayName).sorted().joined(separator: ", ")
        let jargon = max(0, min(3, config.jargonLevel))
        let voice = config.voiceStyle
        let mode = config.generateMode

        let glossary = GlossaryParser.parse(text: config.glossaryText)
        let glossaryBlock: String
        if glossary.isEmpty {
            glossaryBlock = "No glossary provided."
        } else {
            glossaryBlock = glossary.map { "- \($0.term): \($0.preferred)" }.joined(separator: "\n")
        }

        let outputFormat: String = {
            switch mode {
            case .both:
                return """
[spoken]
...
[/spoken]

[formal]
...
[/formal]

[notes]
- optional, keep <= 5 bullets
[/notes]
"""
            case .spokenOnly:
                return """
[spoken]
...
[/spoken]

[notes]
- optional, keep <= 5 bullets
[/notes]
"""
            case .formalOnly:
                return """
[formal]
...
[/formal]

[notes]
- optional, keep <= 5 bullets
[/notes]
"""
            }
        }()

        let system = """
You are an English writing coach.

Rules:
1) Preserve meaning. Do NOT add facts.
2) Use domain-appropriate terminology for: \(domains.isEmpty ? "General" : domains).
3) If a glossary entry exists, prefer the glossary phrasing consistently.
4) Output MUST use this exact tag format (no markdown, no code fences):

\(outputFormat)

Glossary:
\(glossaryBlock)
"""

        let spokenStyle: String = {
            switch voice {
            case .tradfi:
                return """
Spoken style: first-person, natural but professional; like explaining to a colleague. Use short sentences, contractions, and light connectors (e.g., “so”, “anyway”, “to be fair”) when helpful. Avoid cheesy phrases like “as we all know”.
"""
            case .cryptotwitter:
                return """
Spoken style: first-person, casual crypto-native tone; still clear. Short sentences, some slang is OK, but avoid meme spam.
"""
            }
        }()

        let jargonStyle = """
Jargon level: \(jargon) (0 = plain, 3 = most industry-native). Use jargon only when it fits and stays accurate.
"""

        let taskLine: String = {
            switch (isChinese, mode) {
            case (true, .both):
                return "Task: Translate the input Chinese into English in two variants (spoken + formal)."
            case (true, .spokenOnly):
                return "Task: Translate the input Chinese into English (spoken script only)."
            case (true, .formalOnly):
                return "Task: Translate the input Chinese into English (formal writing only)."
            case (false, .both):
                return "Task: Fix grammar, clarity, and coherence of the input English, then produce two variants (spoken + formal)."
            case (false, .spokenOnly):
                return "Task: Fix grammar, clarity, and coherence of the input English, then produce a spoken script only."
            case (false, .formalOnly):
                return "Task: Fix grammar, clarity, and coherence of the input English, then produce formal writing only."
            }
        }()

        if isChinese {
            let user = """
\(taskLine)
\(spokenStyle)
Formal style: concise, professional writing (memo / research note tone).
\(jargonStyle)

Input:
\(input)
"""
            return Prompt(system: system, user: user)
        } else {
            let user = """
\(taskLine)
\(spokenStyle)
Formal style: concise, professional writing (memo / research note tone).
\(jargonStyle)

Input:
\(input)
"""
            return Prompt(system: system, user: user)
        }
    }
}

enum LanguageDetect {
    static func containsChineseCharacters(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // CJK Unified Ideographs + Extension A (covers most practical cases)
            if (0x4E00...0x9FFF).contains(scalar.value) || (0x3400...0x4DBF).contains(scalar.value) {
                return true
            }
        }
        return false
    }
}

struct GlossaryEntry: Equatable {
    let term: String
    let preferred: String
}

enum GlossaryParser {
    static func parse(text: String) -> [GlossaryEntry] {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { line -> GlossaryEntry? in
                let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard parts.count == 2 else { return nil }
                let term = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let preferred = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !term.isEmpty, !preferred.isEmpty else { return nil }
                return GlossaryEntry(term: term, preferred: preferred)
            }
    }
}
