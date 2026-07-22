//
//  ImmediateFeedback.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  The reusable immediate-feedback pieces for the chapter mini-games:
//
//  1. `CorrectAnswerCelebration` — 3 seconds of confetti (reusing
//     `ConfettiOverlay` from StageCleared.swift), a correct-answer sound, yay,
//     and applause, started by one call.
//  2. `wrongAnswerFeedback(...)` — view modifier for a wrong option: red
//     outline, shake, vibration, and the wrong-answer sound.
//  3. `HintOverlay` + `ChapterHints` — after the SECOND wrong answer, the owl
//     appears with a Dynamic Type speech bubble showing the chapter's hint.
//
//  Sounds are played through `AudioService` and are safe no-ops until the
//  audio files are imported (see AudioService.swift for the expected names).
//
//  TYPICAL GAMEPLAY WIRING (driven by ChapterGameplayViewModel)
//  ------------------------------------------------------------
//  Every feature is a modifier callable on ANY view:
//
//      // Option card:
//      AnswerCard(option)
//          .wrongAnswerFeedback(
//              isWrong: viewModel.incorrectAnswerID == option.id,
//              shakeTrigger: viewModel.shakeTrigger
//          )
//
//      // Screen root:
//      GameplayContent(...)
//          .correctAnswerCelebration(
//              isActive: viewModel.isCorrectFeedbackPresented
//          ) { viewModel.finishCorrectFeedback() }
//          .hintOverlay(
//              isPresented: viewModel.isHintPresented,
//              chapter: viewModel.chapter
//          ) { viewModel.dismissHint() }
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 1. Correct Answer Celebration

/// Fullscreen celebration for a correct answer: confetti rains for 3 seconds
/// while correct-answer, yay, and applause sounds play, then `onFinished`
/// fires so the host can move on (e.g. call
/// `ChapterGameplayViewModel.finishCorrectFeedback()`).
///
/// One call starts the confetti and all supplied congratulatory sounds.
struct CorrectAnswerCelebration: View {

    /// How long the celebration runs before `onFinished` is called.
    static let duration: TimeInterval = 3.0

    /// Invoked once after the three-second feedback presentation.
    let onFinished: () -> Void

    /// Fades the confetti out at the end of the celebration.
    @State private var isFadingOut = false

    var body: some View {
        // Confetti reused from StageCleared.swift; it never blocks taps.
        ConfettiOverlay()
            .opacity(isFadingOut ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                startCelebration()
            }
    }

    /// The one entry point: starts all celebration features together and
    /// schedules the finish after `Self.duration` (3 seconds).
    private func startCelebration() {
        isFadingOut = false
        AudioService.shared.playCorrectAnswerSound()
        AudioService.shared.playYaySound()
        AudioService.shared.playApplauseSound()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.duration - 0.3))
            withAnimation(.easeOut(duration: 0.3)) {
                isFadingOut = true
            }

            try? await Task.sleep(for: .seconds(0.3))
            onFinished()
        }
    }
}

// MARK: - 2. Wrong Answer Feedback (Red Outline + Shake + Vibration + Sound)

extension View {

    /// Marks an answer option as wrong: red outline while `isWrong` is true,
    /// and — every time `shakeTrigger` increases — a shake animation, an error
    /// vibration, and the wrong-answer sound.
    ///
    /// Drive it from `ChapterGameplayViewModel`:
    ///
    ///     AnswerCard(option)
    ///         .wrongAnswerFeedback(
    ///             isWrong: viewModel.incorrectAnswerID == option.id,
    ///             shakeTrigger: viewModel.shakeTrigger
    ///         )
    ///
    /// The red is never the only cue — the shake, vibration, and sound carry
    /// the same message for children who can't distinguish the color.
    ///
    /// - Parameters:
    ///   - isWrong: Whether this option is the currently-marked wrong answer.
    ///   - shakeTrigger: Monotonic counter; each increment plays the effects.
    ///   - cornerRadius: Corner radius of the outline (match the option card).
    /// - Returns: The decorated view.
    func wrongAnswerFeedback(
        isWrong: Bool,
        shakeTrigger: Int,
        cornerRadius: CGFloat = 18
    ) -> some View {
        modifier(
            WrongAnswerFeedback(
                isWrong: isWrong,
                shakeTrigger: shakeTrigger,
                cornerRadius: cornerRadius
            )
        )
    }
}

