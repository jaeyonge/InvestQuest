import Foundation

enum StageCatalog {
    static let introAddress = StageAddress(phase: 1, stage: 1)

    static var all: [StageDefinition] {
        Phase1StageDefinitions.all +
        Phase2StageDefinitions.all +
        Phase3StageDefinitions.all +
        Phase4StageDefinitions.all +
        Phase5StageDefinitions.all +
        Phase6StageDefinitions.all +
        Phase7StageDefinitions.all
    }

    static func definition(for address: StageAddress) -> StageDefinition {
        guard let definition = all.first(where: { $0.address == address }) else {
            fatalError("Missing stage definition for \(address.phase)-\(address.stage)")
        }
        return definition
    }

    static func definitions(forPhase phase: Int) -> [StageDefinition] {
        all.filter { $0.phase == phase }.sorted { $0.stage < $1.stage }
    }

    static func next(after address: StageAddress) -> StageAddress? {
        let inPhase = definitions(forPhase: address.phase)
        if let currentIndex = inPhase.firstIndex(where: { $0.address == address }),
           currentIndex + 1 < inPhase.count {
            return inPhase[currentIndex + 1].address
        }

        let nextPhase = address.phase + 1
        guard PhaseConfig.all.contains(where: { $0.id == nextPhase }),
              let nextAddress = definitions(forPhase: nextPhase).first?.address else {
            return nil
        }
        return nextAddress
    }

    static func lastAddress(inPhase phase: Int) -> StageAddress? {
        definitions(forPhase: phase).last?.address
    }

    static func stageCount(forPhase phase: Int) -> Int {
        definitions(forPhase: phase).count
    }
}
