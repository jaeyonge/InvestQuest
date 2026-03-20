import SwiftUI

private let questChartColors: [Color] = [
    AppTheme.accent,
    AppTheme.highlight,
    .investGreen,
    Color(hex: "#5F8CFF"),
    Color(hex: "#FF7A88")
]

struct SimulationView: View {
    @ObservedObject var viewModel: StageViewModel
    let assetNames: [String]
    let onFinish: () -> Void

    private let animationInterval: Double = 0.05

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let prices = viewModel.simulationPrices.first {
                    simulationHeroCard(periodCount: prices.count)
                }

                if !viewModel.portfolioValues.isEmpty {
                    portfolioSummaryCard
                }

                if viewModel.replayFinalValues.count > 1 {
                    ReplaySummaryStrip(finalValues: viewModel.replayFinalValues)
                }

                if viewModel.currentPeriod >= (viewModel.simulationPrices.first?.count ?? 1) - 1 {
                    Button(action: onFinish) {
                        Text("See Results")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuestPrimaryButtonStyle())
                    .accessibilityIdentifier("see-results")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityIdentifier("stage-simulation")
        .task {
            let count = viewModel.simulationPrices.first?.count ?? 0
            let midpoint = (count - 1) / 2
            for step in 0..<(count - 1) {
                try? await Task.sleep(nanoseconds: UInt64(animationInterval * 1_000_000_000))
                let prevPeriod = viewModel.currentPeriod
                viewModel.advanceSimulationPeriod()
                let newPeriod = viewModel.currentPeriod

                let prices = viewModel.simulationPrices
                let isCrash = prices.contains { history in
                    guard newPeriod < history.count, prevPeriod < history.count, history[prevPeriod] > 0 else {
                        return false
                    }
                    return history[newPeriod] / history[prevPeriod] < 0.70
                }

                if isCrash {
                    HapticFeedbackService.shared.fireCrashEvent()
                } else if step == midpoint {
                    HapticFeedbackService.shared.fireMilestone()
                }
            }
        }
    }

    private func simulationHeroCard(periodCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            QuestSectionHeader(
                eyebrow: "Simulation",
                title: "Market replay in motion",
                subtitle: "Watch the path unfold before you lock in the outcome."
            )

            HStack(spacing: 12) {
                QuestStatPill(
                    label: "Period",
                    value: "\(viewModel.currentPeriod)/\(max(periodCount - 1, 0))",
                    accent: AppTheme.highlight
                )
                .accessibilityIdentifier("simulation-period-label")

                if let currentValue = currentPortfolioValue {
                        QuestStatPill(
                            label: "Portfolio",
                            value: "₩\(Int(currentValue).formatted())",
                            accent: currentChange >= 0 ? AppTheme.success : AppTheme.danger
                        )
                }

                Spacer(minLength: 0)
            }

            ProgressView(
                value: Double(viewModel.currentPeriod),
                total: Double(max(1, periodCount - 1))
            )
            .tint(AppTheme.accent)
            .animation(.linear(duration: animationInterval), value: viewModel.currentPeriod)

            PriceChartView(
                priceHistories: viewModel.simulationPrices,
                currentPeriod: viewModel.currentPeriod,
                assetNames: assetNames
            )
            .frame(height: 240)

            if !assetNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(assetNames.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(questChartColors[index % questChartColors.count])
                                    .frame(width: 8, height: 8)
                                Text(name)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppTheme.surfaceInteractive, in: Capsule(style: .continuous))
                        }
                    }
                }
            }
        }
        .questCard()
    }

    private var portfolioSummaryCard: some View {
        let currentValue = currentPortfolioValue ?? 0
        let startValue = viewModel.portfolioValues.first ?? currentValue
        let pct = startValue > 0 ? currentChange / startValue * 100 : 0

        return VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio")
                .font(.system(.headline, design: .rounded).weight(.semibold))

            HStack(spacing: 14) {
                QuestMetricCard(
                    label: "Current",
                    value: "₩\(Int(currentValue).formatted())",
                    detail: "Starting value: ₩\(Int(startValue).formatted())",
                    accent: AppTheme.accent
                )
                QuestMetricCard(
                    label: "Change",
                    value: currentChange >= 0 ? "+\(String(format: "%.1f", pct))%" : "\(String(format: "%.1f", pct))%",
                    detail: currentChange >= 0 ? "Ahead of the starting line" : "Below the starting line",
                    accent: currentChange >= 0 ? AppTheme.success : AppTheme.danger
                )
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.82))
    }

    private var currentPortfolioValue: Double? {
        guard !viewModel.portfolioValues.isEmpty else { return nil }
        let index = min(viewModel.currentPeriod, viewModel.portfolioValues.count - 1)
        return viewModel.portfolioValues[index]
    }

    private var currentChange: Double {
        guard let currentValue = currentPortfolioValue else { return 0 }
        let startValue = viewModel.portfolioValues.first ?? currentValue
        return currentValue - startValue
    }
}

