import Foundation
import SwiftData

@MainActor
final class GameProgressService: ObservableObject {

    static let longAbsenceThresholdDays: Double = 7
    static let minimumScoreDefault: Int = 60

    @Published private(set) var progress: GameProgress
    private let modelContext: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(modelContext: ModelContext, progress: GameProgress) {
        self.modelContext = modelContext
        self.progress = progress
    }

    static func loadOrCreateProgress(modelContext: ModelContext) -> GameProgress {
        let descriptor = FetchDescriptor<GameProgress>()
        if let existingRecords = try? modelContext.fetch(descriptor), let primary = existingRecords.first {
            for duplicate in existingRecords.dropFirst() {
                modelContext.delete(duplicate)
            }
            if existingRecords.count > 1 {
                _ = try? modelContext.save()
            }
            return primary
        }

        let progress = GameProgress()
        modelContext.insert(progress)
        _ = try? modelContext.save()
        return progress
    }

    static func make(modelContext: ModelContext) -> GameProgressService {
        GameProgressService(modelContext: modelContext, progress: loadOrCreateProgress(modelContext: modelContext))
    }

    func isPhaseUnlocked(_ phaseId: Int) -> Bool {
        if phaseId == 1 { return true }
        return progress.completedPhases.contains(phaseId - 1)
    }

    func isPhaseCompleted(_ phaseId: Int) -> Bool {
        progress.completedPhases.contains(phaseId)
    }

    func isStageUnlocked(phase: Int, stage: Int) -> Bool {
        guard isPhaseUnlocked(phase) else { return false }
        if stage == 1 { return true }
        let previous = StageAddress(phase: phase, stage: stage - 1)
        return completion(for: previous)?.isPassed == true
    }

    func currentAddress() -> StageAddress {
        let address = StageAddress(phase: progress.currentPhase, stage: progress.currentStage)
        if StageCatalog.all.contains(where: { $0.address == address }) {
            return address
        }
        return StageCatalog.introAddress
    }

    func entryAddress() -> StageAddress {
        let address = currentAddress()
        if isStageUnlocked(phase: address.phase, stage: address.stage) {
            return address
        }
        return firstUnlockedStage(inPhase: progress.currentPhase) ?? StageCatalog.introAddress
    }

    func addressForPhaseSelection(_ phase: Int) -> StageAddress {
        firstUnlockedStage(inPhase: phase) ?? StageCatalog.definitions(forPhase: phase).first?.address ?? StageCatalog.introAddress
    }

    func firstUnlockedStage(inPhase phase: Int) -> StageAddress? {
        StageCatalog.definitions(forPhase: phase)
            .map(\.address)
            .first(where: { isStageUnlocked(phase: $0.phase, stage: $0.stage) })
    }

