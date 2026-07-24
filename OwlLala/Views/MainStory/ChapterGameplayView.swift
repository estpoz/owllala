//
//  ChapterGamePlayView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 17/07/26.
//

import SwiftUI

struct ChapterGamePlayView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @StateObject private var viewModel: ChapterGameplayViewModel

    /// Closure callback invoked when the user finishes a chapter
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

    var body: some View {
        ZStack {
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
                .appTextSizeAdjustment()
                .environmentObject(settingsViewModel)
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
            title: "Hebat Sekali!",
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
                
                // Triggers parent completion callback
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

                    // Pinned — stays put at every text size, like the button.
                    // Matches the "Bab" heading's size so both read at the same
                    // scale on every chapter's start page.
                    Text("\(totalGameplayPages) Halaman")
                        .appScaledFont(
                            size: AppFontSize.largeTitle,
                            relativeTo: .largeTitle,
                            weight: .bold
                        )
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        // Shrinks to fit the card at big text sizes instead of
                        // truncating with an ellipsis.
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)

                    // Pinned at the bottom — stays put at every text size.
                    PrimaryActionButton(title: "Mulai Baca") {
                        startChapter()
                    }
                    .accessibilityLabel("Mulai Bab \(viewModel.chapter.order)")
                }
                .padding(baseUnit * 0.05)
                .frame(
                    width: geometry.size.width * 0.5,
                    height: geometry.size.height * 0.55
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
        usesTwoColumnAnswerLayout ? 0.12 : 0.055
    }

    private var answerTopSpacing: CGFloat {
        usesTwoColumnAnswerLayout ? 0.075 : 0.035
    }

    private var questionInstructionText: String {
        usesTwoColumnAnswerLayout ? "Tekan penanda yang sesuai" : "Tekan objek yang sesuai"
    }

    @ViewBuilder
    private func questionPromptArea(in geometry: GeometryProxy) -> some View {
        if usesChapterFivePromptLayout {
            chapterFivePromptArea(in: geometry)
        } else if let promptImageAssetName = viewModel.question.promptImageAssetName {
            VStack(spacing: geometry.size.height * 0.02) {
                Text(viewModel.question.prompt)
                    .appScaledFont(
                        size: AppFontSize.headline,
                        relativeTo: .headline,
                        weight: .bold
                    )
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    // Scales with Larger Text, but shrinks to fit its slot so
                    // the whole prompt stays on screen and never truncates.
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)

                HStack(alignment: .center, spacing: geometry.size.width * 0.055) {
                    Image(promptImageAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * (usesCompactPromptImageLayout ? 0.15 : 0.18),
                            height: geometry.size.height * (usesCompactPromptImageLayout ? 0.17 : 0.24)
                        )
                        .accessibilityLabel("Gambar petunjuk")

                    Image("ingameOwl")
                        .resizable()
                        .scaledToFit()
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
                Text(viewModel.question.prompt)
                    .appScaledFont(
                        size: AppFontSize.headline,
                        relativeTo: .headline,
                        weight: .bold
                    )
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    // Scales with Larger Text, but shrinks to fit its slot so
                    // the whole prompt stays on screen and never truncates.
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .frame(width: geometry.size.width * 0.42, alignment: .trailing)

                Image("ingameOwl")
                    .resizable()
                    .scaledToFit()
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
                Text(viewModel.question.prompt)
                    .appScaledFont(
                        size: AppFontSize.headline,
                        relativeTo: .headline,
                        weight: .bold
                    )
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    // Scales with Larger Text, but shrinks to fit its slot so
                    // the whole prompt stays on screen and never truncates.
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)

                VStack(alignment: .leading, spacing: geometry.size.height * 0.006) {
                    Text("Bentuk : Kotak")
                    Text("Warna : Biru")
                    Text("Pola : Bergaris")
                }
                .appScaledFont(
                    size: AppFontSize.body,
                    relativeTo: .body,
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
                    GridItem(.fixed(geometry.size.width * 0.32), spacing: geometry.size.width * 0.035),
                    GridItem(.fixed(geometry.size.width * 0.32), spacing: geometry.size.width * 0.035)
                ],
                spacing: geometry.size.height * 0.035
            ) {
                ForEach(viewModel.question.answerOptions) { option in
                    AnswerOptionButton(
                        option: option,
                        size: CGSize(
                            width: geometry.size.width * 0.32,
                            height: geometry.size.height * 0.12
                        ),
                        maxImageSize: CGSize(
                            width: geometry.size.width * 0.08,
                            height: geometry.size.height * 0.075
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
                    size: AppFontSize.body,
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

private struct ColorFilterSafeVScroll<Content: View>: View {

    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { viewport in
            let maxScroll = max(contentHeight - viewport.size.height, 0)
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
                // A white fade with a down chevron while there is still text
                // below the fold, mirroring the scroll hint on the stats page.
                .overlay(alignment: .bottom) {
                    if maxScroll > 0 && live > -maxScroll + 0.5 {
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 44)
                        .overlay(alignment: .bottom) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.gray.opacity(0.7))
                        }
                        .allowsHitTesting(false)
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
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "chapter-1-question",
                            prompt: "Objek mana yang cocok dengan bayangan ini?",
                            promptImageAssetName: "lunchboxSilhouette",
                            answerOptions: [
                                AnswerOption(id: "lunchbox", text: nil, imageAssetName: "lunchbox")
                            ],
                            correctAnswerID: "lunchbox",
                            hintText: "Coba perhatikan bentuknya."
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "Lala menemukan kotak makannya!",
                        explanation: "Kamu mengenali objek berdasarkan bentuknya, bukan warnanya.",
                        mainIllustrationAssetName: "lunchbox",
                        exampleAssetNames: ["lunchbox"]
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
