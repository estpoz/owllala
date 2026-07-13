//
//  UserStats.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

/// Stores the child's accumulated learning progress across app sessions.
///
/// This model is persisted through `StorageService`. It contains completion
/// state, unlocked chapters, best scores, and historical game-session results.
struct UserStats: Codable, Hashable, Sendable {

    /// Identifiers of chapters the child has completed at least once.
    var completedChapterIDs: Set<String>

    /// Identifiers of chapters currently available to play.
    var unlockedChapterIDs: Set<String>

    /// The child's highest earned star count for each chapter.
    ///
    /// A lower replay result must never replace a higher existing result.
    var bestStarsByChapterID: [String: Int]

    /// All recorded mini-game sessions.
    var gameHistory: [GameStats]

    /// The accumulated duration of all completed game sessions.
    var totalPlayTime: TimeInterval

    /// The date on which the child first played a recorded game.
    var firstPlayedAt: Date?

    /// The date of the child's most recent recorded game.
    var lastPlayedAt: Date?

    /// The sum of the child's best star results across all chapters.
    var totalStars: Int {
        bestStarsByChapterID.values.reduce(0, +)
    }

    /// The number of chapters completed at least once.
    var completedChapterCount: Int {
        completedChapterIDs.count
    }

    /// Checks whether a chapter has been completed.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: `true` when the chapter has been completed.
    func isChapterCompleted(_ chapterID: String) -> Bool {
        completedChapterIDs.contains(chapterID)
    }

    /// Checks whether a chapter is currently available to play.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: `true` when the chapter is unlocked.
    func isChapterUnlocked(_ chapterID: String) -> Bool {
        unlockedChapterIDs.contains(chapterID)
    }

    /// Returns the highest star count recorded for a chapter.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: The best star result, or zero when no result exists.
    func bestStars(for chapterID: String) -> Int {
        bestStarsByChapterID[chapterID, default: 0]
    }

    /// Records a completed or incomplete game session in the child's history.
    ///
    /// Completed sessions update chapter completion and best-star progress.
    /// Incomplete sessions remain in history but do not mark a chapter as
    /// completed.
    ///
    /// - Parameter result: The game-session result to record.
    mutating func recordGameResult(_ result: GameStats) {
        gameHistory.append(result)

        totalPlayTime += result.duration ?? 0
        lastPlayedAt = result.completedAt ?? Date()

        if firstPlayedAt == nil {
            firstPlayedAt = result.startedAt
        }

        guard result.isCompleted else {
            return
        }

        completedChapterIDs.insert(result.chapterID)

        let previousBest = bestStarsByChapterID[result.chapterID, default: 0]

        bestStarsByChapterID[result.chapterID] = max(
            previousBest,
            result.earnedStars
        )
    }

    /// Makes a chapter available without marking it as completed.
    ///
    /// - Parameter chapterID: The identifier of the chapter to unlock.
    mutating func unlockChapter(_ chapterID: String) {
        unlockedChapterIDs.insert(chapterID)
    }

    /// Marks a chapter as completed and optionally unlocks the next chapter.
    ///
    /// - Parameters:
    ///   - chapterID: The identifier of the completed chapter.
    ///   - nextChapterID: The optional identifier of the next chapter.
    mutating func completeChapter(
        _ chapterID: String,
        nextChapterID: String?
    ) {
        completedChapterIDs.insert(chapterID)

        if let nextChapterID {
            unlockedChapterIDs.insert(nextChapterID)
        }
    }
}