import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    @State private var savedHint: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Provider") {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Provider", selection: Binding(
                            get: { viewModel.config.provider },
                            set: { viewModel.setProvider($0) }
                        )) {
                            ForEach(LLMProvider.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                        .pickerStyle(.segmented)

                        LabeledContent("Model") {
                            TextField("", text: Binding(
                                get: { viewModel.config.model },
                                set: { viewModel.setModel($0) }
                            ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 360)
                        }

                        LabeledContent("Base URL") {
                            TextField("", text: Binding(
                                get: { viewModel.config.baseURL },
                                set: { viewModel.setBaseURL($0) }
                            ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 360)
                        }
                        Text("Gemini Base URL: https://generativelanguage.googleapis.com • DeepSeek Base URL: https://api.deepseek.com")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("API Key") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Paste API Key…", text: Binding(
                            get: { viewModel.config.apiKey },
                            set: { viewModel.setApiKey($0) }
                        ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        Text("Stored in app preferences (plain text). If you want stronger protection, we can add Keychain back later.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)

                        HStack {
                            Button("Clear Key") {
                                viewModel.setApiKey("")
                                savedHint = "Cleared."
                            }
                            Button {
                                viewModel.testConnection()
                            } label: {
                                if viewModel.isTestingConnection {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Test Connection")
                                }
                            }
                            .disabled(viewModel.isTestingConnection)
                            Spacer()
                        }
                        if let savedHint {
                            Text(savedHint)
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        if let message = viewModel.connectionTestMessage {
                            Text(message)
                                .foregroundStyle(.secondary)
                                .foregroundColor(message == "Connection OK." ? .secondary : .red)
                                .font(.footnote)
                        }
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your text is only sent to the provider you choose when you press Generate/Test Connection. API keys are stored locally (plain text). History is stored locally in a SQLite file.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Style") {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Spoken Voice") {
                            Picker("", selection: Binding(
                                get: { viewModel.config.voiceStyle },
                                set: { viewModel.setVoiceStyle($0) }
                            )) {
                                ForEach(VoiceStyle.allCases) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 360)
                        }

                        Toggle("Show notes (learning feedback)", isOn: Binding(
                            get: { viewModel.config.showNotes },
                            set: { viewModel.setShowNotes($0) }
                        ))
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Glossary (optional)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One term per line, e.g. `MiCA = EU Markets in Crypto-Assets Regulation (MiCA)`.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                        TextEditor(text: Binding(
                            get: { viewModel.config.glossaryText },
                            set: { viewModel.setGlossaryText($0) }
                        ))
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 160)
                            .overlay(alignment: .topLeading) {
                                if viewModel.config.glossaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Clarity Act = U.S. crypto market structure / regulatory clarity bill\nMiCA = EU Markets in Crypto-Assets Regulation (MiCA)")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }

                HStack {
                    Button("Quit") { NSApp.terminate(nil) }
                    Spacer()
                    Text(viewModel.buildInfo)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .onChange(of: viewModel.config.provider) { _ in
            savedHint = nil
        }
        .onAppear {
            savedHint = nil
        }
    }
}
