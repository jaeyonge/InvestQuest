import Foundation

/// Controls top-level app routing: intro vs main game.
@MainActor
final class AppViewModel: ObservableObject {

    enum AppRoute: Equatable {
        case intro
        case recap(StageAddress)
        case stage(StageAddress)
        case phaseMap
        case phaseSummary(Int)
    }

    @Published private(set) var currentRoute: AppRoute = .intro
    private var bootstrapped = false

    func bootstrap(using service: GameProgressService, force: Bool = false) {
        guard force || !bootstrapped else { return }
        bootstrapped = true

        if service.progress.hasSeenIntro == false {
            currentRoute = .intro
            return
        }

        if let session = service.loadStageSession() {
            currentRoute = .stage(session.address)
            return
        }

        if let recapAddress = service.recapAddress, service.isReturningAfterLongAbsence {
            currentRoute = .recap(recapAddress)
            return
        }

        currentRoute = .stage(service.entryAddress())
    }

    func completeIntro(using service: GameProgressService) {
        service.progress.hasSeenIntro = true
        currentRoute = .stage(service.entryAddress())
    }

    func openPhaseMap() {
        currentRoute = .phaseMap
    }

    func openStage(_ address: StageAddress) {
        currentRoute = .stage(address)
    }

    func openPhaseSummary(_ phase: Int) {
        currentRoute = .phaseSummary(phase)
    }

    func dismissRecap(into address: StageAddress) {
        currentRoute = .stage(address)
    }

    func finishStage(address: StageAddress, outcome: StageOutcome, using service: GameProgressService) {
        let definition = StageCatalog.definition(for: address)
        if outcome.score >= definition.minimumPassingScore,
           StageCatalog.lastAddress(inPhase: address.phase) == address {
            currentRoute = .phaseSummary(address.phase)
            return
        }

        if outcome.score >= definition.minimumPassingScore, let next = StageCatalog.next(after: address) {
            currentRoute = .stage(next)
            return
        }

        currentRoute = .stage(address)
    }

    func closePhaseSummary(using service: GameProgressService) {
        currentRoute = .stage(service.entryAddress())
    }
}
