import Foundation
import SwiftData

/// Manages phase/stage unlock logic, auto-save, and returning-user detection.
/// All mutation methods persist state to the provided GameProgress SwiftData model.
@MainActor
final class GameProgressService: ObservableObject {

    // MARK: - Constants

    static let longAbsenceThresholdDays: Double = 7
    static let minimumScoreDefault: Int = 60

    // MARK: - State

    @Published private(set) var progress: GameProgress
    private(set) var stageResults: [StageResult] = []

    init(progress: GameProgress) {
        self.progress = progress
    }

    // MARK: - Phase unlock queries

    /// Returns true when the given phase is unlocked (available to play).
    /// Phase 1 is always unlocked. Phase N requires Phase N-1 to be completed.
    func isPhaseUnlocked(_ phaseId: Int) -> Bool {
        if phaseId == 1 { return true }
        return progress.completedPhases.contains(phaseId - 1)
    }

    /// Returns true when all stages in phaseId have been completed.
    func isPhaseCompleted(_ phaseId: Int) -> Bool {
        progress.completedPhases.contains(phaseId)
    }

    // MARK: - Stage unlock queries

    /// Returns true when the given stage within a phase is unlocked.
    /// Stage 1 is always unlocked if the phase is unlocked.
    /// Stage N requires stage N-1 score ≥ minimumScoreToAdvance.
    func isStageUnlocked(phase: Int, stage: Int) -> Bool {
        guard isPhaseUnlocked(phase) else { return false }
        if stage == 1 { return true }
        let minScore = PhaseConfig.all.first(where: { $0.id == phase })?.minimumScoreToAdvance
            ?? Self.minimumScoreDefault
        let previousResult = stageResults.first(where: { $0.phase == phase && $0.stage == stage - 1 })
        return (previousResult?.score ?? 0) >= minScore
    }

    // MARK: - Progress recording

    /// Called every time the player makes a decision or a simulation step completes.
    /// Updates GameProgress (auto-save is triggered by SwiftData's @Model).
    func recordDecision(phase: Int, stage: Int,
                        decisionType: String, value: Double, optimalValue: Double,
                        modelContext: ModelContext) {
        progress.currentPhase = phase
        progress.currentStage = stage
        progress.lastPlayedDate = .now

        let record = DecisionRecord(
            phase: phase,
            stage: stage,
            decisionType: decisionType,
            value: value,
            optimalValue: optimalValue
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    /// Called when a stage is completed with a final score.
    func completeStage(phase: Int, stage: Int, score: Int, modelContext: ModelContext) {
        let result = StageResult(phase: phase, stage: stage, score: score, completedAt: .now)
        // Replace existing result if re-played
        stageResults.removeAll { $0.phase == phase && $0.stage == stage }
        stageResults.append(result)

        let config = PhaseConfig.all.first(where: { $0.id == phase })
        let isLastStage = (stage == (config?.stageCount ?? 0))

        if isLastStage {
            completePhase(phaseId: phase, modelContext: modelContext)
        }

        progress.lastPlayedDate = .now
        try? modelContext.save()
    }

    // MARK: - Returning user

    /// True when the user has been absent for ≥ longAbsenceThresholdDays.
    var isReturningAfterLongAbsence: Bool {
        let daysSinceLastPlay = Date().timeIntervalSince(progress.lastPlayedDate) / 86400
        return daysSinceLastPlay >= Self.longAbsenceThresholdDays
            && !progress.completedPhases.isEmpty
    }

    /// The phase/concept to recap for a returning user (last completed phase).
    var recapPhase: PhaseConfig? {
        guard isReturningAfterLongAbsence else { return nil }
        let lastCompleted = progress.completedPhases.max()
        return PhaseConfig.all.first(where: { $0.id == lastCompleted })
    }

    // MARK: - Private

    private func completePhase(phaseId: Int, modelContext: ModelContext) {
        if !progress.completedPhases.contains(phaseId) {
            progress.completedPhases.append(phaseId)
        }
        // Advance to first stage of next phase if available
        if phaseId < 7 {
            progress.currentPhase = phaseId + 1
            progress.currentStage = 1
        }
        try? modelContext.save()
    }
}
