//
//  Chapter.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Chapter

/// Represents one learning chapter in the main story.
///
/// A chapter combines its story presentation, learning competency, reusable
/// mini-game configuration, and end-of-chapter learning summary.
///
/// The model contains static chapter content. Completion state and earned stars
/// are stored in `UserStats`.
struct Chapter: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used by progress and statistics records.
    let id: String

    /// The identifier of the story that contains this chapter.
    let storyID: String

    /// The chapter's position in the story sequence.
    let order: Int

    /// The title displayed on chapter-selection and gameplay screens.
    let title: String

    /// Optional supporting text displayed below the chapter title.
    let subtitle: String?

    /// A short description of the chapter's story and learning objective.
    let description: String

    /// The asset-catalog name of the chapter thumbnail.
    let thumbnailAssetName: String

    /// The non-color visual cue practiced in this chapter.
    let competency: Competency

    /// The ordered storybook pages presented during the chapter.
    let storyPages: [StoryPage]

    /// The mini-game content and scoring configuration for this chapter.
    let gameConfiguration: GameConfiguration

    /// The learning reflection presented after completing the chapter.
    let learningSummary: LearningSummary

    /// The maximum number of stars available in this chapter.
    let maximumStars: Int
}

// MARK: - Learning Competency

/// A non-color visual cue that children can use to identify objects.
enum Competency: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {

    /// Identifying an object using its outline or geometric form.
    case shape

    /// Identifying an object using repeated visual markings or textures.
    case pattern

    /// Distinguishing objects using differences in lightness and contrast.
    case brightnessContrast

    /// Identifying an object using written labels, symbols, or icons.
    case labelSymbol

    /// Identifying an object using its surroundings or expected use.
    case context

    var id: String {
        rawValue
    }

    /// The Indonesian name displayed in the user interface.
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

/// Represents one illustrated page in a chapter's storybook sequence.
struct StoryPage: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier for navigation and page tracking.
    let id: String

    /// The page's position within the chapter.
    let order: Int

    /// The asset-catalog name of the page's background illustration.
    let backgroundAssetName: String

    /// The optional asset-catalog name of the character illustration.
    let characterAssetName: String?

    /// The optional name of the character currently speaking.
    let speakerName: String?

    /// The dialogue displayed in the story's speech area.
    let dialogue: String

    /// Optional narration displayed separately from character dialogue.
    let narration: String?

    /// Optional audio-resource name used for spoken narration.
    let audioAssetName: String?
}

// MARK: - Game Configuration

/// Defines the reusable mini-game content associated with a chapter.
///
/// The same configuration may be launched from the main-story mode or
/// training mode.
struct GameConfiguration: Codable, Hashable, Sendable {

    /// The interaction format used to present the mini-game.
    let gameType: GameType

    /// The child-friendly instruction displayed before gameplay begins.
    let instructions: String

    /// The questions presented during the game session.
    let questions: [GameQuestion]

    /// The highest number of wrong answers that still earns two stars.
    let maximumWrongAnswersForTwoStars: Int

    /// The highest number of wrong answers that still earns three stars.
    let maximumWrongAnswersForThreeStars: Int
}