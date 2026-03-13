import Foundation

// MARK: - Stage Configuration

/// Parameters for configuring a single stage's simulation.
struct StageConfig {
    let seed: UInt64
    let assetCount: Int
    let timePeriods: Int
    let volatility: Double        // 0.0 – 1.0; controls per-step price swing magnitude
    let drift: Double             // annual drift rate (e.g. 0.07 = 7% per year)
    let eventInjections: [EventInjection]
    let outcomeWeight: OutcomeWeight

    struct EventInjection {
        let period: Int           // which time period to inject at (0-based)
        let assetIndex: Int       // which asset is affected (-1 = all)
        let magnitudeFactor: Double  // multiplier applied to price (e.g. 0.5 = -50% crash)
    }

    struct OutcomeWeight {
        /// When correctStrategyWeight > 0.5, the correct strategy wins on average.
        let correctStrategyWeight: Double   // 0.0 – 1.0
        let description: String            // which strategy is "correct"
    }
}

// MARK: - Simulation Result

/// A single asset's complete price history for one simulation run.
struct AssetPriceHistory {
    let assetIndex: Int
    let prices: [Double]   // length == StageConfig.timePeriods + 1 (includes t=0)
}

/// The full output of one simulation run.
struct SimulationResult {
    let seed: UInt64
    let assetHistories: [AssetPriceHistory]
    let durationSeconds: Double
}

// MARK: - Protocol

/// The interface all phase ViewModels use to run market simulations.
protocol MarketSimulationEngineProtocol {
    /// Runs the simulation for a given stage config and returns price histories.
    /// Must be deterministic: same seed → same output.
    /// Must complete in < 1 second.
    func simulate(config: StageConfig) -> SimulationResult

    /// Runs N simulations with sequential seeds (seed, seed+1 … seed+count-1).
    /// Used for outcome weighting validation.
    func simulateBatch(config: StageConfig, count: Int) -> [SimulationResult]
}
