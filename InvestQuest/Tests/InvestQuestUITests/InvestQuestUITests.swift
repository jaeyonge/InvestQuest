import XCTest

final class InvestQuestUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchRoutesFromIntroToStageOne() {
        let app = launchApp(storeName: #function)

        XCTAssertTrue(app.buttons["intro-start"].waitForExistence(timeout: 5))
        app.buttons["intro-start"].tap()

        XCTAssertTrue(element(in: app, id: "stage-briefing").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Phase 1 · Stage 1"].waitForExistence(timeout: 5))
    }

    func testCompletingStageOneUnlocksStageTwo() {
        let app = launchApp(storeName: #function)
        completeIntroIfNeeded(app)
        completeStageOne(app)

        XCTAssertTrue(app.staticTexts["Cash vs. Savings"].waitForExistence(timeout: 5))
    }

    func testPhaseMapOnlyEnablesUnlockedPhases() {
        let app = launchApp(storeName: #function)
        completeIntroIfNeeded(app)

        XCTAssertTrue(app.buttons["open-phase-map"].waitForExistence(timeout: 5))
        app.buttons["open-phase-map"].tap()

        let phase1 = element(in: app, id: "phase-node-1")
        let phase2 = element(in: app, id: "phase-node-2")
        XCTAssertTrue(phase1.waitForExistence(timeout: 5))
        XCTAssertTrue(phase2.waitForExistence(timeout: 5))
        XCTAssertTrue(phase1.isEnabled)
        XCTAssertFalse(phase2.isEnabled)
    }

    func testTimedStageCountsDownAndAutoSubmitsOnTimeout() {
        let app = launchApp(
            storeName: #function,
            seed: UITestSeed(
                progress: .init(
                    currentPhase: 7,
                    currentStage: 1,
                    completedPhases: [1, 2, 3, 4, 5, 6],
                    hasSeenIntro: true
                )
            )
        )

        XCTAssertTrue(element(in: app, id: "stage-briefing").waitForExistence(timeout: 5))
        startStageButton(in: app).tap()

        let timerLabel = element(in: app, id: "decision-timer-label")
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 5))
        let initialValue = timerLabel.label
        sleep(2)
        XCTAssertNotEqual(timerLabel.label, initialValue)

        let simulation = element(in: app, id: "stage-simulation")
        let resultsButton = waitForButton(in: app, identifiers: ["see-results", "See Results"], timeout: 10)
        XCTAssertTrue(
            simulation.exists || resultsButton.exists,
            "Timed stages should auto-submit into the simulation/result flow after timeout"
        )
    }

    func testRelaunchResumesInterruptedSimulation() {
        let storeName = #function
        let firstLaunch = launchApp(
            storeName: storeName,
            seed: UITestSeed(
                progress: .init(
                    currentPhase: 1,
                    currentStage: 1,
                    completedPhases: [],
                    hasSeenIntro: true
                )
            )
        )

        XCTAssertTrue(element(in: firstLaunch, id: "stage-briefing").waitForExistence(timeout: 5))
        startStageButton(in: firstLaunch).tap()
        XCTAssertTrue(firstLaunch.buttons["observe"].waitForExistence(timeout: 5))
        firstLaunch.buttons["observe"].tap()
        XCTAssertTrue(element(in: firstLaunch, id: "stage-simulation").waitForExistence(timeout: 5))
        firstLaunch.terminate()

        let secondLaunch = launchApp(storeName: storeName, reset: false)
        let resumedSimulation = element(in: secondLaunch, id: "stage-simulation")
        let resumedResult = element(in: secondLaunch, id: "stage-result")

        XCTAssertTrue(
            resumedSimulation.waitForExistence(timeout: 5) || resumedResult.waitForExistence(timeout: 5),
            "Relaunch should restore the saved simulation flow instead of briefing"
        )
        XCTAssertFalse(element(in: secondLaunch, id: "stage-briefing").exists)
    }

    func testBehavioralReviewUsesStoredDecisionHistory() {
        let seed = UITestSeed(
            progress: .init(
                currentPhase: 7,
                currentStage: 4,
                completedPhases: [1, 2, 3, 4, 5, 6],
                hasSeenIntro: true
            ),
            completions: [
                .passed(phase: 7, stage: 1),
                .passed(phase: 7, stage: 2),
                .passed(phase: 7, stage: 3)
            ],
            decisions: [
                .init(phase: 5, stage: 4, decisionType: "binary", score: 30, biasTags: ["loss-aversion"]),
                .init(phase: 7, stage: 1, decisionType: "binary", score: 100, biasTags: ["recency-bias-resisted"]),
                .init(phase: 7, stage: 2, decisionType: "binary", score: 25, biasTags: ["herd-behavior"]),
                .init(phase: 7, stage: 3, decisionType: "binary", score: 20, biasTags: ["anchoring-bias"])
            ]
        )
        let app = launchApp(storeName: #function, seed: seed)

        XCTAssertTrue(element(in: app, id: "stage-briefing").waitForExistence(timeout: 5))
        startStageButton(in: app).tap()

        XCTAssertTrue(element(in: app, id: "behavioral-review-summary").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Detected 1 time. Recent example: Phase 7 Stage 3."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Detected 1 time. Recent example: Phase 5 Stage 4."].waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    @discardableResult
    private func launchApp(
        storeName: String,
        reset: Bool = true,
        seed: UITestSeed? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["UITESTING"]
        app.launchEnvironment["INVESTQUEST_UI_STORE"] = sanitizedStoreName(storeName)
        app.launchEnvironment["INVESTQUEST_UI_DISABLE_ANIMATIONS"] = "1"
        if reset {
            app.launchEnvironment["INVESTQUEST_UI_RESET"] = "1"
        }
        if let seed {
            app.launchEnvironment["INVESTQUEST_UI_SEED"] = encodedSeed(seed)
        }
        app.launch()
        return app
    }

    private func completeIntroIfNeeded(_ app: XCUIApplication) {
        if app.buttons["intro-start"].waitForExistence(timeout: 5) {
            app.buttons["intro-start"].tap()
        }
        XCTAssertTrue(element(in: app, id: "stage-briefing").waitForExistence(timeout: 5))
    }

    private func completeStageOne(_ app: XCUIApplication) {
        let startStage = startStageButton(in: app)
        XCTAssertTrue(startStage.waitForExistence(timeout: 5))
        startStage.tap()

        XCTAssertTrue(app.buttons["observe"].waitForExistence(timeout: 5))
        app.buttons["observe"].tap()

        let seeResults = waitForButton(in: app, identifiers: ["see-results", "See Results"], timeout: 10)
        XCTAssertTrue(seeResults.exists)
        seeResults.tap()

        let seeInsight = waitForButton(in: app, identifiers: ["see-insight", "See Insight"], timeout: 5)
        XCTAssertTrue(seeInsight.exists)
        seeInsight.tap()

        XCTAssertTrue(app.buttons["continue-from-insight"].waitForExistence(timeout: 5))
        app.buttons["continue-from-insight"].tap()
    }

    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    private func startStageButton(in app: XCUIApplication) -> XCUIElement {
        primaryButton(in: app, identifiers: ["start-stage", "Start Stage"])
    }

    private func primaryButton(in app: XCUIApplication, identifiers: [String]) -> XCUIElement {
        for identifier in identifiers {
            let button = app.buttons[identifier]
            if button.exists {
                return button
            }
        }
        return app.buttons[identifiers[0]]
    }

    private func waitForButton(
        in app: XCUIApplication,
        identifiers: [String],
        timeout: TimeInterval
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let button = primaryButton(in: app, identifiers: identifiers)
            if button.exists {
                return button
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return app.buttons[identifiers[0]]
    }

    private func sanitizedStoreName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "()", with: "")
            .replacingOccurrences(of: " ", with: "-")
    }

    private func encodedSeed(_ seed: UITestSeed) -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(seed)
        return String(data: data, encoding: .utf8)!
    }
}

private struct UITestSeed: Encodable {
    var progress: UITestProgressSeed?
    var completions: [UITestStageCompletionSeed] = []
    var decisions: [UITestDecisionSeed] = []
    var phaseCompletions: [UITestPhaseCompletionSeed] = []
}

private struct UITestProgressSeed: Encodable {
    let currentPhase: Int
    let currentStage: Int
    let completedPhases: [Int]
    let hasSeenIntro: Bool
    let lastPlayedDate: Date

