//
//  GameStats.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Game Session Statistics

/// Represents the result of one mini-game session.
///
/// Each completed or abandoned play session produces one `GameStats` value.
/// Long-term progress is aggregated separately inside `UserStats`.
struct GameStats: Identifiable, Codable, Hashable, Sendable {

    /// A unique identifier for this individual play session.
    let id: UUID

    /// The chapter associated with the played mini-game.
    let chapterID: String

    /// The interaction format used during the session.
    let gameType: GameType

    /// The application mode from which the game was launched.
    let mode: GameplayMode

    /// The date and time at which the session began.
    let startedAt: Date

    /// The date and time at which the session ended.
    ///
    /// This remains `nil` while the session has not been completed.
    let completedAt: Date?

    /// The total number of questions available in the session.
    let totalQuestions: Int

    /// The number of questions answered correctly.
    let correctAnswers: Int

    /// The number of incorrect answer attempts.
    let wrongAnswers: Int

    /// The number of questions skipped by the learner.
    let skippedAnswers: Int

    /// The final number of stars awarded for the session.
    let earnedStars: Int

    /// Indicates whether the learner reached the end of the session.
    let isCompleted: Bool

    /// The proportion of questions answered correctly.
    ///
    /// The value is between zero and one. Zero is returned when the session
    /// contains no questions.
    var accuracy: Double {
        guard totalQuestions > 0 else {
            return 0
        }

        return Double(correctAnswers) / Double(totalQuestions)
    }

    /// The elapsed session time, or `nil` when the game has not ended.
    var duration: TimeInterval? {
        guard let completedAt else {
            return nil
        }

        return completedAt.timeIntervalSince(startedAt)
    }

    /// Calculates the stars earned from the number of incorrect answers.
    ///
    /// Star rules:
    /// - Three stars: no incorrect answers.
    /// - Two stars: one incorrect answer.
    /// - One star: two or more incorrect answers.
    /// - Zero stars: the game was not completed.
    ///
    /// - Parameters:
    ///   - wrongAnswers: The number of incorrect answer attempts.
    ///   - isCompleted: Whether the learner completed the game.
    /// - Returns: A star value between zero and three.
    static func calculateStars(
        wrongAnswers: Int,
        isCompleted: Bool
    ) -> Int {
        guard isCompleted else {
            return 0
        }

        switch wrongAnswers {
        case 0:
            return 3
        case 1:
            return 2
        default:
            return 1
        }
    }
}