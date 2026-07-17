
# TDD User Stories - OwlLala

Dokumen ini menerjemahkan sticky notes user story dan plain-language assertion menjadi backlog TDD. Gunakan ini sebagai sumber test sebelum implementasi fitur di SwiftUI, view model, dan service.

## User Stories

### US1 - Main Learning Story

As a parent of a child with partial Color Vision Deficiency (CVD), I want my child to learn through interactive games, so that they can stay engaged while learning.

### US2 - Non-Color Visual Cues

As a parent of a child with partial Color Vision Deficiency (CVD), I want my child to become familiar with non-color visual cues such as identification skills, so that they can distinguish everyday objects more independently and confidently.

## Plain-Language Assertions

| ID | Assertion |
| --- | --- |
| PLA-01 | Given the child answers a question incorrectly, when the child retries and selects the correct answer, then the question is marked as completed and the retry scoring rule is applied correctly. |
| PLA-02 | Given a game contains 10 questions and the child answers all 10 correctly, when the final score is calculated, then the child receives 100 points and 5 stars. |
| PLA-03 | Given an object is shown with clear visual cues such as shape, pattern, or symbol, when the child selects the correct object, then the answer is marked as correct and positive feedback is displayed. |
| PLA-04 | Given the user completes 4 chapters with 2 or 3 stars in each chapter, when the total stars are calculated, then Chapter 5 is unlocked for play. |
| PLA-05 | Given a child finishes a learning session, when the game records the result, then the child's progress is updated so the parent can view it later. |
| PLA-06 | Given a child starts a visual cues learning game, when they complete all challenges, then the game shows the result and unlocks the next activity. |

## Test Scope

| Layer | Responsibility | Example Target |
| --- | --- | --- |
| Model tests | Score, star, chapter progress, and session result rules. | `GameStats`, `UserStats`, `Chapter` |
| View model tests | Answer validation, feedback state, retry behavior, and chapter unlock behavior. | `ChapterGameplayViewModel`, `ChapterSelectionViewModel`, `TrainingModeViewModel` |
| Service tests | Save and load child progress locally. | `StorageService` |
| UI tests | Key child flow from chapter selection to answer feedback and unlock state. | `OwlLalaUITests` |

## TDD Scenarios

### TDD-01 - Incorrect Answer Can Be Retried

Related assertion: `PLA-01`

| Given | When | Then |
| --- | --- | --- |
| A child answers a question incorrectly. | The child retries and selects the correct answer. | The question is completed, correct feedback is shown, and retry scoring is applied. |

Acceptance tests:

- `submitAnswer` marks the first wrong attempt as incorrect.
- The question remains retryable after an incorrect answer.
- A later correct answer marks the question as completed.
- Retry scoring gives fewer points than a first-attempt correct answer, if the scoring rule requires a penalty.

Suggested Swift test names:

- `incorrectAnswerKeepsQuestionRetryable()`
- `correctRetryCompletesQuestion()`
- `retryCorrectAnswerAppliesRetryScoringRule()`

### TDD-02 - Perfect 10 Question Session Gives 100 Points And 5 Stars

Related assertion: `PLA-02`

| Given | When | Then |
| --- | --- | --- |
| A game contains 10 questions and all 10 answers are correct. | The final score is calculated. | The child receives 100 points and 5 stars. |

Acceptance tests:

- A 10 out of 10 result calculates `100` points.
- A 10 out of 10 result calculates `5` stars.
- Score calculation does not depend on color-only answers.

Suggested Swift test names:

- `perfectTenQuestionSessionScoresOneHundredPoints()`
- `perfectTenQuestionSessionAwardsFiveStars()`

### TDD-03 - Correct Non-Color Cue Selection Shows Positive Feedback

Related assertion: `PLA-03`

| Given | When | Then |
| --- | --- | --- |
| An object is shown with clear shape, pattern, symbol, or label cues. | The child selects the correct object. | The answer is correct and positive feedback is displayed. |

Acceptance tests:

- Shape-based choices validate by shape, not color.
- Pattern-based choices validate by pattern or texture, not color.
- Symbol or label choices validate by meaning, not color.
- Correct answers produce positive, child-friendly feedback.

