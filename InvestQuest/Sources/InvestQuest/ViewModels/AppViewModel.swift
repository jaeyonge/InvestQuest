import Foundation
import SwiftData

/// Controls top-level app routing: intro vs main game.
@MainActor
final class AppViewModel: ObservableObject {

    enum AppRoute: Equatable {
        case intro
        case phaseMap
    }

    @Published private(set) var currentRoute: AppRoute = .intro

    private var progress: GameProgress?

    init(progress: GameProgress?) {
        self.progress = progress
        // If user has already seen intro, go straight to game
        if progress?.hasSeenIntro == true {
            currentRoute = .phaseMap
        }
    }

    func completeIntro(modelContext: ModelContext) {
        if let progress = progress {
            progress.hasSeenIntro = true
            try? modelContext.save()
        } else {
            let newProgress = GameProgress(hasSeenIntro: true)
            modelContext.insert(newProgress)
            try? modelContext.save()
            self.progress = newProgress
        }
        currentRoute = .phaseMap
    }

    /// True when this is the user's very first launch (no progress record at all).
    var isFirstLaunch: Bool {
        progress == nil || progress?.hasSeenIntro == false
    }
}
