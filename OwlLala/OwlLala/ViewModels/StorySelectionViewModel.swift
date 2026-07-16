//
//  StorySelectionViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Story Selection Item

struct StorySelectionItem: Identifiable, Hashable {
    let story: Story
    let isAvailable: Bool

    var id: String {
        story.id
    }
}

// MARK: - Story Selection View Model

/// Presents stories in their static order and prevents navigation into coming-soon stories.
@MainActor
final class StorySelectionViewModel: ObservableObject {

    @Published private(set) var selectedStory: Story?

    private let stories: [Story]

    var items: [StorySelectionItem] {
        stories.map { story in
            StorySelectionItem(
                story: story,
                isAvailable: story.availability == .available
            )
        }
    }

    init(stories: [Story]) {
        self.stories = stories
    }

    func selectStory(_ story: Story) {
        guard story.availability == .available else {
            selectedStory = nil
            return
        }

        selectedStory = story
    }

    func clearSelection() {
        selectedStory = nil
    }
}


