# Testing — OwlLala

This document describes how OwlLala is tested: the tooling, conventions,
coverage areas, and team responsibilities.

## 1. Test target & tooling

- **Target:** `OwlLalaTests` (unit tests), part of the `OwlLala.xcodeproj` project.
- **Framework:** [Swift Testing](https://developer.apple.com/documentation/testing)
  (`@Suite` / `@Test` / `#expect`), the modern replacement for XCTest.
- **Approach:** Test-Driven Development (TDD), following the scenarios in
  [`TDD.md`](TDD.md).
- **What is tested:** ViewModels, model rules, persistence, Settings migration,
  display mappings, color-filter matrices, and pure control calculations.
  Tests import the real production module with `@testable import OwlLala`.
- **Latest verified result:** 127 passed, 0 failed, and 0 skipped on an iPad Pro
  11-inch (M5) simulator running iOS 26.5.

## 2. Naming & folder conventions

- Test code lives in the `OwlLalaTests/` group, mirroring Xcode's default
  test-target layout.
- General smoke coverage remains in `OwlLalaTests.swift`.
- Feature-focused suites use dedicated files, including
  `SettingsTests.swift`, `ChapterGamePlayVMTests.swift`,
  `ChapterSelectionTests.swift`, `StatisticsViewModelTests.swift`,
  `StorySelectionTests.swift`, and `TrainingModeTests.swift`.
- Suites are named after the type under test (e.g. `@Suite("SettingsViewModel")`).
- Test functions are descriptive, behavior-oriented sentences in camelCase
  (e.g. `selectingCorrectAnswerOnFirstTryEarnsThreeStars()`).
- Test names and suite grouping must make the Given–When–Then behavior clear.

> Note: `OwlLalaTests/UnitTesting.swift` is an older, fully commented-out
> scratch file kept for reference. It contains no active tests.

## 3. How to run the tests locally (Xcode)

1. Open `OwlLala.xcodeproj` in Xcode.
2. Choose an installed iPad Pro 11-inch simulator.
3. **Product ▸ Test** (⌘U). Results appear in the Test navigator (⌘6).

Discover available destinations before running from the command line:

```bash
xcodebuild \
  -project OwlLala.xcodeproj \
  -scheme OwlLala \
  -showdestinations
```

Latest verified command:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -quiet \
  -project /Users/stanleyyoung/Documents/ADA/CVDApp/OwlLala.xcodeproj \
  -scheme OwlLala \
  -destination 'platform=iOS Simulator,id=68CCA33A-7EBF-406D-BFEE-970F409AFD74' \
  -derivedDataPath /private/tmp/CVDAppSettingsSplitTests \
  -resultBundlePath /private/tmp/CVDAppSettingsSplitTests.xcresult \
  -only-testing:OwlLalaTests \
  test
```

Storage tests use a unique, empty `UserDefaults` suite
(`UserDefaults(suiteName: UUID().uuidString)`). They never touch the app's real
saved data or another test's data.

## 4. Coverage areas (organized by module)

The latest full target execution contains **127 tests across 23 suites**.

| Suite / module | Behavior covered |
| --- | --- |
| `ChapterGameplayViewModel` | Story-page navigation reveals the question; correct-first-try scoring (3★); retry scoring after a wrong answer (2★); completing a Main Story chapter saves progress and unlocks the next chapter. |
| `ChapterSelectionViewModel` | Chapter items reflect unlock/completion/best-stars; only unlocked chapters are selectable; next-chapter lookup. |
| `TrainingModeViewModel` | Training unlocks only after the whole story is completed; the gameplay it produces uses the training source. |
| `StorySelectionViewModel` | Only available stories can be selected; "coming soon" is ignored. |
| `MainMenuViewModel` | Selecting and clearing a menu destination. |
| Settings model and Codable | Defaults, brightness normalization, all filters, all 12 text sizes, current payloads, malformed payloads, and legacy migration. |
| Settings persistence | Default loading, update, reload, reset, normalization, isolated storage, and independence from `UserStats`. |
| `SettingsViewModel` | Editing lifecycle, live preview, brightness, text sizes, filter behavior, save/cancel, external updates, and multiple shared ViewModels. |
| Settings display logic | Exact Dynamic Type mapping, color matrices, slider clamping, step snapping, touch geometry, and VoiceOver percentages. |
| `StatisticsViewModel` | Summary values (total stars, completed count, competency items) reflect recorded progress. |

`OwlLalaTests/SettingsTests.swift` contains 82 Settings-focused test functions
across 13 suites. See
[`SETTINGS_AND_ACCESSIBILITY.md`](SETTINGS_AND_ACCESSIBILITY.md) for the
complete Settings test matrix.

### Expected coverage going forward

- **New view-model function → new/updated test** in its suite (TDD: write the
  test first).
- Model and service business rules should receive direct tests when they
  contain normalization, migration, persistence, or progression logic.
- **UI flows** are out of scope for the unit target and belong in
  `OwlLalaUITests`.
- Metal pixel output and final visual layout require manual or dedicated
  rendering/snapshot validation; unit tests verify the matrices and state.

## 5. Testing responsibilities

| Area | Owner |
| --- | --- |
| Gameplay & progression view models (`ChapterGameplay`, `ChapterSelection`, `TrainingMode`) | _<assign team member>_ |
| Menu, settings & statistics view models (`MainMenu`, `Settings`, `Statistics`, `StorySelection`) | _<assign team member>_ |
| Keeping `TDD.md` scenarios and this document in sync | _<assign team member>_ |
| Running the suite before each merge to `main` | Whole team |

_(Fill in the owner names for your team.)_

## 6. Reading failed tests

Swift Testing prints a clear, self-contained failure. A failing `#expect`
reports the source location, the expression that failed, and the actual values,
for example:

```
✘ Test "saveCommitsEveryDraftFieldAndEndsEditing()" recorded an issue at
  SettingsTests.swift:700:9: Expectation failed:
  (storage.settings.backgroundBrightness → 1.0) == (0.8)
```

Because storage-backed tests build isolated stores and focused inputs, a
failure points at one behavior and can be reproduced without touching the
application's persisted data.
