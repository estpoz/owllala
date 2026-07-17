//
//  Chapter.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Chapter

/// Represents one learning chapter inside a story.
///
/// Each chapter contains:
/// - A sequence of illustrated story pages.
/// - One tap-to-select mini-game with one question.
/// - One learning summary shown on the stage-cleared screen.
///
/// The same mini-game is used in both Main Story and Training Mode.
/// Training Mode skips the story pages and starts directly from the game.
///
/// User progress and earned stars are not stored in this model.
/// They are handled separately through `GameStats` and `UserStats`.
struct Chapter: Identifiable, Codable, Hashable, Sendable {

    /// The maximum number of stars that can be earned in any chapter.
    static let maximumStars = 3

    /// A stable identifier used for navigation, progress, and statistics.
    ///
    /// Example: `"chapter-shape"`
    let id: String

    /// The chapter's position within its parent story.
    ///
    /// The first chapter should use `1`.
    let order: Int

    /// The main chapter title displayed in chapter selection and gameplay.
    let title: String

    /// Optional supporting text displayed below the chapter title.
    let subtitle: String?

    /// A short explanation of the chapter's story and learning objective.
    let description: String

    /// The asset-catalog name of the chapter thumbnail.
    let thumbnailAssetName: String

    /// The non-color visual cue taught in this chapter.
    let competency: Competency

    /// The ordered pages displayed before the mini-game in Main Story mode.
    ///
    /// Training Mode does not display these pages.
    let storyPages: [StoryPage]

    /// The reusable mini-game configuration for this chapter.
    ///
    /// Each chapter currently contains exactly one question.
    let gameConfiguration: GameConfiguration

    /// The chapter-specific content displayed after the game is completed.
    let learningSummary: LearningSummary
}

// MARK: - Learning Competency

/// A non-color visual cue that children can use to identify objects.
enum Competency: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {

    /// Identifying objects through outlines and geometric forms.
    case shape

    /// Identifying objects through repeated markings, details, or textures.
    case pattern

    /// Distinguishing objects through differences in lightness and contrast.
    case brightnessContrast

    /// Identifying objects through labels, symbols, signs, or icons.
    case labelSymbol

    /// Identifying objects through their environment or expected use.
    case context

    var id: String {
        rawValue
    }

    /// The fixed Indonesian name displayed in the user interface.
    var displayName: String {
        switch self {
        case .shape:
            return "Bentuk"

        case .pattern:
            return "Pola"

        case .brightnessContrast:
            return "Terang dan Kontras"

        case .labelSymbol:
            return "Label dan Simbol"

        case .context:
            return "Konteks"
        }
    }
}

// MARK: - Story Page

/// Represents one illustrated page in a chapter's story sequence.
///
/// Each page uses one complete static illustration asset.
/// Dialogue and speech bubbles are not rendered separately.
///
/// The narration is displayed below the illustration and may be supported by
/// an optional recorded voice-over.
struct StoryPage: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used for page navigation and tracking.
    ///
    /// Example: `"chapter-1-page-1"`
    let id: String

    /// The page's position within the chapter.
    ///
    /// The first page should use `1`.
    let order: Int

    /// The asset-catalog name of the complete page illustration.
    let illustrationAssetName: String

    /// The fixed Indonesian narration displayed below the illustration.
    let narration: String

    /// The optional audio-resource name used to read the narration aloud.
    ///
    /// Use `nil` when the page does not provide voice-over audio.
    let voiceOverAssetName: String?
}

// MARK: - Game Configuration

/// Defines the reusable mini-game associated with a chapter.
///
/// The same configuration is launched from Main Story and Training Mode.
/// Each chapter currently contains one tap-to-select question.
struct GameConfiguration: Codable, Hashable, Sendable {

    /// The single question presented in this chapter's mini-game.
    let question: GameQuestion
}

// MARK: - Game Question

/// Represents one tap-to-select question.
///
/// A question always contains text and may optionally include a supporting
/// image above the answer options.
///
/// The child must select the correct answer before continuing. Incorrect
/// answers remain selectable and each incorrect selection counts as one
/// wrong attempt.
struct GameQuestion: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used for gameplay and statistics.
    ///
    /// Example: `"chapter-1-question"`
    let id: String

    /// The question or instruction displayed to the child.
    let prompt: String

    /// An optional supporting image displayed with the question.
    ///
    /// Use `nil` for text-only questions.
    let promptImageAssetName: String?

    /// The selectable answers displayed for this question.
    ///
    /// Each answer may contain text, an image, or both.
    let answerOptions: [AnswerOption]

    /// The identifier of the correct answer in `answerOptions`.
    let correctAnswerID: String

    /// The chapter-specific clue shown after the second wrong attempt.
    ///
    /// Only the speech-bubble text is dynamic. The overlay illustration,
    /// encouragement text, and action button are handled by the reusable
    /// immediate-feedback component.
    let hintText: String

    /// Returns the answer option marked as correct.
    ///
    /// Returns `nil` when `correctAnswerID` does not match any option.
    var correctAnswer: AnswerOption? {
        answerOptions.first { $0.id == correctAnswerID }
    }
}

// MARK: - Answer Option

/// Represents one selectable answer in a mini-game question.
///
/// An answer can contain:
/// - Text only.
/// - An image only.
/// - Both text and an image.
///
/// At least one of `text` or `imageAssetName` should contain a value.
struct AnswerOption: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used to evaluate the selected answer.
    ///
    /// Example: `"blue-lunchbox"`
    let id: String

    /// Optional text displayed inside the answer option.
    let text: String?

    /// Optional asset-catalog name displayed inside the answer option.
    let imageAssetName: String?

    /// Indicates whether this option contains displayable content.
    var hasContent: Bool {
        let hasText = !(text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasImage = !(imageAssetName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        return hasText || hasImage
    }
}

// MARK: - Learning Summary

/// Contains chapter-specific content for the reusable stage-cleared screen.
///
/// Layout, star rendering, navigation, and reusable labels are handled by
/// the `StageCleared` component. This model only stores content that differs
/// between chapters.
struct LearningSummary: Codable, Hashable, Sendable {

    /// The short success message displayed after solving the chapter.
    ///
    /// Example: `"Lala berhasil menemukan kotak makannya!"`
    let successMessage: String

    /// The learning reflection explaining the visual cue used in the chapter.
    ///
    /// Example: `"Bentuk membantu kita mengenali benda meskipun warnanya sulit dibedakan."`
    let explanation: String

    /// The asset-catalog name of the main stage-cleared illustration.
    let mainIllustrationAssetName: String

    /// The asset-catalog names of the visual examples shown in the learning
    /// summary panel.
    ///
    /// The current design uses three example assets, but the array remains
    /// flexible for future chapter content.
    let exampleAssetNames: [String]
}
