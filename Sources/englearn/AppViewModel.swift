import AppKit
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var spokenText: String = ""
    @Published var formalText: String = ""
    @Published var notes: [String] = []
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var errorSuggestion: String?
    @Published var config: AppConfig = AppConfig.load()
    @Published var lastSourceText: String = ""
    @Published var lastSourceIsChinese: Bool = false
    private var lastRequest: LastRequest?

    private let llm = LLMService()
    private var activeProvider: LLMProvider = .gemini
    let speech = SpeechService()
    private let history = HistoryStore()

    @Published var isTestingConnection: Bool = false
    @Published var connectionTestMessage: String?

    init() {
        config.applyProviderDefaultsIfNeeded()
        activeProvider = config.provider

        // Prefer per-provider settings if present.
        if let setting = config.providerSettings[config.provider.rawValue] {
            let sanitized = setting.sanitized(for: config.provider)
            config.baseURL = sanitized.baseURL
            config.model = sanitized.model
            config.apiKey = sanitized.apiKey
            config.providerSettings[config.provider.rawValue] = sanitized
        } else {
            config.providerSettings[config.provider.rawValue] = ProviderSetting(
                baseURL: config.baseURL,
                model: config.model,
                apiKey: config.apiKey
            ).sanitized(for: config.provider)
        }

        config.save()
    }

    var buildInfo: String {
        "Thought2English • \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")"
    }

    var canRetryLastRequest: Bool {
        lastRequest != nil
    }

    func clearAll() {
        inputText = ""
        spokenText = ""
        formalText = ""
        notes = []
        errorMessage = nil
        errorSuggestion = nil
    }

    // MARK: - Config setters (avoid in-place mutation of @Published structs)

    func setProvider(_ newProvider: LLMProvider) {
        guard newProvider != activeProvider else { return }

        let previousProvider = activeProvider
        activeProvider = newProvider
        connectionTestMessage = nil

        updateConfig { config in
            config.providerSettings[previousProvider.rawValue] = ProviderSetting(
                baseURL: config.baseURL,
                model: config.model,
                apiKey: config.apiKey
            ).sanitized(for: previousProvider)

            config.provider = newProvider

            let next = (config.providerSettings[newProvider.rawValue] ?? ProviderSetting(
                baseURL: newProvider.defaultBaseURL,
                model: newProvider.defaultModel,
                apiKey: ""
            )).sanitized(for: newProvider)

            config.baseURL = next.baseURL
            config.model = next.model
            config.apiKey = next.apiKey
            config.providerSettings[newProvider.rawValue] = next
        }
    }

    func setBaseURL(_ value: String) {
        updateConfig { config in
            config.baseURL = value
            config.providerSettings[activeProvider.rawValue] = ProviderSetting(
                baseURL: config.baseURL,
                model: config.model,
                apiKey: config.apiKey
            ).sanitized(for: activeProvider)
        }
    }

    func setModel(_ value: String) {
        updateConfig { config in
            config.model = value
            config.providerSettings[activeProvider.rawValue] = ProviderSetting(
                baseURL: config.baseURL,
                model: config.model,
                apiKey: config.apiKey
            ).sanitized(for: activeProvider)
        }
    }

    func setApiKey(_ value: String) {
        updateConfig { config in
            config.apiKey = value
            config.providerSettings[activeProvider.rawValue] = ProviderSetting(
                baseURL: config.baseURL,
                model: config.model,
                apiKey: config.apiKey
            ).sanitized(for: activeProvider)
        }
    }

    func setDomains(_ value: Set<Domain>) {
        updateConfig { $0.domains = value }
    }

    func setJargonLevel(_ value: Int) {
        updateConfig { $0.jargonLevel = (value <= 0) ? 0 : 1 }
    }

    func setVoiceStyle(_ value: VoiceStyle) {
        updateConfig { $0.voiceStyle = value }
    }

    func setShowNotes(_ value: Bool) {
        updateConfig { $0.showNotes = value }
    }

    func setGlossaryText(_ value: String) {
        updateConfig { $0.glossaryText = value }
    }

    func pasteFromClipboard() {
        if let content = NSPasteboard.general.string(forType: .string) {
            inputText = content
        }
    }

    func copySpoken() {
        copyToClipboard(spokenText)
    }

    func copyFormal() {
        copyToClipboard(formalText)
    }

    func toggleSpeakSpoken() {
        speech.toggleSpeak(target: .spoken, text: spokenText)
    }

    func toggleSpeakFormal() {
        speech.toggleSpeak(target: .formal, text: formalText)
    }

    func copyToClipboard(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)
    }

    func generate() {
        generate(mode: nil)
    }

    func generate(mode overrideMode: GenerateMode?) {
        guard !isGenerating else { return }
        errorMessage = nil
        errorSuggestion = nil
        spokenText = ""
        formalText = ""
        notes = []

        if let overrideMode {
            setGenerateMode(overrideMode)
        }

        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Input is empty."
            return
        }
        lastSourceText = input
        lastSourceIsChinese = LanguageDetect.containsChineseCharacters(input)

        let apiKey = config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            errorMessage = "Missing API key."
            errorSuggestion = "Paste your provider API key in Settings."
            return
        }

        isGenerating = true
        lastRequest = LastRequest(
            input: input,
            provider: config.provider,
            baseURL: config.baseURL,
            model: config.model,
            apiKey: apiKey,
            config: config
        )

        Task {
            defer { isGenerating = false }
            do {
                let prompt = PromptBuilder.build(for: input, config: config)
                let raw = try await llm.generate(
                    provider: config.provider,
                    baseURL: config.baseURL,
                    model: config.model,
                    apiKey: apiKey,
                    system: prompt.system,
                    user: prompt.user
                )
                var parsed = OutputParser.parse(rawText: raw)

                // If the model ignored the requested mode (common on shorter token budgets),
                // do a one-time follow-up to fetch the missing section(s) when mode == both.
                if config.generateMode == .both {
                    if parsed.formal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let follow = PromptBuilder.buildMissingSection(for: input, config: config, missing: .formal)
                        let raw2 = try await llm.generate(
                            provider: config.provider,
                            baseURL: config.baseURL,
                            model: config.model,
                            apiKey: apiKey,
                            system: follow.system,
                            user: follow.user
                        )
                        let parsed2 = OutputParser.parse(rawText: raw2)
                        if !parsed2.formal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            parsed = ParsedOutput(spoken: parsed.spoken, formal: parsed2.formal, notes: parsed.notes)
                        }
                    }
                    if parsed.spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let follow = PromptBuilder.buildMissingSection(for: input, config: config, missing: .spoken)
                        let raw2 = try await llm.generate(
                            provider: config.provider,
                            baseURL: config.baseURL,
                            model: config.model,
                            apiKey: apiKey,
                            system: follow.system,
                            user: follow.user
                        )
                        let parsed2 = OutputParser.parse(rawText: raw2)
                        if !parsed2.spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            parsed = ParsedOutput(spoken: parsed2.spoken, formal: parsed.formal, notes: parsed.notes)
                        }
                    }
                }

                spokenText = parsed.spoken
                formalText = parsed.formal
                notes = parsed.notes

                history.add(HistoryEntry(
                    id: UUID().uuidString,
                    createdAt: Date(),
                    provider: config.provider,
                    model: config.model,
                    input: input,
                    spoken: spokenText,
                    formal: formalText,
                    domains: Array(config.domains).sorted { $0.rawValue < $1.rawValue },
                    jargonLevel: config.jargonLevel,
                    voiceStyle: config.voiceStyle
                ))
            } catch {
                apply(error: error)
            }
        }
    }

    func setGenerateMode(_ mode: GenerateMode) {
        updateConfig { $0.generateMode = mode }
    }

    func retryLast() {
        guard let lastRequest else { return }
        guard !isGenerating else { return }

        updateConfig { config in
            config.provider = lastRequest.provider
            config.baseURL = lastRequest.baseURL
            config.model = lastRequest.model
            config.apiKey = lastRequest.apiKey
            config.domains = lastRequest.config.domains
            config.jargonLevel = lastRequest.config.jargonLevel
            config.voiceStyle = lastRequest.config.voiceStyle
            config.glossaryText = lastRequest.config.glossaryText
            config.generateMode = lastRequest.config.generateMode
        }
        generate(mode: nil)
    }

    func loadHistory(limit: Int = 50, completion: @escaping @Sendable ([HistoryEntry]) -> Void) {
        history.list(limit: limit, completion: completion)
    }

    func searchHistory(_ query: String, limit: Int = 50, completion: @escaping @Sendable ([HistoryEntry]) -> Void) {
        history.search(query: query, limit: limit, completion: completion)
    }

    func deleteHistoryEntry(id: String, completion: (@Sendable () -> Void)? = nil) {
        history.delete(id: id, completion: completion)
    }

    func testConnection() {
        guard !isTestingConnection else { return }
        connectionTestMessage = nil

        let apiKey = config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            connectionTestMessage = "Missing API key."
            return
        }

        let provider = config.provider
        let baseURL = config.baseURL
        let model = config.model

        isTestingConnection = true
        Task {
            defer { isTestingConnection = false }
            do {
                let raw = try await llm.generate(
                    provider: provider,
                    baseURL: baseURL,
                    model: model,
                    apiKey: apiKey,
                    system: "You are a connectivity test endpoint.",
                    user: "Reply with exactly: OK"
                )
                if raw.uppercased().contains("OK") {
                    connectionTestMessage = "Connection OK."
                } else {
                    connectionTestMessage = "Connected, but got unexpected reply."
                }
            } catch {
                connectionTestMessage = (error as? LocalizedError)?.errorDescription ?? "Connection failed."
            }
        }
    }
}

