import SwiftUI

struct ResultView: View {
    let outcome: StageOutcome
    let onContinue: () -> Void

    @State private var starsVisible: Bool = false

    private var isGain: Bool { outcome.portfolioFinalValue >= 100.0 }

    var body: some View {
        VStack(spacing: 24) {
            Text("Result")
                .font(.title2.bold())

            // Star rating — animated reveal
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { star in
                    Image(systemName: star <= outcome.starRating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundStyle(star <= outcome.starRating ? .yellow : .gray)
                        .scaleEffect(starsVisible ? 1.0 : 0.4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(Double(star) * 0.12),
                                   value: starsVisible)
                }
            }
            .accessibilityLabel("\(outcome.starRating) out of 3 stars")
            .onAppear {
                starsVisible = true
                // Haptic feedback: rewarding for high score, consequential for low
                if outcome.starRating == 3 {
                    HapticFeedbackService.shared.fireAchievement()
                } else if outcome.starRating == 1 {
                    HapticFeedbackService.shared.fireLossWarning()
                } else {
                    HapticFeedbackService.shared.fireMilestone()
                }
            }

            // Gain/loss
            let gain = outcome.portfolioFinalValue - 100.0 * (outcome.portfolioFinalValue > 0 ? 1 : 1)
            let gainVsStart = outcome.portfolioFinalValue - (outcome.optimalFinalValue > 0 ? 100.0 : 100.0)
            VStack(spacing: 8) {
                resultRow(label: "Your Portfolio",
                          value: "₩\(Int(outcome.portfolioFinalValue).formatted())",
                          highlight: false)
                resultRow(label: "Optimal Play",
                          value: "₩\(Int(outcome.optimalFinalValue).formatted())",
                          highlight: false)
                resultRow(label: "Score",
                          value: "\(outcome.score)",
                          highlight: true)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            // Comparison commentary
            let diff = outcome.portfolioFinalValue - outcome.optimalFinalValue
            let pct = outcome.optimalFinalValue > 0 ? abs(diff) / outcome.optimalFinalValue * 100 : 0
            if diff >= -0.5 {
                Label("Excellent! Near-optimal play.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("You were \(String(format: "%.1f", pct))% below optimal play.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onContinue) {
                Text("See Insight")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }

    private func resultRow(label: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(highlight ? .primary : .secondary)
            Spacer()
            Text(value)
                .fontWeight(highlight ? .bold : .regular)
                .monospacedDigit()
        }
    }
}
