import SwiftUI
import SwiftData

struct DecisionView: View {
    let scenario: StageScenario
    let decisionSpec: DecisionSpec
    let timeRemaining: Double
    let onSubmit: (PlayerDecision) -> Void

    @State private var sliderValues: [String: Double] = [:]
    @State private var rankingOrder: [String] = []
    @State private var valuationEstimate: Double = 200_000_000
    @State private var stopLossThreshold: Double = 0.15

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = AppTheme.contentHorizontalPadding(for: geometry.size.width)
            let topPadding = AppTheme.contentTopPadding(for: geometry.size.width)
            let bottomPadding = AppTheme.contentBottomPadding(for: geometry.size.width)

            ScrollView {
                VStack(spacing: 20) {
                    if let timeout = decisionSpec.timeoutSeconds, timeout > 0 {
                        timerCard(timeout: timeout)
                    }

                    StageScenarioPanelView(scenario: scenario)
                    decisionContent
                }
                .questReadableContentFrame(in: geometry.size.width)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
            .scrollClipDisabled()
        }
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityIdentifier("stage-decision")
    }

    @ViewBuilder
    private var decisionContent: some View {
        switch decisionSpec {
        case .observe(let label, let actionID, _, _):
            singleActionButton(label: label) {
                onSubmit(.binary(choice: actionID))
            }
        case .binary(let options, _, _), .review(let options, _, _):
            binaryOptionsView(options: options)
        case .allocation(let assets, _, _, _):
            allocationView(assets: assets)
        case .ranking(let assets, _, _):
            rankingView(assets: assets)
        case .valuation(let options, _, _):
            valuationView(options: options)
        case .stopLoss(let options, let suggestedThreshold, _, _):
            stopLossView(options: options, suggestedThreshold: suggestedThreshold)
        }
    }

    private func timerCard(timeout: Double) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    timerCopy
                    Spacer(minLength: 12)
                    timerPill(timeout: timeout)
                }

                VStack(alignment: .leading, spacing: 10) {
                    timerCopy
                    timerPill(timeout: timeout)
                }
            }

            ProgressView(value: max(timeRemaining, 0), total: timeout)
                .tint(timeRemaining < timeout * 0.25 ? AppTheme.highlight : AppTheme.accent)
        }
        .questCard(fill: AppTheme.surface.opacity(0.88))
    }

    private func binaryOptionsView(options: [DecisionOption]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose your move".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button {
                    onSubmit(.binary(choice: option.id))
                } label: {
                    HStack(alignment: .center, spacing: 14) {
                        Text(option.label.ko)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 18, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(
                    QuestPrimaryButtonStyle(
                        tint: AppTheme.accent
                    )
                )
                .accessibilityIdentifier("decision-\(option.id)")
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.78))
    }

    private func allocationView(assets: [DecisionAsset]) -> some View {
        let assetIDs = assets.map(\.id)
        let displayedAllocation = AllocationMath.roundedPercentages(sliderValues, assetIDs: assetIDs)
        let submittedAllocation = AllocationMath.roundedAllocation(sliderValues, assetIDs: assetIDs)

        return VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    allocationCopy
                    Spacer(minLength: 12)
                    QuestStatPill(label: "Total", value: "\(displayedAllocation.values.reduce(0, +))%", accent: AppTheme.highlight)
                }

                VStack(alignment: .leading, spacing: 10) {
                    allocationCopy
                    QuestStatPill(label: "Total", value: "\(displayedAllocation.values.reduce(0, +))%", accent: AppTheme.highlight)
                }
            }

            ForEach(assets) { asset in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(asset.label.ko)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Text("\(displayedAllocation[asset.id] ?? 0)%")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Slider(
                        value: Binding(
                            get: { sliderValues[asset.id] ?? 0 },
                            set: { updateAllocation(for: asset.id, newValue: $0, assets: assets) }
                        ),
                        in: 0...1
                    )
                    .tint(AppTheme.accent)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AppTheme.surface)
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.accent, AppTheme.highlight],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(sliderValues[asset.id] ?? 0))
                            }
                        }
                }
                .padding(16)
                .background(AppTheme.surfaceInteractive, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            singleActionButton(label: "Confirm Allocation") {
                onSubmit(.allocation(submittedAllocation))
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.78))
        .onAppear {
            if sliderValues.isEmpty {
                let equal = 1.0 / Double(max(assets.count, 1))
                sliderValues = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, equal) })
            }
        }
    }

    private func rankingView(assets: [DecisionAsset]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rank from strongest to weakest conviction.".ko)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(Array((rankingOrder.isEmpty ? assets.map(\.id) : rankingOrder).enumerated()), id: \.element) { index, assetID in
                let label = (assets.first(where: { $0.id == assetID })?.label ?? assetID).ko
                let instruction = (index == 0 ? "Highest conviction" : "Move up or down to reorder.").ko

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        rankingBadge(index: index)
                        rankingCopy(label: label, instruction: instruction)
                        Spacer(minLength: 8)
                        rankingControls(for: assetID, index: index)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            rankingBadge(index: index)
                            rankingCopy(label: label, instruction: instruction)
                        }

                        HStack {
                            Spacer(minLength: 0)
                            rankingControls(for: assetID, index: index)
                        }
                    }
                }
                .padding(16)
                .background(AppTheme.surfaceInteractive, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            singleActionButton(label: "Confirm Ranking") {
                onSubmit(.ranking(rankingOrder))
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.78))
        .onAppear {
            if rankingOrder.isEmpty {
                rankingOrder = assets.map(\.id)
            }
        }
    }

    private func valuationView(options: [DecisionOption]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Estimate intrinsic value".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))

            QuestMetricCard(
                label: "Estimated Value",
                value: "₩\(Int(valuationEstimate).formatted())",
                detail: "Adjust the range, then choose your action.",
                accent: AppTheme.accent
            )

            Slider(value: $valuationEstimate, in: 10_000_000...500_000_000, step: 5_000_000)
                .tint(AppTheme.accent)

            ForEach(options) { option in
                singleActionButton(label: option.label) {
                    onSubmit(.valuation(estimatedValue: valuationEstimate, actionID: option.id))
                }
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.78))
    }

    private func stopLossView(options: [DecisionOption], suggestedThreshold: Double) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Set stop-loss threshold".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))

            QuestMetricCard(
                label: "Current Threshold",
                value: "-\(Int(stopLossThreshold * 100))%",
                detail: "Suggested: -\(Int(suggestedThreshold * 100))%",
                accent: AppTheme.highlight
            )

            Slider(value: $stopLossThreshold, in: 0.05...0.4, step: 0.01)
                .tint(AppTheme.highlight)

            ForEach(options) { option in
                singleActionButton(label: option.label) {
                    onSubmit(.stopLoss(threshold: stopLossThreshold, actionID: option.id))
                }
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.78))
        .onAppear {
            stopLossThreshold = suggestedThreshold
        }
    }

    private func rankingButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 34, height: 34)
        }
        .buttonStyle(QuestSecondaryButtonStyle(tint: AppTheme.surface))
    }

    private func moveRankingItem(assetID: String, direction: Int) {
        guard let index = rankingOrder.firstIndex(of: assetID) else { return }
        let target = index + direction
        guard rankingOrder.indices.contains(target) else { return }
        rankingOrder.swapAt(index, target)
    }

    private func updateAllocation(for assetID: String, newValue: Double, assets: [DecisionAsset]) {
        let clamped = min(max(newValue, 0), 1)
        let otherIDs = assets.map(\.id).filter { $0 != assetID }
        let remaining = max(0, 1 - clamped)
        let currentOtherTotal = otherIDs.reduce(0) { $0 + (sliderValues[$1] ?? 0) }

        sliderValues[assetID] = clamped

        guard !otherIDs.isEmpty else {
            sliderValues[assetID] = 1
            return
        }

        if currentOtherTotal > 0.0001 {
            for otherID in otherIDs {
                let existing = sliderValues[otherID] ?? 0
                sliderValues[otherID] = existing / currentOtherTotal * remaining
            }
        } else {
            let evenShare = remaining / Double(otherIDs.count)
            for otherID in otherIDs {
                sliderValues[otherID] = evenShare
            }
        }
    }

    private func singleActionButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.ko)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(QuestPrimaryButtonStyle())
        .accessibilityIdentifier(label.replacingOccurrences(of: " ", with: "-").lowercased())
    }

    private var timerCopy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Decision Window".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Commit before the opportunity closes.".ko)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func timerPill(timeout: Double) -> some View {
        QuestStatPill(
            label: "Time",
            value: "\(Int(ceil(timeRemaining)))s",
            accent: timeRemaining < timeout * 0.25 ? AppTheme.highlight : AppTheme.accent
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(ceil(timeRemaining)))초")
        .accessibilityIdentifier("decision-timer-label")
    }

    private var allocationCopy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Build Allocation".ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
            Text("The portfolio auto-balances to 100% as you adjust conviction.".ko)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rankingBadge(index: Int) -> some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent.opacity(0.14))
                .frame(width: 34, height: 34)
            Text("\(index + 1)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func rankingCopy(label: String, instruction: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(instruction)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rankingControls(for assetID: String, index: Int) -> some View {
        HStack(spacing: 8) {
            rankingButton(icon: "arrow.up") {
                moveRankingItem(assetID: assetID, direction: -1)
            }
            .disabled(index == 0)

            rankingButton(icon: "arrow.down") {
                moveRankingItem(assetID: assetID, direction: 1)
            }
            .disabled(index == rankingOrder.count - 1)
        }
    }
}

