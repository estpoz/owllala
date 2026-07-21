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
    @State private var isVoiceOverEnabled = true
    @State private var isShowingExitConfirmation = false
    @State private var isShowingSettings = false
    @State private var isShowingSuccessOverlay = false
    @State private var hasStartedChapter = false

    init(viewModel: ChapterGameplayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

            if isShowingExitConfirmation {
                ExitConfirmation(
                    onContinueLearning: {
                        isShowingExitConfirmation = false
                        resumeStoryVoiceOverIfNeeded()
                    },
                    onDiscardProgress: {
                        stopStoryVoiceOver()
                        dismiss()
                    }
                )
                .zIndex(2)
            }

            // MARK: - Success overlay, layered on top of gameplay
            if isShowingSuccessOverlay {
                StageClearedView(
                    title: "Hebat Sekali!",
                    subtitle: "Kamu berhasil menyelesaikan \(viewModel.chapter.title)",
                    starCount: viewModel.earnedStars ?? Chapter.maximumStars,
                    maxStars: 3,
                    summaryText: viewModel.chapter.learningSummary.explanation,
                    onReplay: {
                        stopStoryVoiceOver()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowingSuccessOverlay = false
                        }
                        viewModel.resetForReplay()
                        hasStartedChapter = viewModel.source == .training
                    },
                    onContinue: {
                        stopStoryVoiceOver()
                        viewModel.finishStageCleared()
                        dismiss()
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        // A separate transparent presentation keeps the modal's AX ScrollView
        // outside gameplay's shader while preserving the same centered card
        // and live preview over the game beneath it.
        .fullScreenCover(
            isPresented: $isShowingSettings,
            onDismiss: resumeStoryVoiceOverIfNeeded
        ) {
            SettingsView(viewModel: settingsViewModel, isModal: true) {
                isShowingSettings = false
            }
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

            stopStoryVoiceOver()
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
        .onDisappear {
            stopStoryVoiceOver()
        }
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

                VStack(spacing: baseUnit * 0.035) {
                    Text("Bab \(viewModel.chapter.order)")
                        .appScaledFont(
                            size: AppFontSize.largeTitle,
                            relativeTo: .largeTitle,
                            weight: .bold
                        )
                        .foregroundStyle(.black)

                    Text(viewModel.chapter.title)
                        .appScaledFont(
                            size: AppFontSize.headline,
                            relativeTo: .headline,
                            weight: .medium
                        )
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text("\(totalGameplayPages) Halaman")
                        .appScaledFont(size: AppFontSize.body)
                        .foregroundStyle(primaryBlue)

                    PrimaryActionButton(title: "Mulai") {
                        startChapter()
                    }
                    .accessibilityLabel("Mulai Bab \(viewModel.chapter.order)")
                }
                .padding(baseUnit * 0.05)
                .frame(width: geometry.size.width * 0.5)
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
                        weight: .semibold
                    )
                    .foregroundStyle(primaryBlue)
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
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

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
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
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
                    .font(.owlHeadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)

                VStack(alignment: .leading, spacing: geometry.size.height * 0.006) {
                    Text("Bentuk : Kotak")
                    Text("Warna : Biru")
                    Text("Pola : Bergaris")
                }
                .font(.owlBody)
                .fontWeight(.bold)
                .foregroundStyle(primaryBlue)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

    private func startChapter() {
        hasStartedChapter = true

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

}

private struct AnswerOptionButton: View {

    let option: AnswerOption
    let size: CGSize
    let maxImageSize: CGSize
    let usesHorizontalContent: Bool
    let appliesLowContrastOverlay: Bool
    let isWrong: Bool
    let shakeTrigger: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(.plain)
        .wrongAnswerFeedback(
            isWrong: isWrong,
            shakeTrigger: shakeTrigger,
            cornerRadius: 18
        )
        .accessibilityLabel(option.text ?? "Pilihan jawaban")
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
                .lineLimit(2)
                .minimumScaleFactor(0.65)
        }
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
