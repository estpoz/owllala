//
//  ChapterGamePlayView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 17/07/26.
//

import SwiftUI

struct ChapterGamePlayView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @StateObject private var viewModel: ChapterGameplayViewModel
    var onChapterCompleted: ((String) -> Void)?
    @State private var isVoiceOverEnabled = true
    @State private var isShowingExitConfirmation = false
    @State private var isShowingSettings = false
    @State private var isShowingSuccessOverlay = false
    @State private var hasStartedChapter = false

    init(
        viewModel: ChapterGameplayViewModel,
        onChapterCompleted: ((String) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChapterCompleted = onChapterCompleted
    }

    private var totalGameplayPages: Int {
        switch viewModel.source {
        case .mainStory:
            return max(viewModel.chapter.storyPages.count + 1, 1)

        case .training:
            return 1
        }
    }

    private var currentGameplayPage: Int {
        guard viewModel.source == .mainStory else {
            return 1
        }

        if viewModel.isQuestionPresented {
            return totalGameplayPages
        }

        return viewModel.currentStoryPageIndex + 1
    }

    /// 0 at the smallest text size, 1 at the largest — used to scale the
    /// start-chapter card responsively across the whole Dynamic Type range.
    private var dynamicTypeProgress: CGFloat {
        let all = DynamicTypeSize.allCases
        guard let index = all.firstIndex(of: dynamicTypeSize), all.count > 1 else {
            return 0
        }
        return CGFloat(index) / CGFloat(all.count - 1)
    }

    /// Start-card width fraction: narrowest at X Small, widest (cap) at AX5.
    private var startCardWidthFraction: CGFloat {
        0.5 + dynamicTypeProgress * (0.68 - 0.5)
    }

    /// Start-card height fraction: shortest at X Small, tallest (cap) at AX5.
    private var startCardHeightFraction: CGFloat {
        0.42 + dynamicTypeProgress * (0.66 - 0.42)
    }

    var body: some View {
        ZStack {
            // The gameplay layer remains independently filterable when the
            // scrolling Stage Cleared overlay asks the navigation wrapper to
            // step aside. `AppScreen` centralizes both settings boundaries.
            AppScreen {
                Color(red: 0.937, green: 0.953, blue: 0.957)
                    .ignoresSafeArea()
            } content: {
                ZStack {
                    if viewModel.source == .mainStory && !hasStartedChapter {
                        startChapterContent
                    } else if viewModel.isQuestionPresented {
                        questionContent
                    } else if let storyPage = viewModel.currentStoryPage {
                        storyPageContent(storyPage)
                    }
                }
            }

        }
        .navigationBarHidden(true)
        // A separate transparent presentation keeps the dialog's accessible
        // ScrollView outside gameplay's shader while preserving the centered
        // card and the visible game beneath it.
        .fullScreenCover(isPresented: $isShowingExitConfirmation) {
            ExitConfirmation(
                onContinueLearning: {
                    isShowingExitConfirmation = false
                    resumeStoryVoiceOverIfNeeded()
                },
                onDiscardProgress: {
                    stopGameplayAudio()
                    isShowingExitConfirmation = false
                    dismiss()
                }
            )
            // A fullScreenCover is a separate presentation that does NOT inherit
            // the root's app-wide text sizing, so re-apply it here — the dialog
            // now follows the "Ukuran Teks" setting like the rest of the app.
            // (Brightness and color filter are applied inside ExitConfirmation
            // from the shared settings.)
            .appTextSizeAdjustment()
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
        }
        .fullScreenCover(
            isPresented: $isShowingSettings,
            onDismiss: resumeStoryVoiceOverIfNeeded
        ) {
            SettingsView(viewModel: settingsViewModel, isModal: true) {
                isShowingSettings = false
            }
            .appTextSizeAdjustment()
            .appIndependentColorFilterScope()
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $isShowingSuccessOverlay) {
            stageClearedOverlay
                .appTextSizeAdjustment() // 1. Re-applies your custom in-app font scaling modifier
                .environmentObject(settingsViewModel) // 2. Passes the settings environment down to the cover
                .appIndependentColorFilterScope()
                .presentationBackground(.clear)
        }
        .correctAnswerCelebration(
            isActive: viewModel.isCorrectFeedbackPresented,
            onFinished: {
                viewModel.finishCorrectFeedback()
            }
        )
        .hintOverlay(
            isPresented: viewModel.isHintPresented,
            chapter: viewModel.chapter,
            onDismiss: viewModel.dismissHint
        )
        .onChange(of: viewModel.destination) { _, destination in
            guard destination == .stageCleared else {
                return
            }

            stopGameplayAudio()
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingSuccessOverlay = true
            }
        }
        .onChange(of: viewModel.currentStoryPageIndex) { _, _ in
            playCurrentStoryVoiceOverIfNeeded()
        }
        .onChange(of: viewModel.isQuestionPresented) { _, isQuestionPresented in
            if isQuestionPresented {
                stopStoryVoiceOver()
            } else {
                playCurrentStoryVoiceOverIfNeeded()
            }
        }
        .onAppear {
            if viewModel.destination == nil {
                startBackgroundMusic()
            }
        }
        .onDisappear {
            stopGameplayAudio()
        }
    }

    private var stageClearedOverlay: some View {
        StageClearedView(
            subtitle: "Kamu berhasil menyelesaikan \(viewModel.chapter.title)",
            starCount: viewModel.earnedStars ?? Chapter.maximumStars,
            maxStars: 3,
            summaryText: viewModel.chapter.learningSummary.explanation,
            onReplay: {
                stopGameplayAudio()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingSuccessOverlay = false
                }
                viewModel.resetForReplay()
                hasStartedChapter = viewModel.source == .training
                startBackgroundMusic()
            },
            onContinue: {
                stopGameplayAudio()
                viewModel.finishStageCleared()
                isShowingSuccessOverlay = false

                onChapterCompleted?(viewModel.chapter.id)
                                
                dismiss()
            }
        )
    }

    private var startChapterContent: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)

            ZStack {
                Image("bgPattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .appBackgroundAdjustments()

                VStack(spacing: baseUnit * 0.02) {
                    // Balances any extra height above and below the content so
                    // the block stays nicely centered when there is white space.
                    Spacer(minLength: 0)

                    // Pinned at the top — stays put at every text size.
                    Text("Bab \(viewModel.chapter.order)")
                        .appScaledFont(
                            size: AppFontSize.largeTitle,
                            relativeTo: .largeTitle,
                            weight: .bold
                        )
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    // Only the title scrolls when it gets too tall for the fixed
                    // card, so the page count and button never move. A
                    // pure-SwiftUI scroller (not a UIKit ScrollView) is used
                    // because the color-vision shader can't rasterize a
                    // ScrollView and would render its content blank.
                    ColorFilterSafeVScroll {
                        Text(viewModel.chapter.title)
                            .appScaledFont(
                                size: AppFontSize.headline,
                                relativeTo: .headline,
                                weight: .medium
                            )
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            // Wrap to as many lines as the text needs instead
                            // of truncating to one line with an ellipsis.
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, baseUnit * 0.005)
                    }

                    // Pinned — stays put at every text size. Same size as the
                    // chapter title above it.
                    Text("\(totalGameplayPages) Halaman")
                        .appScaledFont(
                            size: AppFontSize.headline,
                            relativeTo: .headline,
                            weight: .medium
                        )
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        // Shrinks to fit the card at big text sizes instead of
                        // truncating with an ellipsis.
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Pinned at the bottom — stays put at every text size.
                    PrimaryActionButton(title: "Mulai Baca") {
                        startChapter()
                    }
                    .accessibilityLabel("Mulai Bab \(viewModel.chapter.order)")

                    Spacer(minLength: 0)
                }
                .padding(baseUnit * 0.045)
                // The box scales with the text size — smallest at X Small,
                // largest (its cap) at AX5 — and stays centered on the page.
                .frame(
                    width: geometry.size.width * startCardWidthFraction,
                    height: geometry.size.height * startCardHeightFraction
                )
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.8), lineWidth: 3)
                )

                VStack {
                    HStack {
                        BackButton(style: .outlined) {
                            stopStoryVoiceOver()
                            dismiss()
                        }

                        Spacer()

                        SettingsButton(style: .outlined) {
                            showSettings()
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.045)
                    .padding(.top, geometry.size.height * 0.045)

                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    private func storyPageContent(_ storyPage: StoryPage) -> some View {
        GeometryReader { geometry in
            ZStack {
                Image(storyPage.illustrationAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityLabel("Ilustrasi cerita")

                VStack(spacing: 0) {
                    GameplayTopBar(
                        currentPage: currentGameplayPage,
                        totalPages: totalGameplayPages,
                        isVoiceOverEnabled: isVoiceOverEnabled,
                        onShowExitConfirmation: {
                            showExitConfirmation()
                        },
                        onToggleVoiceOver: {
                            toggleVoiceOver()
                        },
                        onShowSettings: {
                            showSettings()
                        }
                    )
                    .padding(.horizontal, geometry.size.width * 0.045)
                    .padding(.top, geometry.size.height * 0.045)

                    Spacer()

                    StoryNarrationBlock(
                        narration: storyPage.narration,
                        canGoPrevious: !viewModel.isFirstStoryPage,
                        canGoNext: true,
                        onPrevious: viewModel.goToPreviousStoryPage,
                        onNext: viewModel.goToNextStoryPage
                    )
                    .padding(.horizontal, geometry.size.width * 0.045)
                    .padding(.bottom, geometry.size.height * 0.045)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    private var questionContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GameplayTopBar(
                    currentPage: currentGameplayPage,
                    totalPages: totalGameplayPages,
                    isVoiceOverEnabled: isVoiceOverEnabled,
                    onShowExitConfirmation: {
                        showExitConfirmation()
                    },
                    onToggleVoiceOver: {
                        toggleVoiceOver()
                    },
                    onShowSettings: {
                        showSettings()
                    }
                )
                .padding(.horizontal, geometry.size.width * 0.045)
                .padding(.top, geometry.size.height * 0.045)

                Spacer(minLength: geometry.size.height * topQuestionSpacing)

                questionPromptArea(in: geometry)
                    .padding(.horizontal, geometry.size.width * 0.12)

                Spacer(minLength: geometry.size.height * answerTopSpacing)

                answerOptionsGrid(in: geometry)

                Text(questionInstructionText)
                    .appScaledFont(
                        size: AppFontSize.body,
                        weight: .light
                    )
                    .foregroundStyle(.gray)
                    .padding(.top, geometry.size.height * 0.028)
                    .padding(.bottom, geometry.size.height * 0.035)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        // Match the story page so the top bar sits at the same spot on both.
        .ignoresSafeArea()
    }

    private var usesTwoColumnAnswerLayout: Bool {
        viewModel.chapter.order == 2
    }

    private var usesCompactPromptImageLayout: Bool {
        viewModel.chapter.order == 4
    }

    private var usesChapterFivePromptLayout: Bool {
        viewModel.chapter.order == 5
    }

    private var topQuestionSpacing: CGFloat {
        // Tighten the two-column layout at accessibility sizes so the hint line
        // has room to grow.
        if usesTwoColumnAnswerLayout {
            return dynamicTypeSize.isAccessibilitySize ? 0.03 : 0.12
        }
        return 0.055
    }

    private var answerTopSpacing: CGFloat {
        if usesTwoColumnAnswerLayout {
            return dynamicTypeSize.isAccessibilitySize ? 0.03 : 0.075
        }
        return 0.035
    }

    private var questionInstructionText: String {
        usesTwoColumnAnswerLayout ? "Tekan penanda yang sesuai" : "Tekan objek yang sesuai"
    }

    /// Shared question typography for every chapter. The prompt follows the
    /// app's complete Dynamic Type range, wraps instead of truncating, and
    /// keeps priority over the decorative owl when horizontal space is tight.
    private var questionPromptText: some View {
        Text(viewModel.question.prompt)
            .appScaledFont(
                size: 30,
                relativeTo: .headline,
                weight: .bold
            )
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            // The hint line is the only thing that scales; the owl and prompt
            // image are sized by screen geometry so they never change. The low
            // shrink floor lets the line grow but shrink-to-fit rather than
            // truncate when a chapter's fixed layout runs out of room.
            .lineLimit(5)
            .minimumScaleFactor(0.3)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func questionPromptArea(in geometry: GeometryProxy) -> some View {
        if usesChapterFivePromptLayout {
            chapterFivePromptArea(in: geometry)
        } else if let promptImageAssetName = viewModel.question.promptImageAssetName {
            VStack(spacing: geometry.size.height * 0.02) {
                questionPromptText

                HStack(alignment: .center, spacing: geometry.size.width * 0.055) {
                    Image(promptImageAssetName)
                        .resizable()
                        .scaledToFit()
                        // The prompt image shrinks at accessibility sizes to give
                        // the hint line room to grow. The owl stays fixed.
                        .frame(
                            width: geometry.size.width * (dynamicTypeSize.isAccessibilitySize ? 0.11 : (usesCompactPromptImageLayout ? 0.15 : 0.18)),
                            height: geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.12 : (usesCompactPromptImageLayout ? 0.17 : 0.24))
                        )
                        .accessibilityLabel("Gambar petunjuk")

                    Image("ingameOwl")
                        .resizable()
                        .scaledToFit()
                        // Fixed size — the owl never changes.
                        .frame(
                            width: geometry.size.width * 0.12,
                            height: geometry.size.height * 0.16
                        )
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(alignment: .center, spacing: geometry.size.width * 0.025) {
                questionPromptText
                    // Wider at accessibility sizes so the hint line can grow big
                    // without wrapping into a wall of narrow lines.
                    .frame(
                        width: geometry.size.width * (dynamicTypeSize.isAccessibilitySize ? 0.6 : 0.42),
                        alignment: dynamicTypeSize.isAccessibilitySize ? .center : .trailing
                    )

                Image("ingameOwl")
                    .resizable()
                    .scaledToFit()
                    // Fixed size — the owl never changes.
                    .frame(
                        width: geometry.size.width * 0.12,
                        height: geometry.size.height * 0.16
                    )
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func chapterFivePromptArea(in geometry: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: geometry.size.width * 0.03) {
            VStack(spacing: geometry.size.height * 0.018) {
                questionPromptText

                VStack(alignment: .leading, spacing: geometry.size.height * 0.006) {
                    Text("Bentuk : Kotak")
                    Text("Warna : Biru")
                    Text("Pola : Bergaris")
                }
                // Same size as the prompt so the whole hint reads at one size,
                // scaling all the way to AX5.
                .appScaledFont(
                    size: 30,
                    relativeTo: .headline,
                    weight: .bold
                )
                .foregroundStyle(primaryBlue)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            .frame(width: geometry.size.width * 0.36)

            Image("ingameOwl")
                .resizable()
                .scaledToFit()
                // Fixed size — the owl never moves or scales with the text.
                .frame(
                    width: geometry.size.width * 0.12,
                    height: geometry.size.height * 0.16
                )
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func answerOptionsGrid(in geometry: GeometryProxy) -> some View {
        if usesTwoColumnAnswerLayout {
            LazyVGrid(
                columns: [
                    GridItem(.fixed(geometry.size.width * 0.34), spacing: geometry.size.width * 0.03),
                    GridItem(.fixed(geometry.size.width * 0.34), spacing: geometry.size.width * 0.03)
                ],
                // Tighter row gap at accessibility sizes to free room for the hint.
                spacing: geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.02 : 0.035)
            ) {
                ForEach(viewModel.question.answerOptions) { option in
                    AnswerOptionButton(
                        option: option,
                        // Bigger buttons that keep enough room for the full label
                        // at every text size.
                        size: CGSize(
                            width: geometry.size.width * 0.34,
                            height: geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.12 : 0.14)
                        ),
                        maxImageSize: CGSize(
                            width: geometry.size.width * 0.08,
                            height: geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.07 : 0.075)
                        ),
                        usesHorizontalContent: true,
                        appliesLowContrastOverlay: shouldDimIncorrectChapterThreeOption(option),
                        isWrong: viewModel.incorrectAnswerID == option.id,
                        isCorrect: isCorrectOption(option),
                        isBlurred: shouldBlurAfterCorrectAnswer(option),
                        isInteractionLocked: viewModel.isCorrectFeedbackPresented,
                        shakeTrigger: viewModel.shakeTrigger,
                        action: {
                            viewModel.selectAnswer(option)
                        }
                    )
                }
            }
        } else {
            HStack(spacing: geometry.size.width * 0.018) {
                ForEach(viewModel.question.answerOptions) { option in
                    AnswerOptionButton(
                        option: option,
                        // The answer choices are a fixed size — never affected
                        // by the text-size setting.
                        size: CGSize(
                            width: geometry.size.width * 0.18,
                            height: geometry.size.height * 0.19
                        ),
                        maxImageSize: CGSize(
                            width: geometry.size.width * 0.12,
                            height: geometry.size.height * 0.14
                        ),
                        usesHorizontalContent: false,
                        appliesLowContrastOverlay: shouldDimIncorrectChapterThreeOption(option),
                        isWrong: viewModel.incorrectAnswerID == option.id,
                        isCorrect: isCorrectOption(option),
                        isBlurred: shouldBlurAfterCorrectAnswer(option),
                        isInteractionLocked: viewModel.isCorrectFeedbackPresented,
                        shakeTrigger: viewModel.shakeTrigger,
                        action: {
                            viewModel.selectAnswer(option)
                        }
                    )
                }
            }
        }
    }

    private func shouldDimIncorrectChapterThreeOption(_ option: AnswerOption) -> Bool {
        viewModel.chapter.order == 3 && option.id != viewModel.question.correctAnswerID
    }

    private func isCorrectOption(_ option: AnswerOption) -> Bool {
        viewModel.isCorrectFeedbackPresented && option.id == viewModel.question.correctAnswerID
    }

    private func shouldBlurAfterCorrectAnswer(_ option: AnswerOption) -> Bool {
        viewModel.isCorrectFeedbackPresented && option.id != viewModel.question.correctAnswerID
    }

    private func startChapter() {
        hasStartedChapter = true
        startBackgroundMusic()

        guard isVoiceOverEnabled,
              viewModel.source == .mainStory,
              let assetName = viewModel.currentStoryPage?.voiceOverAssetName
        else {
            return
        }

        AudioService.shared.playVoiceOver(named: assetName)
    }

    private func toggleVoiceOver() {
        isVoiceOverEnabled.toggle()
        AudioService.shared.updateBackgroundMusicVolume(
            isVoiceOverEnabled: isVoiceOverEnabled
        )

        if isVoiceOverEnabled {
            playCurrentStoryVoiceOverIfNeeded()
        } else {
            stopStoryVoiceOver()
        }
    }

    private func showExitConfirmation() {
        stopStoryVoiceOver()
        isShowingExitConfirmation = true
    }

    private func showSettings() {
        stopStoryVoiceOver()
        isShowingSettings = true
    }

    private func resumeStoryVoiceOverIfNeeded() {
        resumeBackgroundMusicIfNeeded()
        playCurrentStoryVoiceOverIfNeeded()
    }

    private func playCurrentStoryVoiceOverIfNeeded() {
        guard isVoiceOverEnabled,
              viewModel.source == .mainStory,
              hasStartedChapter,
              !viewModel.isQuestionPresented,
              !isShowingExitConfirmation,
              !isShowingSettings,
              let assetName = viewModel.currentStoryPage?.voiceOverAssetName
        else {
            return
        }

        AudioService.shared.playVoiceOver(named: assetName)
    }

    private func stopStoryVoiceOver() {
        AudioService.shared.stopVoiceOver()
    }

    private func startBackgroundMusic() {
        AudioService.shared.playBackgroundMusic(
            isVoiceOverEnabled: isVoiceOverEnabled
        )
    }

    private func resumeBackgroundMusicIfNeeded() {
        guard !isShowingSuccessOverlay,
              viewModel.destination == nil
        else {
            return
        }

        startBackgroundMusic()
    }

    private func stopGameplayAudio() {
        stopStoryVoiceOver()
        AudioService.shared.restoreBackgroundMusicForApp()
    }

}

private struct AnswerOptionButton: View {

    let option: AnswerOption
    let size: CGSize
    let maxImageSize: CGSize
    let usesHorizontalContent: Bool
    let appliesLowContrastOverlay: Bool
    let isWrong: Bool
    let isCorrect: Bool
    let isBlurred: Bool
    let isInteractionLocked: Bool
    let shakeTrigger: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(primaryBlue, lineWidth: 5)
                        )

                    optionContent
                        .padding(usesHorizontalContent ? 16 : 12)

                    if appliesLowContrastOverlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.65))
                            .padding(4)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: size.width, height: size.height)
                .blur(radius: isBlurred ? 2 : 0)
                .opacity(isBlurred ? 0.35 : 1)

                if isCorrect {
                    correctAnswerBadge
                        .offset(
                            x: correctAnswerBadgeDiameter * 0.22,
                            y: correctAnswerBadgeDiameter * 0.22
                        )
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isInteractionLocked)
        .wrongAnswerFeedback(
            isWrong: isWrong,
            shakeTrigger: shakeTrigger,
            cornerRadius: 18
        )
        .accessibilityLabel(
            isCorrect
                ? "\(option.text ?? "Pilihan jawaban"), jawaban benar"
                : option.text ?? "Pilihan jawaban"
        )
    }

    private var correctAnswerBadgeDiameter: CGFloat {
        max(28, min(size.width, size.height) * 0.32)
    }

    private var correctAnswerBadge: some View {
        Circle()
            .fill(primaryBlue)
            .frame(width: correctAnswerBadgeDiameter, height: correctAnswerBadgeDiameter)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: correctAnswerBadgeDiameter * 0.52, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var optionContent: some View {
        if usesHorizontalContent {
            HStack(spacing: 18) {
                optionImage

                optionText
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 8) {
                optionImage
                optionText
            }
        }
    }

    @ViewBuilder
    private var optionImage: some View {
        if let imageAssetName = option.imageAssetName {
            Image(imageAssetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxImageSize.width, maxHeight: maxImageSize.height)
        }
    }

    @ViewBuilder
    private var optionText: some View {
        if let text = option.text {
            Text(text)
                .appScaledFont(
                    size: 34,
                    relativeTo: .title,
                    weight: .bold
                )
                .foregroundStyle(primaryBlue)
                .multilineTextAlignment(usesHorizontalContent ? .leading : .center)
                // Scales with Larger Text, but shrinks to fit the fixed button
                // so the whole label shows without overflowing or truncating.
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Color-Filter-Safe Vertical Scroll

/// A minimal vertical scroller built from pure SwiftUI (offset + clip + drag),
/// used where a normal `ScrollView` can't be: a UIKit `ScrollView` cannot be
/// rasterized by the color-vision `colorEffect` shader and renders blank, but
/// this offset-based content survives it. It only scrolls when the content is
/// taller than the space it's given; otherwise it behaves like a plain VStack.
private struct ColorFilterSafeVScroll<Content: View>: View {

    @ViewBuilder let content: Content

    /// Committed scroll position (0 = top, negative moves content up).
    @State private var offset: CGFloat = 0
    /// Measured height of the content, used to bound scrolling.
    @State private var contentHeight: CGFloat = 0
    /// Live finger translation during a drag.
    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { viewport in
            let maxScroll = max(contentHeight - viewport.size.height, 0)
            // Positive only while the text fits — centers it vertically. Zero
            // once it overflows, so it pins to the top and scrolls.
            let centerInset = max((viewport.size.height - contentHeight) / 2, 0)
            let live = centerInset + min(max(offset + dragTranslation, -maxScroll), 0)

            content
                // Constrain the width FIRST, then measure — otherwise the
                // height is read at the text's unwrapped one-line width and
                // overflow (and the scroll hint) is never detected.
                .frame(width: viewport.size.width, alignment: .top)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ContentHeightKey.self, value: proxy.size.height)
                    }
                )
                .offset(y: live)
                .frame(height: viewport.size.height, alignment: .top)
                .clipped()
                // A slim scrollbar on the right of the title space appears only
                // when a meaningful chunk is hidden (more than ~10% off-screen)
                // — a tiny overflow shouldn't show a bar that can't move.
                .overlay(alignment: .trailing) {
                    if maxScroll > 12,
                       viewport.size.height < contentHeight * 0.9 {
                        scrollBar(viewportHeight: viewport.size.height)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .updating($dragTranslation) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            offset = min(max(offset + value.translation.height, -maxScroll), 0)
                        }
                )
                .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
        }
        // Hug the text so the surrounding spacers can center the whole content
        // block; when the card squeezes this below the text height it scrolls.
        .frame(maxHeight: contentHeight)
    }

    /// Draws the scroll thumb on the right of the title space: its length
    /// reflects how much of the text is visible, its position how far scrolled.
    private func scrollBar(viewportHeight: CGFloat) -> some View {
        let maxScroll = max(contentHeight - viewportHeight, 0)
        let inset: CGFloat = 6
        let trackHeight = max(viewportHeight - inset * 2, 0)
        let visibleRatio = min(viewportHeight / max(contentHeight, 1), 1)
        let thumbHeight = max(trackHeight * visibleRatio, 24)
        let scrolled = -min(max(offset + dragTranslation, -maxScroll), 0)
        let progress = maxScroll > 0 ? scrolled / maxScroll : 0
        let thumbY = inset + progress * (trackHeight - thumbHeight)

        return GeometryReader { proxy in
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 5, height: thumbHeight)
                .position(x: proxy.size.width - 7, y: thumbY + thumbHeight / 2)
        }
        .allowsHitTesting(false)
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    // Use max so the measured content height wins over the default (0) that
    // sibling subtrees (the fade/chevron overlay) also contribute.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview(traits: .landscapeRight) {
    NavigationStack {
        ChapterGamePlayView(
            viewModel: ChapterGameplayViewModel(
                chapter: Chapter(
                    id: "chapter-1",
                    order: 1,
                    title: "Bentuk Membantu Mika di Kelas",
                    subtitle: nil,
                    description: "",
                    thumbnailAssetName: "",
                    competency: .shape,
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
                            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari lokasi benda berdasarkan bentuk, bukan warna.",
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
                source: .mainStory,
                storageService: StorageService()
            )
        )
        .environmentObject(
            SettingsViewModel(
                storageService: StorageService()
            )
        )
    }
}
