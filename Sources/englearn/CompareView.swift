import SwiftUI

struct CompareView: View {
    let title: String
    let original: String
    let revised: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }

            HSplitView {
                GroupBox("Original") {
                    ScrollView {
                        Text(original)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(.vertical, 2)
                    }
                }

                GroupBox("Revised (highlights = additions)") {
                    ScrollView {
                        Text(DiffHighlighter.highlightInsertions(original: original, revised: revised))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 520)
    }
}

