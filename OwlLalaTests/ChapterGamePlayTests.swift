//
//  ChapterGamePlayTests.swift
//  OwlLalaTests
//
//  Created by Amanda on 28/07/26.
//

import Foundation
import SwiftUI
import Testing
@testable import OwlLala

// MARK: - ChapterGameplayViewModel

/// TDD specifications for `ChapterGameplayViewModel`, the gameplay state
/// machine used by both Main Story and Training Mode.
@MainActor
@Suite("ChapterGameplayViewModel TDD Specifications")
struct ChapterGameplayViewModelTests {

    // MARK: - Initial State

    /// Memastikan VM Main Story yang memiliki halaman cerita belum langsung
    /// menampilkan pertanyaan. Test ini membuat chapter dengan dua story page,
    /// lalu memverifikasi seluruh state awal: halaman pertama aktif, belum ada
    /// jawaban dipilih, feedback/hint/destination kosong, dan properti helper
    /// `isFirstStoryPage`, `isLastStoryPage`, serta `question` benar.
    @Test("Given Main Story chapter with story pages, initial state starts on first story page")
    func test_initialState_whenMainStoryWithStoryPages_startsBeforeQuestion() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .mainStory,
            nextChapterID: "chapter-2"
        )

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.currentStoryPage?.id == "page-1")
        #expect(sut.isQuestionPresented == false)
        #expect(sut.selectedAnswerID == nil)
        #expect(sut.incorrectAnswerID == nil)
        #expect(sut.wrongAnswerCount == 0)
        #expect(sut.shakeTrigger == 0)
        #expect(sut.isHintPresented == false)
        #expect(sut.isCorrectFeedbackPresented == false)
        #expect(sut.earnedStars == nil)
        #expect(sut.destination == nil)
        #expect(sut.isFirstStoryPage == true)
        #expect(sut.isLastStoryPage == false)
        #expect(sut.question.id == "question-1")
    }

    /// Memastikan Main Story tanpa halaman cerita langsung masuk ke pertanyaan.
    /// Test ini memakai chapter tanpa `storyPages`, lalu mengecek bahwa tidak
    /// ada current story page dan kedua helper batas halaman bernilai true
    /// karena tidak ada halaman yang bisa dinavigasi.
    @Test("Given Main Story chapter without story pages, initial state shows question immediately")
    func test_initialState_whenMainStoryWithoutStoryPages_startsAtQuestion() {
        let sut = makeViewModel(source: .mainStory)

        #expect(sut.currentStoryPage == nil)
        #expect(sut.isQuestionPresented == true)
        #expect(sut.isFirstStoryPage == true)
        #expect(sut.isLastStoryPage == true)
    }

    /// Memastikan Training Mode selalu melewati story page walaupun chapter
    /// memiliki data cerita. Test ini membuat chapter dengan dua halaman cerita,
    /// menjalankannya sebagai `.training`, lalu mengecek pertanyaan langsung
    /// tampil tanpa menghapus akses data `currentStoryPage`.
    @Test("Given Training Mode chapter with story pages, initial state skips story pages")
    func test_initialState_whenTrainingWithStoryPages_startsAtQuestion() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .training,
            nextChapterID: "chapter-2"
        )

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.currentStoryPage?.id == "page-1")
        #expect(sut.isQuestionPresented == true)
    }

    // MARK: - Story Navigation

    /// Memastikan tombol/aksi previous aman saat berada di halaman cerita
    /// pertama. Test ini memanggil `goToPreviousStoryPage()` pada index nol
    /// dan mengecek index tidak menjadi negatif.
    @Test("Given first story page, goToPreviousStoryPage keeps index at zero")
    func test_goToPreviousStoryPage_whenAtFirstPage_keepsCurrentIndex() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .mainStory
        )

        sut.goToPreviousStoryPage()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.isFirstStoryPage == true)
    }

    /// Memastikan navigasi next berpindah ke halaman cerita berikutnya saat
    /// halaman berikut masih tersedia. Test ini mulai dari page pertama,
    /// memanggil `goToNextStoryPage()`, lalu memverifikasi index, page id, dan
    /// status first/last page.
    @Test("Given multiple story pages, goToNextStoryPage advances by one page")
    func test_goToNextStoryPage_whenNextPageExists_advancesCurrentIndex() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .mainStory
        )

        sut.goToNextStoryPage()

        #expect(sut.currentStoryPageIndex == 1)
        #expect(sut.currentStoryPage?.id == "page-2")
        #expect(sut.isFirstStoryPage == false)
        #expect(sut.isLastStoryPage == true)
        #expect(sut.isQuestionPresented == false)
    }

    /// Memastikan navigasi previous bekerja setelah user maju ke halaman kedua.
    /// Test ini maju satu halaman terlebih dahulu, lalu mundur dan memastikan
    /// VM kembali ke page pertama.
    @Test("Given second story page, goToPreviousStoryPage returns to first page")
    func test_goToPreviousStoryPage_whenNotAtFirstPage_movesBackOnePage() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .mainStory
        )

        sut.goToNextStoryPage()
        sut.goToPreviousStoryPage()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.currentStoryPage?.id == "page-1")
    }

    /// Memastikan next dari halaman cerita terakhir tidak melewati array, tetapi
    /// mengubah state ke mode pertanyaan. Test ini memakai satu story page,
    /// memanggil `goToNextStoryPage()`, lalu mengecek `isQuestionPresented`.
    @Test("Given final story page, goToNextStoryPage reveals question")
    func test_goToNextStoryPage_whenAtLastPage_revealsQuestion() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .mainStory
        )

        sut.goToNextStoryPage()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.isQuestionPresented == true)
    }

    /// Memastikan perintah navigasi cerita diabaikan saat pertanyaan sudah
    /// tampil. Test ini memaksa `startQuestion()`, memanggil next dan previous,
    /// lalu memastikan index halaman tidak berubah.
    @Test("Given question is already presented, story navigation commands do not move page index")
    func test_storyNavigation_whenQuestionPresented_ignoresNavigationCommands() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 2)),
            source: .mainStory
        )

        sut.startQuestion()
        sut.goToNextStoryPage()
        sut.goToPreviousStoryPage()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.isQuestionPresented == true)
    }

    /// Memastikan `startQuestion()` adalah entry point eksplisit untuk membuka
    /// mini-game dari halaman cerita. Test ini memanggil method tersebut dan
    /// mengecek flag presentasi pertanyaan aktif.
    @Test("When startQuestion is called, question presentation becomes active")
    func test_startQuestion_whenCalled_presentsQuestion() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .mainStory
        )

        sut.startQuestion()

        #expect(sut.isQuestionPresented == true)
    }

    // MARK: - Incorrect Answers

    /// Memastikan jawaban salah menghasilkan state feedback yang dibutuhkan
    /// view. Test ini memilih satu opsi salah, lalu mengecek selected answer,
    /// incorrect answer, counter salah, shake trigger, serta tidak ada hint,
    /// correct feedback, atau bintang.
    @Test("Given incorrect answer, selectAnswer records selected and incorrect answer state")
    func test_selectAnswer_whenIncorrect_recordsWrongAnswerFeedbackState() {
        let sut = makeViewModel()

        sut.selectAnswer(wrongAnswer)

        #expect(sut.selectedAnswerID == wrongAnswer.id)
        #expect(sut.incorrectAnswerID == wrongAnswer.id)
        #expect(sut.wrongAnswerCount == 1)
        #expect(sut.shakeTrigger == 1)
        #expect(sut.isHintPresented == false)
        #expect(sut.isCorrectFeedbackPresented == false)
        #expect(sut.earnedStars == nil)
    }

    /// Memastikan setiap tap jawaban salah tetap dihitung walaupun opsi yang
    /// sama dipilih berulang. Test ini memilih opsi salah yang sama tiga kali
    /// dan memverifikasi `wrongAnswerCount` serta `shakeTrigger` sama-sama naik
    /// sampai tiga.
    @Test("Given same incorrect answer is selected repeatedly, each tap counts as wrong attempt")
    func test_selectAnswer_whenSameIncorrectAnswerRepeated_countsEveryTap() {
        let sut = makeViewModel()

        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(wrongAnswer)

        #expect(sut.selectedAnswerID == wrongAnswer.id)
        #expect(sut.incorrectAnswerID == wrongAnswer.id)
        #expect(sut.wrongAnswerCount == 3)
        #expect(sut.shakeTrigger == 3)
    }

    /// Memastikan hint muncul tepat saat percobaan salah kedua. Test ini memilih
    /// dua opsi salah, lalu mengecek opsi salah terakhir disimpan, counter
    /// salah bernilai dua, shake trigger ikut naik, dan `isHintPresented` aktif.
    @Test("Given second incorrect answer, hint is presented once wrong count reaches two")
    func test_selectAnswer_whenSecondIncorrectAnswer_presentsHint() {
        let sut = makeViewModel()

        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(otherWrongAnswer)

        #expect(sut.selectedAnswerID == otherWrongAnswer.id)
        #expect(sut.incorrectAnswerID == otherWrongAnswer.id)
        #expect(sut.wrongAnswerCount == 2)
        #expect(sut.shakeTrigger == 2)
        #expect(sut.isHintPresented == true)
    }

    /// Memastikan `dismissHint()` hanya menutup overlay petunjuk tanpa mereset
    /// state gameplay. Test ini memunculkan hint lewat dua jawaban salah,
    /// menutup hint, lalu mengecek counter dan incorrect answer tetap utuh.
    @Test("Given hint is presented, dismissHint hides only the hint")
    func test_dismissHint_whenHintPresented_hidesHintAndKeepsGameplayState() {
        let sut = makeViewModel()
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(otherWrongAnswer)

        sut.dismissHint()

        #expect(sut.isHintPresented == false)
        #expect(sut.wrongAnswerCount == 2)
        #expect(sut.incorrectAnswerID == otherWrongAnswer.id)
    }

    /// Memastikan hint tidak otomatis terbuka lagi setelah user menutup hint
    /// yang muncul pada percobaan salah kedua. Test ini dismiss hint, memilih
    /// jawaban salah ketiga, lalu memastikan counter naik tetapi hint tetap
    /// tersembunyi.
    @Test("Given third incorrect answer after dismissing hint, hint does not automatically reopen")
    func test_selectAnswer_whenThirdIncorrectAfterDismiss_keepsHintHidden() {
        let sut = makeViewModel()
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(otherWrongAnswer)
        sut.dismissHint()

        sut.selectAnswer(wrongAnswer)

        #expect(sut.wrongAnswerCount == 3)
        #expect(sut.shakeTrigger == 3)
        #expect(sut.isHintPresented == false)
    }

    // MARK: - Correct Answers and Stars

    /// Memastikan aturan bintang maksimum: jawaban benar tanpa kesalahan
    /// menghasilkan tiga bintang. Test ini memilih jawaban benar pada percobaan
    /// pertama dan mengecek correct feedback aktif serta `earnedStars == 3`.
    @Test("Given no wrong attempts, selecting correct answer earns three stars")
    func test_selectAnswer_whenCorrectOnFirstTry_earnsThreeStars() {
        let sut = makeViewModel()

        sut.selectAnswer(correctAnswer)

        #expect(sut.selectedAnswerID == correctAnswer.id)
        #expect(sut.incorrectAnswerID == nil)
        #expect(sut.isCorrectFeedbackPresented == true)
        #expect(sut.earnedStars == 3)
    }

    /// Memastikan aturan penalti satu kesalahan: satu jawaban salah lalu benar
    /// menghasilkan dua bintang. Test ini membuat satu wrong attempt sebelum
    /// memilih jawaban benar dan mengecek hasil star calculation.
    @Test("Given one wrong attempt, selecting correct answer earns two stars")
    func test_selectAnswer_whenCorrectAfterOneWrong_earnsTwoStars() {
        let sut = makeViewModel()
        sut.selectAnswer(wrongAnswer)

        sut.selectAnswer(correctAnswer)

        #expect(sut.wrongAnswerCount == 1)
        #expect(sut.isCorrectFeedbackPresented == true)
        #expect(sut.earnedStars == 2)
    }

    /// Memastikan aturan minimum bintang: dua atau lebih jawaban salah lalu
    /// benar menghasilkan satu bintang. Test ini membuat dua wrong attempt,
    /// memilih jawaban benar, lalu mengecek `earnedStars == 1`.
    @Test("Given two or more wrong attempts, selecting correct answer earns one star")
    func test_selectAnswer_whenCorrectAfterTwoWrong_earnsOneStar() {
        let sut = makeViewModel()
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(otherWrongAnswer)

        sut.selectAnswer(correctAnswer)

        #expect(sut.wrongAnswerCount == 2)
        #expect(sut.isCorrectFeedbackPresented == true)
        #expect(sut.earnedStars == 1)
    }

    /// Memastikan input jawaban terkunci selama correct feedback tampil. Test
    /// ini memilih jawaban benar, lalu mencoba memilih jawaban salah dan
    /// memastikan state tetap mengarah ke jawaban benar tanpa menambah counter.
    @Test("Given correct feedback is active, selecting another answer is ignored")
    func test_selectAnswer_whenCorrectFeedbackPresented_ignoresFurtherSelections() {
        let sut = makeViewModel()
        sut.selectAnswer(correctAnswer)

        sut.selectAnswer(wrongAnswer)

        #expect(sut.selectedAnswerID == correctAnswer.id)
        #expect(sut.incorrectAnswerID == nil)
        #expect(sut.wrongAnswerCount == 0)
        #expect(sut.shakeTrigger == 0)
        #expect(sut.earnedStars == 3)
    }

    // MARK: - Completion Persistence

    /// Memastikan gameplay yang ditinggalkan sebelum `finishCorrectFeedback()`
    /// tidak menyimpan hasil apa pun. Test ini memilih jawaban benar sampai
    /// correct feedback aktif, tetapi tidak memanggil completion method, lalu
    /// mengecek `StorageService` tetap tanpa stats dan tanpa unlock chapter.
    @Test("Given abandoned gameplay, no result is saved")
    func test_abandonedGameplay_whenNoFinishCorrectFeedback_doesNotPersistStats() {
        let storage = makeStorage()
        let sut = makeViewModel(storageService: storage)

        sut.selectAnswer(correctAnswer)

        #expect(sut.isCorrectFeedbackPresented == true)
        #expect(storage.userStats.stats(for: sut.chapter.id) == nil)
        #expect(storage.userStats.isChapterUnlocked("chapter-2") == false)
    }

    /// Memastikan completion Main Story menyimpan hasil dan membuka chapter
    /// berikutnya. Test ini memakai storage terisolasi, memilih jawaban benar,
    /// memanggil `finishCorrectFeedback()`, lalu mengecek destination stage
    /// cleared, best stars, play count, dan unlock progression.
    @Test("Given correct Main Story answer, finishCorrectFeedback saves stars and unlocks next chapter")
    func test_finishCorrectFeedback_whenMainStory_recordsProgressAndUnlocksNextChapter() {
        let storage = makeStorage()
        let sut = makeViewModel(
            source: .mainStory,
            nextChapterID: "chapter-2",
            storageService: storage
        )

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        #expect(sut.isCorrectFeedbackPresented == false)
        #expect(sut.destination == .stageCleared)
        #expect(storage.userStats.bestStars(for: sut.chapter.id) == 3)
        #expect(storage.userStats.playCount(for: sut.chapter.id) == 1)
        #expect(storage.userStats.isChapterUnlocked("chapter-2") == true)
    }

    /// Memastikan completion Training Mode tetap menyimpan `GameStats`, tetapi
    /// tidak mengubah progression Main Story. Test ini menjalankan source
    /// `.training`, menyelesaikan soal, lalu mengecek stats tersimpan dan
    /// chapter berikutnya tidak di-unlock.
    @Test("Given Training Mode answer, finishCorrectFeedback saves stars without unlocking next chapter")
    func test_finishCorrectFeedback_whenTraining_recordsStatsWithoutUnlockingProgression() {
        let storage = makeStorage()
        let sut = makeViewModel(
            source: .training,
            nextChapterID: "chapter-2",
            storageService: storage
        )

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        #expect(sut.destination == .stageCleared)
        #expect(storage.userStats.bestStars(for: sut.chapter.id) == 3)
        #expect(storage.userStats.playCount(for: sut.chapter.id) == 1)
        #expect(storage.userStats.isChapterUnlocked("chapter-2") == false)
    }

    /// Memastikan `finishCorrectFeedback()` aman dipanggil lebih dari sekali
    /// oleh view lifecycle. Test ini memanggil method completion dua kali dan
    /// memastikan hasil hanya disimpan satu kali melalui `playCount == 1`.
    @Test("Given completion is already saved, finishCorrectFeedback is idempotent")
    func test_finishCorrectFeedback_whenCalledTwice_savesOnlyOnce() {
        let storage = makeStorage()
        let sut = makeViewModel(storageService: storage)

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()
        sut.finishCorrectFeedback()

        #expect(storage.userStats.playCount(for: sut.chapter.id) == 1)
        #expect(storage.userStats.bestStars(for: sut.chapter.id) == 3)
        #expect(sut.destination == .stageCleared)
    }

    /// Memastikan completion tidak melakukan apa pun jika belum ada jawaban
    /// benar dan `earnedStars` masih nil. Test ini langsung memanggil
    /// `finishCorrectFeedback()` lalu mengecek storage dan destination tetap
    /// kosong.
    @Test("Given no earned stars, finishCorrectFeedback does not save or navigate")
    func test_finishCorrectFeedback_whenNoCorrectAnswer_doesNothing() {
        let storage = makeStorage()
        let sut = makeViewModel(storageService: storage)

        sut.finishCorrectFeedback()

        #expect(storage.userStats.stats(for: sut.chapter.id) == nil)
        #expect(sut.destination == nil)
        #expect(sut.isCorrectFeedbackPresented == false)
    }

    /// Memastikan replay dengan skor lebih tinggi memperbarui `bestStars` dan
    /// tetap menambah `playCount`. Test ini menyiapkan stats awal satu bintang,
    /// menyelesaikan ulang dengan tiga bintang, lalu mengecek best berubah ke
    /// tiga dan play count menjadi dua.
    @Test("Given previous lower best, completing with higher stars updates best and play count")
    func test_finishCorrectFeedback_whenHigherReplay_updatesBestStarsAndPlayCount() {
        let storage = makeStorage()
        storage.updateUserStats { userStats in
            userStats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 1)
        }
        let sut = makeViewModel(storageService: storage)

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        #expect(storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(storage.userStats.playCount(for: "chapter-1") == 2)
    }

    /// Memastikan replay dengan skor lebih rendah tidak menurunkan `bestStars`.
    /// Test ini menyiapkan stats awal tiga bintang, menyelesaikan ulang dengan
    /// dua wrong attempt, lalu mengecek best tetap tiga dan play count naik.
    @Test("Given previous higher best, completing with lower stars preserves best and increments play count")
    func test_finishCorrectFeedback_whenLowerReplay_preservesBestStarsAndIncrementsPlayCount() {
        let storage = makeStorage()
        storage.updateUserStats { userStats in
            userStats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
        }
        let sut = makeViewModel(storageService: storage)
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(otherWrongAnswer)

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        #expect(storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(storage.userStats.playCount(for: "chapter-1") == 2)
    }

    // MARK: - Stage Cleared Destinations

    /// Memastikan stage-cleared Main Story non-final kembali ke daftar chapter.
    /// Test ini menyelesaikan chapter dengan `nextChapterID`, memanggil
    /// `finishStageCleared()`, lalu mengecek destination menjadi `.chapterList`.
    @Test("Given non-final Main Story chapter, finishStageCleared routes to chapter list")
    func test_finishStageCleared_whenMainStoryHasNextChapter_routesToChapterList() {
        let sut = makeViewModel(source: .mainStory, nextChapterID: "chapter-2")

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()
        sut.finishStageCleared()

        #expect(sut.destination == .chapterList)
    }

    /// Memastikan stage-cleared Main Story final masuk ke story completion.
    /// Test ini memakai `nextChapterID == nil`, menyelesaikan chapter, lalu
    /// mengecek `finishStageCleared()` menghasilkan `.storyCompletion`.
    @Test("Given final Main Story chapter, finishStageCleared routes to story completion")
    func test_finishStageCleared_whenMainStoryHasNoNextChapter_routesToStoryCompletion() {
        let sut = makeViewModel(source: .mainStory, nextChapterID: nil)

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()
        sut.finishStageCleared()

        #expect(sut.destination == .storyCompletion)
    }

    /// Memastikan Training Mode tidak pernah menuju story completion setelah
    /// stage cleared. Test ini menyelesaikan chapter training, memanggil
    /// `finishStageCleared()`, lalu mengecek destination `.trainingList`.
    @Test("Given Training Mode chapter, finishStageCleared routes to training list")
    func test_finishStageCleared_whenTraining_routesToTrainingList() {
        let sut = makeViewModel(source: .training, nextChapterID: "chapter-2")

        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()
        sut.finishStageCleared()

        #expect(sut.destination == .trainingList)
    }

    /// Memastikan `clearDestination()` membersihkan sinyal navigasi setelah
    /// view memprosesnya. Test ini membuat destination `.stageCleared`, lalu
    /// memanggil clear dan mengecek destination kembali nil.
    @Test("Given active destination, clearDestination resets destination")
    func test_clearDestination_whenDestinationExists_resetsDestinationToNil() {
        let sut = makeViewModel()
        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        sut.clearDestination()

        #expect(sut.destination == nil)
    }

    // MARK: - Replay

    /// Memastikan replay Main Story mengembalikan VM ke state awal sebelum
    /// halaman cerita. Test ini membuat state sudah selesai dengan wrong attempt,
    /// memanggil `resetForReplay()`, lalu mengecek semua state pilihan,
    /// feedback, skor, dan destination kosong kembali.
    @Test("Given completed Main Story gameplay, resetForReplay restores initial Main Story state")
    func test_resetForReplay_whenMainStory_resetsStateBeforeStoryPages() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .mainStory,
            nextChapterID: "chapter-2"
        )
        sut.startQuestion()
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        sut.resetForReplay()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.isQuestionPresented == false)
        #expect(sut.selectedAnswerID == nil)
        #expect(sut.incorrectAnswerID == nil)
        #expect(sut.wrongAnswerCount == 0)
        #expect(sut.shakeTrigger == 0)
        #expect(sut.isHintPresented == false)
        #expect(sut.isCorrectFeedbackPresented == false)
        #expect(sut.earnedStars == nil)
        #expect(sut.destination == nil)
    }

    /// Memastikan replay Training Mode kembali langsung ke pertanyaan, bukan ke
    /// story page. Test ini menyelesaikan gameplay training, memanggil reset,
    /// lalu mengecek `isQuestionPresented` true dan state completion kosong.
    @Test("Given completed Training gameplay, resetForReplay restores initial Training state")
    func test_resetForReplay_whenTraining_resetsStateAtQuestion() {
        let sut = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .training,
            nextChapterID: "chapter-2"
        )
        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        sut.resetForReplay()

        #expect(sut.currentStoryPageIndex == 0)
        #expect(sut.isQuestionPresented == true)
        #expect(sut.selectedAnswerID == nil)
        #expect(sut.earnedStars == nil)
        #expect(sut.destination == nil)
    }

    /// Memastikan `resetForReplay()` juga membuka kembali guard penyimpanan
    /// internal (`didSaveCompletion`). Test ini menyimpan satu completion,
    /// reset, menyelesaikan lagi, lalu memastikan play count bertambah menjadi
    /// dua.
    @Test("Given reset after saved completion, gameplay can be completed and saved again")
    func test_resetForReplay_whenCompleted_allowsAnotherSavedCompletion() {
        let storage = makeStorage()
        let sut = makeViewModel(storageService: storage)
        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        sut.resetForReplay()
        sut.selectAnswer(wrongAnswer)
        sut.selectAnswer(correctAnswer)
        sut.finishCorrectFeedback()

        #expect(storage.userStats.playCount(for: sut.chapter.id) == 2)
        #expect(storage.userStats.bestStars(for: sut.chapter.id) == 3)
    }
}

