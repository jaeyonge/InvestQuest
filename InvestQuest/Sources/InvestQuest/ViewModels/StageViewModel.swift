import Foundation
import Combine

// MARK: - Stage State Machine

enum StageFlowState {
    case briefing
    case decision
    case simulation
    case result(StageOutcome)
    case insight(StageOutcome)
}

// MARK: - ViewModel

@MainActor
final class StageViewModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var flowState: StageFlowState = .briefing
    @Published private(set) var simulationPrices: [[Double]] = []  // [assetIndex][period]
    @Published private(set) var portfolioValues: [Double] = []
    @Published private(set) var currentPeriod: Int = 0
    @Published private(set) var failureCount: Int = 0
    @Published private(set) var pendingDecision: PlayerDecision?
    @Published private(set) var timeRemaining: Double = 0

    // MARK: - Dependencies

    private let definition: StageDefinition
    private let engine: any MarketSimulationEngineProtocol
    private var timeoutTask: Task<Void, Never>?
    private var simulationResult: SimulationResult?

    // MARK: - Init

    init(definition: StageDefinition, engine: any MarketSimulationEngineProtocol = MarketSimulationEngine()) {
        self.definition = definition
        self.engine = engine
    }

    deinit {
        timeoutTask?.cancel()
    }

    // MARK: - Navigation

    func advanceFromBriefing() {
        guard case .briefing = flowState else { return }
        flowState = .decision
        startDecisionTimer()
    }

    func submitDecision(_ decision: PlayerDecision) {
        guard case .decision = flowState else { return }
        timeoutTask?.cancel()
        pendingDecision = decision
        runSimulation(with: decision)
    }

    func advanceFromResult() {
        guard case .result(let outcome) = flowState else { return }
        flowState = .insight(outcome)
    }

    func advanceFromInsight() {
        // Caller handles navigation (back to phase map or next stage)
    }

    /// Resets state to .briefing so the stage can be replayed (e.g. after failure).
    func replayStage() {
        timeoutTask?.cancel()
        pendingDecision = nil
        simulationPrices = []
        portfolioValues = []
        currentPeriod = 0
        flowState = .briefing
    }

    // MARK: - Timeout → hold cash

    private func startDecisionTimer() {
        let timeout = definition.timeoutSeconds
        guard timeout > 0 else { return }
        timeRemaining = timeout
        timeoutTask = Task {
            var remaining = timeout
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                remaining -= 0.2
                self.timeRemaining = max(0, remaining)
            }
            if !Task.isCancelled {
                self.submitDecision(.holdCash)
            }
        }
    }

    // MARK: - Simulation

    private func runSimulation(with decision: PlayerDecision) {
        let result = engine.simulate(config: definition.simulationConfig)
        simulationResult = result

        // Build price arrays [assetIndex][period]
        simulationPrices = result.assetHistories.map { $0.prices }
        currentPeriod = 0

        // Compute portfolio value over time based on decision
        portfolioValues = computePortfolioValues(decision: decision, prices: simulationPrices)

        flowState = .simulation
    }

    func advanceSimulationPeriod() {
        let maxPeriod = (simulationPrices.first?.count ?? 1) - 1
        if currentPeriod < maxPeriod {
            currentPeriod += 1
        } else {
            finishSimulation()
        }
    }

    func finishSimulation() {
        guard case .simulation = flowState else { return }
        let startValue = 100.0 * Double(definition.simulationConfig.assetCount)
        let finalPortfolio = portfolioValues.last ?? startValue
        let optimalPortfolio = computeOptimalFinalValue()
        let score = StageOutcome.score(
            portfolioFinal: finalPortfolio,
            optimalFinal: optimalPortfolio,
            startValue: startValue
        )
        let stars = StageOutcome.starRating(for: score)
        let outcome = StageOutcome(
            playerDecision: pendingDecision ?? .holdCash,
            portfolioFinalValue: finalPortfolio,
            optimalFinalValue: optimalPortfolio,
            score: score,
            starRating: stars
        )

        // Track failures (score < minimumScoreToAdvance)
        if score < 60 {
            failureCount += 1
        }

        flowState = .result(outcome)
    }

    // MARK: - Hint/explanation text

    var hintForCurrentFailures: String? {
        if failureCount >= 5 { return definition.conceptExplanation }
        if failureCount >= 3 { return definition.hintText }
        return nil
    }

    // MARK: - Computed helpers

    private func computePortfolioValues(decision: PlayerDecision, prices: [[Double]]) -> [Double] {
        let periods = prices.first?.count ?? 0
        guard periods > 0 else { return [] }

        var weights: [Double]
        switch decision {
        case .binary(let choice):
            // "A" → all in asset 0; "B" → all in asset 1; else equal weight
            if choice == "A" { weights = [1.0] + Array(repeating: 0, count: max(0, prices.count - 1)) }
            else if choice == "B" { weights = Array(repeating: 0, count: max(0, prices.count - 1)) + [1.0] }
            else { weights = Array(repeating: 1.0 / Double(prices.count), count: prices.count) }
        case .allocation(let alloc):
            let assetNames = (0..<prices.count).map { "asset\($0)" }
            weights = assetNames.map { alloc[$0] ?? 0 }
        case .ranking(let order):
            // Top-ranked asset gets 60%, second gets 40%, rest get 0
            let assetNames = (0..<prices.count).map { "asset\($0)" }
            weights = assetNames.map { name in
                if order.first == name { return 0.6 }
                if order.dropFirst().first == name { return 0.4 }
                return 0.0
            }
        case .holdCash:
            weights = Array(repeating: 0, count: prices.count)
        }

        // Normalise weights
        let total = weights.reduce(0, +)
        if total > 0 { weights = weights.map { $0 / total } }

        let startValue = 100.0 * Double(prices.count)

        return (0..<periods).map { t in
            let weightedPrice = zip(weights, prices).reduce(0.0) { sum, pair in
                sum + pair.0 * pair.1[t]
            }
            return startValue * weightedPrice / 100.0
        }
    }

    private func computeOptimalFinalValue() -> Double {
        let optimalDecision = definition.optimalDecision
        let prices = simulationPrices
        let values = computePortfolioValues(decision: optimalDecision, prices: prices)
        return values.last ?? 100.0
    }
}
