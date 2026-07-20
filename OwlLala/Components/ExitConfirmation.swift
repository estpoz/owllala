//
//  ExitConfirmation.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  A reusable modal (dialog) that asks the child to confirm before they leave a
//  learning session and lose their in-progress score. It renders its own dimmed
//  full-screen backdrop plus a centered white card, so it is meant to be placed
//  in a `ZStack` on top of whatever screen is currently showing — it is not a
//  pushed/navigated screen.
//
//  WHERE IT IS USED
//  ----------------
//  Presentation-only component: it owns no state and talks to its parent purely
//  through the two closures below. It is intended to be shown as an overlay from
//  the chapter mini-game screens (e.g. the Main Story `Chapter*GameplayView` and
//  `TrainingModeView`) when the child taps the exit/close control mid-game,
//  before `ChapterGameplayViewModel` has saved a completion. A typical host:
//
//      ZStack {
//          GameplayContent(...)
//          if isExitPromptVisible {
//              ExitConfirmation(
//                  onContinueLearning: { isExitPromptVisible = false },
//                  onDiscardProgress:  { dismissGame() }
//              )
//          }
//      }
//
//  NOTE: As of now no parent view references this type yet (the `Views/` files
//  are still stubs), so the call sites above are the planned integration, not
//  existing ones.
//

import SwiftUI

// MARK: - Exit Confirmation Dialog

/// A confirmation dialog shown before the child abandons a learning session.
///
/// The view is fully self-contained and responsive: it sizes its card from the
/// available space (`makeLayout(for:)`) and scales its text with the system
/// Dynamic Type setting, so it works across iPad sizes and accessibility text
/// sizes without the caller configuring anything.
///
/// All copy is fixed Indonesian, matching the rest of the app.
struct ExitConfirmation: View {

    /// Invoked when the child chooses to stay ("Kembali Belajar").
    ///
    /// The host should dismiss this dialog and resume the game. This component
    /// does not dismiss itself — the parent controls visibility.
    let onContinueLearning: () -> Void

    /// Invoked when the child confirms leaving ("Hilangkan progress").
    ///
    /// The host should tear down the current session and navigate away. The
    /// unsaved score is intentionally discarded.
    let onDiscardProgress: () -> Void

