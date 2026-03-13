import SwiftUI

/// Brief animated intro shown on first launch.
/// Target: user sees the message and can start playing within 30 seconds.
struct IntroAnimationView: View {

    static let introDurationSeconds: Double = 4.0  // animation auto-advances after this
    static let introMessage = "Your money is disappearing."
    static let introSubtitle = "Let's find out why."

    let onComplete: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var coinScale: CGFloat = 0.3
    @State private var coinOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Shrinking coin animation
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                    .scaleEffect(coinScale)
                    .opacity(coinOpacity)

                VStack(spacing: 12) {
                    Text(Self.introMessage)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(titleOpacity)

                    Text(Self.introSubtitle)
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: onComplete) {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .opacity(buttonOpacity)
                .padding(.bottom, 40)
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
        // Coin shrinks (represents losing value)
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
        // Auto-advance after introDurationSeconds
        Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.introDurationSeconds * 1_000_000_000))
            onComplete()
        }
    }
}
