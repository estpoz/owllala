//
//  GameStats.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Game Statistics

/// Stores the accumulated mini-game statistics for one chapter.
///
/// A chapter has at most one `GameStats` value. The value stores:
/// - The highest star result earned for the chapter.
/// - The number of completed game sessions.
///
/// Abandoned sessions are not recorded. Main Story and Training Mode update
/// the same statistics because both modes use the same chapter mini-game.
struct GameStats: Identifiable, Codable, Hashable, Sendable {

    /// The chapter associated with these statistics.
    ///
    /// The chapter identifier also acts as the stable identifier of this model.
    let chapterID: String

    /// The highest star result earned for this chapter.
    ///
    /// The value is always between one and `Chapter.maximumStars`.
    /// A chapter that has never been completed does not have a `GameStats`
    /// record.
    private(set) var bestStars: Int

    /// The number of times the child has completed this chapter's mini-game.
    ///
    /// Abandoned sessions do not increase this value.
    private(set) var playCount: Int

    /// Uses the chapter identifier as the stable model identifier.
    var id: String {
        chapterID
    }

    /// Creates statistics for a chapter's first completed game.
    ///
    /// - Parameters:
    ///   - chapterID: The stable identifier of the completed chapter.
    ///   - earnedStars: The stars earned from the completed game.
    init(
        chapterID: String,
        earnedStars: Int
    ) {
        precondition(
            (1...Chapter.maximumStars).contains(earnedStars),
            "Earned stars must be between 1 and \(Chapter.maximumStars)."
        )

        self.chapterID = chapterID
        self.bestStars = earnedStars
        self.playCount = 1
    }

    /// Records another completed game for the same chapter.
    ///
    /// The play count always increases. The stored star result only changes
    /// when the new result is higher than the previous best.
    ///
    /// - Parameter earnedStars: The stars earned from the completed game.
    mutating func recordCompletedGame(earnedStars: Int) {
        precondition(
            (1...Chapter.maximumStars).contains(earnedStars),
            "Earned stars must be between 1 and \(Chapter.maximumStars)."
        )

        bestStars = max(bestStars, earnedStars)
        playCount += 1
    }
}
