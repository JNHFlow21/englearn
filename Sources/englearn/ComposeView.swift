import SwiftUI

struct ComposeView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var compareTarget: SpeechTarget?

    var body: some View {
        ScrollView {
            PageContainer(title: "Write") {
                VStack(spacing: 12) {
                    Card(title: "Draft", systemImage: "square.and.pencil") {
                        VStack(spacing: Theme.sectionSpacing) {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                    .fill(.quaternary.opacity(0.25))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                                    }

                                TextEditor(text: $viewModel.inputText)
                                    .font(.system(.body, design: .monospaced))
                                    .scrollContentBackground(.hidden)
                                    .padding(6)

                                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Write in English (fix & polish) or Chinese (translate)…")
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: 200)

                            HStack(alignment: .center, spacing: 12) {
                                Button("Paste") { viewModel.pasteFromClipboard() }
                                Button("Clear") { viewModel.clearAll() }
                                Spacer()
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
                            }

                            ViewThatFits(in: .horizontal) {
                                controlsWide
                                controlsCompact
                            }

                            Text("Jargon: 0 = simple • 1 = light industry terms • 2 = natural finance/Web3/AI tone • 3 = heaviest (still accurate)")
                                .foregroundStyle(.secondary)
                                .font(.footnote)

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
                                .padding(.top, 2)
                            }
                        }
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
                        Card(title: "Notes", systemImage: "sparkles") {
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
            }
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

    private var controlsWide: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            FieldLabel("Domains") {
                DomainsMenuPicker(selection: Binding(
                    get: { viewModel.config.domains },
                    set: { viewModel.setDomains($0) }
                ))
            }

            FieldLabel("Jargon") {
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
                .frame(width: 170, alignment: .leading)
            }

            Spacer(minLength: 0)

            FieldLabel("Output") {
                Picker("", selection: Binding(
                    get: { viewModel.config.generateMode },
                    set: { viewModel.setGenerateMode($0) }
                )) {
                    ForEach(GenerateMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 210, idealWidth: 240, maxWidth: 320)
            }
        }
    }

    private var controlsCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                FieldLabel("Domains") {
                    DomainsMenuPicker(selection: Binding(
                        get: { viewModel.config.domains },
                        set: { viewModel.setDomains($0) }
                    ))
                }

                FieldLabel("Jargon") {
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
                    .frame(width: 170, alignment: .leading)
                }
            }

            FieldLabel("Output") {
                Picker("", selection: Binding(
                    get: { viewModel.config.generateMode },
                    set: { viewModel.setGenerateMode($0) }
                )) {
                    ForEach(GenerateMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180, alignment: .leading)
            }
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
        Card(
            title: title,
            systemImage: target == .spoken ? "quote.bubble" : "doc.text",
            trailing: AnyView(trailingButtons)
        ) {
            Text(text.isEmpty ? "—" : text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.vertical, 2)
        }
    }

    private var isSpeaking: Bool {
        speech.isSpeaking && speech.currentTarget == target
    }

    private var trailingButtons: some View {
        HStack(spacing: 8) {
            if canCompare {
                Button("Compare") { compareAction() }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Button(isSpeaking ? "Stop" : "Speak") { speakAction() }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Copy") { copyAction() }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
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

private struct FieldLabel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 62, alignment: .leading)
            content
        }
    }
}
