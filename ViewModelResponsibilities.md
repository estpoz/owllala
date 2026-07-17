# OwlLala ViewModel Responsibilities

## Purpose

This document defines ViewModel ownership and data flow for the OwlLala MVP.

Use it together with:

- `AGENTS.md`
- `Docs/DataModelsAndBusinessRules.md`

Do not modify the documented responsibilities without confirmation.

## Shared Data Flow

Static application content:

```text
Story
└── Chapter
    ├── StoryPage
    ├── GameConfiguration
    │   └── GameQuestion
    │       └── AnswerOption
    └── LearningSummary
```

Persisted user state:

```text
StorageService
├── UserStats
│   └── [GameStats]
└── Settings
```

Views must not directly decode, encode, or write persisted data.

## Shared Storage

`StorageService` is responsible for:

- Loading and saving `UserStats`.
- Loading and saving `Settings`.
- Returning safe initial values.
- Centralizing `UserDefaults` keys.
- Publishing or otherwise exposing the current persisted values to the application composition layer.

The exact storage API should remain small.

A suitable direction is:

```swift
final class StorageService: ObservableObject {
    @Published private(set) var userStats: UserStats
    @Published private(set) var settings: Settings

    func updateUserStats(_ update: (inout UserStats) -> Void)
    func updateSettings(_ settings: Settings)
}
```

Codex must inspect the project before deciding the final API. It may adjust this shape when needed, but there must remain one shared persistence owner.

## MainMenuViewModel

### Inputs

- Shared application state only when required to derive menu availability.

### Outputs

- Main-menu destinations or actions.

### Exclusions

- No chapter progression logic.
- No gameplay logic.
- No statistics calculation.
- No settings draft management.

## StorySelectionViewModel

### Inputs

- `[Story]`

### Outputs

- Story cards in their existing order.
- Availability state.
- Selected available story.

### Selection Rule

```text
.available   → allow navigation
.comingSoon  → remain on selection screen
```

## ChapterSelectionViewModel

### Inputs

- Selected `Story`
- Shared `UserStats`

### Chapter Presentation State

Each chapter row or card needs:

```swift
struct ChapterSelectionItem: Identifiable, Hashable {
    let chapter: Chapter
    let isUnlocked: Bool
    let isCompleted: Bool
    let bestStars: Int

    var id: String { chapter.id }
}
```

This may be nested inside the ViewModel or declared as a lightweight presentation model in the ViewModels folder.

### Selection Rule

```text
Unlocked chapter → allow gameplay
Locked chapter   → do not navigate
```

## ChapterGameplayViewModel

### Inputs

- `Chapter`
- `GameplaySource`
- Optional next chapter ID for Main Story progression.
- Shared `StorageService`.

### Suggested State

The final names may follow current repository conventions.

```swift
@Published private(set) var currentStoryPageIndex: Int
@Published private(set) var selectedAnswerID: String?
@Published private(set) var incorrectAnswerID: String?
@Published private(set) var wrongAnswerCount: Int
@Published private(set) var shakeTrigger: Int
@Published private(set) var isHintPresented: Bool
@Published private(set) var isCorrectFeedbackPresented: Bool
@Published private(set) var earnedStars: Int?
@Published private(set) var destination: Destination?
```

### Story Navigation

Main Story:

```text
Story page 1
→ next page
→ final story page
→ question
```

Training Mode:

```text
Question immediately
```

The array order in `chapter.storyPages` is authoritative.

### Incorrect Answer

For every incorrect tap:

1. Increment `wrongAnswerCount`.
2. Store the incorrect option identifier.
3. Increment or change a shake trigger.
4. Keep the child on the same question.
5. Present the hint only when the wrong-answer count first reaches two.

The same option may be selected repeatedly.

### Correct Answer

1. Calculate stars.
2. Mark correct-feedback state as active.
3. Do not navigate immediately.
4. Let the View play confetti and applause.
5. The View waits three seconds.
6. The View calls a completion method on the ViewModel.
7. The ViewModel records the completed result and emits the next destination.

### Star Calculation

Keep as a private function in `ChapterGameplayViewModel`:

```swift
private func calculateStars(wrongAnswerCount: Int) -> Int {
    switch wrongAnswerCount {
    case 0:
        return 3
    case 1:
        return 2
    default:
        return 1
    }
}
```

### Completion Destination

Main Story:

```text
Correct feedback
→ chapter Stage Cleared
```

After Chapter 5 Stage Cleared finishes:

```text
Story Completion Summary
→ Story Selection
```

Training Mode:

```text
Correct feedback
→ chapter Stage Cleared
→ Training Mode list
```

The story completion summary must never appear from Training Mode.

### Abandonment

Exiting before the correct answer:

- Must not create `GameStats`.
- Must not increment `playCount`.
- Must not unlock another chapter.
- Must not modify best stars.

## TrainingModeViewModel

### Inputs

- Available story.
- Shared `UserStats`.

### Output State

Before story completion:

- All five mini-game cards are visible.
- All five cards are locked.

After story completion:

- All five cards become available simultaneously.

### Gameplay Launch

Launch:

```swift
ChapterGameplayViewModel(
    chapter: chapter,
    source: .training,
    ...
)
```

Do not duplicate chapter question data.

## StatisticsViewModel

### Inputs

- Story content.
- Shared `UserStats`.

### Summary Values

```text
totalStars
completedChapterCount
completedStoryCount
```

### Competency Presentation

Each chapter maps to exactly one competency.

```swift
struct CompetencyProgressItem: Identifiable, Hashable {
    let competency: Competency
    let score: Int
    let maximumScore: Int
    let chapterID: String

    var id: Competency { competency }
}
```

Maximum competency score is five.

### Static Guidance

Long-form content such as:

- Learning summary.
- Mastered abilities.
- Areas to practice.
- Parent tip.

must live in a static content type, for example:

```swift
struct CompetencyGuidance {
    let competency: Competency
    let learningSummary: String
    let masteredItems: [String]
    let practiceItems: [String]
    let parentTip: String
}
```

This content is not persisted.

## SettingsViewModel

### Inputs

- Shared `StorageService`.

### State

```swift
@Published private(set) var savedSettings: Settings
@Published var draftSettings: Settings
```

The final visibility may be tightened after inspecting View bindings.

### Begin Editing

Copy saved settings into the draft.

### Save

- Normalize brightness using the `Settings` API.
- Persist the draft through `StorageService`.
- Update saved settings.
- Close the Settings presentation.

### Cancel

- Restore the draft from saved settings.
- Close without persisting.

### Shared Use

The Main Settings screen and gameplay overlay use the same persisted settings source.

Each presentation may begin a new draft-editing session, but both must save to the same `StorageService`.

## Navigation

Follow the existing button-driven navigation.

Permitted ViewModel output:

```swift
enum Destination: Hashable {
    case gameplay
    case stageCleared
    case storyCompletion
}
```

Do not add a global coordinator for this MVP.

