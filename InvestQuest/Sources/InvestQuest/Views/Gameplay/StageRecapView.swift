import SwiftUI
import SwiftData

struct StageRecapView: View {
    let address: StageAddress

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @Query private var progressRecords: [GameProgress]

    var body: some View {
        let service = progressRecords.first.map { GameProgressService(modelContext: modelContext, progress: $0) }
        let recapPhase = service?.recapPhase

        GeometryReader { geometry in
            let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
            let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
            let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)

            ScrollView {
                VStack(spacing: 22) {
                    QuestSectionHeader(
                        eyebrow: "Resume",
                        title: "Welcome Back",
                        subtitle: "Take a quick warm-up lap before diving back into the run."
                    )

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.highlight.opacity(0.14))
                                .frame(width: 92, height: 92)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.highlight)
                        }

                        if let recapPhase {
                            Text("You last completed Phase \(recapPhase.id): \(recapPhase.title)".ko)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .multilineTextAlignment(.center)
                            Text(recapPhase.concept.ko)
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Text("Replay one stage as a warm-up, then continue from your current progression.".ko)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .questCard()

                    QuestAdaptiveMetricGrid {
                        QuestMetricCard(label: "Resume At", value: "Phase \(address.phase)", detail: "Stage \(address.stage)", accent: AppTheme.accent)
                        QuestMetricCard(label: "Mode", value: "Warm-up", detail: "One quick replay before the run", accent: AppTheme.highlight)
                    }

                    Button {
                        appViewModel.dismissRecap(into: address)
                    } label: {
                        Text("Continue to Stage".ko)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle(tint: AppTheme.highlight))
                    .accessibilityIdentifier("continue-from-recap")
                }
                .questReadableContentFrame(in: geometry.size.width)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .scrollClipDisabled()
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityIdentifier("stage-recap")
    }
}
