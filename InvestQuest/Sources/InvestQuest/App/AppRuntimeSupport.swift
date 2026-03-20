import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

enum AppRuntimeSupport {
    static let uiTestingArgument = "UITESTING"
    static let uiStoreEnvironmentKey = "INVESTQUEST_UI_STORE"
    static let uiResetEnvironmentKey = "INVESTQUEST_UI_RESET"
    static let uiSeedEnvironmentKey = "INVESTQUEST_UI_SEED"
    static let uiDisableAnimationsEnvironmentKey = "INVESTQUEST_UI_DISABLE_ANIMATIONS"

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingArgument)
    }

    static var shouldDisableAnimations: Bool {
        ProcessInfo.processInfo.environment[uiDisableAnimationsEnvironmentKey] == "1"
    }

    static func makeModelContainer() -> ModelContainer {
        let configuration: ModelConfiguration
        if let storeURL = uiStoreURL() {
            if shouldResetUIStore {
                resetStore(at: storeURL)
            }
            configuration = ModelConfiguration(
                "InvestQuestUITests",
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration("InvestQuest", cloudKitDatabase: .none)
        }

        do {
            return try ModelContainer(
                for: GameProgress.self,
                DecisionRecord.self,
                StageCompletionRecord.self,
                StageSessionRecord.self,
                PhaseCompletionRecord.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    static func configureForLaunch() {
        #if canImport(UIKit)
        if shouldDisableAnimations {
            UIView.setAnimationsEnabled(false)
        }
        #endif
    }

    private static var shouldResetUIStore: Bool {
        ProcessInfo.processInfo.environment[uiResetEnvironmentKey] == "1"
    }

    private static func uiStoreURL() -> URL? {
        guard isUITesting,
              let storeName = ProcessInfo.processInfo.environment[uiStoreEnvironmentKey],
              !storeName.isEmpty else {
            return nil
        }

        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("InvestQuestUITests", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(storeName).store")
    }

    private static func resetStore(at url: URL) {
        let fileManager = FileManager.default
        let sidecars = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]

        for candidate in sidecars where fileManager.fileExists(atPath: candidate.path) {
            try? fileManager.removeItem(at: candidate)
        }
    }
}

@MainActor
enum UITestSeedBootstrapper {
    private static var hasAppliedSeed = false

    static func applyIfNeeded(modelContext: ModelContext) {
        guard AppRuntimeSupport.isUITesting, !hasAppliedSeed else { return }
        hasAppliedSeed = true

        guard let payload = ProcessInfo.processInfo.environment[AppRuntimeSupport.uiSeedEnvironmentKey],
              let data = payload.data(using: .utf8),
              let seed = try? JSONDecoder().decode(UITestSeed.self, from: data) else {
            return
        }

        clearAllData(modelContext: modelContext)
        apply(seed: seed, modelContext: modelContext)
        try? modelContext.save()
    }

    private static func clearAllData(modelContext: ModelContext) {
        deleteAll(GameProgress.self, modelContext: modelContext)
        deleteAll(DecisionRecord.self, modelContext: modelContext)
        deleteAll(StageCompletionRecord.self, modelContext: modelContext)
        deleteAll(StageSessionRecord.self, modelContext: modelContext)
        deleteAll(PhaseCompletionRecord.self, modelContext: modelContext)
    }

    private static func deleteAll<Model: PersistentModel>(_ type: Model.Type, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Model>()
        let models = (try? modelContext.fetch(descriptor)) ?? []
        for model in models {
            modelContext.delete(model)
        }
    }

    private static func apply(seed: UITestSeed, modelContext: ModelContext) {
        if let progress = seed.progress {
            modelContext.insert(
                GameProgress(
                    currentPhase: progress.currentPhase,
                    currentStage: progress.currentStage,
                    completedPhases: progress.completedPhases,
                    lastPlayedDate: progress.lastPlayedDate,
                    hasSeenIntro: progress.hasSeenIntro
                )
            )
        }

        for completion in seed.completions {
            modelContext.insert(
                StageCompletionRecord(
                    phase: completion.phase,
                    stage: completion.stage,
                    latestScore: completion.latestScore,
                    bestScore: completion.bestScore,
                    latestStars: completion.latestStars,
                    bestStars: completion.bestStars,
                    isPassed: completion.isPassed,
                    completedAt: completion.completedAt
                )
            )
        }

        for record in seed.decisions {
            modelContext.insert(
                DecisionRecord(
                    phase: record.phase,
                    stage: record.stage,
                    decisionType: record.decisionType,
                    playerDecisionJSON: playerDecisionJSON(choice: record.playerDecisionChoice),
                    optimalDecisionJSON: playerDecisionJSON(choice: record.optimalDecisionChoice),
                    score: record.score,
                    decisionLatencyMs: record.decisionLatencyMs,
                    outcomeJSON: "{}",
                    biasTags: record.biasTags,
                    timestamp: record.timestamp
                )
            )
        }

        for phaseCompletion in seed.phaseCompletions {
            modelContext.insert(
                PhaseCompletionRecord(
                    phaseId: phaseCompletion.phaseId,
                    conceptName: phaseCompletion.conceptName,
                    completedAt: phaseCompletion.completedAt,
                    averageScore: phaseCompletion.averageScore,
                    badgeIdentifier: phaseCompletion.badgeIdentifier,
                    decisionSummaryJSON: phaseCompletion.decisionSummaryJSON
                )
            )
        }
    }

    private static func playerDecisionJSON(choice: String?) -> String {
        let decision: PlayerDecision
        if let choice {
            decision = .binary(choice: choice)
        } else {
            decision = .holdCash
        }

        let data = (try? JSONEncoder().encode(decision)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

private struct UITestSeed: Decodable {
    let progress: UITestProgressSeed?
    let completions: [UITestStageCompletionSeed]
    let decisions: [UITestDecisionSeed]
    let phaseCompletions: [UITestPhaseCompletionSeed]

    init(
        progress: UITestProgressSeed? = nil,
        completions: [UITestStageCompletionSeed] = [],
        decisions: [UITestDecisionSeed] = [],
        phaseCompletions: [UITestPhaseCompletionSeed] = []
    ) {
        self.progress = progress
        self.completions = completions
        self.decisions = decisions
        self.phaseCompletions = phaseCompletions
    }
}

private struct UITestProgressSeed: Decodable {
    let currentPhase: Int
    let currentStage: Int
    let completedPhases: [Int]
    let hasSeenIntro: Bool
    let lastPlayedDate: Date
}

private struct UITestStageCompletionSeed: Decodable {
    let phase: Int
    let stage: Int
    let latestScore: Int
    let bestScore: Int
    let latestStars: Int
    let bestStars: Int
    let isPassed: Bool
    let completedAt: Date
}

private struct UITestDecisionSeed: Decodable {
    let phase: Int
    let stage: Int
    let decisionType: String
    let playerDecisionChoice: String?
    let optimalDecisionChoice: String?
    let score: Int
    let decisionLatencyMs: Int
    let biasTags: [String]
    let timestamp: Date
}

private struct UITestPhaseCompletionSeed: Decodable {
    let phaseId: Int
    let conceptName: String
    let completedAt: Date
    let averageScore: Int
    let badgeIdentifier: String
    let decisionSummaryJSON: String
}
