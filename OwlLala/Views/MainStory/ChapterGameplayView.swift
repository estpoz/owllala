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

    private var displayedPageCount: Int {
        max(viewModel.chapter.storyPages.count + 1, 5)
    }

    var body: some View {
        ZStack {
            Color(red: 0.937, green: 0.953, blue: 0.957)
                .ignoresSafeArea()

            if viewModel.source == .mainStory && !hasStartedChapter {
                startChapterContent
            } else if viewModel.isQuestionPresented {
                questionContent
            } else if let storyPage = viewModel.currentStoryPage {
                storyPageContent(storyPage)
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

            if isShowingSettings {
                SettingsModalView(viewModel: settingsViewModel) {
                    isShowingSettings = false
                    resumeStoryVoiceOverIfNeeded()
                }
                .zIndex(3)
            }
        }
        .navigationBarHidden(true)
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

                VStack(spacing: baseUnit * 0.035) {
                    Text("Bab \(viewModel.chapter.order)")
                        .font(.owlLargeTitle)
                        .foregroundStyle(.black)

                    Text(viewModel.chapter.title)
                        .font(.owlHeadline)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text("\(displayedPageCount) Halaman")
                        .font(.owlBody)
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
                        currentPage: viewModel.currentStoryPageIndex + 1,
                        totalPages: displayedPageCount,
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
                    currentPage: viewModel.chapter.storyPages.count + 1,
                    totalPages: displayedPageCount,
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

                Spacer(minLength: geometry.size.height * 0.035)

                HStack(alignment: .center, spacing: geometry.size.width * 0.05) {
                    Text(viewModel.question.prompt)
                        .font(.owlHeadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                        .frame(width: geometry.size.width * 0.24, alignment: .leading)

                    if let promptImageAssetName = viewModel.question.promptImageAssetName {
                        Image(promptImageAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geometry.size.width * 0.16,
                                height: geometry.size.height * 0.3
                            )
                            .accessibilityLabel("Bayangan benda")
                    }

                    Image("ingameOwl")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 0.25,
                            height: geometry.size.height * 0.33
                        )
                        .accessibilityHidden(true)
                }

                Spacer(minLength: geometry.size.height * 0.035)

                answerOptionsGrid(in: geometry)

                Text("Tekan objek yang sesuai")
                    .font(.owlBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryBlue)
                    .padding(.top, geometry.size.height * 0.018)
                    .padding(.bottom, geometry.size.height * 0.035)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func answerOptionsGrid(in geometry: GeometryProxy) -> some View {
        HStack(spacing: geometry.size.width * 0.018) {
            ForEach(viewModel.question.answerOptions) { option in
                AnswerOptionButton(
                    option: option,
                    size: CGSize(
                        width: geometry.size.width * 0.2,
                        height: geometry.size.height * 0.25
                    ),
                    maxImageSize: CGSize(
                        width: geometry.size.width * 0.12,
                        height: geometry.size.height * 0.18
                    ),
                    isWrong: viewModel.incorrectAnswerID == option.id,
                    shakeTrigger: viewModel.shakeTrigger,
                    action: {
                        viewModel.selectAnswer(option)
                    }
                )
            }
        }
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

                VStack(spacing: 8) {
                    if let imageAssetName = option.imageAssetName {
                        Image(imageAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: maxImageSize.width, maxHeight: maxImageSize.height)
                    }

                    if let text = option.text {
                        Text(text)
                            .font(.owlBody)
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(12)
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
