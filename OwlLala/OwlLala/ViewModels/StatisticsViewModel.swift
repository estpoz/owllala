//
//  StatisticsViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Competency Progress Item

struct CompetencyProgressItem: Identifiable, Hashable {
    let competency: Competency
    let score: Int
    let maximumScore: Int
    let chapterID: String

    var id: Competency {
        competency
    }
}

// MARK: - Competency Guidance

struct CompetencyGuidance: Identifiable, Hashable {
    let competency: Competency
    let learningSummary: String
    let masteredItems: [String]
    let practiceItems: [String]
    let parentTip: String

    var id: Competency {
        competency
    }
}

// MARK: - Static Statistics Guidance

enum StatisticsGuidanceContent {

    static let guidanceItems: [CompetencyGuidance] = [
        CompetencyGuidance(
            competency: .shape,
            learningSummary: "Anak belajar mengenali benda dari bentuk dan garis luarnya.",
            masteredItems: [
                "Membedakan benda dengan bentuk berbeda.",
                "Menggunakan siluet sebagai petunjuk."
            ],
            practiceItems: [
                "Cari benda di rumah yang bentuknya mirip.",
                "Bandingkan bentuk sebelum melihat warna."
            ],
            parentTip: "Ajak anak menyebut bentuk utama sebuah benda sebelum menyebut warnanya."
        ),
        CompetencyGuidance(
            competency: .pattern,
            learningSummary: "Anak belajar memakai pola dan tekstur sebagai petunjuk visual.",
            masteredItems: [
                "Mengenali garis, titik, dan motif berulang.",
                "Memakai tekstur untuk membedakan objek."
            ],
            practiceItems: [
                "Bandingkan benda polos dan bermotif.",
                "Cari pola yang berulang pada pakaian atau mainan."
            ],
            parentTip: "Tanyakan pola apa yang terlihat sebelum membantu anak memilih benda."
        ),
        CompetencyGuidance(
            competency: .brightnessContrast,
            learningSummary: "Anak belajar memperhatikan terang, gelap, dan kontras.",
            masteredItems: [
                "Membedakan area terang dan gelap.",
                "Memakai kontras untuk menemukan objek."
            ],
            practiceItems: [
                "Cari benda yang terlihat jelas karena kontras.",
                "Bandingkan gambar dengan tingkat terang berbeda."
            ],
            parentTip: "Bantu anak melihat perbedaan terang dan gelap tanpa menebak warna."
        ),
        CompetencyGuidance(
            competency: .labelSymbol,
            learningSummary: "Anak belajar membaca label, tulisan, dan simbol sebagai petunjuk.",
            masteredItems: [
                "Memakai ikon untuk mengenali fungsi benda.",
                "Memperhatikan tulisan atau label sederhana."
            ],
            practiceItems: [
                "Cari simbol pada kemasan atau papan tanda.",
                "Cocokkan ikon dengan fungsi benda."
            ],
            parentTip: "Arahkan anak ke simbol atau label saat warna sulit dibedakan."
        ),
        CompetencyGuidance(
            competency: .context,
            learningSummary: "Anak belajar memakai tempat dan situasi untuk mengenali benda.",
            masteredItems: [
                "Menghubungkan benda dengan lokasi biasanya.",
                "Menggunakan beberapa petunjuk sekaligus."
            ],
            practiceItems: [
                "Tebak benda dari tempat ditemukannya.",
                "Gabungkan bentuk, pola, label, dan konteks."
            ],
            parentTip: "Tanyakan di mana benda biasanya dipakai untuk membantu anak menalar jawabannya."
        )
    ]

    static func guidance(for competency: Competency) -> CompetencyGuidance? {
        guidanceItems.first { $0.competency == competency }
    }
}

// MARK: - Statistics View Model

/// Transforms static chapter content and persisted progress into statistics presentation data.
@MainActor
final class StatisticsViewModel: ObservableObject {

    let stories: [Story]

    private let storageService: StorageService
    private var cancellables: Set<AnyCancellable> = []

    var totalStars: Int {
        storageService.userStats.totalStars
    }

    var completedChapterCount: Int {
        storageService.userStats.completedChapterCount
    }

    var completedStoryCount: Int {
        storageService.userStats.completedStoryCount(in: stories)
    }

    var competencyItems: [CompetencyProgressItem] {
        playableChapters.map { chapter in
            CompetencyProgressItem(
                competency: chapter.competency,
                score: storageService.userStats.competencyScore(for: chapter),
                maximumScore: 5,
                chapterID: chapter.id
            )
        }
    }

    var guidanceItems: [CompetencyGuidance] {
        StatisticsGuidanceContent.guidanceItems
    }

    private var playableChapters: [Chapter] {
        stories
            .filter { $0.availability == .available }
            .flatMap(\.chapters)
    }

    init(
        stories: [Story],
        storageService: StorageService
    ) {
        self.stories = stories
        self.storageService = storageService

        storageService.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    func guidance(for competency: Competency) -> CompetencyGuidance? {
        StatisticsGuidanceContent.guidance(for: competency)
    }
}
