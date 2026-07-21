//
//  StoryNavigation.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

// MARK: - Story Narration

/// Displays the story-page narration with previous and next page controls.
///
/// The host owns page state and decides whether each chevron is available.
/// Keep `canGoPrevious` false on the first page so the back chevron is hidden;
/// keep `canGoNext` true on the last story page when the next tap starts the
/// chapter mini-game.
struct StoryNarrationBlock: View {

    /// Indonesian narration shown below the story illustration.
    let narration: String

    /// Whether the previous-page chevron should be visible and tappable.
    let canGoPrevious: Bool

    /// Whether the next-page chevron should be visible and tappable.
    let canGoNext: Bool

    /// Invoked when the child taps the previous-page chevron.
    let onPrevious: () -> Void

    /// Invoked when the child taps the next-page chevron.
    let onNext: () -> Void

    private let buttonDiameter: CGFloat = 44
    private let borderColor = Color(red: 0.15, green: 0.15, blue: 0.15)
    private let blockCornerRadius: CGFloat = 12
    private let blockHeight: CGFloat = 110

    var body: some View {
        HStack(spacing: 12) {
            StoryChevronButton(
                systemImageName: "chevron.left.circle.fill",
                accessibilityLabel: "Halaman sebelumnya",
                isVisible: canGoPrevious,
                diameter: buttonDiameter,
                action: onPrevious
            )

            narrationText

            StoryChevronButton(
                systemImageName: "chevron.right.circle.fill",
                accessibilityLabel: "Halaman berikutnya",
                isVisible: canGoNext,
                diameter: buttonDiameter,
                action: onNext
            )
        }
        .accessibilityElement(children: .contain)
    }

    private var narrationText: some View {
        Text(narration)
            .appScaledFont(size: 28)
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 36)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: blockHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 4)
            )
            .accessibilityLabel(narration)
    }
}

// MARK: - Story Chevron Button

private struct StoryChevronButton: View {

    let systemImageName: String
    let accessibilityLabel: String
    let isVisible: Bool
    let diameter: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: diameter, weight: .bold))
                .foregroundStyle(primaryBlue)
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .disabled(!isVisible)
        .accessibilityHidden(!isVisible)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Previews

#Preview("Story Narration") {
    VStack(spacing: 32) {
        StoryNarrationBlock(
            narration: "Cluey datang membantu Lala dan mengajarkannya untuk mencari benda berdasarkan bentuk, bukan warna.",
            canGoPrevious: true,
            canGoNext: true,
            onPrevious: {},
            onNext: {}
        )

        StoryNarrationBlock(
            narration: "Lala mencoba mengingat bentuk bekalnya dan menyadari bahwa bekalnya berbentuk seperti kotak kecil dengan pegangan.",
            canGoPrevious: false,
            canGoNext: true,
            onPrevious: {},
            onNext: {}
        )
    }
    .padding(40)
    .background(Color(red: 0.937, green: 0.953, blue: 0.957))
}
