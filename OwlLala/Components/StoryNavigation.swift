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
    private let blockHeight: CGFloat = 150

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
        // The box keeps a FIXED size at every Dynamic Type setting — only the
        // text inside scales. When the text grows past the box it scrolls
        // instead of shrinking or truncating with an ellipsis. A pure-SwiftUI
        // scroller is used because the color-vision shader can't rasterize a
        // UIKit `ScrollView` and would render its content blank.
        NarrationScroll {
            Text(narration)
                .appScaledFont(size: 28)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 36)
                .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: blockHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 4)
        )
        .accessibilityLabel(narration)
    }
}

// MARK: - Narration Scroll

/// A minimal vertical scroller built entirely in SwiftUI (no UIKit
/// `ScrollView`), so the color-vision shader can rasterize its content instead
/// of rendering it blank. Content that fits is centered in the box for a clean
/// standard look; content taller than the box is pinned to the top (so reading
/// starts at the first line) and can be dragged up to read the rest.
private struct NarrationScroll<Content: View>: View {

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
            // Positive only while the content fits — centers it vertically.
            // Zero once it overflows, so it pins to the top and scrolls.
            let centerInset = max((viewport.size.height - contentHeight) / 2, 0)
            let live = centerInset + min(max(offset + dragTranslation, -maxScroll), 0)

            content
                .frame(width: viewport.size.width, alignment: .top)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: NarrationHeightKey.self, value: proxy.size.height)
                    }
                )
                .offset(y: live)
                .frame(width: viewport.size.width, height: viewport.size.height, alignment: .top)
                .clipped()
                // A slim scrollbar on the right appears only when the text is
                // taller than the box, showing there is more to read below.
                .overlay(alignment: .trailing) {
                    if maxScroll > 0 {
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
                .onPreferenceChange(NarrationHeightKey.self) { contentHeight = $0 }
        }
    }

    /// Draws the scroll thumb: its length reflects how much of the text is
    /// visible, and its position reflects how far the reader has scrolled.
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

private struct NarrationHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    // Use max so the measured content height wins over the default (0) that
    // sibling subtrees (the scrollbar/overlay) also contribute.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