struct StageScenarioPanelView: View {
    let scenario: StageScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    scenarioIcon
                    scenarioCopy
                }

                VStack(alignment: .leading, spacing: 12) {
                    scenarioIcon
                    scenarioCopy
                }
            }

            switch scenario {
            case .inflation(let inflation):
                InflationScenarioPanel(scenario: inflation)
            case .valuation(let valuation):
                ValuationScenarioPanel(scenario: valuation)
            case .risk(let risk):
                BulletNoteView(title: "Risk Profiles", items: risk.distributions, accent: AppTheme.highlight)
            case .compounding(let compounding):
                BulletNoteView(title: "Compounding Clues", items: compounding.comparisonHighlights, accent: AppTheme.accent)
            case .exit(let exit):
                BulletNoteView(title: "Exit Discipline", items: exit.prompts, accent: AppTheme.highlight)
            case .diversification(let diversification):
                BulletNoteView(title: "Portfolio Notes", items: diversification.sectorNotes, accent: AppTheme.accent)
            case .behavioral(let behavioral):
                if behavioral.isReviewStage {
                    BehavioralProfileReviewPanel()
                } else {
                    BulletNoteView(title: "Bias Cues", items: behavioral.biasCues, accent: AppTheme.highlight)
                }
            }
        }
        .questCard(fill: AppTheme.surface.opacity(0.86))
    }
}

