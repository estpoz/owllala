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

    init(viewModel: ChapterGameplayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(red: 0.937, green: 0.953, blue: 0.957)
                .ignoresSafeArea()

            if viewModel.isQuestionPresented {
                questionPlaceholder
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
                        // arrow.counterclockwise -> stay on ChapterGamePlayView, restart the chapter
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowingSuccessOverlay = false
                        }
                        resetGameplay()
                    },
                    onContinue: {
                        // play.circle -> pop back to ChapterSelectionView
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
                    },
                    onDiscardProgress: {
                        dismiss()
                    }
                )
                .zIndex(2)
            }

            if isShowingSettings {
                SettingsModalView(viewModel: settingsViewModel) {
                    isShowingSettings = false
                }
                .zIndex(3)
            }
        }
        .navigationBarHidden(true)
    }

    private func storyPageContent(_ storyPage: StoryPage) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                GameplayTopBar(
                    currentPage: viewModel.currentStoryPageIndex + 1,
                    totalPages: viewModel.chapter.storyPages.count,
                    isVoiceOverEnabled: isVoiceOverEnabled,
                    onShowExitConfirmation: {
                        isShowingExitConfirmation = true
                    },
                    onToggleVoiceOver: {
                        isVoiceOverEnabled.toggle()
                    },
                    onShowSettings: {
                        isShowingSettings = true
                    }
                )
                .padding(.horizontal, geometry.size.width * 0.045)
                .padding(.top, geometry.size.height * 0.045)

                Spacer(minLength: geometry.size.height * 0.02)

                Image(storyPage.illustrationAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: geometry.size.width * 0.78,
                        maxHeight: geometry.size.height * 0.54
                    )
                    .accessibilityLabel("Ilustrasi cerita")

                Spacer(minLength: geometry.size.height * 0.02)

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
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var questionPlaceholder: some View {
        VStack(spacing: 24) {
            Text(viewModel.chapter.title)
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.question.prompt)
                .font(.owlHeadline)
                .multilineTextAlignment(.center)

            Button("Selesaikan Bab (debug)") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingSuccessOverlay = true
                }
            }
        }
        .padding()
    }

    private func resetGameplay() {
        // Reset progress state for this chapter (question index, answers, timer, etc.)
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
                            illustrationAssetName: "storyChapter1-1",
                            narration: "Lala melihat kotak bekal di kelas dan belajar mengenali benda dari bentuknya.",
                            voiceOverAssetName: nil
                        )
                    ],
                    gameConfiguration: GameConfiguration(
                        question: GameQuestion(
                            id: "q1",
                            prompt: "Cari benda berbentuk kotak",
                            promptImageAssetName: nil,
                            answerOptions: [],
                            correctAnswerID: "",
                            hintText: ""
                        )
                    ),
                    learningSummary: LearningSummary(
                        successMessage: "",
                        explanation: "Kamu mengenali objek berdasarkan bentuknya.",
                        mainIllustrationAssetName: "",
                        exampleAssetNames: []
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
