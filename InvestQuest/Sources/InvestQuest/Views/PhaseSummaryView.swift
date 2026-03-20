import SwiftUI
import SwiftData

struct PhaseSummaryView: View {
    @StateObject private var viewModel: PhaseCompletionViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @Query private var progressRecords: [GameProgress]

    init(phaseId: Int) {
        _viewModel = StateObject(wrappedValue: PhaseCompletionViewModel(phaseId: phaseId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                QuestSectionHeader(
                    eyebrow: "Phase \(viewModel.completedPhaseConfig.id) Complete",
                    title: viewModel.completedPhaseConfig.concept,
                    subtitle: viewModel.completedPhaseConfig.title
                )

                HStack(spacing: 14) {
                    QuestMetricCard(
                        label: "Average Score",
                        value: "\(viewModel.averageScore)",
                        detail: "\(viewModel.performanceData.count) stages recorded",
                        accent: AppTheme.accent
                    )
                    QuestMetricCard(
                        label: "Status",
                        value: "Unlocked",
                        detail: viewModel.nextPhaseConfig == nil ? "Final phase cleared" : "Next lesson ready",
                        accent: AppTheme.highlight
                    )
                }

                if let badge = viewModel.badge {
                    BadgeView(badge: badge)
                }

                if !viewModel.performanceData.isEmpty {
                    PerformanceDashboardView(data: viewModel.performanceData, averageScore: viewModel.averageScore)
                }

                if let next = viewModel.nextPhaseConfig {
                    NextPhaseTeaserView(config: next)
                }

                if let progress = progressRecords.first {
                    let service = GameProgressService(modelContext: modelContext, progress: progress)
                    Button {
                        appViewModel.closePhaseSummary(using: service)
                    } label: {
                        Text("Continue Journey")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .questScreenBackground()
        .onAppear {
            viewModel.loadPerformance(modelContext: modelContext)
            if !viewModel.isPersisted {
                viewModel.persistCompletion(modelContext: modelContext)
            }
            HapticFeedbackService.shared.fireAchievement()
        }
    }
}

struct BadgeView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: badge.color).opacity(0.14))
                    .frame(width: 132, height: 132)
                Circle()
                    .stroke(Color(hex: badge.color).opacity(0.4), lineWidth: 2)
                    .frame(width: 132, height: 132)
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 112, height: 112)
                Image(systemName: badge.symbolName)
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: badge.color))
            }

            VStack(spacing: 6) {
                Text("Badge Earned")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
                Text(badge.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .questCard()
        .accessibilityLabel("Badge earned: \(badge.title)")
    }
}

struct PerformanceDashboardView: View {
    let data: [PerformanceDataPoint]
    let averageScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Dashboard")
                .font(.system(.headline, design: .rounded).weight(.semibold))

            ForEach(data) { point in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Stage \(point.stageNumber)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.textMuted)
                        Spacer()
                        Text("\(point.playerScore) / \(point.optimalScore)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(AppTheme.surface)
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [scoreColor(point.playerScore), scoreColor(point.playerScore).opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(point.playerScore) / 100)
                        }
                    }
                    .frame(height: 12)
                }
            }

            QuestInfoBanner(
                icon: "chart.bar.fill",
                title: "Average Score",
                message: "\(averageScore) across the completed phase.",
                accent: averageScore >= 80 ? AppTheme.success : (averageScore >= 60 ? AppTheme.highlight : AppTheme.danger)
            )
        }
        .questCard()
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return .investGreen
        case 50..<80:
            return AppTheme.highlight
        default:
            return .investRed
        }
    }
}

struct NextPhaseTeaserView: View {
    let config: PhaseConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                QuestChip(text: "Next Up · Phase \(config.id)", accent: AppTheme.accent)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            Text(config.title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(config.teaserDescription)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .questCard(fill: AppTheme.accentDeep.opacity(0.18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next phase unlocked: \(config.title). \(config.teaserDescription)")
    }
}
