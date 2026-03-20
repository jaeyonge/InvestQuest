import SwiftUI
import SwiftData

@main
struct InvestQuestApp: App {
    private let sharedModelContainer = AppRuntimeSupport.makeModelContainer()

    init() {
        AppRuntimeSupport.configureForLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(AppTheme.accent)
        }
        .modelContainer(sharedModelContainer)
    }
}
