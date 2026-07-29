//
//  StatisticsViewModelTests.swift
//  OwlLalaTests
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - StatisticsViewModel

/// Behavior of `StatisticsViewModel` - deriving the parent-facing summary
/// (total stars, completed count, per-competency items, and guidance content)
/// from persisted progress plus static story content.
@MainActor
@Suite("StatisticsViewModel")
struct StatisticsViewModelTests {

    /// Given no completed chapters, then Statistics exposes zero summary values
    /// and zero-score competency rows for the empty-state UI.
    @Test func emptyProgressReportsZeroSummaryAndZeroCompetencies() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        #expect(viewModel.totalStars == 0)
        #expect(viewModel.completedChapterCount == 0)
        #expect(viewModel.completedStoryCount == 0)
        #expect(viewModel.competencyItems.map(\.score) == [0, 0, 0, 0, 0])
        #expect(viewModel.competencyItems.allSatisfy { $0.maximumScore == 3 })
    }

    /// Given partial progress, then competency rows use the app's Statistics
    /// order and map chapter best stars directly onto the 0/3, 1/3, 2/3, 3/3
    /// row scores.
    @Test func competencyItemsUseThreeStarScoresInStatisticsOrder() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
            stats.recordCompletedGame(chapterID: "chapter-2", earnedStars: 2)
            stats.recordCompletedGame(chapterID: "chapter-3", earnedStars: 1)
            stats.recordCompletedGame(chapterID: "chapter-4", earnedStars: 3)
        }

        #expect(viewModel.competencyItems.map(\.competency) == [
            .shape,
            .labelSymbol,
            .brightnessContrast,
            .pattern,
            .context
        ])
        #expect(viewModel.competencyItems.map(\.chapterID) == [
            "chapter-1",
            "chapter-2",
            "chapter-3",
            "chapter-4",
            "chapter-5"
        ])
        #expect(viewModel.competencyItems.map(\.score) == [3, 2, 1, 3, 0])
        #expect(viewModel.totalStars == 9)
        #expect(viewModel.completedChapterCount == 4)
        #expect(viewModel.completedStoryCount == 0)
    }

    /// Given all five playable chapters are completed, then Statistics reports
    /// the playable story as completed and sums all collected stars.
    @Test func completedStoryCountReflectsFullyCompletedPlayableStory() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        storage.updateUserStats { stats in
            for chapterID in ["chapter-1", "chapter-2", "chapter-3", "chapter-4", "chapter-5"] {
                stats.recordCompletedGame(chapterID: chapterID, earnedStars: 3)
            }
        }

        #expect(viewModel.totalStars == 15)
        #expect(viewModel.completedChapterCount == 5)
        #expect(viewModel.completedStoryCount == 1)
    }

    /// Every displayed competency must have static parent-facing guidance, since
    /// the Statistics detail pane depends on that content and it is not stored in
    /// persisted `UserStats`.
    @Test func guidanceExistsForEveryDisplayedCompetency() throws {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        storage.updateUserStats { stats in
            for chapterID in ["chapter-1", "chapter-2", "chapter-3", "chapter-4", "chapter-5"] {
                stats.recordCompletedGame(chapterID: chapterID, earnedStars: 3)
            }
        }

        for item in viewModel.competencyItems {
            let guidance = try #require(viewModel.guidance(for: item.competency, score: item.score))
            #expect(guidance.learningSummary.isEmpty == false)
            #expect(guidance.masteredItems.isEmpty == false)
            #expect(guidance.practiceItems.isEmpty == false)
            #expect(guidance.parentTip.isEmpty == false)
        }
    }
}
