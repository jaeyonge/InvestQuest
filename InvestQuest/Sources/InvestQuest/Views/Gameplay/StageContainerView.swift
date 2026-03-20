import SwiftUI
import SwiftData

struct StageContainerView: View {
    let address: StageAddress

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @Query private var progressRecords: [GameProgress]

    @StateObject private var viewModel: StageViewModel
    @State private var didRestore = false
    @State private var pendingSessionSaveTask: Task<Void, Never>?

    init(address: StageAddress) {
        self.address = address
        _viewModel = StateObject(wrappedValue: StageViewModel(definition: StageCatalog.definition(for: address)))
    }

    var body: some View {
        if let service = progressRecords.first.map({ GameProgressService(modelContext: modelContext, progress: $0) }) {
            NavigationStack {
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
                            appViewModel.finishStage(address: address, outcome: outcome, using: service)
                        }
                    }
                }
                .navigationTitle("Phase \(address.phase)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            appViewModel.openPhaseMap()
                        } label: {
                            Label("Map", systemImage: "square.grid.2x2")
                        }
                        .buttonStyle(QuestSecondaryButtonStyle())
                        .accessibilityIdentifier("open-phase-map")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        QuestStatPill(
                            label: "Stage",
                            value: "\(address.stage)",
                            accent: AppTheme.highlight
                        )
                    }
                }
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
}
