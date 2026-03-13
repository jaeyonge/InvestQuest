import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var progressRecords: [GameProgress]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let hasSeenIntro = progressRecords.first?.hasSeenIntro ?? false
        Group {
            if hasSeenIntro {
                PhaseMapView()
                    .transition(.opacity)
            } else {
                IntroAnimationView {
                    markIntroSeen()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasSeenIntro)
    }

    private func markIntroSeen() {
        if let progress = progressRecords.first {
            progress.hasSeenIntro = true
        } else {
            let progress = GameProgress(hasSeenIntro: true)
            modelContext.insert(progress)
        }
        try? modelContext.save()
    }
}
