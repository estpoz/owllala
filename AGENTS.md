# OwlLala Engineering Instructions

## Project Overview

OwlLala is an iPadOS learning application for children with partial color vision deficiency. The application teaches children to identify objects using non-color visual cues.

The MVP contains:

- One playable story.
- Five chapters in the playable story.
- One mini-game per chapter.
- One tap-to-select question per mini-game.
- Main Story, Training Mode, Statistics, and Settings.
- Two additional story cards shown as locked `comingSoon` placeholders.

Read `Docs/DataModelsAndBusinessRules.md` before modifying model, storage, progression, gameplay, statistics, or settings logic.

Read `Docs/ViewModelResponsibilities.md` before modifying ViewModels or their bindings to Views.

## General Working Rules

- Inspect existing code before proposing changes.
- Preserve the existing project structure unless the task explicitly requests structural changes.
- Do not invent requirements that are not present in the repository documentation.
- Ask for confirmation before changing a documented business rule.
- Prefer the smallest implementation that fully satisfies the documented MVP.
- Do not create speculative abstractions for future features.
- Do not add third-party dependencies.
- Do not introduce SwiftData.
- Do not increase the deployment target unless explicitly requested.
- Use Foundation and native SwiftUI APIs only.
- Use English for code identifiers and developer documentation.
- Keep user-facing text in Indonesian.
- Do not rewrite unrelated files.
- Do not modify assets or design values unless explicitly requested.
- Do not create tests unless the task explicitly requests them.

## Architecture

Use the existing MVVM structure:

- Models contain static content or persisted data.
- ViewModels own presentation state and application actions.
- Views render state and forward user actions.
- Components contain reusable SwiftUI UI.
- `StorageService` is the single persistence source for `UserStats` and `Settings`.

ViewModels must not access `UserDefaults.standard` directly.

Use:

```swift
ObservableObject
@Published
```

for ViewModels to support the lowest practical iPadOS deployment target.

Do not migrate the project to the Observation framework unless explicitly requested.

## Persistence

Persist only mutable user data:

- `UserStats`
- `GameStats` as part of `UserStats`
- `Settings`

Do not persist static content:

- `Story`
- `Chapter`
- `StoryPage`
- questions
- answer options
- hints
- learning summaries

`StorageService` must:

- Be the only type that reads from or writes to `UserDefaults`.
- Expose typed loading and saving for `UserStats` and `Settings`.
- Use `Codable` encoding.
- Provide safe default values when no saved data exists.
- Avoid force unwraps.
- Avoid silently discarding decoding errors during development.
- Keep storage keys centralized.

## ViewModel Responsibilities

### MainMenuViewModel

Own only presentation logic for the Main Menu.

It may expose menu destinations for:

- Main Story
- Training Mode
- Statistics
- Settings

It must not duplicate story, chapter, progress, or settings data.

### StorySelectionViewModel

Own story-selection presentation logic.

It must:

- Expose stories in their existing array order.
- Distinguish `.available` and `.comingSoon` stories.
- Allow selection only for available stories.
- Prevent navigation into coming-soon stories.
- Avoid duplicating story availability in persisted user data.

### ChapterSelectionViewModel

Own chapter-selection presentation logic for one selected `Story`.

It must expose for each chapter:

- Chapter content.
- Unlocked state.
- Completed state.
- Best stars.

It must use `UserStats` as the source of progress.

The order of `story.chapters` is authoritative. Do not sort it again.

### ChapterGameplayViewModel

Own gameplay state for one chapter.

It must support both:

- Main Story
- Training Mode

Main Story shows story pages before gameplay. Training Mode skips story pages.

The ViewModel must manage:

- Current story-page index.
- Story-page navigation.
- Question state.
- Selected answer.
- Incorrect-answer count.
- The answer currently receiving incorrect feedback.
- A shake trigger value or equivalent presentation signal.
- Hint visibility after the second incorrect attempt.
- Correct-answer completion state.
- Earned stars.
- Saving completed game results.
- Main Story chapter progression.
- Destination after successful completion.

The ViewModel must not create SwiftUI animations directly.

The View handles:

- Red outline rendering.
- Shake animation.
- Confetti animation.
- Applause playback.
- The three-second correct-feedback presentation.

After the View finishes the three-second feedback, it calls back into the ViewModel to continue navigation.

Star calculation belongs in `ChapterGameplayViewModel`.