/// Implementation of `wrongAnswerFeedback(...)`. See that function for usage.
private struct WrongAnswerFeedback: ViewModifier {

    let isWrong: Bool
    let shakeTrigger: Int
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            // Red outline while this option is marked wrong. Opacity (not an
            // if/else branch) keeps the view's identity stable.
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.red, lineWidth: 4)
                    .opacity(isWrong ? 1 : 0)
            )
            // Shake: animates whenever the trigger increments.
            .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
            .animation(.linear(duration: 0.4), value: shakeTrigger)
            .onChange(of: shakeTrigger) { _, newValue in
                guard newValue > 0, isWrong else {
                    return
                }

                playWrongAnswerEffects()
            }
    }

    /// Plays the non-visual half of the feedback: the error vibration and the
    /// wrong-answer sound (sound is a no-op until the asset is imported).
    private func playWrongAnswerEffects() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif

        AudioService.shared.duckBackgroundMusicForWrongAnswer()
        AudioService.shared.playWrongAnswerSound()
    }
}

/// Horizontal shake used for wrong answers: three quick left-right swings per
/// trigger increment, driven through `animatableData` so SwiftUI tweens it.
private struct ShakeEffect: GeometryEffect {

    /// Swings per unit of `animatableData`.
    var shakesPerUnit: CGFloat = 3

    /// Maximum horizontal displacement in points.
    var travelDistance: CGFloat = 10

    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: travelDistance * sin(animatableData * .pi * shakesPerUnit * 2),
                y: 0
            )
        )
    }
}

// MARK: - 3. Second-Wrong Hint (Owl + Speech Bubble)

/// The per-chapter hint texts shown after the second wrong answer, in simple,
/// child-friendly Indonesian. One entry per chapter competency.
enum ChapterHints {

    /// Returns the hint for a chapter's position in the story (1–5).
    ///
    /// - Parameter order: The chapter's `order` (1-based).
    /// - Returns: The kid-friendly Indonesian hint for that chapter.
    static func hint(forChapterOrder order: Int) -> String {
        switch order {
        case 1:
            // Shape: "Look carefully at the shape. Which one has the same outline?"
            return "Lihat bentuknya baik-baik, ya. Mana yang punya bentuk sama?"

        case 2:
            // Label/symbol: "Look carefully at the label or symbol."
            return "Lihat tulisan atau gambarnya baik-baik. Mana yang punya tanda atau kata yang sama?"

        case 3:
            // Contrast: "Which object is the easiest to see in the dark?"
            return "Lihat terang dan gelapnya, ya. Benda mana yang paling mudah terlihat di tempat gelap?"

        case 4:
            // Pattern: "Which one has the same pattern?"
            return "Lihat polanya baik-baik, ya. Mana yang punya pola sama?"

        default:
            // Combine all cues: shape, label, brightness, and pattern.
            return "Coba lihat lebih dari satu petunjuk, ya. Perhatikan bentuk, tulisan, terang-gelapnya, dan polanya. Kotak bekal mana yang cocok dengan semuanya?"
        }
    }

    /// Returns the hint for a chapter, preferring the hand-written
    /// `hintText` from the chapter's question data and falling back to the
    /// per-order defaults above.
    ///
    /// - Parameter chapter: The chapter being played.
    /// - Returns: The speech-bubble hint text.
    static func hint(for chapter: Chapter) -> String {
        let dataHint = chapter.gameConfiguration.question.hintText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return dataHint.isEmpty ? hint(forChapterOrder: chapter.order) : dataHint
    }

