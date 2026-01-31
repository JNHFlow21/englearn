import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 14
}

struct Card<Content: View>: View {
    let title: String
    let systemImage: String?
    let trailing: AnyView?
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String? = nil,
        trailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.headline)
                Spacer()
                if let trailing {
                    trailing
                }
            }

            content
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

