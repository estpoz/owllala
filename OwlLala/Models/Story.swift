//
//  Story.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Story

/// Represents one learning story displayed in Main Story mode.
///
/// An available story contains exactly five ordered chapters and an optional
/// completion summary shown after the final chapter is completed.
///
/// Story completion and Training Mode availability are not stored here.
/// They are derived from chapter progress in `UserStats`.
struct Story: Identifiable, Codable, Hashable, Sendable {

    /// A stable identifier used for navigation and progress lookup.
    ///
    /// Example: `"story-1"`
    let id: String

    /// The story's position on the story-selection screen.
    ///
    /// The first story should use `1`.
    let order: Int

    /// The title displayed on the story-selection screen.
    let title: String

    /// Optional supporting text displayed below the story title.
    let subtitle: String?

    /// A short explanation of the story's learning journey.
    let description: String

    /// The asset-catalog name of the story's cover illustration.
    ///
    /// This asset is only used on the story-selection screen.
    let coverAssetName: String

    /// Indicates whether the story can currently be played.
    ///
    /// For the MVP, Story 1 is available while Story 2 and Story 3 are
    /// displayed as locked coming-soon content.
    let availability: StoryAvailability

    /// The chapters included in this story.
    ///
    /// An available story contains exactly five chapters in presentation
    /// order. A coming-soon story may use an empty array.
    let chapters: [Chapter]

    /// Content displayed after the final chapter is completed.
    ///
    /// This value is available for playable stories and `nil` for
    /// coming-soon stories.
    let completionSummary: StoryCompletionSummary?

    /// Indicates whether the story can be selected and played.
    var isAvailable: Bool {
        availability == .available
    }

    /// The maximum number of stars available across all chapters.
    ///
    /// Each chapter can award up to `Chapter.maximumStars`.
    var totalAvailableStars: Int {
        chapters.count * Chapter.maximumStars
    }
}

// MARK: - Story Availability

/// Describes whether a story can currently be played.
enum StoryAvailability: String, Codable, Hashable, Sendable {

    /// The story contains playable chapter content.
    case available

    /// The story is visible but cannot be played yet.
    case comingSoon
}

// MARK: - Story Completion Summary

/// Contains the content shown after every chapter in a story is completed.
///
/// This summary appears only after completing the final chapter through
/// Main Story mode. Completing a game through Training Mode does not present
/// this screen.
///
/// The current MVP contains one implementation of the summary screen, but its
/// content remains part of the story model rather than being hard-coded into
/// the view.
struct StoryCompletionSummary: Codable, Hashable, Sendable {

    /// The main completion heading.
    ///
    /// Example: `"Hebat! Cerita 1 Selesai!"`
    let title: String

    /// The introductory reflection displayed below the heading.
    let message: String

    /// The asset-catalog name of the main mascot illustration.
    let mascotAssetName: String

    /// The five competency summaries presented on the completion screen.
    ///
    /// Their order should follow the learning order of the story's chapters.
    let competencyItems: [StoryCompetencySummary]

    /// The final encouragement displayed below the competency summaries.
    let closingMessage: String

    /// The optional asset-catalog name of the closing-message icon.
    let closingIconAssetName: String?
}

// MARK: - Story Competency Summary

/// Represents one competency card on the story-completion screen.
struct StoryCompetencySummary: Identifiable, Codable, Hashable, Sendable {

    /// Uses the competency as the stable identifier for the summary item.
    var id: Competency {
        competency
    }

    /// The competency represented by this summary item.
    let competency: Competency

    /// The child-friendly title displayed on the summary card.
    ///
    /// This may be more descriptive than `Competency.displayName`.
    ///
    /// Example: `"Tulisan, Simbol, dan Label"`
    let title: String

    /// A short explanation of how the competency helps identify objects.
    let explanation: String

    /// The asset-catalog name of the competency icon.
    let iconAssetName: String
}

// MARK: - Story Catalog

