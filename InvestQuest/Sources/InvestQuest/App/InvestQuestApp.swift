import SwiftUI
import SwiftData

@main
struct InvestQuestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [GameProgress.self, DecisionRecord.self])
    }
}
