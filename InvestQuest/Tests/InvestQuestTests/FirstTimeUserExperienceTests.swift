import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class FirstTimeUserExperienceTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: GameProgress.self, DecisionRecord.self, PhaseCompletionRecord.self,
            configurations: config
        )
        return ModelContext(container)
    }

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

    // MARK: - AC2: No signup gate — AppViewModel goes straight to phaseMap after intro

    func testAppViewModel_newUser_startsAtIntro() {
        let vm = AppViewModel(progress: nil)
        XCTAssertEqual(vm.currentRoute, .intro,
                       "New user with no progress must start at intro")
    }

    func testAppViewModel_returningUser_skipsIntroToPhaseMap() {
        let progress = GameProgress(hasSeenIntro: true)
        let vm = AppViewModel(progress: progress)
        XCTAssertEqual(vm.currentRoute, .phaseMap,
                       "Returning user must skip intro and go directly to phase map")
    }

    func testAppViewModel_noSignupOrOnboardingGate() {
        // After intro completes, route is immediately phaseMap (no tutorial/signup intermediate)
        let vm = AppViewModel(progress: nil)
        XCTAssertEqual(vm.currentRoute, .intro)
        // completeIntro goes directly to .phaseMap — no intermediate state
    }

    // MARK: - AC3: Phase 1 Stage 1 starts after intro

    func testAppViewModel_completeIntro_routesToPhaseMap() throws {
        let context = try makeInMemoryContext()
        let vm = AppViewModel(progress: nil)
        vm.completeIntro(modelContext: context)
        XCTAssertEqual(vm.currentRoute, .phaseMap,
                       "After intro completes, app must route to phase map")
    }

    func testAppViewModel_completeIntro_persistsHasSeenIntro() throws {
        let context = try makeInMemoryContext()
        let vm = AppViewModel(progress: nil)
        vm.completeIntro(modelContext: context)

        let descriptor = FetchDescriptor<GameProgress>()
        let records = try context.fetch(descriptor)
        XCTAssertTrue(records.first?.hasSeenIntro ?? false,
                      "hasSeenIntro must be persisted after intro completion")
    }

    func testFirstLaunch_newUser_isFirstLaunch() {
        let vm = AppViewModel(progress: nil)
        XCTAssertTrue(vm.isFirstLaunch)
    }

    func testFirstLaunch_returningUser_isNotFirstLaunch() {
        let progress = GameProgress(hasSeenIntro: true)
        let vm = AppViewModel(progress: progress)
        XCTAssertFalse(vm.isFirstLaunch)
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
        let context = try makeInMemoryContext()
        let progress = GameProgress()
        context.insert(progress)
        let service = GameProgressService(progress: progress)

        // Stage 1 of phase 1 is unlocked by default
        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 1))
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2),
                       "Stage 2 must be locked before Stage 1 is completed")

        // Complete Stage 1 with passing score
        service.completeStage(phase: 1, stage: 1, score: 70, modelContext: context)

        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 2),
                      "Stage 2 must automatically unlock after Stage 1 completion with passing score")
    }

    func testStage2_doesNotUnlockWithFailingScore() throws {
        let context = try makeInMemoryContext()
        let progress = GameProgress()
        context.insert(progress)
        let service = GameProgressService(progress: progress)

        service.completeStage(phase: 1, stage: 1, score: 30, modelContext: context)
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2),
                       "Stage 2 must not unlock when Stage 1 score is below threshold")
    }
}