    /// The current Dynamic Type size, used to grow the card when the child uses
    /// an accessibility text size (see `panelHeightRatio` in `makeLayout`).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Dynamic Type multipliers for the three text roles in the card. Each one
    /// tracks a different text style so the title, buttons, and spacing scale
    /// proportionally with the user's chosen size.
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title2) private var buttonScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var spacingScale: CGFloat = 1

    /// The brand blue used for the primary button fill and the secondary
    /// button's text/border. Kept in sync with the palette in `Buttons.swift`.
    private let primaryBlue = AppColor.primary

    var body: some View {
        // `GeometryReader` gives us the space the dialog is presented in so the
        // card can be sized relative to the host screen.
        GeometryReader { geometry in
            let layout = makeLayout(for: geometry.size)

            ZStack {
                // Dimmed backdrop that covers the whole screen and visually
                // separates the dialog from the game behind it.
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                // The centralized scroll container keeps the content reachable
                // while applying the saved color filter inside the scroll view.
                AppFilteredScrollView {
                    VStack(spacing: 0) {
                        // Question / title.
                        Text("Apa kamu yakin mau\nkehilangan progress\nbelajarmu?")
                            .font(.system(size: layout.titleFontSize, weight: .bold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(layout.titleFontSize * 0.18)
                            .padding(.horizontal, layout.horizontalPadding)
                            .padding(.top, layout.verticalPadding)

                        VStack(spacing: layout.buttonSpacing) {
                            // Primary action: stay and keep learning (filled).
                            Button(action: onContinueLearning) {
                                Text("Kembali Belajar")
                                    .font(.system(size: layout.buttonFontSize, weight: .regular))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, layout.buttonHorizontalPadding)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: layout.primaryButtonHeight)
                                    .background(primaryBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: layout.buttonCornerRadius, style: .continuous))
                            }

                            // Destructive action: leave and lose progress
                            // (outlined, to read as the less-preferred option).
                            Button(action: onDiscardProgress) {
                                Text("Hilangkan progress")
                                    .font(.system(size: layout.buttonFontSize, weight: .regular))
                                    .foregroundStyle(primaryBlue)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, layout.buttonHorizontalPadding)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: layout.secondaryButtonHeight)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: layout.buttonCornerRadius, style: .continuous)
                                            .stroke(primaryBlue, lineWidth: 3)
                                    }
                            }
                        }
                        .frame(maxWidth: layout.buttonMaxWidth)
                        .padding(.top, layout.contentSpacing)
                        .padding(.horizontal, layout.horizontalPadding)
                        .padding(.bottom, layout.verticalPadding)

                        Spacer(minLength: 0)
                    }
                }
                .frame(width: layout.panelWidth, height: layout.panelHeight)
                .background(Color.white.appBackgroundAdjustments())
                .clipShape(RoundedRectangle(cornerRadius: layout.panelCornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
            }
        }
    }

    /// Computes every size/spacing value the card needs for a given container
    /// size, returning them together in a `ModalLayout`.
    ///
    /// The rules are proportional (a fraction of the panel width/height) and
    /// then `clamped` to sensible bounds, which keeps the card looking right
    /// from small split-view widths up to a full iPad screen:
    /// - `isCompact` (short side < 500 pt) → wider card, larger relative fonts.
    /// - `isLarge` (roomy screens) → narrower card so it doesn't sprawl.
    /// - Accessibility text sizes → taller card to fit the scaled content.
    ///
    /// - Parameter size: The space the dialog is being presented in (from the
    ///   surrounding `GeometryReader`).
    /// - Returns: A fully-resolved `ModalLayout` for this presentation.
    private func makeLayout(for size: CGSize) -> ModalLayout {
        let shortestSide = min(size.width, size.height)
        let isCompact = shortestSide < 500
        let isLarge = size.width >= 900 && size.height >= 700
        let panelWidthRatio: CGFloat = isCompact ? 0.90 : (isLarge ? 0.66 : 0.76)
        let panelHeightRatio: CGFloat = dynamicTypeSize.isAccessibilitySize ? 0.88 : (isCompact ? 0.72 : 0.64)
        let panelWidth = (size.width * panelWidthRatio).clamped(to: 280...820)
        let panelHeight = (size.height * panelHeightRatio).clamped(to: 320...760)
        let titleBaseSize = (panelWidth * (isCompact ? 0.070 : 0.058)).clamped(to: 28...46)
        let buttonBaseSize = (panelWidth * (isCompact ? 0.045 : 0.038)).clamped(to: 19...30)
        let buttonMaxWidth = (panelWidth * (isCompact ? 0.78 : 0.56)).clamped(to: 230...440)

        return ModalLayout(
            panelWidth: panelWidth,
            panelHeight: panelHeight,
            panelCornerRadius: (panelWidth * 0.032).clamped(to: 18...28),
            titleFontSize: titleBaseSize * titleScale,
            buttonFontSize: buttonBaseSize * buttonScale,
            buttonMaxWidth: buttonMaxWidth,
            primaryButtonHeight: max(panelHeight * 0.13, 52 * buttonScale),
            secondaryButtonHeight: max(panelHeight * 0.12, 48 * buttonScale),
            buttonCornerRadius: (panelWidth * 0.024).clamped(to: 14...20),
            horizontalPadding: (panelWidth * 0.08).clamped(to: 20...64),
            verticalPadding: (panelHeight * 0.10).clamped(to: 28...72),
            contentSpacing: (panelHeight * 0.09).clamped(to: 26...64),
            buttonSpacing: max(panelHeight * 0.04, 16 * spacingScale),
            buttonHorizontalPadding: (18 * spacingScale).clamped(to: 16...34)
        )
    }
}

// MARK: - Layout Values

/// A resolved set of sizes and spacings for one presentation of
/// `ExitConfirmation`, produced by `makeLayout(for:)`.
///
/// Grouping the values in one struct keeps `body` readable (it reads finished
/// numbers instead of recomputing ratios inline) and keeps all the responsive
/// math in a single place. It is `private` because it is an implementation
/// detail of this file only.
private struct ModalLayout {
    /// Card width in points.
    let panelWidth: CGFloat
    /// Card height in points.
    let panelHeight: CGFloat
    /// Corner radius of the white card.
    let panelCornerRadius: CGFloat
    /// Point size for the title, already multiplied by the Dynamic Type scale.
    let titleFontSize: CGFloat
    /// Point size for the button labels, already Dynamic-Type-scaled.
    let buttonFontSize: CGFloat
    /// Maximum width of the button column so buttons don't stretch edge-to-edge.
    let buttonMaxWidth: CGFloat
    /// Minimum height of the filled primary button.
    let primaryButtonHeight: CGFloat
    /// Minimum height of the outlined secondary button.
    let secondaryButtonHeight: CGFloat
    /// Corner radius shared by both buttons.
    let buttonCornerRadius: CGFloat
    /// Inset on the left/right edges of the card content.
    let horizontalPadding: CGFloat
    /// Inset on the top/bottom edges of the card content.
    let verticalPadding: CGFloat
    /// Vertical gap between the title block and the button column.
    let contentSpacing: CGFloat
    /// Vertical gap between the two buttons.
    let buttonSpacing: CGFloat
    /// Left/right inset of the text inside each button.
    let buttonHorizontalPadding: CGFloat
}

// MARK: - Helpers

private extension CGFloat {
    /// Clamps the value into `range` (i.e. no lower than `lowerBound`, no higher
    /// than `upperBound`).
    ///
    /// Used throughout `makeLayout(for:)` to cap the proportional sizes so the
    /// card never becomes too small to read or too large for the screen.
    /// `private` to this file; `Buttons.swift` intentionally has no equivalent.
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview {
    ExitConfirmation(
        onContinueLearning: {},
        onDiscardProgress: {}
    )
}