Suggested Swift test names:

- `shapeQuestionValidatesByShape()`
- `patternQuestionValidatesByPattern()`
- `symbolQuestionValidatesByMeaning()`
- `correctAnswerShowsPositiveFeedback()`

### TDD-04 - Chapter 5 Unlocks After Four Chapters With Enough Stars

Related assertion: `PLA-04`

| Given | When | Then |
| --- | --- | --- |
| The user completes Chapters 1-4 with 2 or 3 stars in each chapter. | Total chapter stars are calculated. | Chapter 5 becomes unlocked and playable. |

Acceptance tests:

- Chapter 5 remains locked before Chapters 1-4 are completed.
- Chapter 5 remains locked if any of Chapters 1-4 has fewer than 2 stars.
- Chapter 5 unlocks when Chapters 1-4 each have at least 2 stars.
- Unlock calculation works with mixed 2-star and 3-star chapter results.

Suggested Swift test names:

- `chapterFiveIsLockedBeforeRequiredChaptersAreComplete()`
- `chapterFiveIsLockedWhenAnyRequiredChapterHasLessThanTwoStars()`
- `chapterFiveUnlocksWhenFirstFourChaptersHaveAtLeastTwoStars()`

### TDD-05 - Learning Session Progress Is Saved For Parent View

Related assertion: `PLA-05`

| Given | When | Then |
| --- | --- | --- |
| A child finishes a learning session. | The game records the result. | Progress is updated and can be viewed later. |

Acceptance tests:

- Completing a session creates or updates a persisted progress record.
- Saved progress includes chapter ID, score, stars, completion status, and completed date.
- Loading progress returns the latest saved result.
- Saving a new best result does not lose earlier completed chapter progress.

Suggested Swift test names:

- `completedSessionSavesProgressRecord()`
- `savedProgressIncludesScoreStarsAndCompletionStatus()`
- `loadingProgressReturnsLatestSavedResult()`

### TDD-06 - Completing All Challenges Shows Result And Unlocks Next Activity

Related assertion: `PLA-06`

| Given | When | Then |
| --- | --- | --- |
| A child starts a visual cues learning game. | The child completes all challenges. | The result screen is shown and the next activity is unlocked. |

Acceptance tests:

- A session is not complete while unanswered challenges remain.
- Completing the last challenge marks the session as complete.
- Completed sessions expose a result summary with score and stars.
- The next activity unlocks after a completed session that meets the required threshold.

Suggested Swift test names:

- `sessionIsIncompleteWhileChallengesRemain()`
- `lastCompletedChallengeCompletesSession()`
- `completedSessionShowsResultSummary()`
- `completedSessionUnlocksNextActivityWhenThresholdIsMet()`

## Red-Green-Refactor Plan

| Step | Red | Green | Refactor |
| --- | --- | --- | --- |
| 1 | Write scoring tests for perfect and retry sessions. | Implement score and star calculation in a small model. | Extract score thresholds into constants or a value type. |
| 2 | Write answer validation tests for shape, pattern, symbol, and label cues. | Implement non-color answer validation. | Keep cue comparison independent from SwiftUI views. |
| 3 | Write feedback tests for correct and incorrect answers. | Implement feedback state in gameplay view model. | Centralize child-friendly feedback copy. |
| 4 | Write chapter unlock tests. | Implement chapter progress and unlock rules. | Move unlock policy into a pure function or model method. |
| 5 | Write storage tests with an isolated test store. | Implement local save and load progress behavior. | Hide persistence behind a protocol for testability. |
| 6 | Write one UI flow test for chapter playthrough. | Wire the view to the tested view model behavior. | Keep UI test focused on the critical path only. |

## Initial Swift Testing Skeleton

Use this shape when the domain types are implemented:

```swift
import Testing
@testable import OwlLala

struct GameplayScoringTests {
    @Test func perfectTenQuestionSessionScoresOneHundredPoints() {
        let result = GameStats.calculate(correctAnswers: 10, totalQuestions: 10)

        #expect(result.points == 100)
        #expect(result.stars == 5)
    }
}
```

The exact API names can change during implementation, but each test should keep the Given-When-Then behavior above intact.