    /// Returns the asset-catalog name of the chapter's cover illustration,
    /// shown in the circle frame beside the hint speech bubble.
    ///
    /// Assets are named `chapterCover1`...`chapterCover6`; out-of-range orders
    /// fall back to `chapterCover1`.
    ///
    /// - Parameter order: The chapter's `order` (1-based).
    /// - Returns: The cover asset name for that chapter.
    static func coverImageName(forChapterOrder order: Int) -> String {
        (1...6).contains(order) ? "chapterCover\(order)" : "chapterCover1"
    }

    /// Returns the cover asset name for a chapter.
    ///
    /// - Parameter chapter: The chapter being played.
    /// - Returns: The cover asset name for the circle frame.
    static func coverImageName(for chapter: Chapter) -> String {
        coverImageName(forChapterOrder: chapter.order)
    }
}

/// The hint overlay shown after the child's SECOND wrong answer: the owl
/// mascot with a speech bubble containing the chapter's hint, plus a button to
/// go back and try again.
///
/// Presentation-only: show it from the game's `ZStack` when
/// `ChapterGameplayViewModel.isHintPresented` is true, and dismiss via
/// `dismissHint()`. Pure SwiftUI (no ScrollView), so it renders correctly
/// under the whole-screen color filter.
struct HintOverlay: View {

    /// The hint sentence displayed inside the speech bubble.
    let hintText: String

    /// Asset name of the chapter cover shown in the circle frame beside the
    /// speech bubble (`chapterCover1`...`chapterCover6`).
    let illustrationImageName: String

    /// Invoked when the child taps the button to try again; the host hides
    /// the overlay (e.g. `viewModel.dismissHint()`).
    let onDismiss: () -> Void

