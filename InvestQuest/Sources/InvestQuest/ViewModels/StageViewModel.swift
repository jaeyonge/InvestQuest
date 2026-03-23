import Foundation

enum StageFlowState: Equatable {
    case briefing
    case decision
    case simulation
    case result(StageOutcome)
    case insight(StageOutcome)
}

@MainActor
final class StageViewModel: ObservableObject {

    @Published private(set) var flowState: StageFlowState = .briefing
    @Published private(set) var simulationPrices: [[Double]] = []
    @Published private(set) var portfolioValues: [Double] = []
    @Published private(set) var replayFinalValues: [Double] = []
    @Published private(set) var currentPeriod: Int = 0
    @Published private(set) var failureCount: Int = 0
    @Published private(set) var pendingDecision: PlayerDecision?
    @Published private(set) var timeRemaining: Double = 0
    @Published private(set) var sessionSnapshot: StageSessionSnapshot?
    @Published private(set) var lastDecisionLatencyMs: Int = 0

    let definition: StageDefinition

    private let engine: any MarketSimulationEngineProtocol
    private var timeoutTask: Task<Void, Never>?
    private var simulationResult: SimulationResult?
    private var decisionStartedAt: Date?

    init(definition: StageDefinition, engine: any MarketSimulationEngineProtocol = MarketSimulationEngine()) {
        self.definition = definition
        self.engine = engine
        refreshSessionSnapshot()
    }

    deinit {
        timeoutTask?.cancel()
    }

    func restore(from snapshot: StageSessionSnapshot?) {
        guard let snapshot, snapshot.address == definition.address else { return }
        failureCount = snapshot.failureCount
        pendingDecision = snapshot.pendingDecision
        timeRemaining = snapshot.timeRemaining

        switch snapshot.flowState {
        case .briefing:
            flowState = .briefing
        case .decision:
            flowState = .decision
            decisionStartedAt = .now.addingTimeInterval(-(definition.timeoutSeconds - snapshot.timeRemaining))
            startDecisionTimer(fromRemaining: snapshot.timeRemaining)
        case .simulation:
            let decision = snapshot.pendingDecision ?? definition.decision.defaultDecision
            runSimulation(with: decision)
            currentPeriod = min(snapshot.currentPeriod, max(simulationPrices.first?.count ?? 1, 1) - 1)
        case .result:
            let decision = snapshot.pendingDecision ?? definition.decision.defaultDecision
            runSimulation(with: decision)
            currentPeriod = min(snapshot.currentPeriod, max(simulationPrices.first?.count ?? 1, 1) - 1)
            finishSimulation()
        case .insight:
            let decision = snapshot.pendingDecision ?? definition.decision.defaultDecision
            runSimulation(with: decision)
            currentPeriod = min(snapshot.currentPeriod, max(simulationPrices.first?.count ?? 1, 1) - 1)
            finishSimulation()
            if case .result = flowState {
                advanceFromResult()
            }
        }
        refreshSessionSnapshot()
    }

    func advanceFromBriefing() {
        guard case .briefing = flowState else { return }
        flowState = .decision
        decisionStartedAt = .now
        startDecisionTimer(fromRemaining: definition.timeoutSeconds)
        refreshSessionSnapshot()
    }

    func submitDecision(_ decision: PlayerDecision) {
        guard case .decision = flowState else { return }
        timeoutTask?.cancel()
        lastDecisionLatencyMs = decisionStartedAt.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0
        pendingDecision = decision
        runSimulation(with: decision)
        refreshSessionSnapshot()
    }

    func advanceFromResult() {
        guard case .result(let outcome) = flowState else { return }
        flowState = .insight(outcome)
        refreshSessionSnapshot()
    }

    func replayStage() {
        timeoutTask?.cancel()
        pendingDecision = nil
        simulationResult = nil
        simulationPrices = []
        portfolioValues = []
        replayFinalValues = []
        currentPeriod = 0
        timeRemaining = 0
        lastDecisionLatencyMs = 0
        decisionStartedAt = nil
        flowState = .briefing
        refreshSessionSnapshot()
    }

    func advanceSimulationPeriod() {
        let maxPeriod = max((simulationPrices.first?.count ?? 1) - 1, 0)
        if currentPeriod < maxPeriod {
            currentPeriod += 1
            refreshSessionSnapshot()
        } else {
            finishSimulation()
        }
    }