    init(
        currentPhase: Int,
        currentStage: Int,
        completedPhases: [Int],
        hasSeenIntro: Bool,
        lastPlayedDate: Date = .now
    ) {
        self.currentPhase = currentPhase
        self.currentStage = currentStage
        self.completedPhases = completedPhases
        self.hasSeenIntro = hasSeenIntro
        self.lastPlayedDate = lastPlayedDate
    }
}

private struct UITestStageCompletionSeed: Encodable {
    let phase: Int
    let stage: Int
    let latestScore: Int
    let bestScore: Int
    let latestStars: Int
    let bestStars: Int
    let isPassed: Bool
    let completedAt: Date

    static func passed(phase: Int, stage: Int, score: Int = 100, stars: Int = 3) -> UITestStageCompletionSeed {
        UITestStageCompletionSeed(
            phase: phase,
            stage: stage,
            latestScore: score,
            bestScore: score,
            latestStars: stars,
            bestStars: stars,
            isPassed: true,
            completedAt: .now
        )
    }
}

private struct UITestDecisionSeed: Encodable {
    let phase: Int
    let stage: Int
    let decisionType: String
    let playerDecisionChoice: String?
    let optimalDecisionChoice: String?
    let score: Int
    let decisionLatencyMs: Int
    let biasTags: [String]
    let timestamp: Date

    init(
        phase: Int,
        stage: Int,
        decisionType: String,
        playerDecisionChoice: String? = nil,
        optimalDecisionChoice: String? = nil,
        score: Int,
        decisionLatencyMs: Int = 1200,
        biasTags: [String],
        timestamp: Date = .now
    ) {
        self.phase = phase
        self.stage = stage
        self.decisionType = decisionType
        self.playerDecisionChoice = playerDecisionChoice
        self.optimalDecisionChoice = optimalDecisionChoice
        self.score = score
        self.decisionLatencyMs = decisionLatencyMs
        self.biasTags = biasTags
        self.timestamp = timestamp
    }
}

private struct UITestPhaseCompletionSeed: Encodable {
    let phaseId: Int
    let conceptName: String
    let completedAt: Date
    let averageScore: Int
    let badgeIdentifier: String
    let decisionSummaryJSON: String
}
