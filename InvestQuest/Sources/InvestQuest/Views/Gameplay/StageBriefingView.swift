import SwiftUI

struct StageBriefingView: View {
    let definition: StageDefinition
    let onStart: () -> Void
    @ObservedObject var viewModel: StageViewModel

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
            let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
            let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Phase \(definition.phase) · Stage \(definition.stage)".ko)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    QuestSectionHeader(
                        eyebrow: "Stage Setup",
                        title: definition.scenarioTitle,
                        subtitle: "Read the setup, find the signal, and commit to your move."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        stageMetaRow

                        Text(definition.scenarioDescription.ko)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .questCard()

                    VStack(alignment: .leading, spacing: 14) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                infoIcon
                                watchCopy
                                Spacer(minLength: 0)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                infoIcon
                                watchCopy
                            }
                        }

                        Text(viewModel.definitionConceptText.ko)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(AppTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
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
                        Text("Start Stage".ko)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle())
                    .accessibilityIdentifier("start-stage")
                }
                .questReadableContentFrame(in: geometry.size.width, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .scrollClipDisabled()
            .foregroundStyle(AppTheme.textPrimary)
            .accessibilityIdentifier("stage-briefing")
        }
    }

    private var shortConcept: String {
        PhaseConfig.all.first(where: { $0.id == definition.phase })?.concept ?? "Lesson"
    }

    private var stageMetaRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                QuestChip(text: shortConcept, accent: AppTheme.accent)
                QuestChip(text: "Pass \(definition.minimumPassingScore)+", accent: AppTheme.highlight)
                if definition.timeoutSeconds > 0 {
                    QuestChip(text: "\(Int(definition.timeoutSeconds))s timer", accent: AppTheme.surfaceInteractive)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    QuestChip(text: shortConcept, accent: AppTheme.accent)
                    QuestChip(text: "Pass \(definition.minimumPassingScore)+", accent: AppTheme.highlight)
                }
                if definition.timeoutSeconds > 0 {
                    QuestChip(text: "\(Int(definition.timeoutSeconds))s timer", accent: AppTheme.surfaceInteractive)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                QuestChip(text: shortConcept, accent: AppTheme.accent)
                QuestChip(text: "Pass \(definition.minimumPassingScore)+", accent: AppTheme.highlight)
                if definition.timeoutSeconds > 0 {
                    QuestChip(text: "\(Int(definition.timeoutSeconds))s timer", accent: AppTheme.surfaceInteractive)
                }
            }
        }
    }

    private var infoIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent.opacity(0.12))
                .frame(width: 48, height: 48)
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private var watchCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What to watch".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(viewModel.definitionHintText.ko)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
