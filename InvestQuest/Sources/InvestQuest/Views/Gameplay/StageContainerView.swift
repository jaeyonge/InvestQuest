import SwiftUI
import SwiftData

struct StageContainerView: View {
    let address: StageAddress

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @Query private var progressRecords: [GameProgress]

    @StateObject private var viewModel: StageViewModel
    @State private var didRestore = false
    @State private var isShowingStageInfo = false
    @State private var pendingSessionSaveTask: Task<Void, Never>?

    init(address: StageAddress) {
        self.address = address
        _viewModel = StateObject(wrappedValue: StageViewModel(definition: StageCatalog.definition(for: address)))
    }

    var body: some View {
        GeometryReader { geometry in
            if let service = progressRecords.first.map({ GameProgressService(modelContext: modelContext, progress: $0) }) {
                Group {
                    switch viewModel.flowState {
                    case .briefing:
                        StageBriefingView(
                            definition: viewModel.definition,
                            onStart: { viewModel.advanceFromBriefing() },
                            viewModel: viewModel
                        )
                    case .decision:
                        DecisionView(
                            scenario: viewModel.definition.scenario,
                            decisionSpec: viewModel.definition.decision,
                            timeRemaining: viewModel.timeRemaining,
                            onSubmit: { viewModel.submitDecision($0) }
                        )
                    case .simulation:
                        SimulationView(
                            viewModel: viewModel,
                            assetNames: viewModel.definition.simulation.assets.map(\.label),
                            onFinish: { viewModel.finishSimulation() }
                        )
                    case .result(let outcome):
                        ResultView(outcome: outcome) {
                            viewModel.advanceFromResult()
                        }
                    case .insight(let outcome):
                        InsightCardView(insightText: viewModel.definition.insightText) {
                            service.recordDecision(
                                address: address,
                                decisionType: decisionTypeName(for: viewModel.definition.decision),
                                decision: outcome.playerDecision,
                                optimalDecision: viewModel.definition.optimalDecision,
                                outcome: outcome,
                                decisionLatencyMs: viewModel.lastDecisionLatencyMs,
                                biasTags: outcome.biasTags
                            )
                            service.completeStage(address: address, outcome: outcome)
                            viewModel.replayStage()
                            appViewModel.finishStage(address: address, outcome: outcome, using: service)
                        }
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    stageChrome(availableWidth: geometry.size.width)
                }
                .sheet(isPresented: $isShowingStageInfo) {
                    StageInfoSheet(definition: viewModel.definition)
                }
                .questScreenBackground()
                .task {
                    guard !didRestore else { return }
                    didRestore = true
                    if let snapshot = service.loadStageSession(), snapshot.address == address {
                        viewModel.restore(from: snapshot)
                    }
                }
                .onChange(of: viewModel.sessionSnapshot) { _, snapshot in
                    pendingSessionSaveTask?.cancel()
                    guard let snapshot else { return }
                    pendingSessionSaveTask = Task {
                        let delayNanos: UInt64 = snapshot.flowState == .decision ? 350_000_000 : 50_000_000
                        try? await Task.sleep(nanoseconds: delayNanos)
                        guard !Task.isCancelled else { return }
                        service.saveSession(snapshot)
                    }
                }
                .onDisappear {
                    pendingSessionSaveTask?.cancel()
                }
            } else {
                ProgressView()
                    .tint(AppTheme.accent)
                    .task {
                        _ = GameProgressService.loadOrCreateProgress(modelContext: modelContext)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func decisionTypeName(for spec: DecisionSpec) -> String {
        switch spec {
        case .observe: return "observe"
        case .binary: return "binary"
        case .allocation: return "allocation"
        case .ranking: return "ranking"
        case .valuation: return "valuation"
        case .stopLoss: return "stop-loss"
        case .review: return "review"
        }
    }

    private func stageChrome(availableWidth: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {
            ZStack {
                stageTitle
                    .padding(.horizontal, 120)

                HStack(spacing: 14) {
                    mapButton
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 12)
                    stageButton
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            VStack(spacing: 12) {
                stageTitle
                HStack(spacing: 14) {
                    mapButton
                    Spacer(minLength: 12)
                    stageButton
                }
            }
        }
        .padding(.horizontal, AppTheme.chromeHorizontalPadding(for: availableWidth))
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    private var stageTitle: some View {
        Text("Phase \(address.phase)".ko)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.84)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var mapButton: some View {
        Button {
            appViewModel.openPhaseMap()
        } label: {
            Label("Map".ko, systemImage: "square.grid.2x2.fill")
        }
        .buttonStyle(QuestGlassButtonStyle(tint: AppTheme.accent, foreground: AppTheme.accent))
        .accessibilityIdentifier("open-phase-map")
    }

    private var stageButton: some View {
        Button {
            isShowingStageInfo = true
        } label: {
            HStack(spacing: 6) {
                Text("Stage \(address.stage)".ko)
                Image(systemName: "info.circle")
            }
        }
        .buttonStyle(QuestGlassButtonStyle(tint: AppTheme.textSecondary, foreground: AppTheme.textPrimary))
        .accessibilityIdentifier("open-stage-info")
    }
}

private struct StageInfoSheet: View {
    let definition: StageDefinition

    @Environment(\.dismiss) private var dismiss

    private var phaseTitle: String {
        PhaseConfig.all.first(where: { $0.id == definition.phase })?.title ?? "Current Stage"
    }

    private var phaseConcept: String {
        PhaseConfig.all.first(where: { $0.id == definition.phase })?.concept ?? "Lesson"
    }

    @ViewBuilder
    private var stageInfoChips: some View {
        QuestChip(text: phaseConcept, accent: AppTheme.accent)
        QuestChip(text: "Pass \(definition.minimumPassingScore)+", accent: AppTheme.highlight)
        if definition.timeoutSeconds > 0 {
            QuestChip(text: "\(Int(definition.timeoutSeconds))s timer", accent: AppTheme.surfaceInteractive)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
                let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
                let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        QuestSectionHeader(
                            eyebrow: "Current Stage",
                            title: definition.scenarioTitle,
                            subtitle: phaseTitle
                        )

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                stageInfoChips
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                stageInfoChips
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scenario".ko)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(definition.scenarioDescription.ko)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .questCard(fill: AppTheme.surface.opacity(0.84))

                        QuestInfoBanner(
                            icon: "sparkles",
                            title: "What to watch",
                            message: definition.hintText,
                            accent: AppTheme.accent
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Core lesson".ko)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(definition.conceptExplanation.ko)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .questCard(fill: AppTheme.surface.opacity(0.84))
                    }
                    .questReadableContentFrame(in: geometry.size.width, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topPadding)
                    .padding(.bottom, bottomPadding)
                }
                .scrollClipDisabled()
            }
            .navigationTitle("Phase \(definition.phase) · Stage \(definition.stage)".ko)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".ko) {
                        dismiss()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .tint(AppTheme.accent)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .questScreenBackground()
            .foregroundStyle(AppTheme.textPrimary)
            .accessibilityIdentifier("stage-info-sheet")
        }
    }
}
