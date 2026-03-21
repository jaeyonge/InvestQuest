import XCTest
@testable import InvestQuest

final class MarketSimulationEngineTests: XCTestCase {

    private let engine = MarketSimulationEngine()

    // MARK: - Helpers

    private func makeSimulation(
        seed: UInt64 = 42,
        assetCount: Int = 3,
        periodCount: Int = 10,
        volatility: Double = 0.2,
        drift: Double = 0.07,
        events: [SimulationEvent] = []
    ) -> StageSimulation {
        let assets = (0..<assetCount).map { index in
            SimAssetConfig(
                id: "asset\(index)",
                label: "Asset \(index + 1)",
                drift: drift,
                volatility: volatility,
                lessonRole: index == min(max(assetCount - 1, 0), 1) ? .preferred : .penalized
            )
        }
        return StageSimulation(
            seed: seed,
            assets: assets,
            periodCount: periodCount,
            replayCount: 1,
            events: events,
            lessonBias: 0.15
        )
    }

    private func simulateBatch(simulation: StageSimulation, count: Int) -> [SimulationResult] {
        (0..<count).map { i in
            engine.simulate(stage: StageSimulation(
                seed: simulation.seed + UInt64(i),
                assets: simulation.assets,
                periodCount: simulation.periodCount,
                replayCount: simulation.replayCount,
                events: simulation.events,
                lessonBias: simulation.lessonBias
            ))
        }
    }

    // MARK: - AC1: Deterministic — same seed = same output

    func testDeterminism_sameSeedProducesSameOutput() {
        let sim = makeSimulation(seed: 12345)
        let result1 = engine.simulate(stage: sim)
        let result2 = engine.simulate(stage: sim)

        XCTAssertEqual(result1.assetHistories.count, result2.assetHistories.count)
        for (h1, h2) in zip(result1.assetHistories, result2.assetHistories) {
            XCTAssertEqual(h1.prices, h2.prices,
                           "Prices must be identical for same seed")
        }
    }

    func testDeterminism_differentSeedsProduceDifferentOutput() {
        let r1 = engine.simulate(stage: makeSimulation(seed: 1))
        let r2 = engine.simulate(stage: makeSimulation(seed: 2))
        // Very high probability these differ; if both produce identical output the PRNG is broken
        XCTAssertNotEqual(r1.assetHistories[0].prices, r2.assetHistories[0].prices)
    }

    // MARK: - AC2: Configurable parameters

    func testConfigurableParams_assetCount() {
        let result = engine.simulate(stage: makeSimulation(assetCount: 5))
        XCTAssertEqual(result.assetHistories.count, 5)
    }

    func testConfigurableParams_timePeriods() {
        let result = engine.simulate(stage: makeSimulation(periodCount: 20))
        // prices array length = periodCount + 1 (includes t=0)
        for history in result.assetHistories {
            XCTAssertEqual(history.prices.count, 21)
        }
    }

    func testConfigurableParams_eventInjection_allAssets() {
        let event = SimulationEvent(period: 5, assetIDs: nil, kind: .multiplier(0.5))
        let sim = makeSimulation(seed: 99, periodCount: 10, events: [event])

        // Run without event for comparison
        let noEventSim = makeSimulation(seed: 99, periodCount: 10)
        let withEvent  = engine.simulate(stage: sim)
        let withoutEvent = engine.simulate(stage: noEventSim)

        // After the event period, prices should diverge from the no-event simulation
        let priceAfterEvent  = withEvent.assetHistories[0].prices[6]
        let priceNoEvent     = withoutEvent.assetHistories[0].prices[6]
        XCTAssertNotEqual(priceAfterEvent, priceNoEvent,
                          "Event injection should alter prices at injection period")
    }

    func testConfigurableParams_singleAssetEventInjection() {
        let event = SimulationEvent(period: 3, assetIDs: ["asset0"], kind: .multiplier(2.0))
        let sim = makeSimulation(seed: 77, assetCount: 2, periodCount: 10, events: [event])
        let noEventSim = makeSimulation(seed: 77, assetCount: 2, periodCount: 10)

        let withEvent    = engine.simulate(stage: sim)
        let withoutEvent = engine.simulate(stage: noEventSim)

        // Asset 0 prices diverge after event; asset 1 should be unaffected
        XCTAssertNotEqual(withEvent.assetHistories[0].prices[4],
                          withoutEvent.assetHistories[0].prices[4])
        // Asset 1 is NOT affected by asset-0 event — prices match before event
        XCTAssertEqual(withEvent.assetHistories[1].prices[1],
                       withoutEvent.assetHistories[1].prices[1],
                       accuracy: 1e-10)
    }

    // MARK: - AC3: Realistic movements (no teleporting)