Star rules:

- Zero wrong attempts: three stars.
- One wrong attempt: two stars.
- Two or more wrong attempts: one star.
- Abandoned gameplay: no result is saved.

The same incorrect answer may be selected repeatedly, and every incorrect tap counts as another wrong attempt.

The hint appears once, after the second incorrect attempt.

A correct answer is required before completion.

### TrainingModeViewModel

Own Training Mode chapter-list presentation.

It must:

- Show all five chapter mini-games.
- Keep all mini-games locked until the entire story is completed.
- Unlock all five mini-games together after the story is completed.
- Launch the same gameplay content used by Main Story.
- Start gameplay without story pages.
- Update the same `GameStats` records as Main Story.
- Never modify chapter unlock progression.
- Never present the story completion summary.

### StatisticsViewModel

Transform `UserStats` and static chapter content into presentation data.

It must expose:

- Total collected stars.
- Completed chapter count.
- Completed story count.
- One competency score per chapter.
- Data suitable for the competency chart and competency rows.

Competency mapping:

- No completed game: 0/3.
- Best one star: 1/3.
- Best two stars: 2/3.
- Best three stars: 3/3.

Static competency guidance content must not be stored in `UserStats`.

Place static statistics guidance in a dedicated static content type rather than hard-coding long text inside SwiftUI views.

### SettingsViewModel

Use one shared persisted settings source for both:

- Main Settings screen.
- Gameplay Settings overlay.

It must support draft editing:

- Begin editing from saved settings.
- Modify draft brightness.
- Enable a simulation.
- Disable simulation.
- Save the draft.
- Cancel and discard the draft.

Closing without saving must not persist changes.

## Navigation

Preserve the navigation approach already used by the project.

Views may navigate using button actions and local destination state.

ViewModels may expose small destination enums or presentation flags, but do not introduce a coordinator, router framework, or `NavigationPath` architecture unless the existing project already uses one.

Before modifying navigation, inspect the current views and follow their existing pattern.

## Gameplay Source

Use a clear source enum where needed, for example:

```swift
enum GameplaySource: Hashable, Sendable {
    case mainStory
    case training
}
```

Do not create separate chapter gameplay ViewModels or gameplay views for each chapter.

## Storage Ownership

`StorageService` is the shared source of persisted state.

ViewModels should receive required dependencies through initializers.

Prefer dependency injection such as:

```swift
init(
    storageService: StorageService,
    story: Story
)
```

Do not create independent `StorageService` instances inside every action.

Do not access global mutable singletons unless the existing application composition explicitly owns one shared instance.

## Code Quality

- Use `private(set)` for externally readable state that should only be mutated by the ViewModel.
- Keep methods focused and clearly named.
- Avoid force unwraps and force casts.
- Avoid `fatalError` for normal application states.
- Avoid unnecessary protocols until there is a concrete need.
- Avoid generic repositories.
- Add concise English documentation to public or non-obvious types and methods.
- Do not over-document obvious stored properties.
- Keep UI-specific types out of models.
- Keep SwiftUI animation implementation out of ViewModels.

## Build Validation

Before implementation, discover the available project configuration:

```bash
xcodebuild -list -project OwlLala.xcodeproj
```

Discover installed simulator destinations:

```bash
xcodebuild \
  -project OwlLala.xcodeproj \
  -scheme OwlLala \
  -showdestinations
```

Use an available iPad Pro 11-inch simulator destination.

After modifying code, run a build similar to:

```bash
xcodebuild \
  -project OwlLala.xcodeproj \
  -scheme OwlLala \
  -destination 'platform=iOS Simulator,name=<AVAILABLE IPAD PRO 11-INCH NAME>' \
  build
```

Do not assume a simulator generation or OS version. Use an installed destination reported by `-showdestinations`.

Tests are outside the current task unless explicitly requested.

## Required Task Reporting

Before making changes:

1. Inspect the relevant models, views, ViewModels, app entry point, and `StorageService`.
2. Report the current architecture and relevant problems.
3. Provide a file-by-file implementation plan.
4. Identify ambiguities and blockers.
5. Wait for approval before editing.

After implementation:

1. Summarize modified files.
2. Explain key ownership and data-flow decisions.
3. Report the exact build command used.
4. Report build success or provide the complete relevant compiler errors.
5. List remaining TODOs without implementing unrequested features.
