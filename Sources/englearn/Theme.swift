import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 14

    enum Metrics {
        static let maxContentWidth: CGFloat = 980
        static let pagePadding: CGFloat = 18
        static let pageVerticalPadding: CGFloat = 16
    }

    enum Fonts {
        static func pageTitle(_ scheme: ColorScheme) -> Font {
            // Light mode: editorial headline (New York-ish via `.serif`).
            // Dark mode: macOS-native SF.
            if scheme == .light {
                return .system(size: 34, weight: .semibold, design: .serif)
            }
            return .system(size: 28, weight: .semibold, design: .default)
        }

        static func cardTitle(_ scheme: ColorScheme) -> Font {
            if scheme == .light {
                return .system(.headline, design: .serif)
            }
            return .headline
        }
    }

    enum Colors {
        static func pageBackground(_ scheme: ColorScheme) -> Color {
            if scheme == .light {
                // Subtle warm paper.
                return Color(red: 0.965, green: 0.955, blue: 0.93)
            }
            return Color(nsColor: .windowBackgroundColor)
        }

        static func cardBackground(_ scheme: ColorScheme) -> AnyShapeStyle {
            if scheme == .light {
                return AnyShapeStyle(Color.white.opacity(0.92))
            }
            return AnyShapeStyle(.regularMaterial)
        }

        static func cardStroke(_ scheme: ColorScheme) -> Color {
            if scheme == .light {
                return Color.black.opacity(0.08)
            }
            return Color.primary.opacity(0.08)
        }

        static func cardShadow(_ scheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            if scheme == .light {
                return (Color.black.opacity(0.08), 14, 7)
            }
            return (Color.black.opacity(0.12), 18, 10)
        }
    }
}

struct Card<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

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
                    .font(Theme.Fonts.cardTitle(colorScheme))
                Spacer()
                if let trailing {
                    trailing
                }
            }

            content
        }
        .padding(Theme.cardPadding)
        .background(
            Theme.Colors.cardBackground(colorScheme),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.Colors.cardStroke(colorScheme), lineWidth: 1)
        }
        .shadow(
            color: Theme.Colors.cardShadow(colorScheme).color,
            radius: Theme.Colors.cardShadow(colorScheme).radius,
            x: 0,
            y: Theme.Colors.cardShadow(colorScheme).y
        )
    }
}

struct PageContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            Text(title)
                .font(Theme.Fonts.pageTitle(colorScheme))
                .padding(.bottom, 2)

            content
        }
        .frame(maxWidth: Theme.Metrics.maxContentWidth, alignment: .leading)
        .padding(.horizontal, Theme.Metrics.pagePadding)
        .padding(.vertical, Theme.Metrics.pageVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Theme.Colors.pageBackground(colorScheme))
    }
}