    func finishSimulation() {
        guard case .simulation = flowState else { return }

        let startValue = initialPortfolioValue
        let finalPortfolio = portfolioValues.last ?? startValue
        let optimalValues = computePortfolioValues(
            decision: definition.optimalDecision,
            histories: simulationResult?.assetHistories ?? []
        )
        let optimalPortfolio = optimalValues.last ?? startValue
        let score = computeScore(playerDecision: pendingDecision ?? .holdCash, portfolioFinal: finalPortfolio, optimalFinal: optimalPortfolio)
        let stars = StageOutcome.starRating(for: score)
        let sortedReplays = replayFinalValues.sorted()
        let replayStats: ReplayStats?
        if sortedReplays.isEmpty {
            replayStats = nil
        } else {
            replayStats = ReplayStats(
                minimum: sortedReplays.first ?? finalPortfolio,
                median: sortedReplays[sortedReplays.count / 2],
                maximum: sortedReplays.last ?? finalPortfolio
            )
        }

        let biasTags = inferredBiasTags(for: pendingDecision ?? .holdCash)
        let outcome = StageOutcome(
            playerDecision: pendingDecision ?? .holdCash,
            portfolioFinalValue: finalPortfolio,
            optimalFinalValue: optimalPortfolio,
            score: score,
            starRating: stars,
            passed: score >= definition.minimumPassingScore,
            replayStats: replayStats,
            biasTags: biasTags
        )

        if score < definition.minimumPassingScore {
            failureCount += 1
        }

        flowState = .result(outcome)
        refreshSessionSnapshot()
    }

    var hintForCurrentFailures: String? {
        if failureCount >= 5 { return definition.conceptExplanation }
        if failureCount >= 3 { return definition.hintText }
        return nil
    }

    var definitionHintText: String { definition.hintText }
    var definitionConceptText: String { definition.conceptExplanation }

    // MARK: - Private

    private var initialPortfolioValue: Double {
        definition.simulation.assets.map(\.startingValue).max() ?? 100
    }

    private func startDecisionTimer(fromRemaining remaining: Double) {
        timeoutTask?.cancel()
        guard let timeout = definition.decision.timeoutSeconds, timeout > 0 else {
            timeRemaining = 0
            return
        }

        timeRemaining = remaining > 0 ? remaining : timeout
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            let interval: Double = 0.1
            while !Task.isCancelled, self.timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { return }
                self.timeRemaining = max(0, self.timeRemaining - interval)
                self.refreshSessionSnapshot()
            }