struct ReplaySummaryStrip: View {
    let finalValues: [Double]

    var body: some View {
        let sorted = finalValues.sorted()
        let low = sorted.first ?? 0
        let median = sorted[sorted.count / 2]
        let high = sorted.last ?? 0

        VStack(alignment: .leading, spacing: 16) {
            Text("Replay Range")
                .font(.system(.headline, design: .rounded).weight(.semibold))

            HStack(spacing: 14) {
                replayValue(label: "Low", value: low, accent: AppTheme.danger)
                replayValue(label: "Median", value: median, accent: AppTheme.accent)
                replayValue(label: "High", value: high, accent: AppTheme.success)
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.82))
    }

    private func replayValue(label: String, value: Double, accent: Color) -> some View {
        QuestMetricCard(
            label: label,
            value: "₩\(Int(value).formatted())",
            detail: "Across replayed runs",
            accent: accent
        )
    }
}

struct PriceChartView: View {
    let priceHistories: [[Double]]
    let currentPeriod: Int
    let assetNames: [String]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                chartGrid(in: geo.size)
                    .padding(16)

                if let firstHistory = priceHistories.first, firstHistory.count > 1 {
                    currentPeriodGuide(in: geo.size, totalPeriods: firstHistory.count)
                        .padding(16)
                }

                ForEach(Array(priceHistories.enumerated()), id: \.offset) { idx, prices in
                    let visiblePrices = Array(prices.prefix(currentPeriod + 1))
                    let color = questChartColors[idx % questChartColors.count]
                    PriceLineShape(prices: visiblePrices, allPrices: prices)
                        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .padding(16)
                        .animation(.linear(duration: 0.05), value: currentPeriod)

                    if let last = visiblePrices.last {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                            .position(
                                point(
                                    for: last,
                                    index: visiblePrices.count - 1,
                                    allPrices: prices,
                                    in: CGSize(width: geo.size.width - 32, height: geo.size.height - 32)
                                )
                            )
                            .offset(x: 16, y: 16)
                    }
                }
            }
        }
    }

    private func chartGrid(in size: CGSize) -> some View {
        Path { path in
            for row in 0...4 {
                let y = size.height * CGFloat(row) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
    }

    private func currentPeriodGuide(in size: CGSize, totalPeriods: Int) -> some View {
        Path { path in
            let divisor = max(totalPeriods - 1, 1)
            let x = size.width * CGFloat(currentPeriod) / CGFloat(divisor)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        .stroke(AppTheme.accent.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
    }

    private func point(for price: Double, index: Int, allPrices: [Double], in size: CGSize) -> CGPoint {
        let minP = allPrices.min() ?? 0
        let maxP = allPrices.max() ?? 1
        let range = max(maxP - minP, 1)
        let x = size.width * CGFloat(index) / CGFloat(max(allPrices.count - 1, 1))
        let y = size.height * (1 - CGFloat((price - minP) / range))
        return CGPoint(x: x, y: y)
    }
}

struct PriceLineShape: Shape {
    let prices: [Double]
    let allPrices: [Double]

    func path(in rect: CGRect) -> Path {
        guard prices.count >= 2 else { return Path() }
        let minP = allPrices.min() ?? 0
        let maxP = allPrices.max() ?? 1
        let range = max(maxP - minP, 1)

        var path = Path()
        for (i, price) in prices.enumerated() {
            let x = rect.width * CGFloat(i) / CGFloat(max(allPrices.count - 1, 1))
            let y = rect.height * (1 - CGFloat((price - minP) / range))
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
