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
    let score: Int
    let learningSummary: String
    let masteredItems: [String]
    let practiceItems: [String]
    let parentTip: String

    var id: String {
        "\(competency.rawValue)-\(score)"
    }
}

// MARK: - Static Statistics Guidance

enum StatisticsGuidanceContent {

    static let guidanceItems: [CompetencyGuidance] = [
        CompetencyGuidance(
            competency: .shape,
            score: 1,
            learningSummary: "Anak mulai mengenali benda dari bentuk dasarnya. Saat pilihan terlihat sangat berbeda, anak sudah dapat menangkap petunjuk bentuk dengan lebih mudah. Namun, ketika beberapa benda memiliki outline yang mirip, anak masih membutuhkan arahan untuk memperhatikan detail sebelum memilih.",
            masteredItems: [
                "Anak mulai memperhatikan bentuk besar pada benda, seperti bulat, kotak, panjang, atau pendek.",
                "Anak dapat mengenali perbedaan bentuk yang sangat jelas ketika pilihannya tidak terlalu mirip.",
                "Anak mulai mencoba melihat bentuk sebelum melihat warna, terutama saat diberi contoh atau arahan.",
                "Anak mulai memahami bahwa bayangan atau outline bisa membantu mengenali benda."
            ],
            practiceItems: [
                "Anak masih perlu bantuan saat bentuk benda terlihat mirip atau memiliki ukuran yang hampir sama.",
                "Anak perlu latihan mencocokkan siluet dengan objek yang sesuai secara bertahap.",
                "Anak perlu lebih teliti melihat detail seperti pegangan, ujung, sisi benda, atau lengkungan kecil.",
                "Anak perlu dibiasakan menyebutkan bentuk yang dilihat sebelum menentukan jawaban."
            ],
            parentTip: "Latih dengan dua benda yang bentuknya sangat berbeda, lalu tanyakan: \"Mana yang bulat?\", \"Mana yang kotak?\", atau \"Mana yang punya pegangan?\" Setelah anak mulai yakin, tambahkan benda ketiga yang bentuknya lebih mirip agar anak belajar melihat detail kecil."
        ),
        CompetencyGuidance(
            competency: .shape,
            score: 2,
            learningSummary: "Anak sudah cukup mampu menggunakan bentuk, outline, dan siluet untuk mengenali benda. Anak mulai dapat memilih berdasarkan bentuk meskipun warna tidak menjadi petunjuk utama. Latihan berikutnya dapat difokuskan pada benda yang mirip agar anak semakin teliti melihat detail kecil.",
            masteredItems: [
                "Anak mampu mengenali beberapa bentuk dasar pada benda sehari-hari dengan cukup konsisten.",
                "Anak dapat menggunakan siluet sebagai petunjuk tambahan saat warna kurang membantu.",
                "Anak mulai membedakan benda berwarna mirip berdasarkan bentuk luarnya.",
                "Anak mulai memperhatikan bagian khas pada benda, seperti pegangan, sudut, atau ukuran."
            ],
            practiceItems: [
                "Anak masih perlu latihan pada benda yang bentuknya hampir sama agar tidak terburu-buru memilih.",
                "Anak perlu memperhatikan detail kecil seperti lengkungan, sudut, ukuran, atau pegangan.",
                "Anak perlu membiasakan diri mengecek bentuk sebelum memilih jawaban.",
                "Anak dapat dilatih membandingkan dua benda dan menyebutkan satu perbedaan bentuknya."
            ],
            parentTip: "Ajak anak membandingkan benda yang bentuknya mirip, seperti tas dan kotak makan, lalu cari perbedaan pada sisi, pegangan, ujung, atau ukuran. Dorong anak menjelaskan alasannya dengan kalimat sederhana, misalnya \"yang ini punya pegangan\"."
        ),
        CompetencyGuidance(
            competency: .shape,
            score: 3,
            learningSummary: "Anak sangat baik menggunakan bentuk sebagai petunjuk utama. Anak dapat mengenali benda tanpa terlalu bergantung pada warna, bahkan ketika pilihan memiliki warna yang mirip. Ini menunjukkan bahwa anak sudah mulai memiliki strategi visual yang kuat dan bisa diterapkan di situasi sehari-hari.",
            masteredItems: [
                "Anak mampu mengenali bentuk dasar dan detail bentuk dengan baik.",
                "Anak dapat mencocokkan siluet dengan objek yang sesuai secara mandiri.",
                "Anak mampu menggunakan bentuk sebagai strategi utama saat warna sulit dibedakan.",
                "Anak dapat memperhatikan ciri khas benda sebelum membuat pilihan."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih dengan bentuk yang lebih kompleks atau sebagian tertutup.",
                "Anak dapat mencoba menggabungkan bentuk dengan pola, label, atau kontras.",
                "Anak tetap perlu mempertahankan kebiasaan memeriksa detail sebelum memilih.",
                "Anak dapat diberi tantangan dengan lebih banyak pilihan agar kemampuan membandingkannya tetap terasah."
            ],
            parentTip: "Pertahankan dengan permainan tebak benda dari bayangan, outline, atau bentuk sebagian. Gunakan benda sehari-hari seperti botol, kotak makan, tas, buku, atau mainan agar latihan terasa dekat dengan aktivitas anak."
        ),
        CompetencyGuidance(
            competency: .pattern,
            score: 1,
            learningSummary: "Anak mulai menyadari pola seperti garis, titik, atau motif. Anak sudah dapat menangkap pola yang sangat jelas, tetapi masih sering tertukar saat pola terlihat mirip atau ketika warna benda menarik perhatian. Area ini perlu dilatih pelan-pelan karena pola adalah petunjuk penting selain warna.",
            masteredItems: [
                "Anak mulai memperhatikan bahwa benda bisa memiliki pola atau tekstur.",
                "Anak dapat mengenali pola yang sangat berbeda dari pilihan lain, seperti polos dan bergaris.",
                "Anak mulai melihat motif sebagai petunjuk selain warna.",
                "Anak mulai memahami bahwa detail kecil pada permukaan benda bisa membantu membedakan pilihan."
            ],
            practiceItems: [
                "Anak masih perlu latihan mencocokkan pola yang sama dari dua atau tiga pilihan.",
                "Anak masih perlu bantuan saat pola terlihat mirip atau warnanya sama-sama menarik.",
                "Anak perlu lebih teliti melihat detail seperti garis, titik, kotak, atau tekstur.",
                "Anak perlu dilatih menyebutkan pola yang dilihat sebelum menentukan jawaban."
            ],
            parentTip: "Gunakan dua pilihan dengan pola yang sangat berbeda, seperti polos dan bergaris. Setelah itu, naikkan tantangan dengan motif yang lebih mirip, misalnya garis tebal dan garis tipis."
        ),
        CompetencyGuidance(
            competency: .pattern,
            score: 2,
            learningSummary: "Anak sudah cukup mampu mengenali pola yang jelas dan mulai memakai motif sebagai petunjuk non-warna. Anak mulai memahami bahwa benda dengan warna mirip tetap bisa dibedakan lewat garis, titik, tekstur, atau susunan motif. Latihan berikutnya dapat fokus pada pola yang lebih mirip.",
            masteredItems: [
                "Anak dapat mengenali pola sederhana seperti garis, titik, atau motif berulang.",
                "Anak mulai mencocokkan motif yang sama pada benda berbeda.",
                "Anak mulai memahami bahwa warna mirip bisa dibedakan melalui pola.",
                "Anak mulai memperhatikan arah dan susunan pola saat melihat pilihan."
            ],
            practiceItems: [
                "Anak masih perlu latihan membedakan pola yang mirip agar tidak hanya melihat warna.",
                "Anak perlu memperhatikan arah, jarak, ukuran, dan pengulangan pola.",
                "Anak perlu mengurangi kebiasaan menebak saat warna benda terlihat sama.",
                "Anak dapat dilatih membandingkan dua motif dan mencari bagian yang berbeda."
            ],
            parentTip: "Ajak anak mencocokkan pola pada baju, tas, buku, atau mainan, lalu tanyakan: \"Motifnya sama atau berbeda?\" Minta anak menunjukkan bagian yang membuatnya yakin."
        ),
        CompetencyGuidance(
            competency: .pattern,
            score: 3,
            learningSummary: "Anak sangat baik menggunakan pola dan tekstur untuk membedakan benda. Anak dapat mengenali detail visual tanpa bergantung pada warna, termasuk saat pilihan terlihat ramai. Kemampuan ini membantu anak menemukan benda yang tepat dengan melihat motif, tekstur, atau pengulangan detail.",
            masteredItems: [
                "Anak mampu mengenali pola dan tekstur dengan baik.",
                "Anak dapat membedakan motif yang mirip dengan lebih teliti.",
                "Anak mampu menggunakan pola sebagai petunjuk utama saat warna tidak jelas.",
                "Anak dapat memperhatikan detail permukaan sebelum menentukan pilihan."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih dengan pola yang lebih ramai atau lebih kecil.",
                "Anak dapat mencoba menggabungkan pola dengan bentuk, label, atau konteks.",
                "Anak tetap perlu menjaga ketelitian saat pilihan terlihat hampir sama.",
                "Anak dapat diberi tantangan mencari pola dalam lingkungan nyata yang lebih beragam."
            ],
            parentTip: "Beri tantangan mencari benda berpola sama di lingkungan sehari-hari. Gunakan benda yang dekat dengan anak, seperti pakaian, tas, buku, botol minum, atau mainan."
        ),
        CompetencyGuidance(
            competency: .brightnessContrast,
            score: 1,
            learningSummary: "Anak mulai melihat perbedaan terang dan gelap. Anak dapat terbantu ketika objek terlihat sangat menonjol dari latar belakang, tetapi masih kesulitan saat kontrasnya rendah atau perbedaannya halus. Latihan perlu dimulai dari perbedaan yang jelas agar anak terbiasa membandingkan tingkat terang.",
            masteredItems: [
                "Anak mulai memperhatikan benda yang terlihat lebih terang atau lebih gelap.",
                "Anak dapat menemukan objek yang sangat jelas dari latar belakang.",
                "Anak mulai memahami bahwa terang-gelap bisa membantu saat warna tidak jelas.",
                "Anak mulai mencoba membandingkan benda berdasarkan seberapa jelas objek terlihat."
            ],
            practiceItems: [
                "Anak masih perlu latihan membedakan terang-gelap yang perbedaannya tipis.",
                "Anak perlu bantuan saat objek kurang menonjol dari latar belakang.",
                "Anak perlu membiasakan diri membandingkan tingkat terang sebelum memilih.",
                "Anak perlu diarahkan untuk melihat batas objek, bukan hanya warna yang terlihat."
            ],
            parentTip: "Latih dengan benda yang jelas berbeda terang-gelapnya sebelum masuk ke benda yang warnanya mirip. Tanyakan: \"Mana yang lebih terang?\", \"Mana yang lebih gelap?\", atau \"Mana yang paling jelas terlihat?\""
        ),
        CompetencyGuidance(
            competency: .brightnessContrast,
            score: 2,
            learningSummary: "Anak cukup mampu membedakan benda yang lebih terang, lebih gelap, atau lebih jelas dari latar belakang. Anak mulai menggunakan kontras sebagai petunjuk saat warna tidak cukup membantu. Latihan masih dibutuhkan untuk perbedaan yang mirip, terutama pada benda dengan shade yang hampir sama.",
            masteredItems: [
                "Anak dapat membedakan benda yang lebih terang dan lebih gelap.",
                "Anak mulai menemukan objek yang paling jelas dari latar belakang.",
                "Anak mulai menggunakan kontras sebagai petunjuk tambahan.",
                "Anak mulai memahami bahwa objek yang lebih menonjol sering lebih mudah dikenali."
            ],
            practiceItems: [
                "Anak masih perlu latihan membedakan shade yang hampir sama.",
                "Anak perlu meningkatkan kemampuan mengenali objek dengan kontras rendah.",
                "Anak perlu mengurangi ketergantungan pada warna yang terlihat.",
                "Anak perlu membiasakan diri membandingkan objek dengan latar belakangnya sebelum memilih."
            ],
            parentTip: "Ajak anak membandingkan \"mana yang paling jelas terlihat\" pada meja, rak, atau area yang agak redup. Gunakan benda yang sama dengan latar berbeda agar anak melihat pengaruh kontras."
        ),
        CompetencyGuidance(
            competency: .brightnessContrast,
            score: 3,
            learningSummary: "Anak sangat baik menggunakan terang, gelap, dan kontras untuk menemukan objek. Anak dapat memakai petunjuk ini saat warna tidak cukup membantu, terutama ketika perlu memilih benda yang paling terlihat jelas. Kemampuan ini berguna di situasi nyata seperti ruangan redup, rak yang ramai, atau latar belakang yang mirip.",
            masteredItems: [
                "Anak mampu membedakan terang dan gelap dengan baik.",
                "Anak dapat menemukan objek yang menonjol dari latar belakang.",
                "Anak mampu menggunakan kontras sebagai strategi saat warna sulit dibedakan.",
                "Anak dapat memilih objek dengan melihat tingkat kejelasan, bukan hanya warna."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih dengan kontras yang lebih halus.",
                "Anak dapat mencoba mencari objek di situasi yang lebih ramai.",
                "Anak tetap perlu menggabungkan kontras dengan bentuk, pola, atau label.",
                "Anak dapat diberi tantangan mencari benda pada pencahayaan yang berbeda-beda."
            ],
            parentTip: "Pertahankan dengan aktivitas mencari benda yang paling menonjol dari latar belakangnya. Contohnya, minta anak mencari benda di meja yang ramai atau di area yang sedikit redup."
        ),
        CompetencyGuidance(
            competency: .labelSymbol,
            score: 1,
            learningSummary: "Anak mulai memperhatikan label dan simbol sebagai petunjuk visual. Anak sudah mulai melihat bahwa tulisan atau tanda bisa membantu, tetapi masih perlu bantuan untuk menghubungkan tanda dengan artinya. Latihan sederhana dan berulang akan membantu anak lebih percaya diri membaca petunjuk non-warna.",
            masteredItems: [
                "Anak mulai mengenali beberapa tulisan atau simbol sederhana.",
                "Anak mulai melihat label sebagai petunjuk tambahan saat warna tidak cukup jelas.",
                "Anak mulai memahami bahwa tanda bisa membantu menemukan tempat atau benda.",
                "Anak mulai memperhatikan gambar kecil atau ikon yang sering muncul di lingkungan sehari-hari."
            ],
            practiceItems: [
                "Anak masih perlu latihan menghubungkan simbol dengan artinya.",
                "Anak perlu bantuan membaca label sebelum memilih.",
                "Anak perlu mengurangi kebiasaan menebak dari warna atau posisi saja.",
                "Anak perlu dilatih mengenali simbol yang sama di tempat atau benda yang berbeda."
            ],
            parentTip: "Mulai dari simbol yang sering ditemui, seperti toilet, kantin, keluar, atau panah arah. Saat anak melihat tanda, tanyakan dulu arti tandanya sebelum menjelaskan jawabannya."
        ),
        CompetencyGuidance(
            competency: .labelSymbol,
            score: 2,
            learningSummary: "Anak sudah mulai menggunakan tulisan, label, dan simbol sebagai petunjuk tambahan. Anak dapat memakai tanda untuk memahami arah, tempat, atau fungsi benda, tetapi masih perlu latihan agar lebih teliti sebelum memilih. Dengan latihan konsisten, label dan simbol bisa menjadi strategi penting saat warna sulit dibedakan.",
            masteredItems: [
                "Anak dapat mengenali tulisan dan label sederhana.",
                "Anak mulai menggunakan simbol untuk memahami arah atau tempat.",
                "Anak mulai memakai teks untuk memastikan pilihan.",
                "Anak mulai memahami bahwa membaca tanda dapat mengurangi tebakan berdasarkan warna."
            ],
            practiceItems: [
                "Anak masih perlu meningkatkan ketelitian saat membaca label.",
                "Anak perlu latihan menghubungkan tulisan dengan fungsi benda atau tempat.",
                "Anak perlu membiasakan diri mengecek simbol sebelum menebak.",
                "Anak perlu latihan pada label yang lebih panjang atau simbol yang kurang familiar."
            ],
            parentTip: "Saat di rumah atau sekolah, minta anak membaca label sederhana sebelum menebak dari warna atau posisi. Gunakan label buku, nama ruangan, menu, papan arah, atau kemasan makanan."
        ),
        CompetencyGuidance(
            competency: .labelSymbol,
            score: 3,
            learningSummary: "Anak sangat baik menggunakan label dan simbol untuk mengenali tempat, benda, atau arah. Anak dapat memahami tanda sebagai petunjuk yang lebih stabil daripada warna. Ini bisa menjadi strategi kuat saat warna sulit dibedakan, terutama di lingkungan sekolah atau tempat umum.",
            masteredItems: [
                "Anak mampu mengenali label dan simbol umum dengan baik.",
                "Anak dapat menghubungkan tanda dengan arti, tempat, atau fungsi.",
                "Anak mampu menggunakan tulisan dan simbol sebagai petunjuk utama.",
                "Anak dapat memakai tanda untuk membuat keputusan dengan lebih mandiri."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih dengan simbol yang lebih kompleks.",
                "Anak dapat mencoba membaca petunjuk di tempat yang lebih ramai.",
                "Anak tetap perlu menggabungkan label dengan bentuk, pola, atau konteks.",
                "Anak dapat diberi tantangan mengikuti beberapa tanda secara berurutan."
            ],
            parentTip: "Beri tantangan mencari arah dari simbol di tempat umum, seperti kantin, lift, tangga, atau pintu keluar. Ajak anak menyebutkan arti simbolnya sebelum mengikuti arahnya."
        ),
        CompetencyGuidance(
            competency: .context,
            score: 1,
            learningSummary: "Anak mulai menggunakan situasi sekitar untuk menebak fungsi atau lokasi benda. Anak sudah mulai memahami bahwa tempat, aktivitas, dan benda di sekitarnya dapat menjadi petunjuk. Namun, anak masih perlu bantuan untuk menggabungkan beberapa petunjuk sekaligus sebelum menentukan pilihan.",
            masteredItems: [
                "Anak mulai memperhatikan tempat atau situasi di sekitar benda.",
                "Anak mulai memahami bahwa lokasi bisa menjadi petunjuk.",
                "Anak mulai mencoba menghubungkan benda dengan fungsinya.",
                "Anak mulai menyadari bahwa satu benda bisa lebih masuk akal di tempat tertentu."
            ],
            practiceItems: [
                "Anak masih perlu bantuan menggabungkan bentuk, pola, label, dan lokasi.",
                "Anak perlu latihan saat pilihannya mirip atau situasinya ramai.",
                "Anak perlu membiasakan diri memeriksa lebih dari satu petunjuk.",
                "Anak perlu dilatih menjelaskan alasan pilihan berdasarkan situasi, bukan warna saja."
            ],
            parentTip: "Latih dengan pertanyaan sederhana seperti: \"Benda ini biasanya dipakai di mana?\" atau \"Kalau di kantin, benda apa yang mungkin dicari?\" Bantu anak menyebutkan alasan dari lingkungan sekitar sebelum memilih."
        ),
        CompetencyGuidance(
            competency: .context,
            score: 2,
            learningSummary: "Anak sudah cukup mampu menggunakan konteks, fungsi, dan lokasi untuk mengenali benda. Anak mulai menggabungkan informasi dari tempat, kegunaan benda, dan petunjuk visual lain. Anak masih perlu latihan saat situasinya ramai atau ketika beberapa pilihan sama-sama masuk akal.",
            masteredItems: [
                "Anak dapat menggunakan lokasi sebagai petunjuk tambahan.",
                "Anak mulai menghubungkan benda dengan fungsi atau tempatnya.",
                "Anak mulai menggabungkan beberapa petunjuk sebelum memilih.",
                "Anak mulai memahami bahwa konteks dapat membantu saat bentuk atau warna terlihat mirip."
            ],
            practiceItems: [
                "Anak masih perlu latihan di situasi yang lebih ramai.",
                "Anak perlu membandingkan beberapa petunjuk saat benda terlihat mirip.",
                "Anak perlu membiasakan diri mengecek konteks bersama bentuk, label, atau pola.",
                "Anak perlu latihan membuat pilihan berdasarkan alasan yang lebih lengkap."
            ],
            parentTip: "Ajak anak melihat tempat benda biasa berada, lalu gabungkan dengan bentuk, label, atau pola. Misalnya, saat di kelas, tanyakan benda apa yang biasanya ada di meja, laci, atau tas."
        ),
        CompetencyGuidance(
            competency: .context,
            score: 3,
            learningSummary: "Anak sangat baik menggabungkan berbagai petunjuk visual dalam situasi sehari-hari. Anak dapat menggunakan konteks untuk membuat pilihan yang lebih yakin, terutama saat warna tidak cukup membantu. Kemampuan ini menunjukkan bahwa anak mulai membangun strategi lengkap dengan melihat tempat, fungsi, bentuk, pola, dan tanda.",
            masteredItems: [
                "Anak mampu menggunakan konteks dan lokasi dengan baik.",
                "Anak dapat menghubungkan benda dengan fungsi dan situasinya.",
                "Anak mampu menggabungkan bentuk, pola, label, dan konteks sebelum memilih.",
                "Anak dapat membuat pilihan yang lebih mandiri dengan melihat beberapa petunjuk sekaligus."
            ],
            practiceItems: [
                "Anak dapat mulai dilatih pada situasi nyata yang lebih ramai.",
                "Anak dapat mencoba menyelesaikan pilihan dengan petunjuk yang lebih banyak.",
                "Anak tetap perlu mempertahankan kebiasaan memeriksa detail sebelum memilih.",
                "Anak dapat diberi tantangan menjelaskan urutan petunjuk yang digunakan."
            ],
            parentTip: "Pertahankan dengan aktivitas mencari benda di tempat nyata, seperti kelas, kantin, tas, atau rak mainan. Ajak anak menyebutkan beberapa petunjuk sekaligus, misalnya tempatnya, bentuknya, dan tanda atau pola yang terlihat."
        )
    ]

    static func guidance(for competency: Competency, score: Int) -> CompetencyGuidance? {
        guidanceItems.first { $0.competency == competency && $0.score == score }
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

    func guidance(for competency: Competency, score: Int) -> CompetencyGuidance? {
        StatisticsGuidanceContent.guidance(for: competency, score: score)
    }

    func competencyItem(for competency: Competency) -> CompetencyProgressItem? {
        competencyItems.first { $0.competency == competency }
    }
}
