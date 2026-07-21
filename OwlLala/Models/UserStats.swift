//
//  UserStats.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - User Statistics

/// Stores the child's accumulated learning progress across app sessions.
///
/// The model contains:
/// - Chapters currently available in Main Story.
/// - Best star results and completed-play counts for each chapter.
///
/// A chapter is considered completed when its mini-game is completed.
/// Abandoned games are not recorded and do not affect progression.
///
/// Story completion and Training Mode availability are derived from the
/// completion state of every chapter in the story.
struct UserStats: Codable, Hashable, Sendable {

    /// Identifiers of chapters currently available in Main Story.
    ///
    /// Chapters are unlocked sequentially as the child completes the previous
    /// chapter.
    private(set) var unlockedChapterIDs: Set<String>

    /// Accumulated mini-game statistics, with at most one record per chapter.
    ///
    /// Main Story and Training Mode update the same chapter record.
    private(set) var gameStats: [GameStats]

    /// Creates a new user-progress record.
    ///
    /// Only the first chapter is available when progress is created.
    ///
    /// - Parameter firstChapterID: The identifier of the first chapter that
    ///   should be available to play.
    init(firstChapterID: String) {
        unlockedChapterIDs = [firstChapterID]
        gameStats = []
    }
}

// MARK: - Summary Statistics

extension UserStats {

    /// The sum of the best star results across all completed chapters.
    var totalStars: Int {
        gameStats.reduce(0) { partialResult, stats in
            partialResult + stats.bestStars
        }
    }

    /// The number of chapters completed at least once.
    var completedChapterCount: Int {
        gameStats.count
    }

    /// Returns the number of completed stories in the provided collection.
    ///
    /// A story is completed when every chapter inside it has been completed.
    ///
    /// - Parameter stories: The stories included in the application.
    /// - Returns: The number of fully completed stories.
    func completedStoryCount(in stories: [Story]) -> Int {
        stories.filter(isStoryCompleted).count
    }
}

// MARK: - Chapter Progress

extension UserStats {

    /// Checks whether a chapter is currently available in Main Story.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: `true` when the chapter is unlocked.
    func isChapterUnlocked(_ chapterID: String) -> Bool {
        unlockedChapterIDs.contains(chapterID)
    }

    /// Checks whether a chapter's mini-game has been completed at least once.
    ///
    /// A completed chapter always has an associated `GameStats` record.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: `true` when statistics exist for the chapter.
    func isChapterCompleted(_ chapterID: String) -> Bool {
        stats(for: chapterID) != nil
    }

    /// Returns the stored statistics for a chapter.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: The chapter statistics, or `nil` when it has not been
    ///   completed.
    func stats(for chapterID: String) -> GameStats? {
        gameStats.first { stats in
            stats.chapterID == chapterID
        }
    }

    /// Returns the highest star result recorded for a chapter.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: The best star result, or zero when the chapter has not been
    ///   completed.
    func bestStars(for chapterID: String) -> Int {
        stats(for: chapterID)?.bestStars ?? 0
    }

    /// Returns the number of completed plays recorded for a chapter.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter.
    /// - Returns: The completed-play count, or zero when the chapter has not
    ///   been completed.
    func playCount(for chapterID: String) -> Int {
        stats(for: chapterID)?.playCount ?? 0
    }

    /// Makes a chapter available in Main Story.
    ///
    /// Calling this method for an already unlocked chapter has no effect.
    ///
    /// - Parameter chapterID: The stable identifier of the chapter to unlock.
    mutating func unlockChapter(_ chapterID: String) {
        unlockedChapterIDs.insert(chapterID)
    }

    /// Handles Main Story progression after a chapter is completed.
    ///
    /// This method only manages chapter availability. Game statistics should
    /// be recorded separately using `recordCompletedGame`.
    ///
    /// Replay sessions and Training Mode do not need to call this method.
    ///
    /// - Parameter nextChapterID: The optional identifier of the next chapter
    ///   that should become available.
    mutating func completeChapter(nextChapterID: String?) {
        guard let nextChapterID else {
            return
        }

        unlockChapter(nextChapterID)
    }
}

// MARK: - Game Statistics

extension UserStats {

    /// Records a completed mini-game result.
    ///
    /// If the chapter has no previous statistics, a new record is created.
    /// Otherwise, its play count and best star result are updated.
    ///
    /// This method is used by both Main Story and Training Mode.
    /// Abandoned games must not call this method.
    ///
    /// - Parameters:
    ///   - chapterID: The identifier of the completed chapter.
    ///   - earnedStars: The stars awarded for the completed game.
    mutating func recordCompletedGame(
        chapterID: String,
        earnedStars: Int
    ) {
        if let index = gameStats.firstIndex(
            where: { $0.chapterID == chapterID }
        ) {
            gameStats[index].recordCompletedGame(
                earnedStars: earnedStars
            )
        } else {
            let newStats = GameStats(
                chapterID: chapterID,
                earnedStars: earnedStars
            )

            gameStats.append(newStats)
        }
    }
}

// MARK: - Story Progress

extension UserStats {

    /// Checks whether every chapter in a story has been completed.
    ///
    /// - Parameter story: The story whose progress should be evaluated.
    /// - Returns: `true` when every chapter has associated game statistics.
    func isStoryCompleted(_ story: Story) -> Bool {
        guard !story.chapters.isEmpty else {
            return false
        }

        return story.chapters.allSatisfy { chapter in
            isChapterCompleted(chapter.id)
        }
    }

    /// Checks whether Training Mode is available for a story.
    ///
    /// Training Mode becomes available only after every chapter in the story
    /// has been completed in Main Story.
    ///
    /// - Parameter story: The story whose Training Mode should be evaluated.
    /// - Returns: `true` when the story has been completed.
    func isTrainingUnlocked(for story: Story) -> Bool {
        isStoryCompleted(story)
    }
}

// MARK: - Competency Progress

extension UserStats {

    /// Returns the child's competency score for a chapter.
    ///
    /// Each chapter teaches exactly one competency, so the competency score is
    /// derived from that chapter's highest star result.
    ///
    /// Score mapping follows the chapter star result:
    /// - Not completed: 0 out of 3.
    /// - Best result of 1 star: 1 out of 3.
    /// - Best result of 2 stars: 2 out of 3.
    /// - Best result of 3 stars: 3 out of 3.
    ///
    /// - Parameter chapter: The chapter associated with the competency.
    /// - Returns: A competency score between zero and `Chapter.maximumStars`.
    func competencyScore(for chapter: Chapter) -> Int {
        bestStars(for: chapter.id)
    }

    /// Returns the competency score for a specific competency.
    ///
    /// This method assumes that each competency is taught by exactly one
    /// chapter.
    ///
    /// - Parameters:
    ///   - competency: The competency whose score should be returned.
    ///   - chapters: The chapters available in the story.
    /// - Returns: A score between zero and `Chapter.maximumStars`, or zero when
    ///   no matching chapter exists.
    func competencyScore(
        for competency: Competency,
        in chapters: [Chapter]
    ) -> Int {
        guard let chapter = chapters.first(
            where: { $0.competency == competency }
        ) else {
            return 0
        }

        return competencyScore(for: chapter)
    }
}
