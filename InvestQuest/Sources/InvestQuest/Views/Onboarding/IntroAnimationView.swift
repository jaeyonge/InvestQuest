import SwiftUI

struct IntroAnimationView: View {
    static let introDurationSeconds: Double = 4.0
    static let introMessage = "Your money is disappearing."
    static let introSubtitle = "Let's find out why."

    let onComplete: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var coinScale: CGFloat = 0.3
    @State private var coinOpacity: Double = 0
    @State private var hasCompleted = false

    var body: some View {
        ZStack {
            QuestBackgroundView()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.highlight.opacity(0.16))
                        .frame(width: 150, height: 150)
                        .blur(radius: 6)
                    Circle()
                        .stroke(AppTheme.highlight.opacity(0.30), lineWidth: 1.5)
                        .frame(width: 120, height: 120)
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 78))
                        .foregroundStyle(AppTheme.highlight)
                        .scaleEffect(coinScale)
                        .opacity(coinOpacity)
                }

                VStack(spacing: 14) {
                    Text("INVESTQUEST".ko)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(2.4)
                        .foregroundStyle(AppTheme.accent)

                    Text(Self.introMessage.ko)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(titleOpacity)

                    Text(Self.introSubtitle.ko)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    Text("A playable investing simulation about inflation, valuation, risk, and behavioral bias.".ko)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                        .multilineTextAlignment(.center)

                    Button {
                        guard !hasCompleted else { return }
                        hasCompleted = true
                        onComplete()
                    } label: {
                        Text("Start".ko)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle())
                    .accessibilityIdentifier("intro-start")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .questCard(fill: AppTheme.surface.opacity(0.82))
                .padding(.horizontal, 20)
                .opacity(buttonOpacity)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            animateIntro()
        }
    }

    private func animateIntro() {
        withAnimation(.easeIn(duration: 0.8)) {
            coinOpacity = 1
            coinScale = 1.0
        }
        withAnimation(.easeInOut(duration: 1.2).delay(0.6)) {
            coinScale = 0.5
        }
        withAnimation(.easeIn(duration: 0.6).delay(0.8)) {
            titleOpacity = 1
        }
        withAnimation(.easeIn(duration: 0.6).delay(1.4)) {
            subtitleOpacity = 1
        }
        withAnimation(.easeIn(duration: 0.5).delay(2.0)) {
            buttonOpacity = 1
        }

        Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.introDurationSeconds * 1_000_000_000))
            guard !hasCompleted else { return }
            hasCompleted = true
            onComplete()
        }
    }
}
