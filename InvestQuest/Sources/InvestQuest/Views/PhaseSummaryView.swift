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
        GeometryReader { geometry in
            let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
            let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
            let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)

            ScrollView {
                VStack(spacing: 24) {
                    QuestSectionHeader(
                        eyebrow: "Phase \(viewModel.completedPhaseConfig.id) Complete",
                        title: viewModel.completedPhaseConfig.concept,
                        subtitle: viewModel.completedPhaseConfig.title
                    )

                    QuestAdaptiveMetricGrid {
                        QuestMetricCard(
                            label: "Average Score",
                            value: "\(viewModel.averageScore)",
                            detail: "\(viewModel.performanceData.count)개 스테이지 기록",
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
                            Text("Continue Journey".ko)
                                .multilineTextAlignment(.center)
                        }
                        .buttonStyle(QuestPrimaryButtonStyle())
                    }
                }
                .questReadableContentFrame(in: geometry.size.width)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .scrollClipDisabled()
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
                Text("Badge Earned".ko)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
                Text(badge.title.ko)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .questCard()
        .accessibilityLabel("획득한 배지: \(badge.title.ko)")
    }
}

struct PerformanceDashboardView: View {
    let data: [PerformanceDataPoint]
    let averageScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Dashboard".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))

            ForEach(data) { point in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Stage \(point.stageNumber)".ko)
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
            ViewThatFits(in: .horizontal) {
                HStack {
                    QuestChip(text: "Next Up · Phase \(config.id)", accent: AppTheme.accent)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    QuestChip(text: "Next Up · Phase \(config.id)", accent: AppTheme.accent)
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            }

            Text(config.title.ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(config.teaserDescription.ko)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .questCard(fill: AppTheme.accentDeep.opacity(0.18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("다음 페이즈 해제: \(config.title.ko). \(config.teaserDescription.ko)")
    }
}
