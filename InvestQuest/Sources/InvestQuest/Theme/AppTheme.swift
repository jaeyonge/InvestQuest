import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(hex: "#04070D")
    static let backgroundMid = Color(hex: "#0A1220")
    static let backgroundBottom = Color(hex: "#121C2D")

    static let surface = Color(hex: "#111A29")
    static let surfaceRaised = Color(hex: "#172235")
    static let surfaceInteractive = Color(hex: "#1E2B40")
    static let border = Color.white.opacity(0.10)

    static let accent = Color(hex: "#56D7FF")
    static let accentBright = Color(hex: "#8EF0FF")
    static let accentDeep = Color(hex: "#1A7DFF")
    static let highlight = Color(hex: "#F9B44D")

    static let textPrimary = Color(hex: "#F7FAFF")
    static let textSecondary = Color(hex: "#B5C3DE")
    static let textMuted = Color(hex: "#7E8CAA")

    static let success = Color.investGreen
    static let danger = Color.investRed

    static func contentHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<350:
            22
        case ..<390:
            26
        case ..<430:
            30
        case ..<768:
            38
        default:
            min(max(width * 0.10, 48), 88)
        }
    }

    static func readableContentWidth(for width: CGFloat) -> CGFloat {
        max(0, min(680, width - (contentHorizontalPadding(for: width) * 2)))
    }

    static func chromeHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            22
        case ..<430:
            24
        case ..<768:
            30
        default:
            min(max(width * 0.08, 36), 64)
        }
    }

    static func contentTopPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            24
        case ..<430:
            28
        case ..<768:
            32
        default:
            36
        }
    }

    static func contentBottomPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            40
        case ..<430:
            44
        case ..<768:
            48
        default:
            56
        }
    }
}

struct QuestBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundMid, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.accent.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(x: 156, y: -240)

            Circle()
                .fill(AppTheme.highlight.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -140, y: -170)

            RoundedRectangle(cornerRadius: 52, style: .continuous)
                .fill(AppTheme.accentDeep.opacity(0.09))
                .frame(width: 360, height: 420)
                .rotationEffect(.degrees(-18))
                .offset(x: -190, y: 250)
                .blur(radius: 12)

            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .frame(width: 420, height: 420)
                .rotationEffect(.degrees(12))
                .offset(x: 160, y: 300)
        }
        .ignoresSafeArea()
    }
}

struct QuestCardModifier: ViewModifier {
    var padding: CGFloat
    var fill: Color

    init(padding: CGFloat = 18, fill: Color = AppTheme.surfaceRaised.opacity(0.92)) {
        self.padding = padding
        self.fill = fill
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.26), radius: 16, x: 0, y: 10)
    }
}

struct QuestPrimaryButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppTheme.backgroundTop)
            .lineLimit(3)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: tint.opacity(0.32), radius: 16, x: 0, y: 12)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct QuestSecondaryButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.surfaceInteractive

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.90 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct QuestGlassButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.accent
    var foreground: Color = AppTheme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.08))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [tint.opacity(0.34), Color.white.opacity(0.16)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.08 : 0.14), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct QuestSectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(eyebrow: String, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.ko.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(AppTheme.accent)

            Text(title.ko)
                .font(.system(horizontalSizeClass == .compact ? .title : .largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle.ko)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuestStatPill: View {
    let label: String
    let value: String
    var accent: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.ko.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            Text(value.ko)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accent.opacity(0.22), lineWidth: 1)
                )
        )
    }
}

struct QuestMetricCard: View {
    let label: String
    let value: String
    var detail: String? = nil
    var accent: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(label.ko.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(value.ko)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let detail {
                Text(detail.ko)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .questCard(padding: 16, fill: AppTheme.surface.opacity(0.82))
    }
}

struct QuestInfoBanner: View {
    let icon: String
    let title: String
    let message: String
    var accent: Color = AppTheme.highlight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title.ko)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(message.ko)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .questCard(fill: accent.opacity(0.10))
    }
}

struct QuestChip: View {
    let text: String
    var accent: Color = AppTheme.accent

    var body: some View {
        Text(text.ko)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(0.12))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(accent.opacity(0.20), lineWidth: 1)
                    )
            )
    }
}

struct QuestAdaptiveMetricGrid<Content: View>: View {
    var minimumColumnWidth: CGFloat = 150
    var spacing: CGFloat = 14
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: spacing, alignment: .top)],
            alignment: .leading,
            spacing: spacing
        ) {
            content()
        }
    }
}

extension View {
    func questCard(padding: CGFloat = 18, fill: Color = AppTheme.surfaceRaised.opacity(0.92)) -> some View {
        modifier(QuestCardModifier(padding: padding, fill: fill))
    }

    func questReadableContentFrame(in width: CGFloat, alignment: Alignment = .center) -> some View {
        frame(maxWidth: AppTheme.readableContentWidth(for: width), alignment: alignment)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    func questScreenBackground() -> some View {
        background(QuestBackgroundView())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let investGreen = Color(red: 0.18, green: 0.72, blue: 0.44)
    static let investRed = Color(red: 0.90, green: 0.27, blue: 0.27)
}
