import Foundation

/// Simplified business fundamentals presented to the player in Phase 2.
struct BusinessFundamentals: Identifiable {
    let id: String
    let businessName: String
    let revenue: Double              // annual revenue in ₩
    let costs: Double                // annual costs in ₩
    let profit: Double               // revenue - costs
    let isHidden: Bool               // AC5: Stage 4 hides some fields
    let hiddenFields: Set<FundamentalField>

    var intrinsicValueEstimate: Double {
        // Simple PE-like valuation: 10x annual profit
        return max(0, profit) * 10
    }

    enum FundamentalField: String, CaseIterable {
        case revenue, costs, profit
    }

    func displayRevenue() -> String? {
        hiddenFields.contains(.revenue) ? nil : "₩\(Int(revenue / 1_000_000))M"
    }
    func displayCosts() -> String? {
        hiddenFields.contains(.costs) ? nil : "₩\(Int(costs / 1_000_000))M"
    }
    func displayProfit() -> String? {
        hiddenFields.contains(.profit) ? nil : "₩\(Int(profit / 1_000_000))M"
    }
}

/// Sentiment indicator for Stage 3+: market price distorted by hype or fear.
enum SentimentIndicator: String {
    case neutral = "Neutral"
    case hype = "🔥 Extreme Hype"
    case fear = "😨 Panic Selling"
    case mildHype = "📈 Mild Optimism"
    case mildFear = "📉 Mild Caution"

    /// Price multiplier applied by sentiment (market price = intrinsic * multiplier)
    var priceDistortionMultiplier: Double {
        switch self {
        case .neutral:   return 1.0
        case .hype:      return 2.5
        case .fear:      return 0.4
        case .mildHype:  return 1.3
        case .mildFear:  return 0.8
        }
    }
}

/// A Phase 2 investment opportunity presented to the player.
struct Phase2Opportunity: Identifiable {
    let id: String
    let fundamentals: BusinessFundamentals
    let marketPrice: Double
    let sentimentIndicator: SentimentIndicator

    /// True when buying at market price is a good deal (price < intrinsic value).
    var isBuyingAboveValue: Bool {
        marketPrice > fundamentals.intrinsicValueEstimate
    }
}

/// Factory for creating Phase 2 business opportunities.
enum Phase2OpportunityFactory {

    static func fruitStand() -> Phase2Opportunity {
        let biz = BusinessFundamentals(
            id: "fruit-stand",
            businessName: "Kim's Fruit Stand",
            revenue: 50_000_000, costs: 30_000_000, profit: 20_000_000,
            isHidden: false, hiddenFields: []
        )
        return Phase2Opportunity(
            id: "fruit-stand",
            fundamentals: biz,
            marketPrice: biz.intrinsicValueEstimate * 0.7,  // undervalued — buy signal
            sentimentIndicator: .neutral
        )
    }

    static func overpriced() -> Phase2Opportunity {
        let biz = BusinessFundamentals(
            id: "overpriced-cafe",
            businessName: "Trendy Café Co.",
            revenue: 80_000_000, costs: 75_000_000, profit: 5_000_000,
            isHidden: false, hiddenFields: []
        )
        return Phase2Opportunity(
            id: "overpriced-cafe",
            fundamentals: biz,
            marketPrice: biz.intrinsicValueEstimate * 3.0,  // massively overvalued — pass
            sentimentIndicator: .hype
        )
    }

    static func hiddenInfo() -> Phase2Opportunity {
        let biz = BusinessFundamentals(
            id: "mystery-tech",
            businessName: "TechX Corp.",
            revenue: 200_000_000, costs: 150_000_000, profit: 50_000_000,
            isHidden: true, hiddenFields: [.costs, .profit]  // hidden — AC5
        )
        return Phase2Opportunity(
            id: "mystery-tech",
            fundamentals: biz,
            marketPrice: 300_000_000,
            sentimentIndicator: .mildHype
        )
    }

    static func allBusinesses() -> [Phase2Opportunity] {
        [
            fruitStand(),
            Phase2Opportunity(
                id: "bakery",
                fundamentals: BusinessFundamentals(
                    id: "bakery", businessName: "Park's Bakery",
                    revenue: 60_000_000, costs: 40_000_000, profit: 20_000_000,
                    isHidden: false, hiddenFields: []),
                marketPrice: 180_000_000, sentimentIndicator: .neutral),
            Phase2Opportunity(
                id: "bookshop",
                fundamentals: BusinessFundamentals(
                    id: "bookshop", businessName: "Classic Books",
                    revenue: 30_000_000, costs: 28_000_000, profit: 2_000_000,
                    isHidden: false, hiddenFields: []),
                marketPrice: 15_000_000, sentimentIndicator: .fear),
            overpriced(),
            hiddenInfo()
        ]
    }
}
