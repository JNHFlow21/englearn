import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    @State private var query: String = ""
    @State private var entries: [HistoryEntry] = []
    @State private var selectedId: String?

    private var selectedEntry: HistoryEntry? {
        entries.first { $0.id == selectedId }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("Search history…", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button("Clear") { query = "" }
                    .disabled(query.isEmpty)
                Spacer()
                Button("Refresh") { reload() }
            }
            .padding()

            Divider()

            HSplitView {
                List(selection: $selectedId) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.createdAt, style: .date)
                                Text(entry.createdAt, style: .time)
                                Spacer()
                                Text(entry.provider.displayName)
                                    .foregroundStyle(.secondary)
                            }
                            Text(snippet(entry.input))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .tag(entry.id)
                        .contextMenu {
                            Button("Delete") { delete(entry) }
                        }
                    }
                }
                .frame(minWidth: 280, idealWidth: 320)

                if let selectedEntry {
                    HistoryDetailView(entry: selectedEntry)
                        .frame(minWidth: 520, idealWidth: 700)
                } else {
                    VStack {
                        Text("Select an item")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear { reload() }
        .onChange(of: query) { _ in reload() }
    }

    private func reload() {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.loadHistory { items in
                Task { @MainActor in
                    entries = items
                    if selectedId == nil { selectedId = items.first?.id }
                }
            }
        } else {
            viewModel.searchHistory(query) { items in
                Task { @MainActor in
                    entries = items
                    if selectedId == nil { selectedId = items.first?.id }
                }
            }
        }
    }

    private func delete(_ entry: HistoryEntry) {
        viewModel.deleteHistoryEntry(id: entry.id) {
            Task { @MainActor in
                if selectedId == entry.id { selectedId = nil }
                reload()
            }
        }
    }

    private func snippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 140 { return trimmed }
        return trimmed.prefix(140) + "…"
    }
}

private struct HistoryDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let entry: HistoryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(entry.createdAt, style: .date)
                    Text(entry.createdAt, style: .time)
                    Spacer()
                    Text("\(entry.provider.displayName) • \(entry.model)")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button("Load into editor") {
                        viewModel.inputText = entry.input
                        viewModel.spokenText = entry.spoken
                        viewModel.formalText = entry.formal
                    }
                    Spacer()
                    Button("Speak Spoken") { viewModel.speech.toggleSpeak(target: .spoken, text: entry.spoken) }
                        .disabled(entry.spoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Speak Formal") { viewModel.speech.toggleSpeak(target: .formal, text: entry.formal) }
                        .disabled(entry.formal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                GroupBox("Input") {
                    Text(entry.input)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                GroupBox("Spoken Script") {
                    Text(entry.spoken.isEmpty ? "—" : entry.spoken)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                GroupBox("Formal Writing") {
                    Text(entry.formal.isEmpty ? "—" : entry.formal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
    }
}
