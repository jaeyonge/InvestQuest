# InvestQuest

InvestQuest is an iOS learning game that teaches core investing principles through stage-based simulations.

## Repository Layout

- `InvestQuest/`: Main Swift project.
- `InvestQuest/Sources/`: App source code.
- `InvestQuest/Tests/`: Unit and UI tests.
- `InvestQuest/docs/analysis/`: Architecture, quality, testing, and performance analysis documents.
- `InvestQuest_PRD_TierA.docx`: Product requirements document.
- `learnings.md`: Append-only execution learnings log.

## Tech Stack

- Swift 5+
- SwiftUI
- SwiftData
- Xcode 15+
- iOS 17+

## Getting Started

1. Open the project in Xcode:
   - `InvestQuest/InvestQuest.xcodeproj`
2. Select the `InvestQuest` scheme.
3. Run on an iOS 17+ simulator (for example, iPhone 15).

## Build and Test

From the repository root:

```bash
cd InvestQuest
xcodebuild build -scheme InvestQuest -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' 2>&1
xcodebuild test -scheme InvestQuest -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -resultBundlePath TestResults 2>&1
```

Optional lint:

```bash
cd InvestQuest
swiftlint lint --strict 2>&1
```

## Notes

- The project is offline-first; gameplay logic runs on-device.
- Progression and stage outcomes are persisted locally.