/// Shared static story content used by story selection, training, and statistics.
///
/// This content is not persisted. Mutable progress stays in `StorageService` and
/// `UserStats`; this catalog only describes the fixed MVP stories and chapters.
enum StoryCatalog {

    static let stories: [Story] = [
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
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari lokasi benda berdasarkan kontras, bukan warna.",
                            voiceOverAssetName: "chapter3-2"
                        ),
                        StoryPage(
                            id: "chapter-3-page-3",
                            order: 3,
                            illustrationAssetName: "page3-3",
                            narration: "Lala memperhatikan dengan saksama barang-barang yang ada di loker gelap tersebut.",
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
                            correctAnswerID: "blue-bag",
                            hintText: "Coba perhatikan bentuknya. Cari kotak makan yang kotak, biru, dan bergaris."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala menemukan kotak makannya!",
                        explanation: "Kamu menggabungkan bentuk, warna, dan pola untuk mengenali benda dalam situasi sehari-hari.",
                        mainIllustrationAssetName: "game5icon4",
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
}


//Contoh data story:
//let storyOne = Story(
//    id: "story-1",
//    order: 1,
//    title: "Cerita 1",
//    subtitle: "Hilangnya Kotak Bekal",
//    description: "Bantu Lala menemukan kotak bekalnya menggunakan berbagai petunjuk visual.",
//    coverAssetName: "story_1_cover",
//    availability: .available,
//    chapters: [
//        chapterOne,
//        chapterTwo,
//        chapterThree,
//        chapterFour,
//        chapterFive
//    ],
//    completionSummary: StoryCompletionSummary(
//        title: "Hebat! Cerita 1 Selesai!",
//        message: "Kamu sudah belajar mengenali benda tanpa bergantung pada warna. Yuk, lihat apa saja yang sudah kamu kuasai!",
//        mascotAssetName: "cluey_story_completion",
//        competencyItems: [
//            StoryCompetencySummary(
//                competency: .shape,
//                title: "Bentuk",
//                explanation: "Mengenali objek berdasarkan bentuknya.",
//                iconAssetName: "competency_shape"
//            ),
//            StoryCompetencySummary(
//                competency: .labelSymbol,
//                title: "Tulisan, Simbol, dan Label",
//                explanation: "Menggunakan tulisan, simbol, dan label sebagai petunjuk arah.",
//                iconAssetName: "competency_label_symbol"
//            ),
//            StoryCompetencySummary(
//                competency: .brightnessContrast,
//                title: "Terang dan Gelap (Kontras)",
//                explanation: "Membedakan benda berdasarkan tingkat terang dan gelapnya.",
//                iconAssetName: "competency_brightness_contrast"
//            ),
//            StoryCompetencySummary(
//                competency: .pattern,
//                title: "Pola dan Tekstur",
//                explanation: "Menemukan perbedaan melalui pola dan tekstur permukaan.",
//                iconAssetName: "competency_pattern"
//            ),
//            StoryCompetencySummary(
//                competency: .context,
//                title: "Menggabungkan Semua Petunjuk",
//                explanation: "Menggabungkan semua petunjuk untuk mengenali benda dalam situasi sehari-hari.",
//                iconAssetName: "competency_context"
//            )
//        ],
//        closingMessage: "Sekarang kamu tahu bahwa warna bukan satu-satunya cara untuk mengenali dunia di sekitarmu. Terus gunakan berbagai petunjuk ini di petualangan berikutnya!",
//        closingIconAssetName: "story_completion_lightbulb"
//    )
//)
//
//Contoh placeholder story:
//let storyTwo = Story(
//    id: "story-2",
//    order: 2,
//    title: "Cerita 2",
//    subtitle: "Segera Hadir",
//    description: "Cerita baru akan hadir pada pembaruan berikutnya.",
//    coverAssetName: "story_2_cover",
//    availability: .comingSoon,
//    chapters: [],
//    completionSummary: nil
//)
