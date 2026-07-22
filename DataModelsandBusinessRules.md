# OwlLala Data Models and Business Rules

## Purpose
This document defines the agreed data model responsibilities and MVP business rules.
Use it as the primary reference when implementing or modifying model, view-model,
storage, and navigation logic.

## Model Overview

### Story
- Represents static story content.
- An available story contains exactly five chapters.
- Story 1 is available.
- Story 2 and Story 3 are `comingSoon`.
- Coming-soon stories may have no chapters and no completion summary.
- Story completion is derived from chapter completion and is not persisted separately.

### Chapter
- Represents one learning chapter.
- Contains 3–4 static story pages.
- Contains exactly one mini-game.
- The mini-game contains exactly one tap-to-select question.
- Contains one chapter learning summary.
- Does not store progress or stars.

### StoryPage
- Contains one complete static illustration asset.
- Contains one fixed Indonesian narration.
- May contain one optional voice-over asset.
- Character dialogue and speech bubbles are not rendered dynamically.

### GameStats
- Stores accumulated results for one chapter.
- There is at most one `GameStats` record per chapter.
- Stores:
  - `chapterID`
  - `bestStars`
  - `playCount`
- Abandoned sessions are not recorded.
- Main Story and Training Mode update the same record.
- Replays only replace `bestStars` when the new score is higher.

### UserStats
- Stores:
  - unlocked chapter identifiers;
  - one `GameStats` record per completed chapter.
- Chapter completion is derived from the existence of `GameStats`.
- Chapters unlock sequentially in Main Story.
- Training Mode unlocks only after all five chapters in the story are completed.
- Story completion is derived dynamically and is not stored.

### Settings
- Stores only:
  - background brightness;
  - whether a color-vision simulation is active;
  - the most recently selected color-vision simulation;
  - the preferred app text size from X Small through Accessibility 5.
- Disabling the color-vision simulation retains its most recently selected
  type, and enabling it again restores that selection.
- Text size uses the matching native iPadOS Dynamic Type category throughout
  the app, including Accessibility 1–5.
- Exit confirmation is always enabled and is not configurable.
- Audio settings are not persisted in the MVP.

## Gameplay Rules

### Main Story
1. Show story pages.
2. Show the chapter mini-game.
3. Require the correct answer before completion.
4. Show correct-answer feedback.
5. Save the game result.
6. Show chapter stage-cleared summary.
7. Unlock the next chapter.
8. After Chapter 5, show the story completion summary.

### Training Mode
1. Skip story pages.
2. Open the same chapter mini-game used by Main Story.
3. Save results to the same `GameStats`.
4. Show the chapter stage-cleared summary.
5. Do not modify chapter progression.
6. Do not show the story completion summary.

## Answer and Hint Rules
- All mini-games use tap-to-select answers.
- Answer content may be:
  - text;
  - image;
  - text and image.
- A question may contain:
  - text only;
  - text and one supporting image.
- Incorrect selections:
  - count individually;
  - may select the same incorrect answer multiple times;
  - show a red outline and shake animation.
- The hint overlay appears once after the second incorrect attempt.
- Only the hint speech-bubble text is dynamic.
- The child must eventually select the correct answer.
- There is no maximum attempt count.

## Star Scoring
- 0 wrong attempts: 3 stars.
- 1 wrong attempt: 2 stars.
- 2 or more wrong attempts: 1 star.
- Abandoned game: no result is saved.
- Scoring logic belongs in `ChapterGameplayViewModel`, not in the model layer.

## Competency Scoring
Competency score is derived directly from the chapter's best stars:

- No completed game: 0/3.
- Best 1 star: 1/3.
- Best 2 stars: 2/3.
- Best 3 stars: 3/3.

Each chapter maps to exactly one competency:

- Shape.
- Pattern.
- Brightness and contrast.
- Label and symbol.
- Context.

## Persistence Rules
Persist only mutable user data through `UserDefaults`:

- `UserStats`
- `GameStats`
- `Settings`

Do not persist static content:

- `Story`
- `Chapter`
- `StoryPage`
- questions;
- answers;
- hints;
- summaries.

Static content should be declared in Swift or bundled local data.

## Asset Responsibilities
- `Story.coverAssetName`
  - Story-selection book cover.
- `Chapter.thumbnailAssetName`
  - Chapter-selection map thumbnail.
- `StoryPage.illustrationAssetName`
  - Full story-page illustration.
- `LearningSummary.mainIllustrationAssetName`
  - Chapter stage-cleared illustration.
- Settings preview assets are view content and are not stored in `Settings`.

## MVP Constraints
- One playable story.
- Two coming-soon story placeholders.
- Exactly five chapters in the playable story.
- One question per chapter.
- Static story images only.
- No SwiftData.
- No per-session game history.
- No duration tracking.
- No dates or timestamps.
- No answer shuffling yet.
- No configurable audio or haptic settings.

## Codex Implementation Guardrails
When generating or modifying code:

- Do not add properties that are not defined in this document.
- Do not introduce SwiftData.
- Do not store abandoned game sessions.
- Do not create separate gameplay views for each chapter.
- Reuse one chapter gameplay view for all five chapters.
- Do not duplicate best-star data inside `UserStats`.
- Do not persist story completion separately.
- Do not place scoring rules inside `Chapter` or `GameStats`.
- Keep static content separate from persisted user data.
- Ask for confirmation before changing any business rule in this document.
