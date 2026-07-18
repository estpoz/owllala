import Combine
import Foundation

struct StorySelectionItem: Identifiable, Hashable {
    let story: Story
    let isAvailable: Bool

    var id: String { story.id }
}

@MainActor
final class StorySelectionViewModel: ObservableObject {
    @Published var selectedStory: Story?

    // MARK: - Centralized Story Catalog Storage Core
    private let stories: [Story] = [
        Story(
            id: "story-1",
            order: 1,
            title: "Cerita 1",
            subtitle: "Hilangnya Kotak Bekal",
            description: "Bantu Lala menemukan kotak bekalnya menggunakan berbagai petunjuk visual.",
            coverAssetName: "story_1_cover",
            availability: .available,
            chapters: [
                Chapter(
                    id: "chapter-1", order: 1,
                    title: "Bentuk Membantu Mika di Kelas", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .shape, storyPages: [],
                    gameConfiguration: GameConfiguration(question: GameQuestion(id: "q1", prompt: "Mana yang berbentuk kotak?", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                    learningSummary: LearningSummary(successMessage: "Lala menemukan kotak makannya!", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
                ),
                Chapter(
                    id: "chapter-2", order: 2,
                    title: "Ikuti Tanda di Lorong Sekolah", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .labelSymbol, storyPages: [],
                    gameConfiguration: GameConfiguration(question: GameQuestion(id: "q2", prompt: "Ikuti panah penunjuk jalan!", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                    learningSummary: LearningSummary(successMessage: "Kamu berhasil melewati lorong!", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
                ),
                Chapter(
                    id: "chapter-3", order: 3,
                    title: "Cahaya Kecil di Loker Gelap", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .brightnessContrast, storyPages: [],
                    gameConfiguration: GameConfiguration(question: GameQuestion(id: "q3", prompt: "Cari benda yang paling terang!", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                    learningSummary: LearningSummary(successMessage: "Loker berhasil diterangi!", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
                ),
                Chapter(
                    id: "chapter-4", order: 4,
                    title: "Pola Rahasia di Taman Bermain", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .pattern, storyPages: [],
                    gameConfiguration: GameConfiguration(question: GameQuestion(id: "q4", prompt: "Pasangkan pola yang sama!", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                    learningSummary: LearningSummary(successMessage: "Pola rahasia terpecahkan!", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
                ),
                Chapter(
                    id: "chapter-5", order: 5,
                    title: "Misi Besar di Kantin Sekolah", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .context, storyPages: [],
                    gameConfiguration: GameConfiguration(question: GameQuestion(id: "q5", prompt: "Di mana sendok makan disimpan?", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                    learningSummary: LearningSummary(successMessage: "Misi kantin selesai sempurna!", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
                )
            ],
            completionSummary: nil
        ),
        Story(
            id: "story-2",
            order: 2,
            title: "Cerita 2",
            subtitle: "Segera Hadir",
            description: "Petualangan baru akan segera hadir pada pembaruan aplikasi berikutnya.",
            coverAssetName: "story_2_cover",
            availability: .comingSoon,
            chapters: [],
            completionSummary: nil
        ),
        Story(
            id: "story-3",
            order: 3,
            title: "Cerita 3",
            subtitle: "Segera Hadir",
            description: "Petualangan seru lainnya sedang dipersiapkan untukmu.",
            coverAssetName: "story_3_cover",
            availability: .comingSoon,
            chapters: [],
            completionSummary: nil
        )
    ]

    var items: [StorySelectionItem] {
        stories.map { story in
            StorySelectionItem(story: story, isAvailable: story.isAvailable)
        }
    }

    init() {}

    func selectStory(_ story: Story) {
        guard story.isAvailable else {
            selectedStory = nil
            return
        }
        selectedStory = story
    }

    func clearSelection() {
        selectedStory = nil
    }
}
