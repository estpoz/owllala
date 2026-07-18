//
//  ChapterGamePlayView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 17/07/26.
//

import SwiftUI

struct ChapterGamePlayView: View {

    let chapter: Chapter

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingSuccessOverlay = false
    @State private var earnedStars: Int = 3

    var body: some View {
        ZStack {
            // MARK: - Actual gameplay content goes here
            Color(red: 0.937, green: 0.953, blue: 0.957)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(chapter.title)
                    .font(.title)
                    .fontWeight(.bold)

                Button("Selesaikan Bab (debug)") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingSuccessOverlay = true
                    }
                }
            }

            // MARK: - Success overlay, layered on top of gameplay
            if isShowingSuccessOverlay {
                StageClearedView(
                    title: "Hebat Sekali!",
                    subtitle: "Kamu berhasil menyelesaikan \(chapter.title)",
                    starCount: earnedStars,
                    maxStars: 3,
                    summaryText: chapter.learningSummary.explanation,
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
        }
        .navigationBarHidden(true)
    }

    private func resetGameplay() {
        // Reset progress state for this chapter (question index, answers, timer, etc.)
    }
}

#Preview(traits: .landscapeRight) {
    NavigationStack {
        ChapterGamePlayView(
            chapter: Chapter(
                id: "chapter-1",
                order: 1,
                title: "Bentuk Membantu Mika di Kelas",
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
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
            )
        )
    }
}
