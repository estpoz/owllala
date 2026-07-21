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
            learningSummary: "Kemampuan anak dalam mengenali bentuk sudah baik. Anak mampu menggunakan bentuk, outline, dan siluet sebagai petunjuk untuk mengenali objek. Anak sudah cukup mandiri dalam membedakan benda berdasarkan bentuk, tetapi masih perlu latihan pada objek yang bentuknya mirip atau memiliki detail kecil.",
            masteredItems: [
                "Anak mampu mengenali bentuk dasar pada benda sehari-hari.",
                "Anak dapat mencocokkan siluet dengan objek yang sesuai.",
                "Anak mampu membedakan benda berwarna mirip berdasarkan bentuk.",
                "Anak mulai menggunakan bentuk sebagai petunjuk utama sebelum melihat warna."
            ],
            practiceItems: [
                "Anak masih perlu latihan membedakan objek dengan bentuk yang hampir sama.",
                "Anak perlu lebih teliti melihat detail bentuk kecil seperti sisi, ujung, atau lengkungan.",
                "Anak perlu dilatih menggunakan bentuk bersama petunjuk lain seperti pola, teks, atau kontras."
            ],
            parentTip: "Latih anak mengenali benda dari bentuknya sebelum membahas warna. Gunakan pertanyaan seperti: \"Bentuknya bulat atau kotak?\", \"Panjang atau pendek?\", atau \"Kalau dari bayangannya saja, ini benda apa?\""
        ),
        CompetencyGuidance(
            competency: .pattern,
            learningSummary: "Kemampuan anak dalam mengenali pola dan tekstur masih perlu ditingkatkan. Anak sudah mulai memperhatikan pola seperti garis, titik, atau motif sederhana, tetapi masih sering tertukar dan belum konsisten menggunakan pola sebagai petunjuk. Area ini adalah salah satu petunjuk visual non-warna yang perlu lebih sering dilatih.",
            masteredItems: [
                "Anak mulai menyadari bahwa benda bisa memiliki pola atau tekstur.",
                "Anak dapat mengenali pola yang sangat jelas.",
                "Anak mulai memahami bahwa warna yang mirip bisa dibedakan melalui motif."
            ],
            practiceItems: [
                "Anak masih perlu banyak latihan mencocokkan pola yang sama.",
                "Anak masih kesulitan membedakan pola yang mirip.",
                "Anak masih cenderung menebak saat warna benda terlihat sama.",
                "Anak perlu lebih teliti melihat detail seperti garis, titik, kotak, dan tekstur permukaan."
            ],
            parentTip: "Mulai dari latihan sederhana dengan dua pilihan saja. Gunakan baju, tas, buku, gelas, atau mainan berpola. Tanyakan: \"Mana yang bergaris?\", \"Mana yang bertitik?\", atau \"Motifnya sama atau berbeda?\""
        ),
        CompetencyGuidance(
            competency: .brightnessContrast,
            learningSummary: "Kemampuan anak dalam membedakan kecerahan dan kontras sudah cukup berkembang. Anak mulai bisa melihat perbedaan terang, gelap, dan objek yang lebih jelas dari background. Namun, kemampuan ini belum kuat pada perbedaan yang halus. Anak masih perlu latihan untuk membedakan shade yang mirip dan objek dengan kontras rendah.",
            masteredItems: [
                "Anak mulai dapat membedakan benda yang lebih terang dan lebih gelap.",
                "Anak dapat menemukan objek yang terlihat lebih jelas dari background.",
                "Anak mulai memahami bahwa kontras dapat membantu saat warna tidak jelas."
            ],
            practiceItems: [
                "Anak masih perlu latihan membedakan shade yang hampir sama.",
                "Anak masih perlu meningkatkan kemampuan mengenali objek dengan kontras rendah.",
                "Anak perlu membiasakan diri membandingkan terang-gelap sebelum memilih.",
                "Anak perlu mengurangi ketergantungan pada warna yang terlihat."
            ],
            parentTip: "Latih anak membandingkan benda terang dan gelap di rumah. Tanyakan: \"Mana yang lebih terang?\", \"Mana yang lebih gelap?\", atau \"Mana yang paling jelas terlihat dari background?\" Gunakan senter kecil untuk latihan mencari benda di area redup."
        ),
        CompetencyGuidance(
            competency: .labelSymbol,
            learningSummary: "Kemampuan anak dalam menggunakan teks dan label sudah berada di tingkat cukup berkembang. Anak sudah mulai memahami bahwa tulisan dapat membantu mengenali benda, tempat, atau arah saat warna tidak jelas. Namun, kemampuan ini belum konsisten. Anak masih perlu latihan agar lebih teliti membaca label dan tidak langsung menebak.",
            masteredItems: [
                "Anak sudah mulai mengenali tulisan dan label sederhana.",
                "Anak dapat menggunakan teks sebagai petunjuk tambahan.",
                "Anak mulai memahami bahwa tulisan bisa membantu memastikan pilihan."
            ],
            practiceItems: [
                "Anak masih perlu meningkatkan ketelitian saat membaca label.",
                "Anak masih perlu latihan menghubungkan tulisan dengan fungsi benda atau tempat.",
                "Anak masih perlu mengurangi kebiasaan menebak berdasarkan warna, posisi, atau bentuk."
            ],
            parentTip: "Latih anak membaca label sederhana di rumah atau tempat umum, seperti nama ruangan, label buku, menu, papan arah, atau kemasan makanan. Minta anak menjawab berdasarkan tulisan, bukan warna."
        ),
        CompetencyGuidance(
            competency: .context,
            learningSummary: "Kemampuan anak dalam memahami simbol dan ikon sudah sangat baik. Anak mampu mengenali simbol umum, memahami maknanya, dan menggunakan ikon sebagai petunjuk visual secara mandiri. Ini menunjukkan bahwa simbol adalah salah satu kekuatan utama anak dalam mengenali informasi tanpa bergantung pada warna.",
            masteredItems: [
                "Anak mampu mengenali simbol umum dengan sangat baik.",
                "Anak dapat menghubungkan ikon dengan arti, tempat, atau fungsi.",
                "Anak mampu mengikuti petunjuk visual seperti panah atau tanda arah.",
                "Anak dapat menggunakan simbol sebagai petunjuk utama saat warna tidak jelas."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih dengan simbol yang lebih kompleks.",
                "Anak perlu dibiasakan menggunakan simbol di situasi nyata yang lebih ramai.",
                "Anak dapat dilatih menggabungkan simbol dengan teks, bentuk, dan arah."
            ],
            parentTip: "Gunakan kemampuan ini dalam kehidupan nyata. Saat di sekolah, mall, rumah sakit, atau restoran, minta anak membaca simbol seperti toilet, kantin, keluar, tangga, lift, atau panah arah."
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

    /// The fixed presentation order for Statistics, matching Story 1 chapter order.
    static let competencyOrder: [Competency] = [
        .shape,
        .labelSymbol,
        .brightnessContrast,
        .pattern,
        .context
    ]

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
        Self.competencyOrder.map { competency in
            if let chapter = playableChapters.first(where: { $0.competency == competency }) {
                return CompetencyProgressItem(
                    competency: chapter.competency,
                    score: storageService.userStats.competencyScore(for: chapter),
                    maximumScore: Chapter.maximumStars,
                    chapterID: chapter.id
                )
            }

            return CompetencyProgressItem(
                competency: competency,
                score: 0,
                maximumScore: Chapter.maximumStars,
                chapterID: ""
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

    func competencyItem(for competency: Competency) -> CompetencyProgressItem? {
        competencyItems.first { $0.competency == competency }
    }
}