    /// Dynamic Type multipliers for the bubble text and illustration size.
    @ScaledMetric(relativeTo: .body) private var bubbleTextScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var owlScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title) private var buttonScale: CGFloat = 1

    /// Creates the overlay with an explicit hint sentence and cover image.
    ///
    /// - Parameters:
    ///   - hintText: The sentence inside the speech bubble.
    ///   - illustrationImageName: The chapter-cover asset for the circle
    ///     frame; defaults to chapter 1's cover.
    ///   - onDismiss: Called when the child taps "Coba Lagi".
    init(
        hintText: String,
        illustrationImageName: String = ChapterHints.coverImageName(forChapterOrder: 1),
        onDismiss: @escaping () -> Void
    ) {
        self.hintText = hintText
        self.illustrationImageName = illustrationImageName
        self.onDismiss = onDismiss
    }

    /// Creates the overlay for a chapter, resolving its hint text AND its
    /// cover illustration automatically — the usual initializer for gameplay,
    /// so every chapter shows its own cover in the circle.
    init(chapter: Chapter, onDismiss: @escaping () -> Void) {
        self.init(
            hintText: ChapterHints.hint(for: chapter),
            illustrationImageName: ChapterHints.coverImageName(for: chapter),
            onDismiss: onDismiss
        )
    }

    /// Creates the overlay for a chapter number (1–5), for hosts that don't
    /// have a `Chapter` value at hand.
    init(chapterOrder: Int, onDismiss: @escaping () -> Void) {
        self.init(
            hintText: ChapterHints.hint(forChapterOrder: chapterOrder),
            illustrationImageName: ChapterHints.coverImageName(forChapterOrder: chapterOrder),
            onDismiss: onDismiss
        )
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop pausing the game visually behind the hint.
            Color.black
                .opacity(0.36)
                .ignoresSafeArea()

            // Chapter cover + speech bubble, side by side like a conversation,
            // with the retry action grouped directly under the hint.
            HStack(alignment: .center, spacing: 24) {
                owlIllustration

                VStack(alignment: .leading, spacing: 20) {
                    speechBubble
                    retryButton
                        .padding(.leading, 26)
                }
                .frame(maxWidth: 520, alignment: .leading)
            }
            .padding(40)
        }
        .accessibilityElement(children: .contain)
    }

    /// The chapter cover inside the circle frame beside the speech bubble.
    /// The image is fitted (not cropped) on a white disc, so the whole cover
    /// illustration stays visible inside the frame.
    private var owlIllustration: some View {
        ZStack {
            Circle()
                .fill(.white)

            Image(illustrationImageName)
                .resizable()
                .scaledToFit()
                .padding(14)
        }
        .frame(width: 180 * owlScale, height: 180 * owlScale)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.black, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }

    /// The speech bubble with the chapter's hint. Text follows Dynamic Type
    /// and wraps freely inside the bubble.
    private var speechBubble: some View {
        HStack(alignment: .center, spacing: -1) {
            // Tail pointing at the chapter cover.
            BubbleTail()
                .fill(.white)
                .frame(width: 26, height: 30)

            Text(hintText)
                .font(.owlRounded(AppFontSize.body * bubbleTextScale, .medium))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .padding(28)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxWidth: 520, alignment: .leading)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
        .accessibilityLabel("Petunjuk: \(hintText)")
    }

    /// Closes the hint so the child can return to the same question.
    private var retryButton: some View {
        Button(action: onDismiss) {
            Text("Coba Lagi")
                .font(.owlRounded(AppFontSize.button * buttonScale, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 30 * buttonScale)
                .padding(.vertical, 10 * buttonScale)
                .background(AppColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Coba lagi")
        .accessibilityHint("Tutup petunjuk dan kembali ke pertanyaan")
    }
}

/// The small triangle pointing from the speech bubble toward the owl.
private struct BubbleTail: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Apply-Anywhere Modifiers

// These let ANY view opt into the feedback with one call, driven by
// `ChapterGameplayViewModel` (or any other state). A full gameplay screen
// wires all three like this:
//
//     GameplayContent(...)                      // option cards inside use
//                                               // .wrongAnswerFeedback(...)
//         .correctAnswerCelebration(
//             isActive: viewModel.isCorrectFeedbackPresented
//         ) { viewModel.finishCorrectFeedback() }
//         .hintOverlay(
//             isPresented: viewModel.isHintPresented,
//             chapter: viewModel.chapter
//         ) { viewModel.dismissHint() }
//
// Apply the two overlay modifiers to the SCREEN'S ROOT view so the confetti
// and the hint scrim cover the whole screen.

extension View {

    /// Overlays the 3-second confetti + clap celebration on this view while
    /// `isActive` is true; `onFinished` fires when it completes (set your flag
    /// back to false there).
    ///
    /// - Parameters:
    ///   - isActive: Whether the celebration is currently playing.
    ///   - onFinished: Called once, after the 3 seconds.
    /// - Returns: The view with the celebration overlay attached.
    func correctAnswerCelebration(
        isActive: Bool,
        onFinished: @escaping () -> Void
    ) -> some View {
        overlay {
            if isActive {
                CorrectAnswerCelebration(onFinished: onFinished)
            }
        }
    }

    /// Overlays the owl hint (speech bubble + "Coba Lagi") on this view while
    /// `isPresented` is true, with an explicit hint sentence and chapter cover.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the hint is showing.
    ///   - hintText: The sentence inside the speech bubble.
    ///   - illustrationImageName: The chapter-cover asset for the circle frame
    ///     (defaults to chapter 1's cover).
    ///   - onDismiss: Called when the child taps "Coba Lagi".
    /// - Returns: The view with the hint overlay attached.
    func hintOverlay(
        isPresented: Bool,
        hintText: String,
        illustrationImageName: String = ChapterHints.coverImageName(forChapterOrder: 1),
        onDismiss: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented {
                HintOverlay(
                    hintText: hintText,
                    illustrationImageName: illustrationImageName,
                    onDismiss: onDismiss
                )
            }
        }
    }

    /// Overlays the owl hint for a chapter, resolving its text automatically
    /// via `ChapterHints` — the usual form for gameplay screens.
    ///
    /// - Parameters:
    ///   - isPresented: Whether the hint is showing.
    ///   - chapter: The chapter being played (provides the hint text).
    ///   - onDismiss: Called when the child taps "Coba Lagi".
    /// - Returns: The view with the hint overlay attached.
    func hintOverlay(
        isPresented: Bool,
        chapter: Chapter,
        onDismiss: @escaping () -> Void
    ) -> some View {
        hintOverlay(
            isPresented: isPresented,
            hintText: ChapterHints.hint(for: chapter),
            onDismiss: onDismiss
        )
    }
}

// MARK: - Previews

#Preview("Celebration") {
    ZStack {
        Color(white: 0.9)
            .ignoresSafeArea()

        CorrectAnswerCelebration {}
    }
}

