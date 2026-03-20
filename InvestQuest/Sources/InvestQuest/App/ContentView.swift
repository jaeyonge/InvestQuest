import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var progressRecords: [GameProgress]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appViewModel = AppViewModel()
    @State private var didInitialize = false

    var body: some View {
        ZStack {
            QuestBackgroundView()

            Group {
                if let progress = progressRecords.first {
                    let service = GameProgressService(modelContext: modelContext, progress: progress)
                    routeView(service: service)
                        .environmentObject(appViewModel)
                        .task {
                            appViewModel.bootstrap(using: service)
                        }
                } else {
                    ProgressView()
                        .tint(AppTheme.accent)
                        .controlSize(.large)
                        .padding(28)
                        .questCard()
                }
            }
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            UITestSeedBootstrapper.applyIfNeeded(modelContext: modelContext)
            _ = GameProgressService.loadOrCreateProgress(modelContext: modelContext)
        }
        .animation(.easeInOut(duration: 0.3), value: appViewModel.currentRoute)
    }

    @ViewBuilder
    private func routeView(service: GameProgressService) -> some View {
        switch appViewModel.currentRoute {
        case .intro:
            IntroAnimationView {
                appViewModel.completeIntro(using: service)
                _ = try? modelContext.save()
            }
        case .recap(let address):
            StageRecapView(address: address)
        case .stage(let address):
            StageContainerView(address: address)
                .id(address.id)
        case .phaseMap:
            PhaseMapView()
        case .phaseSummary(let phase):
            PhaseSummaryView(phaseId: phase)
        }
    }
}
