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
                                stageLabel: service.addressForPhaseSelection(phase.id).stage
                            ) {
                                guard service.isPhaseUnlocked(phase.id) else { return }
                                appViewModel.openStage(service.addressForPhaseSelection(phase.id))
                            }
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
    let stageLabel: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
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

                VStack(alignment: .leading, spacing: 8) {
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

                    HStack(spacing: 10) {
                        if isUnlocked {
                            QuestChip(
                                text: isCompleted ? "Replay" : "Open Stage \(stageLabel)",
                                accent: isCompleted ? AppTheme.highlight : AppTheme.accent
                            )
                        }
                        QuestChip(text: "\(config.stageCount) stages", accent: AppTheme.surfaceInteractive)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isUnlocked ? AppTheme.textMuted : AppTheme.border)
            }
            .questCard(fill: cardFill)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1 : 0.72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
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

    private var accessibilityLabel: String {
        let status = isCompleted ? "Completed" : (isUnlocked ? "Unlocked" : "Locked")
        return "Phase \(config.id): \(config.title). \(status)."
    }
}