#Preview("Wrong Answer") {
    // INTERACTIVE — the canvas must be in LIVE mode (▶ button, bottom-left of
    // the canvas), not the Variants view: variant snapshots ignore taps.
    // Tap any card to simulate picking a wrong answer — the outline, shake,
    // vibration (device only), and sound all fire on the trigger increment,
    // exactly like ChapterGameplayViewModel does in gameplay. The outline
    // adapts to whatever size the option view is.
    @Previewable @State var isWrong = false
    @Previewable @State var shakeTrigger = 0

    VStack(spacing: 32) {
        Text("Tap a card (Live mode) to trigger the wrong-answer feedback")
            .font(.footnote)
            .foregroundStyle(.secondary)

        // Different sizes to show the outline fitting any box.
        HStack(spacing: 32) {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .frame(width: 260, height: 120)
                .wrongAnswerFeedback(isWrong: isWrong, shakeTrigger: shakeTrigger)

            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .frame(width: 160, height: 200)
                .wrongAnswerFeedback(isWrong: isWrong, shakeTrigger: shakeTrigger)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isWrong = true
            shakeTrigger += 1
        }
    }
    .padding(60)
    .background(Color(white: 0.9))
}

#Preview("Hint") {
    // Tap the picker to see each chapter's cover + hint pair.
    @Previewable @State var chapterOrder = 1

    ZStack {
        HintOverlay(chapterOrder: chapterOrder) {}

        VStack {
            Picker("Bab", selection: $chapterOrder) {
                ForEach(1...5, id: \.self) { order in
                    Text("Bab \(order)").tag(order)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)
            .padding(.top, 24)

            Spacer()
        }
    }
}

#Preview("All Feedback (modifiers)") {
    // Demonstrates that any plain view can opt in with the three modifiers.
    // Use LIVE mode (▶) and tap the buttons.
    @Previewable @State var isCelebrating = false
    @Previewable @State var isHintShowing = false
    @Previewable @State var isWrong = false
    @Previewable @State var shakeTrigger = 0

    ZStack {
        Color(white: 0.93)
            .ignoresSafeArea()

        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .frame(width: 280, height: 130)
                .overlay(
                    Text("Kartu Jawaban")
                        .appScaledFont(size: AppFontSize.body)
                )
                .wrongAnswerFeedback(isWrong: isWrong, shakeTrigger: shakeTrigger)

            HStack(spacing: 16) {
                Button("Benar ✓") { isCelebrating = true }
                Button("Salah ✗") {
                    isWrong = true
                    shakeTrigger += 1
                    if shakeTrigger == 2 { isHintShowing = true }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    .correctAnswerCelebration(isActive: isCelebrating) { isCelebrating = false }
    .hintOverlay(isPresented: isHintShowing, hintText: ChapterHints.hint(forChapterOrder: 1)) {
        isHintShowing = false
        isWrong = false
    }
}
