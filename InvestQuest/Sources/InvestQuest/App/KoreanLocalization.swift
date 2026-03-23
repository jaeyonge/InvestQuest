import Foundation

enum KoreanLocalization {
    static func translate(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        if let patterned = translatedByPattern(text) {
            return patterned
        }

        let key = normalize(text)
        return directMap[key] ?? text
    }

    private static func translatedByPattern(_ text: String) -> String? {
        let key = normalize(text)

        if let captures = captures(for: #"^Phase (\d+) · Stage (\d+)$"#, in: key) {
            return "페이즈 \(captures[0]) · 스테이지 \(captures[1])"
        }

        if let captures = captures(for: #"^Phase (\d+) Complete$"#, in: key) {
            return "페이즈 \(captures[0]) 완료"
        }

        if let captures = captures(for: #"^Phase (\d+)$"#, in: key) {
            return "페이즈 \(captures[0])"
        }

        if let captures = captures(for: #"^Stage (\d+)$"#, in: key) {
            return "스테이지 \(captures[0])"
        }

        if let captures = captures(for: #"^Stage (\d+), (completed|unlocked|locked)$"#, in: key) {
            return "스테이지 \(captures[0]), \(translate(captures[1]))"
        }

        if let captures = captures(for: #"^Pass (\d+)\+$"#, in: key) {
            return "통과 기준 \(captures[0])+"
        }

        if let captures = captures(for: #"^(\d+)s timer$"#, in: key) {
            return "\(captures[0])초 타이머"
        }

        if let captures = captures(for: #"^(\d+)s$"#, in: key) {
            return "\(captures[0])초"
        }

        if let captures = captures(for: #"^Next Up · Phase (\d+)$"#, in: key) {
            return "다음 단계 · 페이즈 \(captures[0])"
        }

        if let captures = captures(for: #"^You last completed Phase (\d+): (.+)$"#, in: key) {
            return "최근에 완료한 페이즈 \(captures[0]): \(translate(captures[1]))"
        }

        if let captures = captures(for: #"^Starting value: (.+)$"#, in: key) {
            return "시작 금액: \(captures[0])"
        }

        if let captures = captures(for: #"^Suggested: (.+)$"#, in: key) {
            return "권장값: \(captures[0])"
        }

        if let captures = captures(for: #"^₩(\d+)M$"#, in: key) {
            return "\(captures[0])백만 원"
        }

        if let captures = captures(for: #"^Recent example: Phase (\d+) Stage (\d+)$"#, in: key) {
            return "최근 예시: 페이즈 \(captures[0]) 스테이지 \(captures[1])"
        }

        if let captures = captures(for: #"^Detected (\d+) times?$"#, in: key) {
            return "감지 \(captures[0])회"
        }

        if let captures = captures(for: #"^Resisted (\d+) times?$"#, in: key) {
            return "극복 \(captures[0])회"
        }

        if let captures = captures(for: #"^(\d+) across the completed phase\.$"#, in: key) {
            return "완료한 페이즈 전체 평균 \(captures[0])점"
        }

        if let captures = captures(for: #"^You finished ([0-9.]+)% below the modeled optimum\.$"#, in: key) {
            return "모델상 최적값보다 \(captures[0])% 낮게 마쳤어요."
        }

        return nil
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func captures(for pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }

        return (1..<match.numberOfRanges).compactMap { index in
            guard let captureRange = Range(match.range(at: index), in: text) else { return nil }
            return String(text[captureRange])
        }
    }

    private static func entry(_ english: String, _ korean: String) -> (String, String) {
        (normalize(english), korean)
    }

