import SwiftUI

struct ComposeView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var compareTarget: SpeechTarget?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                GroupBox {
                    VStack(spacing: 10) {
                        TextEditor(text: $viewModel.inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 180)
                            .overlay {
                                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Write in English (fix & polish) or Chinese (translate)…")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .allowsHitTesting(false)
                                }
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            LabeledContent("Domains") {
                                DomainsMenuPicker(selection: Binding(
                                    get: { viewModel.config.domains },
                                    set: { viewModel.setDomains($0) }
                                ))
                            }

                            LabeledContent("Jargon") {
                                Picker("", selection: Binding(
                                    get: { viewModel.config.jargonLevel },
                                    set: { viewModel.setJargonLevel($0) }
                                )) {
                                    Text("0 Plain").tag(0)
                                    Text("1 Light").tag(1)
                                    Text("2 Native").tag(2)
                                    Text("3 Heavy").tag(3)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 180, alignment: .leading)
                            }

                            Text("0 = simple • 1 = light industry terms • 2 = natural finance/Web3/AI tone • 3 = heaviest (still accurate)")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center, spacing: 12) {
                            HStack(spacing: 10) {
                                Button("Paste") { viewModel.pasteFromClipboard() }
                                Button("Clear") { viewModel.clearAll() }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Text("Output")
                                    .foregroundStyle(.secondary)
                                Picker("", selection: Binding(
                                    get: { viewModel.config.generateMode },
                                    set: { viewModel.setGenerateMode($0) }
                                )) {
                                    ForEach(GenerateMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 240)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            Button {
                                viewModel.generate()
                            } label: {
                                if viewModel.isGenerating {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Generate")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                            .disabled(viewModel.isGenerating)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(3)
                                if let suggestion = viewModel.errorSuggestion {
                                    Text(suggestion)
                                        .foregroundStyle(.secondary)
                                        .font(.footnote)
                                }
                                HStack {
                                    Button("Retry") { viewModel.retryLast() }
                                        .disabled(!viewModel.canRetryLastRequest || viewModel.isGenerating)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    Text("Input")
                        .font(.headline)
                }

                OutputSectionView(
                    title: "Spoken Script",
                    text: viewModel.spokenText,
                    copyAction: viewModel.copySpoken,
                    speakAction: viewModel.toggleSpeakSpoken,
                    speech: viewModel.speech,
                    target: .spoken,
                    canCompare: !viewModel.lastSourceIsChinese && !viewModel.lastSourceText.isEmpty,
                    compareAction: { compareTarget = .spoken }
                )

                OutputSectionView(
                    title: "Formal Writing",
                    text: viewModel.formalText,
                    copyAction: viewModel.copyFormal,
                    speakAction: viewModel.toggleSpeakFormal,
                    speech: viewModel.speech,
                    target: .formal,
                    canCompare: !viewModel.lastSourceIsChinese && !viewModel.lastSourceText.isEmpty,
                    compareAction: { compareTarget = .formal }
                )

                if viewModel.config.showNotes, !viewModel.notes.isEmpty {
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.notes, id: \.self) { note in
                                Text("• \(note)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .sheet(item: Binding(
            get: { compareTarget.map(CompareTarget.init) },
            set: { newValue in compareTarget = newValue?.target }
        )) { item in
            let revised = item.target == .spoken ? viewModel.spokenText : viewModel.formalText
            CompareView(
                title: item.target == .spoken ? "Compare: Spoken Script" : "Compare: Formal Writing",
                original: viewModel.lastSourceText,
                revised: revised
            )
        }
    }
}

private struct OutputSectionView: View {
    let title: String
    let text: String
    let copyAction: () -> Void
    let speakAction: () -> Void
    @ObservedObject var speech: SpeechService
    let target: SpeechTarget
    let canCompare: Bool
    let compareAction: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if canCompare {
                        Button("Compare") { compareAction() }
                            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Button(isSpeaking ? "Stop" : "Speak") { speakAction() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Copy") { copyAction() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Text(text.isEmpty ? "—" : text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.vertical, 2)
            }
        }
    }

    private var isSpeaking: Bool {
        speech.isSpeaking && speech.currentTarget == target
    }
}

private struct CompareTarget: Identifiable {
    let target: SpeechTarget
    var id: String { target.rawValue }
}

private struct DomainsMenuPicker: View {
    @Binding var selection: Set<Domain>

    var body: some View {
        Menu {
            ForEach(Domain.allCases) { domain in
                Toggle(domain.displayName, isOn: Binding(
                    get: { selection.contains(domain) },
                    set: { isOn in
                        if isOn { selection.insert(domain) } else { selection.remove(domain) }
                    }
                ))
            }
            Divider()
            Button("Select all") { selection = Set(Domain.allCases) }
            Button("Clear") { selection.removeAll() }
        } label: {
            HStack(spacing: 6) {
                Text(selectionSummary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 260, alignment: .leading)
        }
    }

    private var selectionSummary: String {
        let names = selection.map(\.displayName).sorted()
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }
}
