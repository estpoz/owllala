# Testing — OwlLala

This document describes how OwlLala is tested: the tooling, conventions,
coverage areas, and team responsibilities.

## 1. Test target & tooling

- **Target:** `OwlLalaTests` (unit tests), part of the `OwlLala.xcodeproj` project.
- **Framework:** [Swift Testing](https://developer.apple.com/documentation/testing)
  (`@Suite` / `@Test` / `#expect`), the modern replacement for XCTest.
- **Approach:** Test-Driven Development (TDD), following the scenarios in
  [`TDD.md`](TDD.md).
- **What is tested:** the **view-model layer** (`OwlLala/OwlLala/ViewModels/`).
  Tests instantiate the real production view models via
  `@testable import OwlLala`, call their functions the way the UI would, and
  assert on the resulting published state. The SwiftUI views are intentionally
  thin, so verifying the view models verifies the app's behavior.

## 2. Naming & folder conventions

- Test code lives in the `OwlLalaTests/` group, mirroring Xcode's default
  test-target layout.
- The suite file is named after the target: `OwlLalaTests.swift`.
- Suites are named after the type under test (e.g. `@Suite("SettingsViewModel")`).
- Test functions are descriptive, behavior-oriented sentences in camelCase
  (e.g. `selectingCorrectAnswerOnFirstTryEarnsThreeStars()`).
- Each test is documented with a Given–When–Then doc comment.

> Note: `OwlLalaTests/UnitTesting.swift` is an older, fully commented-out
> scratch file kept for reference. It contains no active tests.

## 3. How to run the tests locally (Xcode)

1. Open `OwlLala.xcodeproj` in Xcode.
2. Choose any iOS Simulator (e.g. **iPhone 17**) as the run destination.
3. **Product ▸ Test** (⌘U). Results appear in the Test navigator (⌘6).

Command line (CI or terminal):

```bash
xcodebuild test \
  -project OwlLala.xcodeproj \
  -scheme OwlLala \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:OwlLalaTests
```

Every test uses its own isolated, empty `UserDefaults` suite
(`UserDefaults(suiteName: UUID().uuidString)`), so runs are deterministic and
never touch shared app data or each other.

## 4. Coverage areas (organized by module)

One suite per view model. Current coverage — **14 tests across 7 suites**:

| Suite / module | Behavior covered |
| --- | --- |
| `ChapterGameplayViewModel` | Story-page navigation reveals the question; correct-first-try scoring (3★); retry scoring after a wrong answer (2★); completing a Main Story chapter saves progress and unlocks the next chapter. |
| `ChapterSelectionViewModel` | Chapter items reflect unlock/completion/best-stars; only unlocked chapters are selectable; next-chapter lookup. |
| `TrainingModeViewModel` | Training unlocks only after the whole story is completed; the gameplay it produces uses the training source. |
| `StorySelectionViewModel` | Only available stories can be selected; "coming soon" is ignored. |
| `MainMenuViewModel` | Selecting and clearing a menu destination. |
| `SettingsViewModel` | Save commits the draft (brightness + color filter) to storage; cancel discards it. |
| `StatisticsViewModel` | Summary values (total stars, completed count, competency items) reflect recorded progress. |

### Expected coverage going forward

- **New view-model function → new/updated test** in its suite (TDD: write the
  test first).
- **Models** (`GameStats`, `UserStats`, `Settings`, …) and **Services**
  (`StorageService`) are currently covered indirectly through the view models;
  add dedicated model/service suites if their logic grows.
- **UI flows** are out of scope for the unit target and belong in
  `OwlLalaUITests`.

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
✘ Test "saveCommitsDraftToStorageAndEndsEditing()" recorded an issue at
  OwlLalaTests.swift:262:9: Expectation failed:
  (storage.settings.backgroundBrightness → 1.0) == (0.8)
```

Because each test builds its own isolated store and inputs, a failure points at
exactly one behavior, and re-running reproduces it deterministically.