    private static let directMap: [String: String] = {
        Dictionary(uniqueKeysWithValues: [
            entry("INVESTQUEST", "인베스트퀘스트"),
            entry("InvestQuest", "인베스트퀘스트"),
            entry("Your money is disappearing.", "당신의 돈은 사라지고 있어요."),
            entry("Let's find out why.", "왜 그런지 알아봐요."),
            entry(
                "A playable investing simulation about inflation, valuation, risk, and behavioral bias.",
                "인플레이션, 가치평가, 위험, 행동 편향을 배우는 플레이형 투자 시뮬레이션이에요."
            ),
            entry("Start", "시작하기"),
            entry("Progress Map", "진행 지도"),
            entry("Seven phases. Each lesson unlocks after you prove the last one.", "7개의 페이즈로 구성되어 있어요. 앞선 교훈을 증명해야 다음 교훈이 열려요."),
            entry("Current Phase", "현재 페이즈"),
            entry("Completed", "완료"),
            entry("Phases cleared so far", "지금까지 클리어한 페이즈"),
            entry("Current", "현재"),
            entry("Cleared", "클리어"),
            entry("Locked", "잠김"),
            entry("completed", "완료"),
            entry("unlocked", "해제됨"),
            entry("locked", "잠김"),
            entry("Stage Setup", "스테이지 소개"),
            entry("Read the setup, find the signal, and commit to your move.", "상황을 읽고 핵심 신호를 찾은 뒤, 당신의 결정을 확정하세요."),
            entry("Concept unlocked", "개념 해제"),
            entry("Hint unlocked", "힌트 해제"),
            entry("Start Stage", "스테이지 시작"),
            entry("What to watch", "무엇을 봐야 하나요"),
            entry("Lesson", "교훈"),
            entry("Map", "맵"),
            entry("Current Stage", "현재 스테이지"),
            entry("Scenario", "시나리오"),
            entry("Core lesson", "핵심 교훈"),
            entry("Done", "닫기"),
            entry("Takeaway", "핵심 정리"),
            entry("Key Insight", "핵심 인사이트"),
            entry("Lock in the lesson before you move on.", "다음으로 넘어가기 전에 교훈을 확실히 남기세요."),
            entry("Carry this forward into the next stage.", "이 배움을 다음 스테이지까지 이어가세요."),
            entry("Continue", "계속"),
            entry("Simulation", "시뮬레이션"),
            entry("Market replay in motion", "시장 리플레이 진행 중"),
            entry("Watch the path unfold before you lock in the outcome.", "결과를 확정하기 전에 경로가 어떻게 전개되는지 지켜보세요."),
            entry("Press and hold to move chart", "길게 눌러 차트를 움직이세요"),
            entry("Release to pause chart", "손을 떼면 차트가 멈춰요"),
            entry("The replay only advances while you keep pressing.", "누르고 있는 동안에만 리플레이가 진행돼요."),
            entry("Replay complete", "리플레이 완료"),
            entry("You can review the result now.", "이제 결과를 확인할 수 있어요."),
            entry("See Results", "결과 보기"),
            entry("Portfolio", "포트폴리오"),
            entry("Change", "변화"),
            entry("Ahead of the starting line", "시작점보다 위에 있어요"),
            entry("Below the starting line", "시작점보다 아래에 있어요"),
            entry("Period", "구간"),
            entry("Replay Range", "리플레이 범위"),
            entry("Across replayed runs", "반복 실행 전체 기준"),
            entry("Low", "최저"),
            entry("Median", "중앙값"),
            entry("High", "최고"),
            entry("Resume", "이어하기"),
            entry("Welcome Back", "다시 오신 것을 환영해요"),
            entry("Take a quick warm-up lap before diving back into the run.", "다시 본격적으로 시작하기 전에 짧게 몸을 푸세요."),
            entry("Replay one stage as a warm-up, then continue from your current progression.", "워밍업으로 스테이지 하나를 다시 플레이한 뒤 현재 진행 지점으로 이어가세요."),
            entry("Resume At", "재개 위치"),
            entry("Mode", "모드"),
            entry("Warm-up", "워밍업"),
            entry("One quick replay before the run", "본격 진행 전 짧은 리플레이"),
            entry("Continue to Stage", "스테이지로 계속"),
            entry("Stage Cleared", "스테이지 클리어"),
            entry("Stage Review", "스테이지 복기"),
            entry("You held up under pressure", "압박 속에서도 잘 버텼어요"),
            entry("There was value left on the table", "아직 챙기지 못한 가치가 남아 있어요"),
            entry("Strong execution across the replay.", "리플레이 전반에서 실행이 좋았어요."),
            entry("Review the gap, then apply the lesson on the next run.", "차이를 복기한 뒤 다음 도전에 반영하세요."),
            entry("Your Portfolio", "내 포트폴리오"),
            entry("Final value after replay", "리플레이 종료 후 최종 가치"),
            entry("Optimal Play", "최적 선택"),
            entry("Best modeled decision path", "모델이 제시한 최적의 결정 경로"),
            entry("Replay Distribution", "리플레이 분포"),
            entry("Worst replay", "최악의 리플레이"),
            entry("Middle replay", "중간 리플레이"),
            entry("Best replay", "최고의 리플레이"),
            entry("Stage cleared", "스테이지 클리어"),
            entry("Performance gap", "성과 차이"),
            entry("Your choice stayed resilient across the simulation.", "당신의 선택은 시뮬레이션 전반에서 잘 버텼어요."),
            entry("Bias Signals", "편향 신호"),
            entry("See Insight", "인사이트 보기"),
            entry("You captured enough of the modeled upside to clear the stage.", "모델이 보여준 상승 여력을 충분히 확보해 스테이지를 통과했어요."),
            entry("The replay shows that a stronger allocation or decision path was available.", "리플레이를 보면 더 나은 배분이나 결정 경로가 가능했어요."),
            entry("Passed", "통과"),
            entry("Needs Work", "보완 필요"),
            entry("Score", "점수"),
            entry("Decision Window", "결정 시간"),
            entry("Commit before the opportunity closes.", "기회가 닫히기 전에 결정을 확정하세요."),
            entry("Choose your move", "당신의 선택을 고르세요"),
            entry("Total", "합계"),
            entry("Confirm Allocation", "배분 확정"),
            entry("Rank from strongest to weakest conviction.", "확신이 가장 큰 순서부터 가장 낮은 순서까지 정렬하세요."),
            entry("Highest conviction", "가장 높은 확신"),
            entry("Move up or down to reorder.", "위아래로 이동해 순서를 바꾸세요."),
            entry("Confirm Ranking", "순위 확정"),
            entry("Estimate intrinsic value", "내재가치를 추정하세요"),
            entry("Estimated Value", "추정 가치"),
            entry("Adjust the range, then choose your action.", "범위를 조정한 뒤 행동을 선택하세요."),
            entry("Set stop-loss threshold", "손절 기준을 설정하세요"),
            entry("Current Threshold", "현재 기준"),
            entry("Time", "시간"),
            entry("Build Allocation", "배분 구성"),
            entry("The portfolio auto-balances to 100% as you adjust conviction.", "확신도를 조정하면 포트폴리오가 자동으로 100%에 맞춰져요."),
            entry("Risk Profiles", "위험 프로필"),
            entry("Compounding Clues", "복리 힌트"),
            entry("Exit Discipline", "매도 원칙"),
            entry("Portfolio Notes", "포트폴리오 메모"),
            entry("Bias Cues", "편향 단서"),
            entry("Inflation path", "인플레이션 경로"),
            entry("Purchasing power check", "구매력 확인"),
            entry("Revenue", "매출"),
            entry("Costs", "비용"),
            entry("Profit", "이익"),
            entry("Market Price", "시장 가격"),
            entry("Hidden", "비공개"),
            entry("Detected from your play", "당신의 플레이에서 감지된 패턴"),
            entry("No earlier decisions are stored yet. Finish more stages to build a behavioral profile.", "아직 저장된 이전 결정이 없어요. 더 많은 스테이지를 완료하면 행동 프로필이 쌓여요."),
            entry("Anchoring", "앵커링"),
            entry("Loss Aversion", "손실 회피"),
            entry("Herd Behavior", "군중 추종"),
            entry("Recency Bias", "최신 편향"),
            entry("Anchoring Bias", "앵커링 편향"),
            entry("Inflation", "인플레이션"),
            entry("Valuation", "가치평가"),
            entry("Risk", "위험"),
            entry("Compounding", "복리"),
            entry("Exit", "매도"),
            entry("Diversification", "분산투자"),
            entry("Behavioral", "행동 심리"),
            entry("Average Score", "평균 점수"),
            entry("Status", "상태"),
            entry("Unlocked", "해제됨"),
            entry("Final phase cleared", "최종 페이즈 완료"),
            entry("Next lesson ready", "다음 교훈 준비 완료"),
            entry("Continue Journey", "여정 계속"),
            entry("Badge Earned", "획득한 배지"),
            entry("Performance Dashboard", "성과 대시보드"),
            entry("Cash Loses Value", "현금은 가치를 잃는다"),
            entry("Why does your money buy less every year?", "왜 당신의 돈은 해마다 살 수 있는 것이 줄어들까요?"),
            entry("Price vs. Value", "가격과 가치"),
            entry("Price is what you pay. Value is what you get.", "가격은 지불하는 것이고, 가치는 얻는 거예요."),
            entry("Risk and Return", "위험과 수익"),
            entry("Risk-Return Tradeoff", "위험-수익 상충관계"),
            entry("Higher potential returns come with higher risk.", "더 높은 기대수익에는 더 높은 위험이 따라요."),
            entry("Compound Growth", "복리 성장"),
            entry("Small consistent gains accumulate exponentially.", "작고 꾸준한 수익은 기하급수적으로 쌓여요."),
            entry("Knowing When to Exit", "언제 나와야 하는가"),
            entry("Cut losses early, let winners run.", "손실은 빨리 끊고 수익 자산은 길게 가져가세요."),
            entry("Portfolio Construction", "포트폴리오 구성"),
            entry("Spreading investments reduces single-failure impact.", "투자를 분산하면 단일 실패의 충격을 줄일 수 있어요."),
            entry("You Are Not Rational", "당신은 늘 합리적이지 않다"),
            entry("Behavioural Biases", "행동 편향"),
            entry("Cognitive biases systematically distort decisions.", "인지 편향은 결정을 체계적으로 왜곡해요."),
            entry("Inflation Fighter", "인플레이션 대응자"),
            entry("Value Seeker", "가치 탐색가"),
            entry("Risk Aware", "위험 감지자"),
            entry("Compound Master", "복리 마스터"),
            entry("Exit Strategist", "매도 전략가"),
            entry("Diversifier", "분산 투자자"),
            entry("Bias Buster", "편향 돌파자"),
            entry("Observe", "관찰하기"),
            entry("Cash", "현금"),
            entry("Savings Account", "예금 계좌"),
            entry("Inflation-Linked Bond", "물가연동채"),
            entry("All Cash", "전부 현금"),
            entry("Diversified", "분산 투자"),
            entry("Rice", "쌀"),
            entry("Coffee", "커피"),
            entry("Rent", "월세"),
            entry("Buy (Good Deal)", "매수 (좋은 가격)"),
            entry("Pass (Overpriced)", "패스 (고평가)"),
            entry("Kim's Fruit Stand", "김씨 과일가게"),
            entry("Park's Bakery", "박씨 빵집"),
            entry("Classic Books", "클래식 서점"),
            entry("Trendy Café", "트렌디 카페"),
            entry("Trendy Café Co.", "트렌디 카페"),
            entry("TechBoom Inc", "테크붐"),
            entry("StableGrocery", "스테이블그로서리"),
            entry("Buy (Looks Cheap)", "매수 (싸 보임)"),
            entry("Pass (Too Uncertain)", "패스 (불확실함)"),
            entry("TechX Corp", "테크X"),
            entry("TechX Corp.", "테크X"),
            entry("Hold (Stay the Course)", "보유 (계획 유지)"),
            entry("Sell (Cut Losses)", "매도 (손실 축소)"),
            entry("Neutral", "중립"),
            entry("🔥 Extreme Hype", "🔥 극단적 과열"),
            entry("😨 Panic Selling", "😨 공포 매도"),
            entry("📈 Mild Optimism", "📈 완만한 낙관"),
            entry("📉 Mild Caution", "📉 신중한 관망"),
            entry("Safe Asset", "안전자산"),
            entry("Medium Asset", "중간 위험 자산"),
            entry("Risky Asset", "고위험 자산"),
            entry("Narrow", "좁음"),
            entry("Balanced", "균형"),
            entry("Wide tail", "두꺼운 꼬리"),
            entry("Alpha Fund", "알파 펀드"),
            entry("Beta Fund", "베타 펀드"),
            entry("Gamma Fund", "감마 펀드"),
            entry("Guaranteed 50% Fund", "연 50% 보장 펀드"),
            entry("Index Fund", "인덱스 펀드"),
            entry("Withdraw Profits", "수익 인출"),
            entry("Reinvest All", "전액 재투자"),
            entry("Start Now", "지금 시작"),
            entry("Wait 10 Years", "10년 기다리기"),
            entry("Start Now (age 25)", "지금 시작 (25세)"),
            entry("Wait 10 Years (age 35)", "10년 기다리기 (35세)"),
            entry("Low Fee Fund", "저보수 펀드"),
            entry("High Fee Fund", "고보수 펀드"),
            entry("Low Fee Fund (0.5%)", "저보수 펀드 (0.5%)"),
            entry("High Fee Fund (2.0%)", "고보수 펀드 (2.0%)"),
            entry("Withdraw During Dip", "하락 중 인출"),
            entry("Hold and Wait", "보유하며 기다리기"),
            entry("Asset", "자산"),
            entry("Sell Now", "지금 매도"),
            entry("Hold On", "계속 보유"),
            entry("Asset A (Winner)", "자산 A (수익 중)"),
            entry("Asset B (Winner)", "자산 B (수익 중)"),
            entry("Asset C (Loser)", "자산 C (손실 중)"),
            entry("Asset D (Loser)", "자산 D (손실 중)"),
            entry("Asset E (Loser)", "자산 E (손실 중)"),
            entry("Set Stop-Loss", "손절 설정"),
            entry("No Stop-Loss", "손절 없음"),
            entry("With Stop-Loss", "손절 있음"),
            entry("Sell Now (Accept Loss)", "지금 매도 (손실 수용)"),
            entry("Hold for Recovery", "회복 기대하며 보유"),
            entry("All In on Best Asset", "최고 자산에 올인"),
            entry("Split Across 5 Assets", "5개 자산으로 분산"),
            entry("Concentrated (1 asset)", "집중 투자 (1개 자산)"),
            entry("Diversified (10 assets)", "분산 투자 (10개 자산)"),
            entry("All In on MegaCorp", "메가코프에 올인"),
            entry("Diversified Fund", "분산 펀드"),
            entry("TechCorp A", "테크코프 A"),
            entry("TechCorp B", "테크코프 B"),
            entry("TechCorp C", "테크코프 C"),
            entry("TechCorp D", "테크코프 D"),
            entry("TechCorp E", "테크코프 E"),
            entry("Government Bond", "국채"),
            entry("tech", "기술주"),
            entry("multi-class", "멀티 자산군"),
            entry("Urgency", "조급함"),
            entry("FOMO", "포모"),
            entry("fomo", "포모"),
            entry("anchoring bias", "앵커링 편향"),
            entry("fomo resisted", "포모 극복"),
            entry("loss aversion resisted", "손실 회피 극복"),
            entry("recency bias resisted", "최신 편향 극복"),
            entry("Buy Now!", "지금 매수!"),
            entry("Wait and Research", "기다리고 조사하기"),
            entry("Buy CryptoMoon (Top Leaderboard!)", "크립토문 매수 (리더보드 1위!)"),
            entry("Boring Index Fund", "심심한 인덱스 펀드"),
            entry("CryptoMoon", "크립토문"),
            entry("Buy (Anchored: was ₩500M, now ₩200M!)", "매수 (앵커링: 예전 5억, 지금 2억!)"),
            entry("Pass (₩200M is still 6× intrinsic value)", "패스 (2억은 여전히 내재가치의 6배)"),
            entry("Seoul Property Fund", "서울 부동산 펀드"),
            entry("Review My Decisions", "내 결정 복기하기"),
            entry("Skip Review", "복기 건너뛰기"),
            entry("Behavioral Review", "행동 편향 복기"),
            entry("Cut losses early", "손실은 빨리 끊기"),
            entry("Let winners run", "수익 자산은 길게 가져가기"),
            entry("Use rules before emotion", "감정보다 원칙 우선"),
            entry("Reinvest vs withdraw", "재투자 vs 인출"),
            entry("20-year horizon", "20년 투자 기간"),
            entry("Exponential vs linear growth", "기하급수 성장 vs 선형 성장"),
            entry("Early vs late start", "일찍 시작 vs 늦게 시작"),
            entry("35 vs 25 years", "35년 vs 25년"),
            entry("10-year head start value", "10년 선행의 가치"),
            entry("Low fee vs high fee", "저보수 vs 고보수"),
            entry("0.5% vs 2.0% annual fee", "연 0.5% vs 2.0% 수수료"),
            entry("30-year compounding drag", "30년 복리 잠식"),
            entry("Withdraw vs hold through dip", "하락 중 인출 vs 보유 유지"),
            entry("40% drawdown recovery", "40% 하락 후 회복"),
            entry("Breaking compounding chain", "복리 사슬 끊기"),
            entry(
                """
                Inflation is the gradual rise in prices over time. \
                When prices rise 3% per year, your cash loses 3% of its purchasing power — \
                even though the number in your bank account stays the same. \
                Holding only cash is not "safe". It is a guaranteed slow loss. \
                The goal is to find assets that grow at least as fast as inflation.
                """,
                """
                인플레이션은 시간이 지나며 물가가 서서히 오르는 현상이에요.
                물가가 매년 3% 오르면, 은행 계좌 숫자는 그대로여도
                당신의 현금은 구매력을 3% 잃어요.
                현금만 들고 있는 것은 '안전한' 선택이 아니에요.
                그것은 느리지만 확실한 손실이에요.
                목표는 인플레이션만큼, 또는 그보다 더 빨리 성장하는 자산을 찾는 거예요.
                """
            ),
            entry("The Vanishing 10 Million", "사라지는 1천만 원"),
            entry(
                """
                You have ₩10,000,000 in cash.
                Inflation runs at 3% per year.
                Watch what happens to your purchasing power over 10 years.
                You have no choice but to hold cash in Stage 1.
                """,
                """
                당신은 현금 1,000만 원을 가지고 있어요.
                인플레이션은 매년 3%씩 진행돼요.
                10년 동안 구매력이 어떻게 변하는지 지켜보세요.
                스테이지 1에서는 현금을 보유하는 것 외에 선택지가 없어요.
                """
            ),
            entry("Your ₩10M lost real value every year — not because you spent it, but because inflation made everything more expensive. Holding cash is a slow loss.", "당신의 1천만 원은 매년 실질가치를 잃었어요. 돈을 써서가 아니라 인플레이션 때문에 모든 것이 더 비싸졌기 때문이에요. 현금 보유는 느린 손실이에요."),
            entry("Watch the purchasing power line. It only goes one direction.", "구매력 선을 보세요. 방향은 하나뿐이에요."),
            entry("Cash vs. Savings", "현금 vs 예금"),
            entry(
                """
                You have ₩10,000,000 to allocate.
                Option A: Cash (loses ~3% purchasing power per year)
                Option B: Savings account (earns ~0.5% — barely offsets inflation)
                How do you split your money?
                """,
                """
                당신은 1,000만 원을 배분해야 해요.
                선택지 A: 현금 (매년 구매력이 약 3% 감소)
                선택지 B: 예금 계좌 (약 0.5% 수익, 인플레이션을 겨우 상쇄)
                돈을 어떻게 나눌까요?
                """
            ),
            entry("The savings account barely kept up with inflation — but it was still better than pure cash. Moving money to savings is a small but real improvement.", "예금 계좌는 인플레이션을 겨우 따라갔지만, 순수한 현금보다는 여전히 나았어요. 돈을 예금으로 옮기는 것은 작지만 분명한 개선이에요."),
            entry("One option keeps up with inflation slightly better than the other.", "한 선택지가 다른 선택지보다 인플레이션을 조금 더 잘 따라가요."),
            entry("The Inflation Shield", "인플레이션 방패"),
            entry(
                """
                You have ₩10,000,000 to allocate across three options:
                • Cash: loses purchasing power every year
                • Savings Account: barely keeps up with inflation
                • Inflation-Linked Bond: designed to preserve and grow purchasing power
                How do you allocate?
                """,
                """
                당신은 1,000만 원을 세 가지 선택지에 배분해야 해요.
                • 현금: 매년 구매력이 감소해요.
                • 예금 계좌: 인플레이션을 겨우 따라가요.
                • 물가연동채: 구매력을 지키고 키우도록 설계되었어요.
                어떻게 배분할까요?
                """
            ),
            entry("The inflation-linked bond preserved and grew your purchasing power while cash kept eroding. Not all assets fight inflation equally.", "물가연동채는 구매력을 지키고 키워줬지만, 현금은 계속 깎였어요. 모든 자산이 인플레이션에 똑같이 대응하는 것은 아니에요."),
            entry("Which asset is designed specifically to track inflation?", "어떤 자산이 인플레이션을 따라가도록 특별히 설계됐나요?"),
            entry("Inflation Rollercoaster", "인플레이션 롤러코스터"),
            entry(
                """
                Inflation is not constant. Over 4 periods:
                • Period 1-2: Low inflation (1%)
                • Period 3: High inflation spike (8%)
                • Period 4: Moderate (4%)
                Reallocate between Cash, Savings, and Inflation-Linked Bond each period.
                """,
                """
                인플레이션은 항상 일정하지 않아요. 4개 구간 동안:
                • 1-2구간: 낮은 인플레이션 (1%)
                • 3구간: 높은 인플레이션 급등 (8%)
                • 4구간: 보통 수준 (4%)
                각 구간마다 현금, 예금, 물가연동채 사이에서 다시 배분해 보세요.
                """
            ),
            entry("Active reallocation — moving into inflation-linked assets before a spike — can protect purchasing power better than any single static allocation.", "인플레이션 급등 전에 물가연동 자산으로 옮기는 능동적 재배분은 어떤 고정 배분보다도 구매력을 더 잘 지킬 수 있어요."),
            entry("Watch what happens to each asset during the high-inflation period.", "고인플레이션 구간에서 각 자산이 어떻게 움직이는지 보세요."),
            entry("30 Years of Decisions", "30년의 결정"),
            entry(
                """
                The final test: two strategies over 30 years.
                • Strategy A: 100% Cash
                • Strategy B: Diversified (20% Cash, 30% Savings, 50% Inflation-Linked Bond)
                ₩10,000,000 invested. Which do you choose for the long run?
                """,
                """
                마지막 테스트예요. 30년 동안의 두 전략을 비교해요.
                • 전략 A: 현금 100%
                • 전략 B: 분산 투자 (현금 20%, 예금 30%, 물가연동채 50%)
                1,000만 원을 투자할 때, 장기적으로 무엇을 선택할까요?
                """
            ),
            entry("Over 30 years, the compounding effect of inflation versus real returns creates an enormous wealth gap. Diversification is not just about risk — it's about surviving time.", "30년이 지나면 인플레이션과 실질수익의 복리 효과가 엄청난 자산 격차를 만들어요. 분산투자는 단지 위험 관리가 아니라 시간을 버텨내는 전략이에요."),
            entry("Think about 3% annual erosion compounded over 30 years.", "연 3%의 잠식이 30년 동안 복리로 쌓이면 어떤 결과가 되는지 생각해 보세요."),
            entry(
                """
                Price is what you pay. Value is what you get. \
                The market price of an asset is set by supply, demand, and emotion — not by fundamentals. \
                A skilled investor estimates intrinsic value independently, then only buys when \
                the market price is below that value. When everyone is greedy, prices are above value. \
                When everyone is fearful, prices may fall below value — creating opportunities.
                """,
                """
                가격은 당신이 지불하는 것이고, 가치는 당신이 얻는 거예요.
                자산의 시장가격은 펀더멘털이 아니라 수급과 감정에 의해 정해져요.
                숙련된 투자자는 내재가치를 독립적으로 추정한 뒤,
                시장가격이 그 가치보다 낮을 때만 매수해요.
                모두가 탐욕스러우면 가격은 가치보다 높아지고,
                모두가 두려워하면 가격은 가치 아래로 떨어져 기회가 생길 수 있어요.
                """
            ),
            entry("The Fruit Stand", "과일가게"),
            entry(
                """
                Kim's Fruit Stand generates:
                • Revenue: ₩50M/year
                • Costs: ₩30M/year
                • Profit: ₩20M/year

                The asking price is ₩140M.
                A fair value estimate is roughly 10× annual profit.

                Is the asking price a good deal?
                """,
                """
                김씨 과일가게의 연간 실적은 다음과 같아요.
                • 매출: 연 5천만 원
                • 비용: 연 3천만 원
                • 이익: 연 2천만 원

                제시 가격은 1억 4천만 원이에요.
                적정가치는 보통 연간 이익의 약 10배로 볼 수 있어요.

                이 가격은 좋은 거래일까요?
                """
            ),
            entry("The asking price was ₩140M but the intrinsic value (10× profit) was ₩200M. You were buying at a 30% discount. That's the core skill: price vs. value.", "제시 가격은 1억 4천만 원이었지만 내재가치(이익의 10배)는 2억 원이었어요. 당신은 30% 할인된 가격에 사는 셈이었어요. 이것이 핵심이에요. 가격과 가치의 차이예요."),
            entry("Calculate: 10 × annual profit = estimated intrinsic value. Compare to asking price.", "계산해 보세요. 연간 이익 × 10 = 추정 내재가치예요. 그 값을 제시 가격과 비교하세요."),
            entry("Business Ranking", "사업 순위 매기기"),
            entry(
                """
                Rank these four businesses from best value to worst:
                • Kim's Fruit Stand: Profit ₩20M, Price ₩140M
                • Park's Bakery: Profit ₩20M, Price ₩180M
                • Classic Books: Profit ₩2M, Price ₩15M
                • Trendy Café: Profit ₩5M, Price ₩150M

                Best deal = lowest price-to-value ratio.
                """,
                """
                다음 네 가지 사업을 가치가 가장 좋은 순서부터 가장 나쁜 순서까지 정렬하세요.
                • 김씨 과일가게: 이익 2천만 원, 가격 1억 4천만 원
                • 박씨 빵집: 이익 2천만 원, 가격 1억 8천만 원
                • 클래식 서점: 이익 2백만 원, 가격 1천5백만 원
                • 트렌디 카페: 이익 5백만 원, 가격 1억 5천만 원

                가장 좋은 거래는 가격 대비 가치 비율이 가장 낮은 것이에요.
                """
            ),
            entry("Kim's Fruit Stand (P/E 7) was the best deal; Trendy Café (P/E 30) was the worst. Same metric — price-to-earnings — ranked them all.", "김씨 과일가게(P/E 7)가 가장 좋은 거래였고, 트렌디 카페(P/E 30)가 가장 나빴어요. 같은 지표인 주가수익비율(P/E)만으로도 모두를 순위화할 수 있었어요."),
            entry("Divide price by profit for each. Lower = better value.", "각 사업의 가격을 이익으로 나눠 보세요. 값이 낮을수록 더 좋은 가치예요."),
            entry("Hype vs. Fear", "과열 vs 공포"),
            entry(
                """
                Two businesses. Same fundamentals. Different market sentiment.

                • TechBoom Inc: Profit ₩30M, Price ₩900M — 🔥 Extreme Hype
                • StableGrocery: Profit ₩30M, Price ₩120M — 😨 Panic Selling

                Both have the same intrinsic value (₩300M). Sentiment has distorted prices.
                Which do you buy?
                """,
                """
                두 개의 사업이 있어요. 펀더멘털은 같지만 시장 심리는 달라요.

                • 테크붐: 이익 3천만 원, 가격 9억 원 — 🔥 극단적 과열
                • 스테이블그로서리: 이익 3천만 원, 가격 1억 2천만 원 — 😨 공포 매도

                두 사업의 내재가치는 모두 3억 원으로 같아요.
                하지만 심리가 가격을 왜곡했어요.
                무엇을 살까요?
                """
            ),
            entry("StableGrocery was trading at 40% of intrinsic value due to fear. TechBoom was at 300% due to hype. Sentiment distorts price — but value reverts.", "스테이블그로서리는 공포 때문에 내재가치의 40% 수준에서 거래되고 있었고, 테크붐은 과열 때문에 300% 수준이었어요. 심리는 가격을 왜곡하지만, 가치는 결국 제자리로 돌아와요."),
            entry("Which one is trading far below its fundamental value?", "둘 중 어떤 것이 본질가치보다 훨씬 낮게 거래되고 있나요?"),
            entry("Incomplete Information", "불완전한 정보"),
            entry(
                """
                You're evaluating TechX Corp.
                • Revenue: ₩200M/year
                • Costs: [HIDDEN]
                • Profit: [HIDDEN]
                • Sentiment: 📈 Mild Optimism
                • Market Price: ₩300M

                You can only see revenue. Make your best estimate of fair value.
                """,
                """
                당신은 테크X를 평가하고 있어요.
                • 매출: 연 2억 원
                • 비용: [비공개]
                • 이익: [비공개]
                • 심리: 📈 완만한 낙관
                • 시장 가격: 3억 원

                당신은 매출만 볼 수 있어요.
                가능한 최선으로 적정가치를 추정해 보세요.
                """
            ),
            entry("When you can't see costs or profit, you can't estimate value. Passing is a valid decision — and often the wisest one when information is incomplete.", "비용이나 이익을 볼 수 없다면 가치를 추정할 수 없어요. 패스하는 것도 유효한 결정이며, 정보가 불완전할 때는 종종 가장 현명한 선택이에요."),
            entry("If costs are unknown, profit is unknown. If profit is unknown, value is unknown.", "비용을 모르면 이익도 몰라요. 이익을 모르면 가치도 몰라요."),
            entry("Patience Pays", "인내는 보상된다"),
            entry(
                """
                You identified Park's Bakery as undervalued (₩180M, value ₩200M).
                You buy. Now hold through 10 years of market noise.
                The price will fluctuate — sometimes below what you paid.
                Will you hold or sell when it dips?
                """,
                """
                당신은 박씨 빵집이 저평가되었다고 판단했어요. (가격 1억 8천만 원, 가치 2억 원)
                매수한 뒤 10년간의 시장 잡음을 견뎌야 해요.
                가격은 흔들릴 것이고, 때로는 당신이 산 가격 아래로 내려갈 수도 있어요.
                하락이 오면 보유할까요, 아니면 매도할까요?
                """
            ),
            entry("Short-term price movements are noise. Long-term, value wins. Buying below intrinsic value and holding is the complete strategy.", "단기 가격 움직임은 잡음이에요. 장기적으로는 가치가 이겨요. 내재가치보다 낮게 사고 보유하는 것이 완성된 전략이에요."),
            entry("The fundamentals haven't changed. Only the price did.", "펀더멘털은 바뀌지 않았어요. 바뀐 것은 가격뿐이에요."),
            entry(
                """
                Risk and return are inseparable. \
                Every investment that offers higher potential return carries higher risk — \
                the possibility of larger losses. Safe assets produce steady, modest returns. \
                Risky assets can deliver large gains or large losses. \
                There are no guaranteed high returns. \
                Anyone promising guaranteed high returns is either wrong or lying. \
                The skill is choosing the right level of risk for your situation, \
                not chasing the highest possible return.
                """,
                """
                위험과 수익은 떼어낼 수 없어요.
                더 높은 기대수익을 제공하는 투자는 반드시 더 큰 위험,
                즉 더 큰 손실 가능성을 함께 안고 있어요.
                안전자산은 꾸준하지만 크지 않은 수익을 내고,
                위험자산은 큰 수익도 큰 손실도 가능하게 해요.
                확실하게 높은 수익을 보장하는 투자는 없어요.
                그런 약속을 하는 사람은 틀렸거나 거짓말을 하는 거예요.
                핵심 기술은 가장 높은 수익을 쫓는 것이 아니라
                자신의 상황에 맞는 위험 수준을 고르는 거예요.
                """
            ),
            entry("See the Risk", "위험을 보라"),
            entry(
                """
                Three assets. Same starting price. Very different risk profiles.

                • Safe Asset: narrow outcome range — low volatility (5%), low drift (3%)
                • Medium Asset: moderate range — medium volatility (15%), medium drift (7%)
                • Risky Asset: wide outcome range — high volatility (35%), medium drift (7%)

                The probability distributions are shown visually. \
                Safe has a tight bell curve. Risky has a wide, flat one.

                Allocate ₩10,000,000 across the three assets.
                Run the simulation 10 times to see how outcomes vary.
                """,
                """
                세 가지 자산이 있어요. 시작 가격은 같지만 위험 프로필은 크게 달라요.

                • 안전자산: 결과 범위가 좁음, 낮은 변동성(5%), 낮은 성장률(3%)
                • 중간 위험 자산: 결과 범위가 중간, 중간 변동성(15%), 중간 성장률(7%)
                • 고위험 자산: 결과 범위가 넓음, 높은 변동성(35%), 중간 성장률(7%)

                확률 분포가 시각적으로 표시돼요.
                안전자산은 종 모양이 좁고, 고위험 자산은 넓고 평평해요.

                1,000만 원을 세 자산에 배분하세요.
                시뮬레이션을 10번 돌려 결과가 어떻게 달라지는지 확인해 보세요.
                """
            ),
            entry("Safe assets have narrow outcome ranges — you rarely win big or lose big. Risky assets have wide ranges — big wins and big losses are both possible. Running 10 simulations makes the variance difference visible.", "안전자산은 결과 범위가 좁아 크게 벌거나 크게 잃을 일이 드물어요. 위험자산은 범위가 넓어 큰 수익도 큰 손실도 모두 가능해요. 시뮬레이션을 10번 돌리면 분산의 차이가 눈에 보여요."),
            entry("Look at how wide the outcome range is for each asset. Wider = more risk.", "각 자산의 결과 범위가 얼마나 넓은지 보세요. 넓을수록 위험이 커요."),
            entry("Smooth the Ride", "흔들림을 줄여라"),
            entry(
                """
                You have ₩10,000,000 to allocate across three risk levels:

                • Safe Asset: low risk, low reward
                • Medium Asset: moderate risk, moderate reward
                • Risky Asset: high risk, high potential reward

                Observe how mixing risk levels smooths overall portfolio outcomes.
                """,
                """
                당신은 1,000만 원을 세 가지 위험 수준에 배분해야 해요.

                • 안전자산: 낮은 위험, 낮은 보상
                • 중간 위험 자산: 중간 위험, 중간 보상
                • 고위험 자산: 높은 위험, 높은 기대보상

                서로 다른 위험 수준을 섞으면 전체 포트폴리오 결과가 어떻게 부드러워지는지 살펴보세요.
                """
            ),
            entry("Mixing assets with different risk levels reduces the extremes. A portfolio is smoother than any single asset within it — this is the foundation of risk management.", "서로 다른 위험 수준의 자산을 섞으면 극단값이 줄어들어요. 포트폴리오는 그 안의 어떤 단일 자산보다도 더 부드럽게 움직여요. 이것이 위험 관리의 기초예요."),
            entry("Try spreading your allocation. Watch what happens to the total portfolio swing.", "배분을 분산해 보세요. 전체 포트폴리오의 흔들림이 어떻게 달라지는지 보세요."),
            entry("Hidden Danger", "숨은 위험"),
            entry(
                """
                Three funds with nearly identical past returns over 7 periods.
                Which is the safest choice?

                • Alpha Fund: steady historical performance
                • Beta Fund: steady historical performance
                • Gamma Fund: steady historical performance — but look closely at the pattern

                Past returns look identical. But one fund has hidden tail risk. \
                A rare catastrophic event can occur. Rank them from safest to riskiest.
                """,
                """
                7개 구간 동안 과거 수익률이 거의 똑같아 보이는 세 개의 펀드가 있어요.
                가장 안전한 선택은 무엇일까요?

                • 알파 펀드: 안정적인 과거 성과
                • 베타 펀드: 안정적인 과거 성과
                • 감마 펀드: 안정적인 과거 성과처럼 보이지만 패턴을 자세히 보세요

                과거 수익률은 비슷해 보이지만, 한 펀드에는 숨겨진 꼬리위험이 있어요.
                드물지만 치명적인 사건이 발생할 수 있어요.
                가장 안전한 것부터 가장 위험한 것까지 순위를 매겨 보세요.
                """
            ),
            entry("Past returns that look identical can hide very different risk profiles. Tail risk — rare but catastrophic — doesn't show up in average performance. Gamma's crash at period 7 was the signal buried in the pattern.", "겉보기에 똑같은 과거 수익률 뒤에도 완전히 다른 위험 프로필이 숨어 있을 수 있어요. 꼬리위험은 드물지만 치명적이며 평균 성과에는 잘 드러나지 않아요. 7구간에서 감마 펀드가 붕괴한 것이 바로 패턴 속에 숨어 있던 신호였어요."),
            entry("Look at the variance in each fund's returns, not just the average.", "평균만 보지 말고 각 펀드 수익률의 분산을 보세요."),
            entry("Too Good to Be True", "너무 좋아 보인다면"),
            entry(
                """
                Two investment options:

                • Guaranteed 50% Fund: promises 50% annual returns. No risk. Guaranteed.
                • Index Fund: tracks the market. Modest returns. Boring. No promises.

                The Guaranteed 50% Fund looks spectacular for the first 4 periods.
                Then something happens.

                Which do you choose?
                """,
                """
                두 가지 투자 선택지가 있어요.

                • 연 50% 보장 펀드: 연 50% 수익을 약속해요. 위험 없음. 보장.
                • 인덱스 펀드: 시장을 추종해요. 수익은 평범하고 지루하지만 어떤 약속도 하지 않아요.

                연 50% 보장 펀드는 처음 4구간 동안 놀라워 보여요.
                그리고 나서 무언가가 일어나요.

                무엇을 선택할까요?
                """
            ),
            entry("No investment can guarantee 50% returns. High guaranteed returns are the signature of fraud or a bubble. The 'Guaranteed 50% Fund' lost 95% in one period. The boring index fund survived.", "어떤 투자도 연 50% 수익을 보장할 수 없어요. 높고 확실한 수익을 약속하는 것은 사기나 버블의 전형적인 신호예요. '연 50% 보장 펀드'는 한 구간 만에 95%를 잃었지만, 지루한 인덱스 펀드는 살아남았어요."),
            entry("If something sounds too good to be true, it usually is. What happens when 'guaranteed' promises fail?", "너무 좋아 보이는 이야기는 대부분 사실이 아니에요. '보장'이라는 약속이 무너지면 무슨 일이 생길까요?"),
            entry(
                """
                Compounding is the process where your gains generate their own gains. \
                Over time, this creates exponential growth — not linear. \
                Starting early matters enormously: 10 extra years of compounding can \
                be worth more than doubling your contributions later. \
                Fees compound too — a 2% annual fee vs 0.5% costs hundreds of millions \
                of ₩ in absolute terms over 30 years. \
                Breaking compounding by withdrawing during a dip is one of the most \
                expensive mistakes an investor can make.
                """,
                """
                복리는 당신의 수익이 다시 새로운 수익을 만드는 과정이에요.
                시간이 지나면 이는 선형이 아니라 기하급수적 성장을 만들어요.
                일찍 시작하는 것은 엄청나게 중요해요.
                복리 10년의 차이는 나중에 납입액을 두 배로 늘리는 것보다 더 큰 가치를 가질 수 있어요.
                수수료도 복리로 쌓여요.
                연 2% 수수료와 0.5% 수수료의 차이는 30년 동안 절대 금액 기준으로 수억 원의 차이를 만들 수 있어요.
                하락장에서 인출해 복리를 끊어버리는 것은 투자자가 저지를 수 있는 가장 비싼 실수 중 하나예요.
                """
            ),
            entry("The Power of Reinvesting", "재투자의 힘"),
            entry(
                """
                You have ₩10,000,000 invested in a fund earning ~8% per year.
                • Option A: Withdraw Profits — take gains out each year
                • Option B: Reinvest All — let gains compound for 20 years

                Both start with the same amount. What do you choose?
                """,
                """
                당신은 연 8% 정도를 버는 펀드에 1,000만 원을 투자했어요.
                • 선택지 A: 수익 인출 - 매년 난 수익을 꺼내요.
                • 선택지 B: 전액 재투자 - 수익이 20년 동안 복리로 쌓이게 둬요.

                두 선택지는 같은 금액에서 시작해요.
                무엇을 고를까요?
                """
            ),
            entry("Reinvesting turned ₩100 into far more than withdrawing over 20 years. Each year's gains became the base for next year's growth — that's compounding.", "재투자는 20년 동안 인출보다 훨씬 큰 결과를 만들었어요. 매년의 수익이 다음 해 성장의 바탕이 된 거예요. 그것이 바로 복리예요."),
            entry("Which option lets your gains generate their own gains?", "어떤 선택지가 당신의 수익이 다시 수익을 만들게 하나요?"),
            entry("The 10-Year Head Start", "10년 먼저 시작하기"),
            entry(
                """
                Two investors both retire at 60. Both earn 7% per year.
                • Option A: Start Now (age 25) — 35 years of compounding
                • Option B: Wait 10 Years (age 35) — 25 years of compounding

                Same annual contribution. Who ends up with more at age 60?
                """,
                """
                두 투자자는 모두 60세에 은퇴해요. 둘 다 연 7%를 벌어들여요.
                • 선택지 A: 지금 시작 (25세) - 35년의 복리
                • 선택지 B: 10년 기다리기 (35세) - 25년의 복리

                연간 납입액은 같아요.
                60세가 되었을 때 누가 더 많은 자산을 갖게 될까요?
                """
            ),
            entry("The 10-year head start advantage is worth more than doubling contributions later. Time is the most powerful input to compounding — and it can't be bought back.", "10년 먼저 시작하는 이점은 나중에 납입액을 두 배로 늘리는 것보다 더 커요. 시간은 복리에서 가장 강력한 요소이며, 한 번 지나가면 다시 살 수 없어요."),
            entry("Compounding needs time. Every year you wait shrinks the base that grows.", "복리에는 시간이 필요해요. 기다리는 해가 늘어날수록 성장할 바탕은 줄어들어요."),
            entry("The Fee Drain", "수수료의 누수"),
            entry(
                """
                Two funds. Same gross return of 7% per year. Different fees.
                • Option A: Low Fee Fund — 0.5% annual fee (net return ≈ 6.5%)
                • Option B: High Fee Fund — 2.0% annual fee (net return ≈ 5.0%)

                Over 30 years on ₩10,000,000, the fee difference costs you tens of millions of ₩.
                Which fund do you choose?
                """,
                """
                두 개의 펀드가 있어요. 연간 총수익률은 모두 7%로 같지만 수수료가 달라요.
                • 선택지 A: 저보수 펀드 - 연 수수료 0.5% (순수익 약 6.5%)
                • 선택지 B: 고보수 펀드 - 연 수수료 2.0% (순수익 약 5.0%)

                1,000만 원을 30년 투자하면 수수료 차이만으로 수천만 원의 격차가 나요.
                무엇을 선택할까요?
                """
            ),
            entry("Over 30 years, the 1.5% fee difference compounds into tens of millions of ₩ lost — not just in fees paid, but in the growth those fees could have generated. Fees compound too.", "30년이 지나면 1.5%포인트의 수수료 차이는 수천만 원의 손실로 불어나요. 단지 낸 수수료 때문만이 아니라, 그 돈이 만들어낼 수 있었던 성장까지 사라지기 때문이에요. 수수료도 복리로 쌓여요."),
            entry("A 2% fee vs 0.5% means 1.5% less compounding every single year for 30 years.", "연 2% 수수료와 0.5% 수수료의 차이는 30년 동안 매년 1.5%포인트씩 복리 성장을 깎아 먹는다는 뜻이에요."),
            entry("The Dip Test", "하락장 테스트"),
            entry(
                """
                Your long-term investment drops 40% at year 8.
                Analysts are split: some say it will recover, others say sell now.
                • Option A: Withdraw During Dip — exit and cut your losses
                • Option B: Hold and Wait — stay invested through the downturn

                History shows holding through dips usually wins — but it's hard in the moment.
                """,
                """
                당신의 장기 투자가 8년 차에 40% 하락했어요.
                분석가들의 의견은 갈려요. 어떤 이는 회복을 말하고, 어떤 이는 지금 팔라고 해요.
                • 선택지 A: 하락 중 인출 - 지금 빠져나와 손실을 끊어요.
                • 선택지 B: 보유하며 기다리기 - 하락장을 버티며 계속 투자 상태를 유지해요.

                역사적으로 하락장을 버틴 쪽이 대체로 이겼지만, 그 순간에는 매우 어려워요.
                """
            ),
            entry("The -40% dip recovered fully by year 12 and went on to strong gains. Withdrawing during the dip locked in the loss and broke the compounding chain permanently.", "마이너스 40%의 하락은 12년 차에 완전히 회복됐고, 이후 강한 상승으로 이어졌어요. 하락 중에 인출하면 손실이 확정되고 복리의 사슬도 영구히 끊어져요."),
            entry("If the fundamentals haven't changed, a dip is not a reason to stop compounding.", "펀더멘털이 바뀌지 않았다면, 하락은 복리를 멈출 이유가 아니에요."),
            entry(
                """
                The disposition effect is one of the most costly investment mistakes: \
                investors instinctively sell their winners and hold their losers. \
                It feels right — locking in a gain, waiting for a loser to recover — \
                but the data shows it destroys returns over time. \
                Loss aversion makes losses feel twice as painful as equivalent gains feel good. \
                This psychological bias causes us to hold losing positions far too long, \
                hoping to "get back to even." \
                The discipline: cut losses early with a pre-set exit rule, \
                and let winners run until the fundamentals change. \
                Don't let emotions override your exit strategy.
                """,
                """
                처분효과는 가장 비싼 투자 실수 중 하나예요.
                투자자는 본능적으로 수익 난 자산은 팔고, 손실 난 자산은 계속 들고 가요.
                이익을 확정하고, 손실 자산이 회복되길 기다리는 것이 맞는 것처럼 느껴지지만
                데이터는 이것이 시간이 지날수록 수익을 망친다고 보여줘요.
                손실 회피 때문에 손실은 같은 크기의 이익보다 두 배 이상 더 고통스럽게 느껴져요.
                이 심리적 편향은 우리로 하여금
                '본전만 오면 팔겠다'는 생각으로 손실 자산을 너무 오래 붙들게 만들어요.
                규율은 분명해요.
                미리 정한 규칙으로 손실은 빨리 끊고,
                펀더멘털이 바뀔 때까지 수익 자산은 계속 보유하세요.
                감정이 매도 전략을 덮어쓰게 두지 마세요.
                """
            ),
            entry("The Right Moment to Sell", "매도해야 할 순간"),
            entry(
                """
                You hold one asset. It has been rising — but markets don't rise forever.
                A sharp event is coming that will erase most of the gains.
                Watch the price movement and decide: sell now to lock in gains,
                or hold on hoping for more upside?
                """,
                """
                당신은 하나의 자산을 보유하고 있어요.
                계속 오르고 있었지만 시장이 영원히 오르지는 않아요.
                곧 대부분의 수익을 지워버릴 급격한 사건이 다가와요.
                가격 움직임을 보고 결정하세요.
                지금 팔아 이익을 확정할까요, 아니면 더 오르길 바라며 계속 보유할까요?
                """
            ),
            entry("The asset peaked and then dropped 35% in a single event. Selling while ahead — even before the top — beats holding through a crash and waiting to recover.", "이 자산은 고점을 찍은 뒤 한 번의 사건으로 35% 하락했어요. 꼭 최고점이 아니더라도 이익일 때 매도하는 것이, 폭락을 버티며 회복만 기다리는 것보다 나아요."),
            entry("Once an asset has risen significantly, the question is no longer 'will it go higher?' but 'how much can I lose if it doesn't?'", "자산이 크게 오른 뒤에는 '더 오를까?'보다 '더 오르지 않는다면 얼마나 잃을 수 있을까?'를 물어야 해요."),
            entry("Winners and Losers", "수익 자산과 손실 자산"),
            entry(
                """
                Your portfolio has 5 assets. Some have gained, some have lost.
                You need to sell two positions to raise cash.
                Rank them in the order you would sell — most urgent first.

                • Asset A (Winner): Up significantly since purchase
                • Asset B (Winner): Up moderately since purchase
                • Asset C (Loser): Down 40% since purchase
                • Asset D (Loser): Down 30% since purchase
                • Asset E (Loser): Down 20% since purchase

                Which do you sell first?
                """,
                """
                당신의 포트폴리오에는 5개의 자산이 있어요.
                어떤 것은 올랐고, 어떤 것은 내렸어요.
                현금을 마련하려면 두 포지션을 팔아야 해요.
                가장 먼저 팔 것부터 순서를 정해 보세요.

                • 자산 A (수익 중): 매수 이후 크게 상승
                • 자산 B (수익 중): 매수 이후 완만하게 상승
                • 자산 C (손실 중): 매수 이후 40% 하락
                • 자산 D (손실 중): 매수 이후 30% 하락
                • 자산 E (손실 중): 매수 이후 20% 하락

                무엇을 먼저 팔까요?
                """
            ),
            entry("Most people instinctively sell winners and hold losers — this is the disposition effect. Rational exit discipline is the opposite: cut your losers early, let your winners run.", "대부분의 사람은 본능적으로 수익 자산을 팔고 손실 자산을 들고 가요. 이것이 처분효과예요. 합리적인 매도 규율은 그 반대예요. 손실 자산은 빨리 정리하고, 수익 자산은 계속 가게 두세요."),
            entry("Which assets show no sign of recovery? Holding a loser hoping to 'get back to even' is a trap.", "회복의 신호가 전혀 없는 자산은 무엇인가요? '본전만 오면'을 바라며 손실 자산을 붙드는 것은 함정이에요."),
            entry("The Stop-Loss Shield", "손절 방패"),
            entry(
                """
                You are comparing two identical investments — only one has a stop-loss rule.
                A catastrophic event strikes at period 6.

                • With Stop-Loss (−15% trigger): Position automatically exits when down 15%
                • Without Stop-Loss: Position remains open through any loss

                Which approach do you take before the simulation runs?
                """,
                """
                두 개의 동일한 투자 대상을 비교해요.
                차이는 하나만 손절 규칙이 있다는 점이에요.
                6구간에 치명적인 사건이 발생해요.

                • 손절 있음 (-15% 발동): 15% 하락하면 포지션이 자동으로 종료돼요.
                • 손절 없음: 어떤 손실이 나도 포지션은 계속 열려 있어요.

                시뮬레이션이 시작되기 전에 어떤 방식을 택할까요?
                """
            ),
            entry("Without a stop-loss, a single catastrophic event wiped out 70% of the position. The stop-loss exited at -15% — painful, but survivable. Pre-set rules remove emotion from the exit decision.", "손절이 없으면 단 한 번의 치명적 사건으로 포지션의 70%가 사라졌어요. 손절은 -15%에서 종료되어 아프지만 생존 가능한 손실에 그쳤어요. 미리 정한 규칙은 매도 결정에서 감정을 제거해 줘요."),
            entry("A stop-loss is a pre-commitment to cut losses at a defined level. It removes the temptation to hold through a crash.", "손절은 정해진 수준에서 손실을 끊겠다는 사전 약속이에요. 폭락을 버티고 싶어지는 유혹을 없애 줘요."),
            entry("The -40% Dilemma", "-40% 딜레마"),
            entry(
                """
                Your position has dropped -40%. There are mixed signals about recovery.
                A partial rebound appeared — but is it a real recovery or a dead cat bounce?

                The money you originally invested is gone from the current price.
                The question is not where the price was — it's where it's going.

                Do you sell and accept the loss, or hold hoping for full recovery?
                """,
                """
                당신의 포지션은 40% 하락했어요.
                회복에 대한 신호는 엇갈려요.
                부분 반등이 나타났지만, 진짜 회복일까요 아니면 일시적 반등일까요?

                당신이 처음 넣은 돈은 현재 가격에 이미 반영되어 있지 않아요.
                중요한 것은 과거 가격이 아니라 앞으로 가격이 어디로 가는가예요.

                손실을 인정하고 매도할까요, 아니면 완전한 회복을 바라며 보유할까요?
                """
            ),
            entry("The sunk cost fallacy says 'I can't sell — I'd be locking in a loss.' But the loss already happened. On average, holding through a -40% drop hoping for full recovery loses more than accepting the loss and redeploying capital.", "매몰비용의 오류는 '지금 팔면 손실이 확정되잖아'라고 말해요. 하지만 그 손실은 이미 발생했어요. 평균적으로 보면, -40% 하락 이후 완전한 회복을 기대하며 버티는 것이 손실을 받아들이고 자본을 재배치하는 것보다 더 큰 손해를 낳아요."),
            entry("The price you paid is irrelevant to what the asset will do next. Ignore what you paid — focus only on future expected returns vs. current price.", "당신이 얼마에 샀는지는 이 자산이 앞으로 어떻게 움직일지와 무관해요. 매수가를 잊고, 현재 가격 대비 앞으로 기대되는 수익만 보세요."),
            entry(
                """
                Diversification means spreading your investments so that \
                a single failure cannot wipe out your portfolio. \
                When one asset crashes, others can absorb the blow.

                But not all diversification is real. \
                Correlation matters: assets that move together crash together. \
                Owning 5 tech stocks is not diversification — \
                they are highly correlated and all fall in the same sector downturn.

                True portfolio construction combines asset classes with low or negative \
                correlation: stocks, bonds, real estate, commodities. \
                When one falls, another often holds or rises.

                Diversification does not eliminate risk, but it reduces the impact \
                of any single failure on your overall portfolio.
                """,
                """
                분산투자는 한 번의 실패로 포트폴리오 전체가 무너지지 않도록
                투자를 나누는 거예요.
                하나의 자산이 급락할 때 다른 자산이 충격을 흡수할 수 있어야 해요.

                하지만 모든 분산이 진짜 분산은 아니에요.
                상관관계가 중요해요.
                함께 움직이는 자산은 함께 무너져요.
                기술주 5개를 보유하는 것은 분산이 아니에요.
                그것들은 높은 상관관계를 가지며 같은 업종 침체에서 함께 하락해요.

                진짜 포트폴리오 구성은 상관관계가 낮거나 음의 상관관계를 가진 자산군을 조합해요.
                주식, 채권, 부동산, 원자재처럼 말이에요.
                하나가 떨어질 때 다른 하나는 버티거나 오르는 경우가 많아요.

                분산투자가 위험을 없애지는 못하지만,
                단일 실패가 전체 포트폴리오에 미치는 충격은 줄여 줘요.
                """
            ),
            entry("All In or Spread Out?", "올인인가 분산인가?"),
            entry(
                """
                You have ₩10,000,000 to invest.
                Asset A looks very attractive — high growth so far.
                Option A: Put everything into that one asset.
                Option B: Split evenly across 5 different assets.
                One unexpected crash could change everything. Choose wisely.
                """,
                """
                당신에게는 투자할 1,000만 원이 있어요.
                자산 A는 지금까지의 성장률이 높아 매우 매력적으로 보여요.
                선택지 A: 그 하나의 자산에 전부 투자해요.
                선택지 B: 서로 다른 5개 자산에 균등 분산해요.
                예상치 못한 한 번의 폭락이 모든 것을 바꿀 수 있어요.
                신중히 선택하세요.
                """
            ),
            entry("The all-in asset looked great — until it crashed. Putting everything in one place means a single failure destroys your entire portfolio. Spreading across assets limits the damage any one event can cause.", "올인한 자산은 폭락하기 전까지는 훌륭해 보였어요. 모든 돈을 한곳에 두면 단 한 번의 실패가 포트폴리오 전체를 무너뜨릴 수 있어요. 자산을 나누면 한 사건이 낼 수 있는 피해를 제한할 수 있어요."),
            entry("What happens to your money if the best-looking asset suddenly drops 80%?", "가장 좋아 보이던 자산이 갑자기 80% 떨어지면 당신의 돈에는 무슨 일이 생기나요?"),
            entry("The Variance Experiment", "분산 실험"),
            entry(
                """
                Run 20 simulations and watch the outcomes.
                Strategy A: Concentrated (all in 1 asset) — high highs, catastrophic lows.
                Strategy B: Diversified (10 assets) — more consistent, less dramatic swings.
                Variance across simulations reveals the true risk of each strategy.
                Which do you choose?
                """,
                """
                시뮬레이션을 20번 돌려 결과를 보세요.
                전략 A: 집중 투자 (1개 자산 올인) - 높은 고점, 치명적인 저점
                전략 B: 분산 투자 (10개 자산) - 더 일관되고, 흔들림이 덜 극적임
                여러 번의 시뮬레이션에서 드러나는 분산이 각 전략의 진짜 위험을 보여줘요.
                무엇을 선택할까요?
                """
            ),
            entry("Across 20 simulations, the diversified portfolio showed far less variance — fewer catastrophic losses without sacrificing expected return. Diversification is free risk reduction.", "20번의 시뮬레이션에서 분산 포트폴리오는 기대수익을 크게 해치지 않으면서도 훨씬 낮은 분산을 보여줬어요. 치명적 손실도 훨씬 적었어요. 분산투자는 공짜에 가까운 위험 감소예요."),
            entry("Look at the worst outcomes for each strategy across all 20 simulations.", "20번 시뮬레이션 전체에서 각 전략의 최악의 결과를 보세요."),
            entry("MegaCorp Goes Bankrupt", "메가코프 파산"),
            entry(
                """
                MegaCorp has delivered 20% returns for 5 years straight.
                Investors are piling in. The future looks bright.
                Option A: All In on MegaCorp
                Option B: Diversified Fund (MegaCorp is 5% of the fund)
                What could go wrong?
                """,
                """
                메가코프는 5년 연속 20% 수익을 냈어요.
                투자자들이 몰려들고 있고 미래도 밝아 보여요.
                선택지 A: 메가코프에 올인
                선택지 B: 분산 펀드 (메가코프 비중은 펀드의 5%)
                무엇이 잘못될 수 있을까요?
                """
            ),
            entry("MegaCorp went bankrupt. The concentrated portfolio lost everything. The diversified fund lost only 15% — MegaCorp was just 5% of its holdings. The fund survived. The concentrated bet did not.", "메가코프는 파산했어요. 집중 포트폴리오는 모든 것을 잃었어요. 하지만 분산 펀드는 15%만 잃었어요. 메가코프 비중이 전체 보유의 5%에 불과했기 때문이에요. 펀드는 살아남았고, 집중 베팅은 살아남지 못했어요."),
            entry("Even the best-performing companies can fail completely. What protects you when they do?", "아무리 잘나가는 기업도 완전히 실패할 수 있어요. 그럴 때 당신을 지켜주는 것은 무엇인가요?"),
            entry("The Correlation Trap", "상관관계의 함정"),
            entry(
                """
                You own 5 different tech stocks. That's diversified, right?
                Option A: 5 Tech Stocks (different companies, same sector)
                Option B: Stocks + Bonds + Real Estate (different asset classes)
                A sector-wide crash is coming. Which portfolio is truly protected?
                """,
                """
                당신은 서로 다른 기술주 5개를 가지고 있어요. 이게 분산투자일까요?
                선택지 A: 기술주 5개 (다른 기업이지만 같은 업종)
                선택지 B: 주식 + 채권 + 부동산 (다른 자산군)
                업종 전체의 폭락이 다가오고 있어요.
                진짜로 보호받는 포트폴리오는 무엇일까요?
                """
            ),
            entry("5 tech stocks are correlated — they crash together. Real diversification requires different asset classes that don't move in lockstep. When the tech sector fell 50%, bonds and real estate held steady.", "기술주 5개는 서로 높은 상관관계를 가지므로 함께 폭락해요. 진짜 분산투자에는 같은 방향으로만 움직이지 않는 서로 다른 자산군이 필요해요. 기술 업종이 50% 하락했을 때 채권과 부동산은 비교적 버텼어요."),
            entry("Do all 5 stocks move in the same direction when tech news hits? That tells you how correlated they are.", "기술 업종 뉴스가 나올 때 5개 종목이 모두 같은 방향으로 움직이나요? 그것이 상관관계의 수준을 보여줘요."),
            entry(
                """
                Your brain is not wired for investing. Four biases systematically distort your decisions:

                Anchoring: You fixate on an irrelevant reference price (e.g. "it was ₩500M, so ₩200M feels cheap") \
                even when it no longer reflects current value.

                Loss Aversion: Losses feel 2–3× more painful than equivalent gains feel good. \
                This makes you hold losers too long and cut winners too early.

                Herd Behavior: You follow the crowd — buying when everyone buys, selling when everyone panics — \
                because social proof feels safer than independent analysis.

                Recency Bias: You over-weight recent events. A recent crash makes you too cautious; \
                a recent boom makes you too optimistic.

                Recognising these biases is the first step to overriding them.
                """,
                """
                당신의 뇌는 투자를 위해 설계되어 있지 않아요.
                네 가지 편향이 당신의 결정을 체계적으로 왜곡해요.

                앵커링: 현재 가치와 무관해졌는데도
                '예전엔 5억이었으니 지금 2억이면 싸다' 같은 기준가격에 집착해요.

                손실 회피: 손실은 같은 크기의 이익보다 2~3배 더 크게 아프게 느껴져요.
                그래서 손실 자산은 너무 오래 들고, 수익 자산은 너무 빨리 팔아요.

                군중 추종: 독자적 분석보다 사회적 증거가 더 안전하게 느껴져
                모두가 살 때 사고, 모두가 공포에 팔 때 같이 파는 경향이 생겨요.

                최신 편향: 최근 사건에 지나치게 큰 비중을 둬요.
                최근 폭락은 지나친 조심으로, 최근 급등은 과한 낙관으로 이어져요.

                이 편향들을 알아차리는 것이 그것을 넘어서기 위한 첫걸음이에요.
                """
            ),
            entry("Flash Sale!", "긴급 세일!"),
            entry(
                """
                ⚡ LIMITED TIME OFFER ⚡
                You have 5 seconds to decide.
                MegaStock is up 40% today. Everyone is buying.
                The countdown has started. ACT NOW or miss out!

                (Note: Rushed decisions under pressure are rarely optimal.)
                """,
                """
                ⚡ 한정 시간 제안 ⚡
                결정할 시간은 5초뿐이에요.
                메가스톡은 오늘 40% 올랐고 모두가 사들이고 있어요.
                카운트다운이 시작됐어요. 지금 행동하지 않으면 기회를 놓쳐요!

                (참고: 압박 속에서 서두른 결정은 대개 최적이 아니에요.)
                """
            ),
            entry("Time pressure induces recency bias and herd thinking. The 5-second timer made 'Buy Now' feel urgent — but the asset crashed shortly after. Research beats reaction.", "시간 압박은 최신 편향과 군중 심리를 자극해요. 5초 타이머는 '지금 매수'를 매우 급하게 느끼게 했지만, 그 자산은 곧 폭락했어요. 반응보다 조사가 나아요."),
            entry("Urgency is a sales tactic. What do you actually know about this asset?", "조급함은 판매 기법이에요. 당신은 이 자산에 대해 실제로 무엇을 알고 있나요?"),
            entry("The Leaderboard", "리더보드"),
            entry(
                """
                🏆 Today's Leaderboard:
                #1: CryptoMoon — up 312% this month! Others are getting rich.
                #2: TechRocket — up 180% this month! "Hot tip from insiders"
                #3: Boring Index Fund — up 0.8% this month

                Everyone around you is buying CryptoMoon. Are you missing out?
                """,
                """
                🏆 오늘의 리더보드:
                #1: 크립토문 - 이번 달 312% 상승! 다른 사람들은 돈을 벌고 있어요.
                #2: 테크로켓 - 이번 달 180% 상승! "내부자 핫팁"
                #3: 심심한 인덱스 펀드 - 이번 달 0.8% 상승

                주변 사람들은 모두 크립토문을 사고 있어요.
                당신만 기회를 놓치고 있는 걸까요?
                """
            ),
            entry("CryptoMoon was already past its peak when it hit the leaderboard. The leaderboard shows past winners — you're always buying yesterday's news. FOMO is expensive.", "크립토문은 리더보드에 올랐을 때 이미 정점을 지난 뒤였어요. 리더보드는 과거의 승자만 보여줘요. 당신은 늘 어제의 뉴스를 사게 돼요. 포모는 비싸요."),
            entry("Leaderboards show past returns. Past returns don't predict future returns.", "리더보드는 과거 수익률을 보여줄 뿐이에요. 과거 수익률은 미래 수익률을 예측하지 못해요."),
            entry("The Anchored Mind", "앵커링된 마음"),
            entry(
                """
                Seoul Property Fund peaked at ₩500M per unit 2 years ago.
                After a market correction, it now trades at ₩200M.

                New analysis shows:
                • Revenue: ₩15M/year
                • Costs: ₩12M/year
                • Profit: ₩3M/year
                • Intrinsic value (10× profit): ₩30M

                "It was ₩500M — at ₩200M it must be a bargain!"
                Is it?
                """,
                """
                서울 부동산 펀드는 2년 전 주당 5억 원까지 올랐어요.
                시장 조정 이후 지금은 2억 원에 거래돼요.

                새로운 분석 결과는 다음과 같아요.
                • 매출: 연 1천5백만 원
                • 비용: 연 1천2백만 원
                • 이익: 연 3백만 원
                • 내재가치 (이익의 10배): 3천만 원

                "예전에 5억이었는데 지금 2억이면 엄청 싼 거 아냐?"
                정말 그럴까요?
                """
            ),
            entry("₩200M feels cheap vs ₩500M — but intrinsic value is only ₩30M. The ₩500M peak was never justified. Anchoring to an irrelevant past price is a cognitive trap.", "2억 원은 5억 원과 비교하면 싸 보이지만, 내재가치는 고작 3천만 원이에요. 5억 원의 고점은 애초에 정당화된 적이 없어요. 무관한 과거 가격에 매달리는 것은 인지적 함정이에요."),
            entry("Ignore the historical peak. Calculate intrinsic value. Compare to current price.", "과거의 최고가는 무시하세요. 내재가치를 계산하고 현재 가격과 비교하세요."),
            entry("Your Behavioral Profile", "당신의 행동 프로필"),
            entry(
                """
                Based on your decisions across Phases 1–6, we identified patterns:

                📌 [Anchoring Detected] — You bought assets trading above intrinsic value.
                📌 [Loss Aversion Detected] — You held losing positions longer than winners.
                📌 [Herd Behavior Detected] — Your decisions correlated with sentiment indicators.
                📌 [Recency Bias Detected] — You over-weighted recent price movements.

                This is not a failure. These are universal human patterns.
                The review overlay shows where emotions overrode logic.
                Are you ready to see your complete behavioral profile?
                """,
                """
                페이즈 1~6에서 당신이 내린 결정을 바탕으로 다음과 같은 패턴을 확인했어요.

                📌 [앵커링 감지] - 내재가치보다 비싸게 거래되는 자산을 매수했어요.
                📌 [손실 회피 감지] - 수익 자산보다 손실 자산을 더 오래 보유했어요.
                📌 [군중 추종 감지] - 당신의 결정이 심리 지표와 함께 움직였어요.
                📌 [최신 편향 감지] - 최근 가격 움직임에 지나치게 큰 비중을 두었어요.

                이것은 실패가 아니에요. 누구에게나 나타나는 인간적 패턴이에요.
                리뷰 오버레이는 감정이 논리를 덮어쓴 지점을 보여줘요.
                당신의 전체 행동 프로필을 볼 준비가 되었나요?
                """
            ),
            entry("Anchoring, loss aversion, herd behavior, recency bias — these four patterns appeared in your gameplay. Recognising them is the most valuable skill you can build as an investor.", "앵커링, 손실 회피, 군중 추종, 최신 편향. 이 네 가지 패턴이 당신의 플레이에 나타났어요. 이것을 알아차리는 능력은 투자자로서 기를 수 있는 가장 값진 기술이에요."),
            entry("Reviewing your mistakes is how you improve.", "실수를 복기하는 것이 성장의 시작이에요.")
        ])
    }()
}

extension String {
    var ko: String {
        KoreanLocalization.translate(self)
    }
}
