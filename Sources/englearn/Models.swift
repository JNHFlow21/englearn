import Foundation

enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case gemini
    case deepseek

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini: "Gemini"
        case .deepseek: "DeepSeek"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .gemini: "https://generativelanguage.googleapis.com"
        case .deepseek: "https://api.deepseek.com"
        }
    }

    var defaultModel: String {
        switch self {
        case .gemini: "gemini-3-flash-preview"
        case .deepseek: "deepseek-chat"
        }
    }
}

enum VoiceStyle: String, Codable, CaseIterable, Identifiable {
    case tradfi
    case cryptotwitter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tradfi: "TradFi / Research"
        case .cryptotwitter: "Crypto Twitter"
        }
    }
}

enum Domain: String, Codable, CaseIterable, Identifiable {
    case life
    case food
    case fitness
    case ai
    case web3
    case reading
    case investing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .life: "Life"
        case .food: "Food"
        case .fitness: "Fitness"
        case .ai: "AI"
        case .web3: "Web3"
        case .reading: "Reading"
        case .investing: "Investing"
        }
    }
}

enum GenerateMode: String, Codable, CaseIterable, Identifiable {
    case both
    case spokenOnly
    case formalOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .both: "Both"
        case .spokenOnly: "Spoken"
        case .formalOnly: "Formal"
        }
    }
}

struct AppConfig: Codable, Equatable {
    var provider: LLMProvider = .gemini
    var baseURL: String = LLMProvider.gemini.defaultBaseURL
    var model: String = LLMProvider.gemini.defaultModel
    var apiKey: String = ""
    var providerSettings: [String: ProviderSetting] = [:]

    var domains: Set<Domain> = [.ai, .web3, .investing]
    var jargonLevel: Int = 2
    var voiceStyle: VoiceStyle = .tradfi
    var showNotes: Bool = false
    var glossaryText: String = ""
    var generateMode: GenerateMode = .both

    private static let defaultsKey = "AppConfig.v1"

    enum CodingKeys: String, CodingKey {
        case provider
        case baseURL
        case model
        case apiKey
        case providerSettings
        case domains
        case jargonLevel
        case voiceStyle
        case showNotes
        case glossaryText
        case generateMode
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decodeIfPresent(LLMProvider.self, forKey: .provider) ?? .gemini
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? provider.defaultBaseURL
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? provider.defaultModel
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        providerSettings = try container.decodeIfPresent([String: ProviderSetting].self, forKey: .providerSettings) ?? [:]

        domains = try container.decodeIfPresent(Set<Domain>.self, forKey: .domains) ?? [.ai, .web3, .investing]
        jargonLevel = try container.decodeIfPresent(Int.self, forKey: .jargonLevel) ?? 2
        voiceStyle = try container.decodeIfPresent(VoiceStyle.self, forKey: .voiceStyle) ?? .tradfi
        showNotes = try container.decodeIfPresent(Bool.self, forKey: .showNotes) ?? false
        glossaryText = try container.decodeIfPresent(String.self, forKey: .glossaryText) ?? ""
        generateMode = try container.decodeIfPresent(GenerateMode.self, forKey: .generateMode) ?? .both
    }

    static func load() -> AppConfig {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode(AppConfig.self, from: data)
        else {
            return AppConfig()
        }
        return decoded.migratedIfNeeded()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func migratedIfNeeded() -> AppConfig {
        var copy = self
        if let setting = copy.providerSettings[copy.provider.rawValue] {
            copy.baseURL = setting.baseURL
            copy.model = setting.model
            copy.apiKey = setting.apiKey
        } else {
            if copy.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                copy.baseURL = copy.provider.defaultBaseURL
            }
            if copy.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                copy.model = copy.provider.defaultModel
            }
            copy.apiKey = copy.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if copy.providerSettings.isEmpty {
            copy.providerSettings[copy.provider.rawValue] = ProviderSetting(baseURL: copy.baseURL, model: copy.model, apiKey: copy.apiKey)
        }
        return copy
    }
}

extension AppConfig {
    mutating func applyProviderDefaultsIfNeeded() {
        if baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseURL = provider.defaultBaseURL
        }
        if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            model = provider.defaultModel
        }
    }
}

struct ProviderSetting: Codable, Equatable {
    var baseURL: String
    var model: String
    var apiKey: String

    enum CodingKeys: String, CodingKey {
        case baseURL
        case model
        case apiKey
    }

    init(baseURL: String, model: String, apiKey: String) {
        self.baseURL = baseURL
        self.model = model
        self.apiKey = apiKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = try container.decode(String.self, forKey: .baseURL)
        model = try container.decode(String.self, forKey: .model)
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
    }
}

extension ProviderSetting {
    func sanitized(for provider: LLMProvider) -> ProviderSetting {
        var copy = self
        copy.baseURL = copy.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.model = copy.model.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.apiKey = copy.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if copy.baseURL.isEmpty { copy.baseURL = provider.defaultBaseURL }
        if copy.model.isEmpty { copy.model = provider.defaultModel }

        // Auto-heal when values are obviously from the other provider (common after earlier bugs).
        if provider == .deepseek {
            if copy.baseURL.contains("googleapis.com") || copy.model.hasPrefix("gemini-") {
                copy.baseURL = provider.defaultBaseURL
                copy.model = provider.defaultModel
            }
        }
        if provider == .gemini {
            if copy.baseURL.contains("deepseek") || copy.model.hasPrefix("deepseek-") {
                copy.baseURL = provider.defaultBaseURL
                copy.model = provider.defaultModel
            }
        }

        return copy
    }
}
