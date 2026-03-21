import SwiftUI
import SwiftData

struct PhaseMapView: View {
    @Query private var progressRecords: [GameProgress]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        if let progress = progressRecords.first {
            let service = GameProgressService(modelContext: modelContext, progress: progress)
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        QuestSectionHeader(
                            eyebrow: "Progress Map",
                            title: "InvestQuest",
                            subtitle: "Seven phases. Each lesson unlocks after you prove the last one."
                        )

                        HStack(spacing: 14) {
                            QuestMetricCard(
                                label: "Current Phase",
                                value: "Phase \(service.progress.currentPhase)",
                                detail: "Stage \(service.progress.currentStage)",
                                accent: AppTheme.accent
                            )
                            QuestMetricCard(
                                label: "Completed",
                                value: "\(service.progress.completedPhases.count)/\(PhaseConfig.all.count)",
                                detail: "Phases cleared so far",
                                accent: AppTheme.highlight
                            )
                        }

                        ForEach(PhaseConfig.all) { phase in
                            PhaseNodeView(
                                config: phase,
                                isUnlocked: service.isPhaseUnlocked(phase.id),
                                isCompleted: service.isPhaseCompleted(phase.id),
                                isCurrent: service.progress.currentPhase == phase.id,
                                isStageUnlocked: { stage in
                                    service.isStageUnlocked(phase: phase.id, stage: stage)
                                },
                                isStageCompleted: { stage in
                                    service.completion(for: StageAddress(phase: phase.id, stage: stage))?.isPassed == true
                                },
                                onSelectStage: { stage in
                                    guard service.isStageUnlocked(phase: phase.id, stage: stage) else { return }
                                    appViewModel.openStage(StageAddress(phase: phase.id, stage: stage))
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .navigationTitle("InvestQuest")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
            }
            .questScreenBackground()
        } else {
            ProgressView()
                .tint(AppTheme.accent)
                .task {
                    _ = GameProgressService.loadOrCreateProgress(modelContext: modelContext)
                }
        }
    }
}

struct PhaseNodeView: View {
    let config: PhaseConfig
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let isStageUnlocked: (Int) -> Bool
    let isStageCompleted: (Int) -> Bool
    let onSelectStage: (Int) -> Void

    var body: some View {
        // Outer button makes the phase node an interactive element so XCUITest
        // can check isEnabled (disabled for locked phases). Inner stage buttons
        // intercept taps for their own area; the outer button handles header taps.
        Button {
            if let firstUnlocked = (1...config.stageCount).first(where: { isStageUnlocked($0) }) {
                onSelectStage(firstUnlocked)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(nodeColor.opacity(0.22))
                            .frame(width: 58, height: 58)
                        Circle()
                            .stroke(nodeColor.opacity(0.6), lineWidth: 1.5)
                            .frame(width: 58, height: 58)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .foregroundStyle(nodeColor)
                                .fontWeight(.bold)
                        } else if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(nodeColor)
                        } else {
                            Text("\(config.id)")
                                .foregroundStyle(nodeColor)
                                .fontWeight(.bold)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Phase \(config.id)")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.textMuted)
                            Spacer(minLength: 0)
                            if isCurrent {
                                QuestChip(text: "Current", accent: AppTheme.accent)
                            } else if isCompleted {
                                QuestChip(text: "Cleared", accent: AppTheme.success)
                            } else if !isUnlocked {
                                QuestChip(text: "Locked", accent: AppTheme.surfaceInteractive)
                            }
                        }

                        Text(config.title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary)

                        Text(isUnlocked ? config.concept : config.teaserDescription)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isUnlocked ? AppTheme.textMuted : AppTheme.border)
                }

                if isUnlocked {
                    Rectangle()
                        .fill(AppTheme.border.opacity(0.35))
                        .frame(height: 1)
                        .padding(.vertical, 12)

                    HStack(spacing: 8) {
                        ForEach(1...config.stageCount, id: \.self) { stage in
                            let unlocked = isStageUnlocked(stage)
                            let completed = isStageCompleted(stage)
                            Button {
                                onSelectStage(stage)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(stageCircleFill(unlocked: unlocked, completed: completed))
                                        .frame(width: 38, height: 38)
                                    Circle()
                                        .stroke(stageCircleBorder(unlocked: unlocked, completed: completed), lineWidth: 1.5)
                                        .frame(width: 38, height: 38)
                                    if completed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(AppTheme.success)
                                    } else if !unlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.textMuted)
                                    } else {
                                        Text("\(stage)")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!unlocked)
                            .opacity(unlocked ? 1.0 : 0.45)
                            .accessibilityLabel(stageAccessibilityLabel(stage: stage, unlocked: unlocked, completed: completed))
                            .accessibilityIdentifier("stage-button-\(config.id)-\(stage)")
                        }
                        Spacer()
                    }
                }
            }
            .questCard(fill: cardFill)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1 : 0.72)
        .accessibilityIdentifier("phase-node-\(config.id)")
    }

    private var nodeColor: Color {
        if isCompleted { return AppTheme.success }
        if isCurrent { return AppTheme.accent }
        if isUnlocked { return AppTheme.highlight }
        return AppTheme.textMuted
    }

    private var cardFill: Color {
        if isCurrent {
            return AppTheme.accentDeep.opacity(0.22)
        }
        return AppTheme.surfaceRaised.opacity(0.92)
    }

    private func stageCircleFill(unlocked: Bool, completed: Bool) -> Color {
        if completed { return AppTheme.success.opacity(0.15) }
        if unlocked { return AppTheme.accent.opacity(0.15) }
        return AppTheme.surfaceInteractive.opacity(0.25)
    }

    private func stageCircleBorder(unlocked: Bool, completed: Bool) -> Color {
        if completed { return AppTheme.success.opacity(0.55) }
        if unlocked { return AppTheme.accent.opacity(0.55) }
        return AppTheme.border.opacity(0.3)
    }

    private func stageAccessibilityLabel(stage: Int, unlocked: Bool, completed: Bool) -> String {
        let status = completed ? "completed" : (unlocked ? "unlocked" : "locked")
        return "Stage \(stage), \(status)"
    }
}
