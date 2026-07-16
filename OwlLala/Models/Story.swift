//
//  Story.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Story

/// Represents one learning story displayed in Main Story mode.
///
/// An available story contains exactly five ordered chapters and an optional
/// completion summary shown after the final chapter is completed.
///
/// Story completion and Training Mode availability are not stored here.
/// They are derived from chapter progress in `UserStats`.
struct Story: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used for navigation and progress lookup.
    ///
    /// Example: `"story-1"`
    let id: String

    /// The story's position on the story-selection screen.
    ///
    /// The first story should use `1`.
    let order: Int

    /// The title displayed on the story-selection screen.
    let title: String

    /// Optional supporting text displayed below the story title.
    let subtitle: String?

    /// A short explanation of the story's learning journey.
    let description: String

    /// The asset-catalog name of the story's cover illustration.
    ///
    /// This asset is only used on the story-selection screen.
    let coverAssetName: String

    /// Indicates whether the story can currently be played.
    ///
    /// For the MVP, Story 1 is available while Story 2 and Story 3 are
    /// displayed as locked coming-soon content.
    let availability: StoryAvailability

    /// The chapters included in this story.
    ///
    /// An available story contains exactly five chapters in presentation
    /// order. A coming-soon story may use an empty array.
    let chapters: [Chapter]

    /// Content displayed after the final chapter is completed.
    ///
    /// This value is available for playable stories and `nil` for
    /// coming-soon stories.
    let completionSummary: StoryCompletionSummary?

    /// Indicates whether the story can be selected and played.
    var isAvailable: Bool {
        availability == .available
    }

    /// The maximum number of stars available across all chapters.
    ///
    /// Each chapter can award up to `Chapter.maximumStars`.
    var totalAvailableStars: Int {
        chapters.count * Chapter.maximumStars
    }
}

// MARK: - Story Availability

/// Describes whether a story can currently be played.
enum StoryAvailability: String, Codable, Hashable, Sendable {

    /// The story contains playable chapter content.
    case available

    /// The story is visible but cannot be played yet.
    case comingSoon
}

// MARK: - Story Completion Summary

/// Contains the content shown after every chapter in a story is completed.
///
/// This summary appears only after completing the final chapter through
/// Main Story mode. Completing a game through Training Mode does not present
/// this screen.
///
/// The current MVP contains one implementation of the summary screen, but its
/// content remains part of the story model rather than being hard-coded into
/// the view.
struct StoryCompletionSummary: Codable, Hashable, Sendable {

    /// The main completion heading.
    ///
    /// Example: `"Hebat! Cerita 1 Selesai!"`
    let title: String

    /// The introductory reflection displayed below the heading.
    let message: String

    /// The asset-catalog name of the main mascot illustration.
    let mascotAssetName: String

    /// The five competency summaries presented on the completion screen.
    ///
    /// Their order should follow the learning order of the story's chapters.
    let competencyItems: [StoryCompetencySummary]

    /// The final encouragement displayed below the competency summaries.
    let closingMessage: String

    /// The optional asset-catalog name of the closing-message icon.
    let closingIconAssetName: String?
}

// MARK: - Story Competency Summary

/// Represents one competency card on the story-completion screen.
struct StoryCompetencySummary: Identifiable, Codable, Hashable, Sendable {

    /// Uses the competency as the stable identifier for the summary item.
    var id: Competency {
        competency
    }

    /// The competency represented by this summary item.
    let competency: Competency

    /// The child-friendly title displayed on the summary card.
    ///
    /// This may be more descriptive than `Competency.displayName`.
    ///
    /// Example: `"Tulisan, Simbol, dan Label"`
    let title: String

    /// A short explanation of how the competency helps identify objects.
    let explanation: String

    /// The asset-catalog name of the competency icon.
    let iconAssetName: String
}

//Contoh data story:
//let storyOne = Story(
//    id: "story-1",
//    order: 1,
//    title: "Cerita 1",
//    subtitle: "Hilangnya Kotak Bekal",
//    description: "Bantu Lala menemukan kotak bekalnya menggunakan berbagai petunjuk visual.",
//    coverAssetName: "story_1_cover",
//    availability: .available,
//    chapters: [
//        chapterOne,
//        chapterTwo,
//        chapterThree,
//        chapterFour,
//        chapterFive
//    ],
//    completionSummary: StoryCompletionSummary(
//        title: "Hebat! Cerita 1 Selesai!",
//        message: "Kamu sudah belajar mengenali benda tanpa bergantung pada warna. Yuk, lihat apa saja yang sudah kamu kuasai!",
//        mascotAssetName: "cluey_story_completion",
//        competencyItems: [
//            StoryCompetencySummary(
//                competency: .shape,
//                title: "Bentuk",
//                explanation: "Mengenali objek berdasarkan bentuknya.",
//                iconAssetName: "competency_shape"
//            ),
//            StoryCompetencySummary(
//                competency: .labelSymbol,
//                title: "Tulisan, Simbol, dan Label",
//                explanation: "Menggunakan tulisan, simbol, dan label sebagai petunjuk arah.",
//                iconAssetName: "competency_label_symbol"
//            ),
//            StoryCompetencySummary(
//                competency: .brightnessContrast,
//                title: "Terang dan Gelap (Kontras)",
//                explanation: "Membedakan benda berdasarkan tingkat terang dan gelapnya.",
//                iconAssetName: "competency_brightness_contrast"
//            ),
//            StoryCompetencySummary(
//                competency: .pattern,
//                title: "Pola dan Tekstur",
//                explanation: "Menemukan perbedaan melalui pola dan tekstur permukaan.",
//                iconAssetName: "competency_pattern"
//            ),
//            StoryCompetencySummary(
//                competency: .context,
//                title: "Menggabungkan Semua Petunjuk",
//                explanation: "Menggabungkan semua petunjuk untuk mengenali benda dalam situasi sehari-hari.",
//                iconAssetName: "competency_context"
//            )
//        ],
//        closingMessage: "Sekarang kamu tahu bahwa warna bukan satu-satunya cara untuk mengenali dunia di sekitarmu. Terus gunakan berbagai petunjuk ini di petualangan berikutnya!",
//        closingIconAssetName: "story_completion_lightbulb"
//    )
//)
//
//Contoh placeholder story:
//let storyTwo = Story(
//    id: "story-2",
//    order: 2,
//    title: "Cerita 2",
//    subtitle: "Segera Hadir",
//    description: "Cerita baru akan hadir pada pembaruan berikutnya.",
//    coverAssetName: "story_2_cover",
//    availability: .comingSoon,
//    chapters: [],
//    completionSummary: nil
//)
