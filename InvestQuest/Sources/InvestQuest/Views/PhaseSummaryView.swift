import SwiftUI
import SwiftData

struct PhaseSummaryView: View {
    @StateObject private var viewModel: PhaseCompletionViewModel
    @Environment(\.modelContext) private var modelContext

    init(phaseId: Int, stageResults: [StageResult]) {
        _viewModel = StateObject(wrappedValue: PhaseCompletionViewModel(
            phaseId: phaseId, stageResults: stageResults))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Phase concept header (AC1)
                VStack(spacing: 8) {
                    Text("Phase \(viewModel.completedPhaseConfig.id) Complete!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.completedPhaseConfig.concept)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(viewModel.completedPhaseConfig.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Badge (AC3)
                if let badge = viewModel.badge {
                    BadgeView(badge: badge)
                }

                // Performance dashboard (AC2)
                if !viewModel.performanceData.isEmpty {
                    PerformanceDashboardView(data: viewModel.performanceData,
                                            averageScore: viewModel.averageScore)
                }

                // Next phase teaser (AC4)
                if let next = viewModel.nextPhaseConfig {
                    NextPhaseTeaserView(config: next)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .onAppear {
            if !viewModel.isPersisted {
                viewModel.persistCompletion(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: badge.color).opacity(0.15))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(Color(hex: badge.color), lineWidth: 3)
                    .frame(width: 100, height: 100)
                Image(systemName: badge.symbolName)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: badge.color))
            }
            Text(badge.title)
                .font(.headline)
        }
        .accessibilityLabel("Badge earned: \(badge.title)")
    }
}

// MARK: - Performance Dashboard

struct PerformanceDashboardView: View {
    let data: [PerformanceDataPoint]
    let averageScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Performance")
                .font(.headline)

            ForEach(data) { point in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Stage \(point.stageNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(point.playerScore) / \(point.optimalScore)")
                            .font(.caption.monospacedDigit())
                    }
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreColor(point.playerScore))
                                .frame(width: geo.size.width * CGFloat(point.playerScore) / 100,
                                       height: 10)
                        }
                    }
                    .frame(height: 10)
                }
            }

            HStack {
                Text("Average Score")
                    .font(.subheadline)
                Spacer()
                Text("\(averageScore)")
                    .font(.subheadline.bold().monospacedDigit())
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .investGreen
        case 50..<80:  return .orange
        default:       return .investRed
        }
    }
}

// MARK: - Next Phase Teaser

struct NextPhaseTeaserView: View {
    let config: PhaseConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Next Up: Phase \(config.id)", systemImage: "lock.open.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(config.title)
                .font(.headline)
            Text(config.teaserDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next phase unlocked: \(config.title). \(config.teaserDescription)")
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
