import SwiftUI

struct SimulationView: View {
    @ObservedObject var viewModel: StageViewModel
    let assetNames: [String]
    let onFinish: () -> Void

    private let animationInterval: Double = 0.05  // ~20fps in preview; 60fps rendered

    var body: some View {
        VStack(spacing: 16) {
            // Time progress indicator
            if let prices = viewModel.simulationPrices.first {
                ProgressView(
                    value: Double(viewModel.currentPeriod),
                    total: Double(max(1, prices.count - 1))
                )
                .tint(.blue)
                .animation(.linear(duration: animationInterval), value: viewModel.currentPeriod)

                Text("Period \(viewModel.currentPeriod) / \(prices.count - 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            // Price chart (sparklines)
            PriceChartView(
                priceHistories: viewModel.simulationPrices,
                currentPeriod: viewModel.currentPeriod,
                assetNames: assetNames
            )
            .frame(height: 200)

            // Portfolio value tracker
            if !viewModel.portfolioValues.isEmpty {
                let current = viewModel.currentPeriod
                let currentValue = viewModel.portfolioValues[min(current, viewModel.portfolioValues.count - 1)]
                let startValue = viewModel.portfolioValues.first ?? currentValue
                let change = currentValue - startValue
                let pct = startValue > 0 ? change / startValue * 100 : 0

                HStack {
                    VStack(alignment: .leading) {
                        Text("Portfolio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("₩\(Int(currentValue).formatted())")
                            .font(.title3.bold().monospacedDigit())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(change >= 0 ? "+\(String(format: "%.1f", pct))%" : "\(String(format: "%.1f", pct))%")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(change >= 0 ? Color.investGreen : Color.investRed)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            if viewModel.currentPeriod >= (viewModel.simulationPrices.first?.count ?? 1) - 1 {
                Button(action: onFinish) {
                    Text("See Results")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .task {
            // Auto-advance through periods
            let count = viewModel.simulationPrices.first?.count ?? 0
            for _ in 0..<(count - 1) {
                try? await Task.sleep(nanoseconds: UInt64(animationInterval * 1_000_000_000))
                viewModel.advanceSimulationPeriod()
            }
        }
    }
}

// MARK: - Price Chart

struct PriceChartView: View {
    let priceHistories: [[Double]]
    let currentPeriod: Int
    let assetNames: [String]

    private let assetColors: [Color] = [.blue, .orange, .green, .purple, .red]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(priceHistories.enumerated()), id: \.offset) { idx, prices in
                    let visiblePrices = Array(prices.prefix(currentPeriod + 1))
                    let color = assetColors[idx % assetColors.count]
                    PriceLineShape(prices: visiblePrices, allPrices: prices)
                        .stroke(color, lineWidth: 2)
                        .animation(.linear(duration: 0.05), value: currentPeriod)
                }
            }
        }
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
            let x = rect.width * CGFloat(i) / CGFloat(allPrices.count - 1)
            let y = rect.height * (1 - CGFloat((price - minP) / range))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }
}

// MARK: - Color helpers

extension Color {
    static let investGreen = Color(red: 0.18, green: 0.72, blue: 0.44)  // colorblind-safe green
    static let investRed   = Color(red: 0.90, green: 0.27, blue: 0.27)  // colorblind-safe red
}
