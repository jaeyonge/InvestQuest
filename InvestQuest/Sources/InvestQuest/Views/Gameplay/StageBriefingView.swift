import SwiftUI

struct StageBriefingView: View {
    let definition: StageDefinition
    let onStart: () -> Void
    @ObservedObject var viewModel: StageViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Phase \(definition.phase) · Stage \(definition.stage)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)

                QuestSectionHeader(
                    eyebrow: "Stage Setup",
                    title: definition.scenarioTitle,
                    subtitle: "Read the setup, find the signal, and commit to your move."
                )

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        QuestChip(text: shortConcept, accent: AppTheme.accent)
                        QuestChip(text: "Pass \(definition.minimumPassingScore)+", accent: AppTheme.highlight)
                        if definition.timeoutSeconds > 0 {
                            QuestChip(text: "\(Int(definition.timeoutSeconds))s timer", accent: AppTheme.surfaceInteractive)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(definition.scenarioDescription)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .questCard()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("What to watch")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(viewModel.definitionHintText)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Text(viewModel.definitionConceptText)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .questCard(fill: AppTheme.surface.opacity(0.82))

                if let hint = viewModel.hintForCurrentFailures {
                    QuestInfoBanner(
                        icon: viewModel.failureCount >= 5 ? "lightbulb.max.fill" : "lightbulb",
                        title: viewModel.failureCount >= 5 ? "Concept unlocked" : "Hint unlocked",
                        message: hint,
                        accent: AppTheme.highlight
                    )
                }

                Button(action: onStart) {
                    Text("Start Stage")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuestPrimaryButtonStyle())
                .accessibilityIdentifier("start-stage")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityIdentifier("stage-briefing")
    }

    private var shortConcept: String {
        PhaseConfig.all.first(where: { $0.id == definition.phase })?.concept ?? "Lesson"
    }
}