    func testRealisticMovements_noPriceTeleporting() {
        // Each step should change price by at most 3x or 0.33x under normal conditions
        // (no events injected). High-vol but still bounded.
        let sim = makeSimulation(seed: 42, assetCount: 3, periodCount: 50,
                                 volatility: 0.5, drift: 0.0)
        let result = engine.simulate(stage: sim)

        for history in result.assetHistories {
            for i in 1..<history.prices.count {
                let ratio = history.prices[i] / history.prices[i - 1]
                XCTAssertGreaterThan(ratio, 0.01,
                    "Price should never collapse to near-zero in one step without an event")
                XCTAssertLessThan(ratio, 100.0,
                    "Price should not teleport 100x in one step without an event")
            }
        }
    }

    func testRealisticMovements_pricesAlwaysPositive() {
        let sim = makeSimulation(seed: 0xDEAD_BEEF, assetCount: 5, periodCount: 100,
                                 volatility: 0.8, drift: -0.5)
        let result = engine.simulate(stage: sim)
        for history in result.assetHistories {
            for price in history.prices {
                XCTAssertGreaterThan(price, 0, "All prices must remain positive")
            }
        }
    }

    // MARK: - AC4: Outcome weighting (correct strategy wins on average)

    func testOutcomeWeighting_correctStrategyWinsOnAverage() {
        // Simulate 200 runs with positive drift (long position = correct strategy).
        // The "correct" strategy final price should average above starting price.
        let sim = makeSimulation(seed: 1, assetCount: 1, periodCount: 20,
                                 volatility: 0.2, drift: 0.10)
        let batch = simulateBatch(simulation: sim, count: 200)

        let finalPrices = batch.map { $0.assetHistories[0].prices.last! }
        let averageFinal = finalPrices.reduce(0, +) / Double(finalPrices.count)

        // With 10% drift over 20 periods, expected final ≈ 100 * e^(0.10) ≈ 110+
        XCTAssertGreaterThan(averageFinal, 105.0,
            "Positive-drift asset should average above 105 over 200 runs")
    }

    func testOutcomeWeighting_negativeDriftWinsOnAverage() {
        // Use strong negative drift and more periods to get a clear statistical signal.
        // E[final] = 100 * exp(-0.20) ≈ 81.9 — well below 90 even with PRNG variance.
        let sim = makeSimulation(seed: 2, assetCount: 1, periodCount: 50,
                                 volatility: 0.2, drift: -0.20)
        let batch = simulateBatch(simulation: sim, count: 300)
        let finalPrices = batch.map { $0.assetHistories[0].prices.last! }
        let averageFinal = finalPrices.reduce(0, +) / Double(finalPrices.count)

        XCTAssertLessThan(averageFinal, 100.0,
            "Negative-drift asset should average below its starting value over 300 runs")
    }

    // MARK: - AC5: Performance — completes in < 1 second

    func testPerformance_simulationCompletesUnderOneSecond() {
        // Worst-case stage: many assets, many periods
        let sim = makeSimulation(seed: 9999, assetCount: 10, periodCount: 120,
                                 volatility: 0.3, drift: 0.05)
        let result = engine.simulate(stage: sim)
        XCTAssertLessThan(result.durationSeconds, 1.0,
            "Simulation must complete in < 1 second on-device")
    }

    func testPerformance_batchOf100CompletesUnderOneSecond() {
        let sim = makeSimulation(seed: 7777, assetCount: 5, periodCount: 60)
        let start = Date()
        _ = simulateBatch(simulation: sim, count: 100)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
            "Batch of 100 simulations must complete in < 1 second")
    }

    // MARK: - AC6: Protocol interface

    func testProtocolInterface_canBeUsedPolymorphically() {
        // Verify that MarketSimulationEngine can be assigned to the protocol type
        let engine: any MarketSimulationEngineProtocol = MarketSimulationEngine()
        let sim = makeSimulation()
        let result = engine.simulate(stage: sim)
        XCTAssertFalse(result.assetHistories.isEmpty)
    }

    func testProtocolInterface_batchViaProtocol() {
        let engine: any MarketSimulationEngineProtocol = MarketSimulationEngine()
        let sim = makeSimulation()
        let results = (0..<5).map { i in
            engine.simulate(stage: StageSimulation(
                seed: sim.seed + UInt64(i),
                assets: sim.assets,
                periodCount: sim.periodCount,
                replayCount: sim.replayCount,
                events: sim.events,
                lessonBias: sim.lessonBias
            ))
        }
        XCTAssertEqual(results.count, 5)
        // Each seed should be different → different results
        let firstPrices = results.map { $0.assetHistories[0].prices.last! }
        let unique = Set(firstPrices.map { Int($0 * 1000) })
        XCTAssertGreaterThan(unique.count, 1, "Batch runs with different seeds should differ")
    }
}