private struct LastRequest {
    let input: String
    let provider: LLMProvider
    let baseURL: String
    let model: String
    let apiKey: String
    let config: AppConfig
}

private extension AppViewModel {
    func updateConfig(_ block: (inout AppConfig) -> Void) {
        var copy = config
        block(&copy)
        config = copy
        config.save()
    }

    func apply(error: Error) {
        if let llmError = error as? LLMError {
            errorMessage = llmError.errorDescription ?? "Request failed."
            errorSuggestion = suggestion(for: llmError)
            return
        }
        errorMessage = (error as? LocalizedError)?.errorDescription ?? "Request failed."
        errorSuggestion = nil
    }

    func suggestion(for error: LLMError) -> String? {
        switch error {
        case .invalidBaseURL:
            return "Check Base URL in Settings."
        case .badHTTPStatus(let code, _):
            switch code {
            case 401, 403:
                return "API key may be invalid or missing permissions."
            case 404:
                return "Model may be wrong. Check the model name for the selected provider."
            case 429:
                return "Rate limited. Try again later or switch to a lighter model."
            case 503:
                return "Provider is busy/unavailable. Try again later or switch models."
            default:
                return "Check your network, Base URL, and provider status."
            }
        case .emptyResponse:
            return "Try again. If it repeats, switch models."
        case .decodingFailed:
            return "Provider response format changed. Try again or switch models."
        }
    }
}
