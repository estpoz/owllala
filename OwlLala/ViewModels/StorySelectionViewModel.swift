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
                    thumbnailAssetName: "", competency: .shape,
                    storyPages: [
                        StoryPage(
                            id: "chapter-1-page-1",
                            order: 1,
                            illustrationAssetName: "page1-1",
                            narration: "Lala membuka laci mejanya untuk mengambil bekal, tetapi bekalnya tidak ada di sana!",
                            voiceOverAssetName: "chapter1-1"
                        ),
                        StoryPage(
                            id: "chapter-1-page-2",
                            order: 2,
                            illustrationAssetName: "page1-2",
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari benda berdasarkan bentuk, bukan warna.",
                            voiceOverAssetName: "chapter1-2"
                        ),
                        StoryPage(
                            id: "chapter-1-page-3",
                            order: 3,
                            illustrationAssetName: "page1-3",
                            narration: "Lala mencoba mengingat bentuk bekalnya dan menyadari bahwa bekalnya berbentuk seperti kotak kecil dengan pegangan.",
                            voiceOverAssetName: "chapter1-3"
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-1-question",
                            prompt: "Objek mana yang cocok dengan bayangan ini?",
                            promptImageAssetName: "lunchboxSilhouette",
                            answerOptions: [
                                AnswerOption(id: "book", text: nil, imageAssetName: "game1Icon2"),
                                AnswerOption(id: "backpack", text: nil, imageAssetName: "game1Icon3"),
                                AnswerOption(id: "lunchbox", text: nil, imageAssetName: "lunchbox"),
                                AnswerOption(id: "bottle", text: nil, imageAssetName: "game1Icon1")
                            ],
                            correctAnswerID: "lunchbox",
                            hintText: "Coba perhatikan bentuknya. Cari benda yang kotak dan punya pegangan seperti bayangannya."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala menemukan kotak makannya!",
                        explanation: "Kamu mengenali objek berdasarkan bentuknya, bukan warnanya.",
                        mainIllustrationAssetName: "lunchbox",
                        exampleAssetNames: ["game1Icon2", "game1Icon3", "lunchbox"]
                    )
                ),
                Chapter(
                    id: "chapter-2", order: 2,
                    title: "Ikuti Tanda di Lorong Sekolah", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .labelSymbol,
                    storyPages: [
                        StoryPage(
                            id: "chapter-2-page-1",
                            order: 1,
                            illustrationAssetName: "page2-1",
                            narration: "Lala menemukan selembar catatan yang dapat membantu pencariannya.",
                            voiceOverAssetName: "chapter2-1"
                        ),
                        StoryPage(
                            id: "chapter-2-page-2",
                            order: 2,
                            illustrationAssetName: "page2-2",
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari lokasi benda berdasarkan simbol, bukan warna.",
                            voiceOverAssetName: "chapter2-2"
                        ),
                        StoryPage(
                            id: "chapter-2-page-3",
                            order: 3,
                            illustrationAssetName: "page2-3",
                            narration: "Lala memperhatikan dengan saksama simbol-simbol yang ada di lorong sekolah.",
                            voiceOverAssetName: "chapter2-3"
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-2-question",
                            prompt: "Tanda mana yang menunjukkan arah ke kantin?",
                            promptImageAssetName: nil,
                            answerOptions: [
                                AnswerOption(id: "loker", text: "Loker", imageAssetName: "game2Icon1"),
                                AnswerOption(id: "taman-bermain", text: "Taman Bermain", imageAssetName: "game2Icon2"),
                                AnswerOption(id: "kantin", text: "Kantin", imageAssetName: "game2Icon3"),
                                AnswerOption(id: "uks", text: "UKS", imageAssetName: "game2Icon4")
                            ],
                            correctAnswerID: "kantin",
                            hintText: "Coba cari tanda yang gambarnya berhubungan dengan tempat makan."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala berhasil mengikuti tanda kantin!",
                        explanation: "Kamu menggunakan simbol sebagai petunjuk untuk menemukan tempat yang tepat.",
                        mainIllustrationAssetName: "game2Icon3",
                        exampleAssetNames: ["game2Icon1", "game2Icon2", "game2Icon3", "game2Icon4"]
                    )
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