            guard !Task.isCancelled else { return }
            self.submitDecision(self.definition.decision.defaultDecision)
        }
    }

    private func runSimulation(with decision: PlayerDecision) {
        let result = engine.simulate(stage: definition.simulation)
        simulationResult = result
        simulationPrices = result.assetHistories.map(\.prices)
        currentPeriod = 0
        portfolioValues = computePortfolioValues(decision: decision, histories: result.assetHistories)
        replayFinalValues = result.runs.map { run in
            computePortfolioValues(decision: decision, histories: run.assetHistories).last ?? initialPortfolioValue
        }
        timeRemaining = 0
        flowState = .simulation
    }

    private func computePortfolioValues(decision: PlayerDecision, histories: [AssetPriceHistory]) -> [Double] {
        guard let firstHistory = histories.first else { return [] }
        let assetIDs = histories.map(\.assetID)
        var weights = weights(for: decision, assetIDs: assetIDs)
        if weights.isEmpty, let fallback = fallbackCashAssetID(assetIDs: assetIDs) {
            weights = [fallback: 1]
        }

        let total = max(weights.values.reduce(0, +), 0.0001)
        let normalized = weights.mapValues { $0 / total }
        return (0..<firstHistory.prices.count).map { period in
            histories.reduce(0) { partial, history in
                partial + (normalized[history.assetID] ?? 0) * history.prices[period]
            }
        }
    }

    private func weights(for decision: PlayerDecision, assetIDs: [String]) -> [String: Double] {
        switch decision {
        case .binary(let choice):
            return strategyWeights(forChoiceID: choice, assetIDs: assetIDs)
        case .allocation(let allocation):
            return allocation.filter { assetIDs.contains($0.key) }
        case .ranking(let ranking):
            return ranking.enumerated().reduce(into: [String: Double]()) { partial, item in
                guard assetIDs.contains(item.element) else { return }
                partial[item.element] = Double(max(ranking.count - item.offset, 1))
            }
        case .valuation(_, let actionID):
            return strategyWeights(forChoiceID: actionID, assetIDs: assetIDs)
        case .stopLoss(_, let actionID):
            return strategyWeights(forChoiceID: actionID, assetIDs: assetIDs)
        case .review(let actionID):
            return strategyWeights(forChoiceID: actionID, assetIDs: assetIDs)
        case .holdCash:
            if let cash = fallbackCashAssetID(assetIDs: assetIDs) {
                return [cash: 1]
            }
            return assetIDs.first.map { [$0: 1] } ?? [:]
        }
    }

    private func strategyWeights(forChoiceID choiceID: String, assetIDs: [String]) -> [String: Double] {
        switch definition.decision {
        case .observe(_, let actionID, _, _):
            if choiceID == actionID, let first = assetIDs.first {
                return [first: 1]
            }
            return fallbackCashAssetID(assetIDs: assetIDs).map { [$0: 1] } ?? [:]
        case .binary(let options, _, _),
             .valuation(let options, _, _),
             .stopLoss(let options, _, _, _),
             .review(let options, _, _):
            guard let option = options.first(where: { $0.id == choiceID }) else {
                return fallbackCashAssetID(assetIDs: assetIDs).map { [$0: 1] } ?? [:]
            }
            switch option.strategy {
            case .directAsset(let assetID):
                return [assetID: 1]
            case .portfolio(let weights):
                return weights
            case .cash:
                return fallbackCashAssetID(assetIDs: assetIDs).map { [$0: 1] } ?? [:]
            }
        case .allocation, .ranking:
            return [:]
        }
    }

    private func fallbackCashAssetID(assetIDs: [String]) -> String? {
        if let cash = definition.simulation.assets.first(where: { $0.kind == .cash || $0.kind == .savings })?.id {
            return cash
        }
        return assetIDs.first
    }

    private func computeScore(playerDecision: PlayerDecision, portfolioFinal: Double, optimalFinal: Double) -> Int {
        switch definition.scoring {
        case .portfolio:
            return StageOutcome.score(
                portfolioFinal: portfolioFinal,
                optimalFinal: optimalFinal,
                startValue: initialPortfolioValue
            )
        case .correctness:
            return matchesOptimalDecision(playerDecision) ? 100 : max(20, StageOutcome.score(
                portfolioFinal: portfolioFinal,
                optimalFinal: optimalFinal,
                startValue: initialPortfolioValue
            ))
        case .rankingDistance:
            guard case .ranking(let playerOrder) = playerDecision,
                  case .ranking(let optimalOrder) = definition.optimalDecision else {
                return 0
            }
            return rankingScore(player: playerOrder, optimal: optimalOrder)
        case .valuationError(let targetValue):
            switch playerDecision {
            case .valuation(let estimatedValue, let actionID):
                let estimateScore = max(0, 100 - Int(abs(estimatedValue - targetValue) / max(targetValue, 1) * 100))
                let actionScore = actionID == extractActionID(from: definition.optimalDecision) ? 100 : 30
                return (estimateScore + actionScore) / 2
            default:
                return playerDecision == definition.optimalDecision ? 100 : 30
            }
        case .reviewCompletion:
            return playerDecision == definition.optimalDecision ? 100 : 35
        }
    }

    private func rankingScore(player: [String], optimal: [String]) -> Int {
        let optimalPositions = Dictionary(uniqueKeysWithValues: optimal.enumerated().map { ($1, $0) })
        let totalDistance = player.enumerated().reduce(0) { partial, item in
            let optimalIndex = optimalPositions[item.element] ?? optimal.count
            return partial + abs(optimalIndex - item.offset)
        }
        let maxDistance = max(optimal.count * max(optimal.count - 1, 1), 1)
        let normalizedPenalty = Double(totalDistance) / Double(maxDistance)
        return max(0, 100 - Int(normalizedPenalty * 100))
    }

    private func extractActionID(from decision: PlayerDecision) -> String? {
        switch decision {
        case .binary(let choice): return choice
        case .valuation(_, let actionID): return actionID
        case .stopLoss(_, let actionID): return actionID
        case .review(let actionID): return actionID
        case .allocation, .ranking, .holdCash: return nil
        }
    }

    private func inferredBiasTags(for decision: PlayerDecision) -> [String] {
        switch (definition.address.phase, definition.address.stage) {
        case (7, 1):
            return decision == definition.optimalDecision ? ["recency-bias-resisted"] : ["recency-bias", "herd-behavior"]
        case (7, 2):
            return decision == definition.optimalDecision ? ["fomo-resisted"] : ["fomo", "herd-behavior"]
        case (7, 3):
            return decision == definition.optimalDecision ? ["anchoring-resisted"] : ["anchoring-bias"]
        case (5, 4):
            return decision == definition.optimalDecision ? ["loss-aversion-resisted"] : ["loss-aversion"]
        default:
            return []
        }
    }

    private func matchesOptimalDecision(_ playerDecision: PlayerDecision) -> Bool {
        switch (playerDecision, definition.optimalDecision) {
        case (.allocation(let playerAllocation), .allocation(let optimalAllocation)):
            return AllocationMath.matches(playerAllocation, optimalAllocation, assetIDs: allocationAssetIDs)
        default:
            return playerDecision == definition.optimalDecision
        }
    }

    private var allocationAssetIDs: [String] {
        switch definition.decision {
        case .allocation(let assets, _, _, _):
            return assets.map(\.id)
        default:
            return definition.simulation.assets.map(\.id)
        }
    }

    private func refreshSessionSnapshot() {
        let snapshotState: StageFlowSnapshotState
        switch flowState {
        case .briefing: snapshotState = .briefing
        case .decision: snapshotState = .decision
        case .simulation: snapshotState = .simulation
        case .result: snapshotState = .result
        case .insight: snapshotState = .insight
        }

        sessionSnapshot = StageSessionSnapshot(
            address: definition.address,
            flowState: snapshotState,
            currentPeriod: currentPeriod,
            failureCount: failureCount,
            pendingDecision: pendingDecision,
            timeRemaining: timeRemaining
        )
    }
}
