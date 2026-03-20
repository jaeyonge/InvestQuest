# Build And Developer Experience Review

## Build System Overview

Fact:

- `project.yml` defines the project, indicating XcodeGen-style project generation.
- `InvestQuest.xcodeproj` is also checked into the repository.
- `xcodebuild -list -project InvestQuest.xcodeproj` shows one scheme:
  - `InvestQuest`
- Build configurations:
  - `Debug`
  - `Release`

## Targets

- `InvestQuest`
- `InvestQuestTests`
- `InvestQuestUITests`

The build graph is simple and easy to understand.

## Dependencies

- No Swift Package Manager dependencies
- No CocoaPods
- No Carthage
- Apple frameworks only

This is a strong point for build reproducibility.

## What Worked During Audit

Verified during this audit:

- `xcodebuild test -scheme InvestQuest -project InvestQuest.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'`
- Full scheme test run succeeded

XCResult path from the run:

- `/Users/jason/Library/Developer/Xcode/DerivedData/InvestQuest-ahswgkzicogulufoxynncectbllk/Logs/Test/Test-InvestQuest-2026.03.17_00-01-08-+0900.xcresult`

## Strengths

- Very low dependency complexity
- Straightforward target graph
- Fast unit-test cycle
- UI tests are already wired into the shared scheme

## Build And DX Weaknesses

### 1. Generated Project Drift Risk

Because both `project.yml` and `InvestQuest.xcodeproj` are present, the repo can drift unless regeneration is enforced in CI or developer workflow.

### 2. No CI Configuration Found

Repo scan found no:

- `.github/workflows`
- `fastlane`
- `Dangerfile`
- other CI automation

Impact:

- No automated guarantee that the checked-in Xcode project matches `project.yml`
- No automatic test gate for pull requests

### 3. No Shared Build Settings Layer

Repo scan found no `.xcconfig` files.

Impact:

- Build settings live inline in the project definition
- Environment-specific configuration will get harder as the app grows

### 4. Signing And Release Readiness Are Minimal

From `project.yml`:

- `DEVELOPMENT_TEAM` is blank
- `CODE_SIGN_STYLE` is automatic

Assessment:

- Fine for local development
- weak for production release hygiene

### 5. Versioning And Resource Setup Are Minimal

From `Info.plist`:

- version is hard-coded to `1.0`
- build number is hard-coded to `1`

Repo scan also found no `.xcassets` or localization resource files, despite `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` being set in `project.yml`.

Inference:

- Release packaging and branding resources are either incomplete or managed outside the repository.

### 6. No Lint/Format Tooling

Repo scan found no:

- `swiftlint`
- `swiftformat`
- formatting scripts

Impact:

- Style is currently maintained by discipline rather than tooling

## Scheme And Test Configuration

Observed in `InvestQuest.xcscheme`:

- App, unit tests, and UI tests are all part of the shared scheme
- Test action includes `-AppleLanguages (en)`
- Parallelization is not enabled for testables

Assessment:

- Reasonable default
- Could be improved with CI coverage publishing and parallel UI/unit job splitting

## Recommended Improvements

- Add CI to run `xcodebuild test` on every pull request.
- Add a regeneration check so `project.yml` and `InvestQuest.xcodeproj` cannot drift silently.
- Introduce `.xcconfig` files before environment-specific settings appear.
- Add shared lint/format tooling.
- Formalize versioning and signing configuration.
- Add a clear source-controlled assets/localization strategy if this is moving beyond prototype status.

## DX Assessment

Developer experience is good for a solo or small-team local workflow. It is not yet mature enough for multi-developer release management, automated validation, or safe scaling of build configuration.