// MARK: - ChapterGamePlayView

/// Native compile-level specifications for `ChapterGamePlayView` composition.
/// The view's interaction methods are private SwiftUI implementation details,
/// so behavior is covered through the injected `ChapterGameplayViewModel`.
@MainActor
@Suite("ChapterGamePlayView TDD Specifications")
struct ChapterGamePlayViewTests {

    /// Memastikan `ChapterGamePlayView` dapat dibuat dengan VM Main Story.
    /// Test ini membuat VM yang masih berada di halaman cerita, menginisialisasi
    /// view, lalu mengecek tipe view dan state VM yang menjadi kontrak input
    /// view.
    @Test("Given Main Story ViewModel, ChapterGamePlayView can be initialized")
    func test_init_whenMainStoryViewModel_createsGameplayView() {
        let viewModel = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .mainStory,
            nextChapterID: "chapter-2"
        )

        let sut = ChapterGamePlayView(viewModel: viewModel)

        #expect(String(describing: type(of: sut)) == "ChapterGamePlayView")
        #expect(viewModel.source == .mainStory)
        #expect(viewModel.isQuestionPresented == false)
    }

    /// Memastikan `ChapterGamePlayView` dapat dibuat dengan VM Training Mode
    /// yang langsung berada pada state pertanyaan. Test ini menginisialisasi
    /// view dan memverifikasi source serta state awal VM.
    @Test("Given Training ViewModel, ChapterGamePlayView can be initialized at question state")
    func test_init_whenTrainingViewModel_createsGameplayViewAtQuestion() {
        let viewModel = makeViewModel(
            chapter: makeChapter(storyPages: makeStoryPages(count: 1)),
            source: .training,
            nextChapterID: nil
        )

        let sut = ChapterGamePlayView(viewModel: viewModel)

        #expect(String(describing: type(of: sut)) == "ChapterGamePlayView")
        #expect(viewModel.source == .training)
        #expect(viewModel.isQuestionPresented == true)
    }

    /// Memastikan callback completion yang dipasang pada `ChapterGamePlayView`
    /// tetap callable. Test ini membuat closure untuk chapter completion dan
    /// story completion, memanggil closure dari instance view, lalu mengecek
    /// efeknya pada variabel test.
    @Test("Given completion callbacks, ChapterGamePlayView stores callable completion hooks")
    func test_init_whenCompletionCallbacksProvided_createsGameplayView() {
        var completedChapterID: String?
        var didCompleteStory = false
        let viewModel = makeViewModel()

        let sut = ChapterGamePlayView(
            viewModel: viewModel,
            onChapterCompleted: { completedChapterID = $0 },
            onStoryCompleted: { didCompleteStory = true }
        )

        sut.onChapterCompleted?("chapter-1")
        sut.onStoryCompleted?()

        #expect(completedChapterID == "chapter-1")
        #expect(didCompleteStory == true)
    }
}

