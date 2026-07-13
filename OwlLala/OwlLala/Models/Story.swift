//
//  Story.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

/// Represents the complete learning story available in the main-story mode.
///
/// A story contains an ordered collection of chapters. The model describes
/// static story content and does not store the child's completion progress.
/// Progress is stored separately in `UserStats`.
struct Story: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used to reference the story across app sessions.
    let id: String

    /// The title displayed on the story-selection screen.
    let title: String

    /// Optional supporting text displayed below the main title.
    let subtitle: String?

    /// A short explanation of the story's learning journey.
    let description: String

    /// The asset-catalog name of the story's cover image.
    let coverAssetName: String

    /// All chapters that belong to this story.
    ///
    /// Consumers should use `sortedChapters` when presentation order matters.
    let chapters: [Chapter]

    /// Returns the chapters ordered by their configured chapter number.
    var sortedChapters: [Chapter] {
        chapters.sorted { $0.order < $1.order }
    }

    /// The maximum number of stars that can be collected in the story.
    var totalAvailableStars: Int {
        chapters.reduce(0) { result, chapter in
            result + chapter.maximumStars
        }
    }
}