private extension StageScenarioPanelView {
    var scenarioIcon: some View {
        ZStack {
            Circle()
                .fill(scenario.categoryAccent.opacity(0.14))
                .frame(width: 48, height: 48)
            Image(systemName: scenario.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(scenario.categoryAccent)
        }
    }

    var scenarioCopy: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(scenario.categoryLabel.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textMuted)
            Text(scenario.title.ko)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(scenario.description.ko)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct InflationScenarioPanel: View {
    let scenario: InflationScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !scenario.inflationRates.isEmpty {
                QuestInfoBanner(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Inflation path",
                    message: inflationPath,
                    accent: AppTheme.highlight
                )
            }

            ForEach(scenario.goods) { good in
                ViewThatFits(in: .horizontal) {
                    HStack {
                        goodInfo(good)
                        Spacer()
                        goodPrice(good)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        goodInfo(good)
                        goodPrice(good)
                    }
                }
                .padding(14)
                .background(AppTheme.surfaceInteractive, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var inflationPath: String {
        scenario.inflationRates
            .map { "\(($0 * 100).formatted(.number.precision(.fractionLength(0))))%" }
            .joined(separator: " -> ")
    }

    private func goodInfo(_ good: InflationGood) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(good.label.ko)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            Text("Purchasing power check".ko)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
        }
    }

    private func goodPrice(_ good: InflationGood) -> some View {
        Text("₩\(Int(good.startingPrice).formatted()) -> ₩\(Int(good.endingPrice).formatted())")
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ValuationScenarioPanel: View {
    let scenario: ValuationScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(scenario.opportunities) { opportunity in
                VStack(alignment: .leading, spacing: 10) {
                    Text(opportunity.fundamentals.businessName.ko)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))

                    valuationRow(label: "Revenue", value: opportunity.fundamentals.displayRevenue() ?? "Hidden")
                    valuationRow(label: "Costs", value: opportunity.fundamentals.displayCosts() ?? "Hidden")
                    valuationRow(label: "Profit", value: opportunity.fundamentals.displayProfit() ?? "Hidden")
                    valuationRow(label: "Market Price", value: "₩\(Int(opportunity.marketPrice).formatted())")

                    Text(opportunity.sentimentIndicator.rawValue.ko)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(16)
                .background(AppTheme.surfaceInteractive, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func valuationRow(label: String, value: String) -> some View {
        HStack {
            Text(label.ko)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
            Text(value.ko)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

private struct BulletNoteView: View {
    let title: String
    let items: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.ko)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(item.ko)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
}

private struct BehavioralProfileReviewPanel: View {
    @Query private var decisionRecords: [DecisionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected from your play".ko)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            if summaries.isEmpty {
                Text("No earlier decisions are stored yet. Finish more stages to build a behavioral profile.".ko)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(summaries) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.title.ko)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(summary.detail.ko)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceInteractive, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("bias-summary-\(summary.id)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("behavioral-review-summary")
    }

    private var summaries: [BehavioralBiasSummary] {
        let observations = decisionRecords
            .sorted { $0.timestamp > $1.timestamp }
            .flatMap(BehavioralObservation.observations(for:))

        return BehavioralBiasCategory.allCases.compactMap { category in
            let matches = observations.filter { $0.category == category }
            guard !matches.isEmpty else { return nil }

            let detectedCount = matches.filter { $0.kind == .detected }.count
            let resistedCount = matches.filter { $0.kind == .resisted }.count
            let latest = matches.first

            var fragments: [String] = []
            if detectedCount > 0 {
                fragments.append("감지 \(detectedCount)회")
            }
            if resistedCount > 0 {
                fragments.append("극복 \(resistedCount)회")
            }
            if let latest {
                fragments.append("최근 예시: 페이즈 \(latest.phase) 스테이지 \(latest.stage)")
            }

            return BehavioralBiasSummary(
                id: category.rawValue,
                title: category.title,
                detail: fragments.joined(separator: ". ") + "."
            )
        }
    }
}

private struct BehavioralBiasSummary: Identifiable {
    let id: String
    let title: String
    let detail: String
}

private struct BehavioralObservation {
    enum Kind {
        case detected
        case resisted
    }

    let category: BehavioralBiasCategory
    let kind: Kind
    let phase: Int
    let stage: Int
    let timestamp: Date

    static func observations(for record: DecisionRecord) -> [BehavioralObservation] {
        record.biasTags.compactMap { tag in
            guard let category = BehavioralBiasCategory(tag: tag) else { return nil }
            let kind: Kind = tag.contains("resisted") ? .resisted : .detected
            return BehavioralObservation(
                category: category,
                kind: kind,
                phase: record.phase,
                stage: record.stage,
                timestamp: record.timestamp
            )
        }
    }
}

private enum BehavioralBiasCategory: String, CaseIterable {
    case anchoring
    case lossAversion
    case herdBehavior
    case recencyBias

    init?(tag: String) {
        if tag.contains("anchoring") {
            self = .anchoring
        } else if tag.contains("loss-aversion") {
            self = .lossAversion
        } else if tag.contains("recency") {
            self = .recencyBias
        } else if tag.contains("herd") || tag.contains("fomo") {
            self = .herdBehavior
        } else {
            return nil
        }
    }

    var title: String {
        switch self {
        case .anchoring:
            return "앵커링"
        case .lossAversion:
            return "손실 회피"
        case .herdBehavior:
            return "군중 추종"
        case .recencyBias:
            return "최신 편향"
        }
    }
}

private extension StageScenario {
    var categoryLabel: String {
        switch self {
        case .inflation:
            return "인플레이션"
        case .valuation:
            return "가치평가"
        case .risk:
            return "위험"
        case .compounding:
            return "복리"
        case .exit:
            return "매도"
        case .diversification:
            return "분산투자"
        case .behavioral:
            return "행동 심리"
        }
    }

    var symbolName: String {
        switch self {
        case .inflation:
            return "thermometer.sun"
        case .valuation:
            return "chart.line.uptrend.xyaxis"
        case .risk:
            return "gauge.high"
        case .compounding:
            return "clock.arrow.circlepath"
        case .exit:
            return "arrow.uturn.backward.circle"
        case .diversification:
            return "square.grid.2x2"
        case .behavioral:
            return "brain.head.profile"
        }
    }

    var categoryAccent: Color {
        switch self {
        case .inflation:
            return AppTheme.highlight
        case .valuation:
            return AppTheme.accent
        case .risk:
            return Color(hex: "#B686FF")
        case .compounding:
            return AppTheme.success
        case .exit:
            return AppTheme.highlight
        case .diversification:
            return AppTheme.accent
        case .behavioral:
            return Color(hex: "#FF7FB3")
        }
    }
}