// MARK: - Shared Fixtures

private let correctAnswer = AnswerOption(
    id: "correct",
    text: "Benar",
    imageAssetName: nil
)

private let wrongAnswer = AnswerOption(
    id: "wrong",
    text: "Salah",
    imageAssetName: nil
)

private let otherWrongAnswer = AnswerOption(
    id: "other-wrong",
    text: "Salah Lain",
    imageAssetName: nil
)

@MainActor
private func makeViewModel(
    chapter: Chapter = makeChapter(),
    source: GameplaySource = .mainStory,
    nextChapterID: String? = "chapter-2",
    storageService: StorageService? = nil
) -> ChapterGameplayViewModel {
    ChapterGameplayViewModel(
        chapter: chapter,
        source: source,
        nextChapterID: nextChapterID,
        storageService: storageService ?? makeStorage()
    )
}

@MainActor
private func makeStorage() -> StorageService {
    let suiteName = "ChapterGamePlayTests_\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.removePersistentDomain(forName: suiteName)
    return StorageService(userDefaults: userDefaults)
}

private func makeStoryPages(count: Int) -> [StoryPage] {
    (1...count).map { index in
        StoryPage(
            id: "page-\(index)",
            order: index,
            illustrationAssetName: "illustration-\(index)",
            narration: "Narasi \(index)",
            voiceOverAssetName: nil
        )
    }
}

private func makeChapter(
    id: String = "chapter-1",
    order: Int = 1,
    storyPages: [StoryPage] = []
) -> Chapter {
    Chapter(
        id: id,
        order: order,
        title: "Bab",
        subtitle: nil,
        description: "Deskripsi",
        thumbnailAssetName: "thumbnail",
        competency: .shape,
        storyPages: storyPages,
        gameConfiguration: GameConfiguration(
            question: GameQuestion(
                id: "question-1",
                prompt: "Pilih jawaban yang benar",
                promptImageAssetName: nil,
                answerOptions: [
                    correctAnswer,
                    wrongAnswer,
                    otherWrongAnswer
                ],
                correctAnswerID: correctAnswer.id,
                hintText: "Petunjuk"
            )
        ),
        learningSummary: LearningSummary(
            successMessage: "Berhasil",
            explanation: "Penjelasan",
            mainIllustrationAssetName: "summary",
            exampleAssetNames: []
        )
    )
}
