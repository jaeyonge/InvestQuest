import SwiftUI

struct DecisionView: View {
    let decisionType: DecisionType
    let timeRemaining: Double
    let timeoutTotal: Double
    let onSubmit: (PlayerDecision) -> Void

    @State private var sliderValues: [String: Double] = [:]
    @State private var rankingOrder: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            // Timer bar
            if timeoutTotal > 0 {
                ProgressView(value: timeRemaining, total: timeoutTotal)
                    .tint(timeRemaining < timeoutTotal * 0.25 ? .red : .blue)
                    .animation(.linear(duration: 0.2), value: timeRemaining)
                Text("Decide in \(Int(timeRemaining))s")
                    .font(.caption)
                    .foregroundStyle(timeRemaining < timeoutTotal * 0.25 ? .red : .secondary)
            }

            decisionContent
        }
        .padding()
    }

    @ViewBuilder
    private var decisionContent: some View {
        switch decisionType {
        case .binary(let a, let b):
            binaryView(optionA: a, optionB: b)

        case .allocationSlider(let assets, let total):
            allocationView(assets: assets, totalBudget: total)

        case .multiAssetRanking(let assets):
            rankingView(assets: assets)

        case .timed(let kind, _):
            switch kind {
            case .binary(let a, let b):
                binaryView(optionA: a, optionB: b)
            case .allocationSlider(let assets, let total):
                allocationView(assets: assets, totalBudget: total)
            }
        }
    }

    // MARK: - Binary choice

    private func binaryView(optionA: String, optionB: String) -> some View {
        HStack(spacing: 16) {
            Button {
                onSubmit(.binary(choice: "A"))
            } label: {
                Text(optionA)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Button {
                onSubmit(.binary(choice: "B"))
            } label: {
                Text(optionB)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Allocation slider

    private func allocationView(assets: [String], totalBudget: Double) -> some View {
        VStack(spacing: 16) {
            ForEach(assets, id: \.self) { asset in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(asset)
                        Spacer()
                        Text("\(Int((sliderValues[asset] ?? 0) * 100))%")
                            .font(.caption.monospacedDigit())
                    }
                    Slider(value: Binding(
                        get: { sliderValues[asset] ?? 0 },
                        set: { sliderValues[asset] = $0 }
                    ), in: 0...1)
                    .tint(.blue)
                }
            }

            Button {
                var alloc: [String: Double] = [:]
                for asset in assets {
                    alloc[asset] = sliderValues[asset] ?? 0
                }
                onSubmit(.allocation(alloc))
            } label: {
                Text("Confirm Allocation")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            if sliderValues.isEmpty {
                let equal = 1.0 / Double(assets.count)
                for asset in assets { sliderValues[asset] = equal }
            }
        }
    }

    // MARK: - Multi-asset ranking

    private func rankingView(assets: [String]) -> some View {
        VStack(spacing: 12) {
            Text("Drag to rank from best to worst")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(rankingOrder.isEmpty ? assets : rankingOrder, id: \.self) { asset in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                    Text(asset)
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            Button {
                onSubmit(.ranking(rankingOrder.isEmpty ? assets : rankingOrder))
            } label: {
                Text("Confirm Ranking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            if rankingOrder.isEmpty { rankingOrder = assets }
        }
    }
}
