import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class FirstTimeUserExperienceTests: XCTestCase {

    // MARK: - AC1: Intro shows 'Your money is disappearing'

    func testIntroMessage_containsKeyPhrase() {
        XCTAssertTrue(
            IntroAnimationView.introMessage.lowercased().contains("money"),
            "Intro message must mention 'money'"
        )
        XCTAssertTrue(
            IntroAnimationView.introMessage.lowercased().contains("disappearing"),
            "Intro message must convey 'disappearing'"
        )
    }

    func testIntroSubtitle_presentsEngagingFollowUp() {
        XCTAssertFalse(IntroAnimationView.introSubtitle.isEmpty,
                       "Intro subtitle must not be empty")
    }

    // MARK: - AC2: No signup gate — intro routes straight into the game loop

    func testBootstrap_newUser_startsAtIntro() throws {
        let (_, _, service) = try TestDataFactory.makeService(progress: GameProgress(hasSeenIntro: false))
        let vm = AppViewModel()

        vm.bootstrap(using: service)

        XCTAssertEqual(vm.currentRoute, .intro)
    }

    func testBootstrap_returningUser_skipsIntroToCurrentStage() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 2, hasSeenIntro: true)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        let vm = AppViewModel()

        vm.bootstrap(using: service)

        XCTAssertEqual(vm.currentRoute, .stage(StageAddress(phase: 1, stage: 1)),
                       "Locked current stage should fall back to the current unlocked stage")
    }

    func testBootstrap_savedSession_resumesThatStage() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 1, hasSeenIntro: true)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        service.completeStage(address: StageAddress(phase: 1, stage: 1), outcome: TestDataFactory.makeOutcome(score: 80))
        let snapshot = StageSessionSnapshot(
            address: StageAddress(phase: 1, stage: 2),
            flowState: .decision,
            currentPeriod: 0,
            failureCount: 1,
            pendingDecision: nil,
            timeRemaining: 12
        )
        service.saveSession(snapshot)

        let vm = AppViewModel()
        vm.bootstrap(using: service)

        XCTAssertEqual(vm.currentRoute, .stage(StageAddress(phase: 1, stage: 2)))
    }

    func testBootstrap_ignoresStaleLevelOneSessionWhenProgressHasAdvanced() throws {
        let progress = GameProgress(hasSeenIntro: true)
        let (_, context, service) = try TestDataFactory.makeService(progress: progress)
        service.completeStage(address: StageAddress(phase: 1, stage: 1), outcome: TestDataFactory.makeOutcome(score: 80))
        context.insert(
            StageSessionRecord(
                phase: 1,
                stage: 1,
                flowState: StageFlowSnapshotState.briefing.rawValue,
                currentPeriod: 0,
                failureCount: 0,
                pendingDecisionJSON: nil,
                timeRemaining: 0
            )
        )
        try context.save()

        let vm = AppViewModel()
        vm.bootstrap(using: service)

        XCTAssertEqual(vm.currentRoute, .stage(StageAddress(phase: 1, stage: 2)))
    }

    // MARK: - AC3: Phase 1 Stage 1 starts after intro

    func testCompleteIntro_routesToStageOneAndMarksProgress() throws {
        let progress = GameProgress(hasSeenIntro: false)
        let (_, context, service) = try TestDataFactory.makeService(progress: progress)
        let vm = AppViewModel()

        vm.completeIntro(using: service)
        try context.save()

        XCTAssertEqual(vm.currentRoute, .stage(StageCatalog.introAddress))
        XCTAssertTrue(progress.hasSeenIntro)
    }

    func testBootstrap_longAbsentReturningUser_showsRecap() throws {
        let longAgo = Date().addingTimeInterval(-8 * 86_400)
        let progress = GameProgress(
            currentPhase: 3,
            currentStage: 1,
            completedPhases: [1, 2],
            lastPlayedDate: longAgo,
            hasSeenIntro: true
        )
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        let vm = AppViewModel()

        vm.bootstrap(using: service)

        XCTAssertEqual(vm.currentRoute, .recap(StageCatalog.lastAddress(inPhase: 2)!))
    }

    // MARK: - AC4: Intro animation ≤ 30 seconds

    func testIntroDuration_under30Seconds() {
        XCTAssertLessThanOrEqual(
            IntroAnimationView.introDurationSeconds, 30.0,
            "Intro animation must auto-complete in ≤ 30 seconds"
        )
    }

    func testIntroDuration_engagingWithin4Seconds() {
        XCTAssertLessThanOrEqual(
            IntroAnimationView.introDurationSeconds, 4.0,
            "Intro animation should be brief (≤ 4 seconds) for quick engagement"
        )
    }

    // MARK: - AC5: Stage 2 auto-unlocks after Stage 1 completion

    func testStage2_autoUnlocksAfterStage1() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        let address = StageAddress(phase: 1, stage: 1)

        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 1))
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2))

        service.completeStage(address: address, outcome: TestDataFactory.makeOutcome(score: 70))

        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 2))
    }

    func testStage2_doesNotUnlockWithFailingScore() throws {
        let (_, _, service) = try TestDataFactory.makeService()

        service.completeStage(
            address: StageAddress(phase: 1, stage: 1),
            outcome: TestDataFactory.makeOutcome(
                score: 30,
                decision: PlayerDecision.holdCash,
                optimal: PlayerDecision.binary(choice: "A")
            )
        )

        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2))
    }
}
