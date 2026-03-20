import SwiftUI

struct ResultView: View {
    let outcome: StageOutcome
    let onContinue: () -> Void

    @State private var starsVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                QuestSectionHeader(
                    eyebrow: outcome.passed ? "Stage Cleared" : "Stage Review",
                    title: outcome.passed ? "You held up under pressure" : "There was value left on the table",
                    subtitle: outcome.passed ? "Strong execution across the replay." : "Review the gap, then apply the lesson on the next run."
                )

                VStack(spacing: 18) {
                    HStack {
                        QuestChip(
                            text: outcome.passed ? "Passed" : "Needs Work",
                            accent: outcome.passed ? AppTheme.success : AppTheme.highlight
                        )
                        Spacer(minLength: 0)
                        QuestStatPill(label: "Score", value: "\(outcome.score)", accent: AppTheme.accent)
                    }

                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { star in
                            Image(systemName: star <= outcome.starRating ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundStyle(star <= outcome.starRating ? AppTheme.highlight : AppTheme.textMuted)
                                .scaleEffect(starsVisible ? 1 : 0.4)
                                .animation(
                                    .spring(response: 0.42, dampingFraction: 0.62).delay(Double(star) * 0.12),
                                    value: starsVisible
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(outcome.starRating) out of 3 stars")

                    Text(outcomeSummary)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .questCard(fill: AppTheme.surface.opacity(0.84))
                .onAppear {
                    starsVisible = true
                    if outcome.starRating == 3 {
                        HapticFeedbackService.shared.fireAchievement()
                    } else if outcome.starRating == 1 {
                        HapticFeedbackService.shared.fireLossWarning()
                    } else {
                        HapticFeedbackService.shared.fireMilestone()
                    }
                }

                HStack(spacing: 14) {
                    QuestMetricCard(
                        label: "Your Portfolio",
                        value: "₩\(Int(outcome.portfolioFinalValue).formatted())",
                        detail: "Final value after replay",
                        accent: AppTheme.accent
                    )
                    QuestMetricCard(
                        label: "Optimal Play",
                        value: "₩\(Int(outcome.optimalFinalValue).formatted())",
                        detail: "Best modeled decision path",
                        accent: AppTheme.highlight
                    )
                }

                if let replayStats = outcome.replayStats {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Replay Distribution")
                            .font(.system(.headline, design: .rounded).weight(.semibold))

                        HStack(spacing: 14) {
                            QuestMetricCard(label: "Low", value: "₩\(Int(replayStats.minimum).formatted())", detail: "Worst replay", accent: AppTheme.danger)
                            QuestMetricCard(label: "Median", value: "₩\(Int(replayStats.median).formatted())", detail: "Middle replay", accent: AppTheme.accent)
                            QuestMetricCard(label: "High", value: "₩\(Int(replayStats.maximum).formatted())", detail: "Best replay", accent: AppTheme.success)
                        }
                    }
                    .questCard(fill: AppTheme.surface.opacity(0.84))
                }

                QuestInfoBanner(
                    icon: outcome.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    title: outcome.passed ? "Stage cleared" : "Performance gap",
                    message: outcome.passed ? "Your choice stayed resilient across the simulation." : "You finished \(String(format: "%.1f", optimalGapPercent))% below the modeled optimum.",
                    accent: outcome.passed ? AppTheme.success : AppTheme.highlight
                )

                if !outcome.biasTags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bias Signals")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                        WrapChipsView(tags: outcome.biasTags)
                    }
                    .questCard(fill: AppTheme.surface.opacity(0.72))
                }

                Button(action: onContinue) {
                    Text("See Insight")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .accessibilityIdentifier("see-insight")
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityIdentifier("stage-result")
    }

    private var optimalGapPercent: Double {
        guard outcome.optimalFinalValue > 0 else { return 0 }
        return abs(outcome.portfolioFinalValue - outcome.optimalFinalValue) / outcome.optimalFinalValue * 100
    }

    private var outcomeSummary: String {
        outcome.passed
            ? "You captured enough of the modeled upside to clear the stage."
            : "The replay shows that a stronger allocation or decision path was available."
    }
}

private struct WrapChipsView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunkedTags, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { tag in
                        QuestChip(text: tag.replacingOccurrences(of: "-", with: " "), accent: AppTheme.highlight)
                    }
                }
            }
        }
    }

    private var chunkedTags: [[String]] {
        stride(from: 0, to: tags.count, by: 2).map { index in
            Array(tags[index..<min(index + 2, tags.count)])
        }
    }
}