    func completion(for address: StageAddress) -> StageCompletionRecord? {
        var descriptor = FetchDescriptor<StageCompletionRecord>(
            predicate: #Predicate { $0.phase == address.phase && $0.stage == address.stage }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func completionRecords(forPhase phase: Int) -> [StageCompletionRecord] {
        let descriptor = FetchDescriptor<StageCompletionRecord>(
            predicate: #Predicate { $0.phase == phase },
            sortBy: [SortDescriptor(\.stage, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func stageResults(forPhase phase: Int) -> [StageResult] {
        completionRecords(forPhase: phase).map {
            StageResult(phase: $0.phase, stage: $0.stage, score: $0.latestScore, completedAt: $0.completedAt)
        }
    }

    func recordDecision(
        address: StageAddress,
        decisionType: String,
        decision: PlayerDecision,
        optimalDecision: PlayerDecision,
        outcome: StageOutcome?,
        decisionLatencyMs: Int,
        biasTags: [String] = []
    ) {
        progress.currentPhase = address.phase
        progress.currentStage = address.stage
        progress.lastPlayedDate = .now

        let record = DecisionRecord(
            phase: address.phase,
            stage: address.stage,
            decisionType: decisionType,
            playerDecisionJSON: encode(decision),
            optimalDecisionJSON: encode(optimalDecision),
            score: outcome?.score ?? 0,
            decisionLatencyMs: decisionLatencyMs,
            outcomeJSON: outcome.map(encode) ?? "{}",
            biasTags: biasTags
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    func completeStage(address: StageAddress, outcome: StageOutcome) {
        let passingScore = StageCatalog.definition(for: address).minimumPassingScore
        let passed = outcome.score >= passingScore

        if let existing = completion(for: address) {
            existing.latestScore = outcome.score
            existing.latestStars = outcome.starRating
            existing.bestScore = max(existing.bestScore, outcome.score)
            existing.bestStars = max(existing.bestStars, outcome.starRating)
            existing.isPassed = existing.isPassed || passed
            existing.completedAt = .now
        } else {
            let record = StageCompletionRecord(
                phase: address.phase,
                stage: address.stage,
                latestScore: outcome.score,
                bestScore: outcome.score,
                latestStars: outcome.starRating,
                bestStars: outcome.starRating,
                isPassed: passed
            )
            modelContext.insert(record)
        }

        progress.lastPlayedDate = .now
        if passed {
            updateProgressAfterPassing(address: address)
        } else {
            progress.currentPhase = address.phase
            progress.currentStage = address.stage
        }

        clearSession(for: address)
        try? modelContext.save()
    }

    func saveSession(_ snapshot: StageSessionSnapshot) {
        let json = snapshot.pendingDecision.map(encode)
        progress.currentPhase = snapshot.address.phase
        progress.currentStage = snapshot.address.stage
        if let existing = loadStageSessionRecord(for: snapshot.address) {
            existing.flowState = snapshot.flowState.rawValue
            existing.currentPeriod = snapshot.currentPeriod
            existing.failureCount = snapshot.failureCount
            existing.pendingDecisionJSON = json
            existing.timeRemaining = snapshot.timeRemaining
            existing.savedAt = .now
        } else {
            let record = StageSessionRecord(
                phase: snapshot.address.phase,
                stage: snapshot.address.stage,
                flowState: snapshot.flowState.rawValue,
                currentPeriod: snapshot.currentPeriod,
                failureCount: snapshot.failureCount,
                pendingDecisionJSON: json,
                timeRemaining: snapshot.timeRemaining
            )
            modelContext.insert(record)
        }
        progress.lastPlayedDate = .now
        try? modelContext.save()
    }

    func clearSession(for address: StageAddress) {
        if let existing = loadStageSessionRecord(for: address) {
            modelContext.delete(existing)
            try? modelContext.save()
        }
    }

    func loadStageSession() -> StageSessionSnapshot? {
        let descriptor = FetchDescriptor<StageSessionRecord>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        for record in records {
            if let snapshot = validatedSessionSnapshot(from: record) {
                return snapshot
            }
        }
        return nil
    }

    var isReturningAfterLongAbsence: Bool {
        let daysSinceLastPlay = Date().timeIntervalSince(progress.lastPlayedDate) / 86400
        return daysSinceLastPlay >= Self.longAbsenceThresholdDays && !progress.completedPhases.isEmpty
    }

    var recapPhase: PhaseConfig? {
        guard isReturningAfterLongAbsence else { return nil }
        let lastCompleted = progress.completedPhases.max()
        return PhaseConfig.all.first(where: { $0.id == lastCompleted })
    }

    var recapAddress: StageAddress? {
        guard let phase = recapPhase?.id else { return nil }
        return StageCatalog.lastAddress(inPhase: phase)
    }

    func isHardModeAvailable(forPhase phaseId: Int) -> Bool {
        let completions = completionRecords(forPhase: phaseId)
        let expectedCount = StageCatalog.stageCount(forPhase: phaseId)
        guard completions.count == expectedCount else { return false }
        return completions.allSatisfy { $0.bestScore >= 80 }
    }

    // MARK: - Private

    private func updateProgressAfterPassing(address: StageAddress) {
        let phaseStages = StageCatalog.definitions(forPhase: address.phase)
        let isLastStage = phaseStages.last?.address == address
        if isLastStage {
            if !progress.completedPhases.contains(address.phase) {
                progress.completedPhases.append(address.phase)
            }
            if let next = StageCatalog.next(after: address) {
                progress.currentPhase = next.phase
                progress.currentStage = next.stage
            }
        } else if let next = StageCatalog.next(after: address) {
            progress.currentPhase = next.phase
            progress.currentStage = next.stage
        }
    }

    private func loadStageSessionRecord(for address: StageAddress) -> StageSessionRecord? {
        var descriptor = FetchDescriptor<StageSessionRecord>(
            predicate: #Predicate { $0.phase == address.phase && $0.stage == address.stage }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func validatedSessionSnapshot(from record: StageSessionRecord) -> StageSessionSnapshot? {
        let address = StageAddress(phase: record.phase, stage: record.stage)
        guard let flowState = StageFlowSnapshotState(rawValue: record.flowState),
              catalogIndex(for: address) != nil,
              isStageUnlocked(phase: address.phase, stage: address.stage) else {
            discardSessionRecord(record)
            return nil
        }

        if completion(for: address)?.isPassed == true || isSessionBehindProgress(address) {
            discardSessionRecord(record)
            return nil
        }

        return StageSessionSnapshot(
            address: address,
            flowState: flowState,
            currentPeriod: record.currentPeriod,
            failureCount: record.failureCount,
            pendingDecision: record.pendingDecisionJSON.flatMap(decodePlayerDecision),
            timeRemaining: record.timeRemaining
        )
    }

    private func isSessionBehindProgress(_ address: StageAddress) -> Bool {
        guard let sessionIndex = catalogIndex(for: address),
              let progressIndex = catalogIndex(for: currentAddress()) else {
            return false
        }
        return sessionIndex < progressIndex
    }

    private func catalogIndex(for address: StageAddress) -> Int? {
        StageCatalog.all.firstIndex(where: { $0.address == address })
    }

    private func discardSessionRecord(_ record: StageSessionRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        let data = (try? encoder.encode(value)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func decodePlayerDecision(_ json: String) -> PlayerDecision? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? decoder.decode(PlayerDecision.self, from: data)
    }
}
