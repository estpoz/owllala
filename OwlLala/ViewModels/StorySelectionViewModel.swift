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
                    thumbnailAssetName: "", competency: .brightnessContrast,
                    storyPages: [
                        StoryPage(
                            id: "chapter-3-page-1",
                            order: 1,
                            illustrationAssetName: "page3-1",
                            narration: "Lala mencari bekalnya di area loker, tetapi karena suasananya gelap, Lala sulit melihat dengan jelas barang-barang di sekitarnya.",
                            voiceOverAssetName: "chapter3-1"
                        ),
                        StoryPage(
                            id: "chapter-3-page-2",
                            order: 2,
                            illustrationAssetName: "page3-2",
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari benda berdasarkan simbol, bukan warna.",
                            voiceOverAssetName: "chapter3-2"
                        ),
                        StoryPage(
                            id: "chapter-3-page-3",
                            order: 3,
                            illustrationAssetName: "page3-3",
                            narration: "Lala memperhatikan dengan saksama simbol-simbol yang ada di lorong sekolah.",
                            voiceOverAssetName: "chapter3-3"
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-3-question",
                            prompt: "Pilih barang yang mencolok paling jelas!",
                            promptImageAssetName: nil,
                            answerOptions: [
                                AnswerOption(id: "bottle", text: nil, imageAssetName: "game3Icon1"),
                                AnswerOption(id: "book", text: nil, imageAssetName: "game3Icon2"),
                                AnswerOption(id: "lunchbox", text: nil, imageAssetName: "game3Icon4"),
                                AnswerOption(id: "ruler", text: nil, imageAssetName: "game3Icon3")
                            ],
                            correctAnswerID: "lunchbox",
                            hintText: "Coba perhatikan kontrasnya. Cari benda yang terlihat paling jelas dari sekitarnya."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala berhasil melihat barang yang paling jelas!",
                        explanation: "Kamu membedakan benda berdasarkan tingkat terang dan gelapnya.",
                        mainIllustrationAssetName: "game3Icon4",
                        exampleAssetNames: ["game3Icon1", "game3Icon2", "game3Icon4"]
                    )
                ),
                Chapter(
                    id: "chapter-4", order: 4,
                    title: "Pola Rahasia di Taman Bermain", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .pattern,
                    storyPages: [
                        StoryPage(
                            id: "chapter-4-page-1",
                            order: 1,
                            illustrationAssetName: "page4-1",
                            narration: "Lala sudah sampai di area playground dan menemukan banyak sekali tas dan kotak makan.",
                            voiceOverAssetName: "chapter4-1"
                        ),
                        StoryPage(
                            id: "chapter-4-page-2",
                            order: 2,
                            illustrationAssetName: "page4-2",
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari lokasi benda berdasarkan pola, bukan warna.",
                            voiceOverAssetName: "chapter4-2"
                        ),
                        StoryPage(
                            id: "chapter-4-page-3",
                            order: 3,
                            illustrationAssetName: "page4-3",
                            narration: "Lala memperhatikan dengan saksama pola yang ada dan teringat dengan detail dari tas miliknya.",
                            voiceOverAssetName: "chapter4-3"
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-4-question",
                            prompt: "Tas mana yang cocok dengan pola ini?",
                            promptImageAssetName: "game4Icon5",
                            answerOptions: [
                                AnswerOption(id: "rabbit-bag", text: nil, imageAssetName: "game4Icon1"),
                                AnswerOption(id: "owl-bag", text: nil, imageAssetName: "game4Icon2"),
                                AnswerOption(id: "striped-bag", text: nil, imageAssetName: "game4Icon3"),
                                AnswerOption(id: "yellow-bag", text: nil, imageAssetName: "game4Icon4")
                            ],
                            correctAnswerID: "striped-bag",
                            hintText: "Coba perhatikan polanya. Cari tas yang punya garis sama seperti contoh."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala menemukan tas dengan pola yang sama!",
                        explanation: "Kamu mengenali perbedaan melalui pola dan tekstur permukaan.",
                        mainIllustrationAssetName: "game4Icon3",
                        exampleAssetNames: ["game4Icon1", "game4Icon3", "game4Icon4"]
                    )
                ),
                Chapter(
                    id: "chapter-5", order: 5,
                    title: "Misi Besar di Kantin Sekolah", subtitle: nil, description: "",
                    thumbnailAssetName: "", competency: .context,
                    storyPages: [
                        StoryPage(
                            id: "chapter-5-page-1",
                            order: 1,
                            illustrationAssetName: "page5-1",
                            narration: "Lala sampai di kantin dan melihat banyaknya kotak makan di meja.",
                            voiceOverAssetName: "chapter5-1"
                        ),
                        StoryPage(
                            id: "chapter-5-page-2",
                            order: 2,
                            illustrationAssetName: "page5-2",
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari benda berdasarkan semua petunjuk: bentuk, warna, dan pola.",
                            voiceOverAssetName: "chapter5-2"
                        ),
                        StoryPage(
                            id: "chapter-5-page-3",
                            order: 3,
                            illustrationAssetName: "page5-3",
                            narration: "Lala memperhatikan dengan saksama semua detail dari barang yang sudah diambilnya dan mengingat semua detail penting.",
                            voiceOverAssetName: "chapter5-3"
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-5-question",
                            prompt: "Cari kotak makan Lala di kantin sekolah",
                            promptImageAssetName: nil,
                            answerOptions: [
                                AnswerOption(id: "pink-lunchbox", text: nil, imageAssetName: "game5Icon1"),
                                AnswerOption(id: "purple-pouch", text: nil, imageAssetName: "game5Icon3"),
                                AnswerOption(id: "blue-bag", text: nil, imageAssetName: "game5icon4"),
                                AnswerOption(id: "blue-lunchbox", text: nil, imageAssetName: "game5Icon2")
                            ],
                            correctAnswerID: "blue-lunchbox",
                            hintText: "Coba perhatikan bentuknya. Cari kotak makan yang kotak, biru, dan bergaris."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala menemukan kotak makannya!",
                        explanation: "Kamu menggabungkan bentuk, warna, dan pola untuk mengenali benda dalam situasi sehari-hari.",
                        mainIllustrationAssetName: "game5Icon2",
                        exampleAssetNames: ["game5Icon1", "game5icon4", "game5Icon2"]
                    )
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
