//
//  SplashScreenView.swift
//  OwlLala
//
//  Created by Amanda on 14/07/26.
//

import SwiftUI

struct SplashScreenView: View {

    /// Called automatically after the splash animation has had time to play.
    var onFinished: () -> Void = {}

    @State private var visibleCharacterCount = 0
    @State private var isOwlVisible = false
    @State private var isOwlWinking = false
    @State private var didFinish = false

    private let splashLetters = SplashLetter.owllala
    private let letterInterval: UInt64 = 220_000_000
    private let owlHoldDuration: UInt64 = 1_350_000_000

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)

            AppScreen {
                SplashBackground()
            } content: {
                ZStack{
                    AnimatedSplashTitle(
                        letters: splashLetters,
                        visibleCharacterCount: visibleCharacterCount,
                        letterHeight: baseUnit * 0.16
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.34)

                    SplashOwlView(
                        isVisible: isOwlVisible,
                        isWinking: isOwlWinking,
                        size: CGSize(
                            width: geometry.size.width * 0.28,
                            height: geometry.size.height * 0.32
                        )
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.60)
                    .accessibilityHidden(true)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .task {
            await playSplashSequence()
        }
    }

    @MainActor
    private func playSplashSequence() async {
        guard visibleCharacterCount == 0, !didFinish else {
            return
        }

        for index in 1...splashLetters.count {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
                visibleCharacterCount = index
            }
            try? await Task.sleep(nanoseconds: letterInterval)
        }

        withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
            isOwlVisible = true
        }

        try? await Task.sleep(nanoseconds: 420_000_000)

        withAnimation(.easeInOut(duration: 0.12)) {
            isOwlWinking = true
        }

        try? await Task.sleep(nanoseconds: 260_000_000)

        withAnimation(.easeOut(duration: 0.12)) {
            isOwlWinking = false
        }

        try? await Task.sleep(nanoseconds: owlHoldDuration)
        finishIfNeeded()
    }

    @MainActor
    private func finishIfNeeded() {
        guard !didFinish else {
            return
        }

        didFinish = true
        onFinished()
    }
}

private struct SplashLetter: Identifiable {
    let id: Int
    let imageName: String
    let widthScale: CGFloat
    let xNudgeScale: CGFloat
    let yOffsetScale: CGFloat
    let rotationDegrees: Double

    static let owllala: [SplashLetter] = [
        SplashLetter(id: 0, imageName: "O", widthScale: 0.80, xNudgeScale: 0.06, yOffsetScale: 0.18, rotationDegrees: -1.5),
        SplashLetter(id: 1, imageName: "W", widthScale: 1.18, xNudgeScale: -0.08, yOffsetScale: 0.00, rotationDegrees: -0.8),
        SplashLetter(id: 2, imageName: "LBiru", widthScale: 0.58, xNudgeScale: -0.10, yOffsetScale: -0.04, rotationDegrees: -0.2),
        SplashLetter(id: 3, imageName: "LHitam", widthScale: 0.58, xNudgeScale: -0.10, yOffsetScale: -0.05, rotationDegrees: 0.2),
        SplashLetter(id: 4, imageName: "A1", widthScale: 0.82, xNudgeScale: -0.12, yOffsetScale: -0.02, rotationDegrees: 0.8),
        SplashLetter(id: 5, imageName: "L2Hitam", widthScale: 0.58, xNudgeScale: -0.12, yOffsetScale: 0.02, rotationDegrees: 1.2),
        SplashLetter(id: 6, imageName: "A2", widthScale: 0.82, xNudgeScale: -0.14, yOffsetScale: 0.16, rotationDegrees: 2.0)
    ]
}

private struct AnimatedSplashTitle: View {

    let letters: [SplashLetter]
    let visibleCharacterCount: Int
    let letterHeight: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: letterHeight * 0.12) {
            ForEach(Array(letters.enumerated()), id: \.element.id) { index, letter in
                Image(letter.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: letterHeight * letter.widthScale, height: letterHeight)
                    .rotationEffect(.degrees(letter.rotationDegrees))
                    .offset(
                        x: letterHeight * letter.xNudgeScale,
                        y: letterHeight * letter.yOffsetScale
                    )
                    .opacity(index < visibleCharacterCount ? 1 : 0)
                    .scaleEffect(index < visibleCharacterCount ? 1 : 0.72)
            }
        }
        .accessibilityLabel("OWLLALA")
    }
}

private struct SplashOwlView: View {

    let isVisible: Bool
    let isWinking: Bool
    let size: CGSize

    var body: some View {
        ZStack {
            splashOwlImage("owlSplash")
                .opacity(isWinking ? 0.0 : 1.0)

            splashOwlImage("owlWinkSplash")
                .opacity(isWinking ? 1.0 : 0.0)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(isVisible ? 1.0 : 0.72)
        .opacity(isVisible ? 1.0 : 0.0)
    }

    private func splashOwlImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
    }
}

private struct SplashBackground: View {

    var body: some View {
        GeometryReader { geometry in
            Image("bgPattern")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
        }
    }
}

#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return SplashScreenView()
        .environmentObject(storageService)
        .environmentObject(SettingsViewModel(storageService: storageService))
}
