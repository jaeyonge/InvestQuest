import Foundation

/// Concrete implementation of MarketSimulationEngineProtocol.
///
/// Uses a seeded xorshift64 PRNG so that identical seeds always produce
/// identical price sequences (deterministic, reproducible).
///
/// Price model:
///   p[t+1] = p[t] * exp(step_drift + step_vol * Z)
/// where Z ~ N(0,1) approximated via Box-Muller on the seeded PRNG.
/// This produces log-normal returns — realistic, smooth, no teleporting.
/// Event injections apply a one-time multiplicative shock at a specified period.
final class MarketSimulationEngine: MarketSimulationEngineProtocol {

    // MARK: - PRNG (xorshift64 — fast, seedable, deterministic)

    private struct RNG {
        var state: UInt64

        init(seed: UInt64) {
            // Avoid zero state
            self.state = seed == 0 ? 0x1234_5678_9ABC_DEF0 : seed
        }

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }

        /// Returns a value in [0, 1)
        mutating func nextDouble() -> Double {
            let raw = next()
            // Use upper 53 bits for Double mantissa precision
            return Double(raw >> 11) * (1.0 / Double(1 << 53))
        }

        /// Box-Muller transform → standard normal N(0,1)
        /// Consumes two uniform samples.
        mutating func nextNormal() -> Double {
            let u1 = max(nextDouble(), 1e-15)  // guard against log(0)
            let u2 = nextDouble()
            return Foundation.sqrt(-2.0 * Foundation.log(u1)) * Foundation.cos(2.0 * .pi * u2)
        }
    }

    // MARK: - simulate

    func simulate(stage: StageSimulation) -> SimulationResult {
        let start = Date()

        let runs = (0..<max(1, stage.replayCount)).map { replayIndex in
            let seed = stage.seed + UInt64(replayIndex)
            return SimulationRun(seed: seed, assetHistories: simulateRun(stage: stage, seed: seed))
        }

        let elapsed = Date().timeIntervalSince(start)
        return SimulationResult(runs: runs, durationSeconds: elapsed)
    }

    func simulate(config: StageConfig) -> SimulationResult {
        simulate(stage: StageSimulation.fromLegacy(
            config: config,
            phase: 0,
            stage: 0,
            assetIDs: (0..<config.assetCount).map { "asset\($0)" },
            assetLabels: (0..<config.assetCount).map { "Asset \($0 + 1)" }
        ))
    }

    // MARK: - simulateBatch

    func simulateBatch(config: StageConfig, count: Int) -> [SimulationResult] {
        (0..<count).map { i in
            var cfg = config
            cfg = StageConfig(
                seed: config.seed + UInt64(i),
                assetCount: config.assetCount,
                timePeriods: config.timePeriods,
                volatility: config.volatility,
                drift: config.drift,
                eventInjections: config.eventInjections,
                outcomeWeight: config.outcomeWeight
            )
            return simulate(config: cfg)
        }
    }

    // MARK: - Private

    private func simulateRun(stage: StageSimulation, seed: UInt64) -> [AssetPriceHistory] {
        var rng = RNG(seed: seed)
        var groupNormals: [Int: [String: Double]] = [:]

        for period in 0..<stage.periodCount {
            var groups: Set<String> = []
            for asset in stage.assets {
                if let correlationGroup = asset.correlationGroup {
                    groups.insert(correlationGroup)
                }
            }
            groupNormals[period] = Dictionary(uniqueKeysWithValues: groups.map { ($0, rng.nextNormal()) })
        }

        var histories: [AssetPriceHistory] = []
        for (assetIndex, asset) in stage.assets.enumerated() {
            var prices = [Double](repeating: 0, count: stage.periodCount + 1)
            prices[0] = asset.startingValue
            var stopLossFloor: Double?

            for period in 0..<stage.periodCount {
                let periodNumber = period + 1
                let idiosyncraticShock = rng.nextNormal()
                let groupShock: Double
                if let correlationGroup = asset.correlationGroup,
                   let shared = groupNormals[period]?[correlationGroup] {
                    groupShock = shared * min(max(asset.correlationStrength, 0), 1)
                } else {
                    groupShock = 0
                }

                let lessonAdjustment: Double
                switch asset.lessonRole {
                case .preferred:
                    lessonAdjustment = stage.lessonBias
                case .penalized:
                    lessonAdjustment = -stage.lessonBias
                case .neutral:
                    lessonAdjustment = 0
                }

                var drift = asset.drift + lessonAdjustment - asset.annualFee
                var volatility = max(asset.volatility, 0.001)
                var multiplier = 1.0

                for event in stage.events where event.period == periodNumber {
                    guard applies(event: event, to: asset) else { continue }
                    switch event.kind {
                    case .multiplier(let factor):
                        multiplier *= factor
                    case .driftShift(let shift):
                        drift += shift
                    case .volatilityShift(let shift):
                        volatility = max(0.001, volatility + shift)
                    case .feeDrag(let fee):
                        drift -= fee
                    case .bankruptcy(let floor):
                        multiplier *= floor
                    case .stopLossFloor(let floor):
                        stopLossFloor = floor
                    }
                }

                let blendedShock = groupShock + idiosyncraticShock * (1 - min(max(asset.correlationStrength, 0), 1))
                let stepDrift = drift / Double(max(stage.periodCount, 1))
                let stepVolatility = volatility / Foundation.sqrt(Double(max(stage.periodCount, 1)))
                let logReturn = stepDrift + stepVolatility * blendedShock
                var nextPrice = prices[period] * Foundation.exp(logReturn)
                nextPrice *= multiplier

                if let stopLossFloor, nextPrice / max(prices[0], 0.01) <= stopLossFloor {
                    nextPrice = prices[0] * stopLossFloor
                }

                prices[periodNumber] = max(nextPrice, 0.01)
            }

            histories.append(
                AssetPriceHistory(
                    assetIndex: assetIndex,
                    assetID: asset.id,
                    prices: prices
                )
            )
        }

        return histories
    }

    private func applies(event: SimulationEvent, to asset: SimAssetConfig) -> Bool {
        guard let assetIDs = event.assetIDs, !assetIDs.isEmpty else { return true }
        return assetIDs.contains(asset.id)
    }
}
