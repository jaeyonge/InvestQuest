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

    func simulate(config: StageConfig) -> SimulationResult {
        let start = Date()

        var rng = RNG(seed: config.seed)

        // Per-step drift and vol (assuming timePeriods represents years; step = 1 period)
        let stepDrift = config.drift / Double(config.timePeriods)
        let stepVol   = config.volatility / Foundation.sqrt(Double(config.timePeriods))

        // Build event lookup: [period: [assetIndex: factor]]
        var events: [Int: [Int: Double]] = [:]
        for event in config.eventInjections {
            if events[event.period] == nil { events[event.period] = [:] }
            events[event.period]![event.assetIndex] = event.magnitudeFactor
        }

        var histories: [AssetPriceHistory] = []

        for assetIdx in 0..<config.assetCount {
            var prices = [Double](repeating: 0, count: config.timePeriods + 1)
            prices[0] = 100.0  // normalised base price

            for t in 0..<config.timePeriods {
                let z = rng.nextNormal()
                let logReturn = stepDrift + stepVol * z
                var nextPrice = prices[t] * Foundation.exp(logReturn)

                // Apply event injection if present
                if let periodEvents = events[t + 1] {
                    if let factor = periodEvents[assetIdx] {
                        nextPrice *= factor
                    } else if let factor = periodEvents[-1] {
                        nextPrice *= factor
                    }
                }

                // Clamp to prevent degenerate prices (never zero or negative)
                prices[t + 1] = max(nextPrice, 0.01)
            }

            histories.append(AssetPriceHistory(assetIndex: assetIdx, prices: prices))
        }

        let elapsed = Date().timeIntervalSince(start)
        return SimulationResult(seed: config.seed, assetHistories: histories, durationSeconds: elapsed)
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
}
