import SwiftUI
import SwiftData

struct PhaseMapView: View {
    @Query private var progressRecords: [GameProgress]
    @Environment(\.modelContext) private var modelContext

    private var service: GameProgressService {
        let progress = progressRecords.first ?? GameProgress()
        return GameProgressService(progress: progress)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(PhaseConfig.all) { phase in
                        PhaseNodeView(
                            config: phase,
                            isUnlocked: service.isPhaseUnlocked(phase.id),
                            isCompleted: service.isPhaseCompleted(phase.id),
                            isCurrent: service.progress.currentPhase == phase.id
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("InvestQuest")
        }
    }
}

struct PhaseNodeView: View {
    let config: PhaseConfig
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 56, height: 56)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.white)
                } else {
                    Text("\(config.id)")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(config.title)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(isUnlocked ? config.concept : config.teaserDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if isCurrent && isUnlocked && !isCompleted {
                    Label("Current", systemImage: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var nodeColor: Color {
        if isCompleted { return .green }
        if isCurrent { return .blue }
        if isUnlocked { return .orange }
        return .gray
    }

    private var accessibilityLabel: String {
        let status = isCompleted ? "Completed" : (isUnlocked ? "Unlocked" : "Locked")
        return "Phase \(config.id): \(config.title). \(status)."
    }
}
