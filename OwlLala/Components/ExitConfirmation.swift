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

    /// The shared display settings, so the dialog reflects the same background
    /// brightness and color filter as the rest of the app. (Text size is applied
    /// by the presenter via `appTextSizeAdjustment()`.)
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

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
        // The active display settings drive the background brightness and color
        // filter, so the dialog matches the rest of the app.
        let settings = settingsViewModel.activeDisplaySettings

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

                // The card sizes to its content (no fixed height) so there is no
                // empty gap under the buttons. Title and button labels WRAP
                // (never truncate), so every text stays readable at every size —
                // on the iPad the content fits even at the largest text size, so
                // no ScrollView is needed (a color shader can't rasterize one).
                VStack(spacing: 0) {
                    // Question / title — SF Pro Rounded Bold, black, centered.
                    Text("Apa kamu yakin mau kehilangan progress belajarmu?")
                        .font(.owlRounded(layout.titleFontSize, .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(layout.titleFontSize * 0.18)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, layout.horizontalPadding)
                        .padding(.top, layout.verticalPadding)

                    VStack(spacing: layout.buttonSpacing) {
                        // Primary action: stay and keep learning (filled blue).
                        Button(action: onContinueLearning) {
                            Text("Kembali Belajar")
                                .font(.owlRounded(layout.buttonFontSize, .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, layout.buttonHorizontalPadding)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: layout.primaryButtonHeight)
                                .background(primaryBlue)
                                .clipShape(RoundedRectangle(cornerRadius: layout.buttonCornerRadius, style: .continuous))
                        }

                        // Destructive action: leave and lose progress (outlined).
                        Button(action: onDiscardProgress) {
                            Text("Hilangkan Progres")
                                .font(.owlRounded(layout.buttonFontSize, .bold))
                                .foregroundStyle(primaryBlue)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, layout.buttonHorizontalPadding)
                                .padding(.vertical, 14)
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
                }
                .frame(width: layout.panelWidth)
                .background(
                    // Designated background layer: dims with the "Kecerahan Latar
                    // Belakang" setting, like the rest of the app's backgrounds.
                    Image("bgPattern")
                        .resizable()
                        .scaledToFill()
                        .backgroundBrightness(settings.backgroundBrightness)
                )
                .clipShape(RoundedRectangle(cornerRadius: layout.panelCornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
            }
            // The whole dialog follows the app's color filter, exactly like every
            // other screen. `nil` (filter off) is a no-op; no ScrollView sits
            // under this shader, so it rasterizes and never blanks.
            .colorVisionFilter(settings.colorVisionSimulation)
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
        let usesAccessibilityLayout = dynamicTypeSize.isAccessibilitySize
        let panelWidthRatio: CGFloat = usesAccessibilityLayout
            ? (isCompact ? 0.96 : 0.90)
            : (isCompact ? 0.90 : (isLarge ? 0.66 : 0.76))
        let panelHeightRatio: CGFloat = usesAccessibilityLayout
            ? 0.92
            : (isCompact ? 0.72 : 0.64)
        let panelWidth = (size.width * panelWidthRatio).clamped(to: 280...900)
        let panelHeight = (size.height * panelHeightRatio).clamped(to: 320...820)
        let titleBaseSize = (panelWidth * (isCompact ? 0.070 : 0.058)).clamped(to: 28...46)
        let buttonBaseSize = (panelWidth * (isCompact ? 0.045 : 0.038)).clamped(to: 19...30)
        let buttonMaxWidth = (
            panelWidth * (usesAccessibilityLayout ? 0.82 : (isCompact ? 0.78 : 0.56))
        )
        .clamped(to: 230...680)

        return ModalLayout(
            panelWidth: panelWidth,
            panelHeight: panelHeight,
            panelCornerRadius: (panelWidth * 0.05).clamped(to: 28...44),
            titleFontSize: titleBaseSize * titleScale,
            buttonFontSize: buttonBaseSize * buttonScale,
            buttonMaxWidth: buttonMaxWidth,
            primaryButtonHeight: max(panelHeight * 0.13, 52 * buttonScale),
            secondaryButtonHeight: max(panelHeight * 0.12, 48 * buttonScale),
            buttonCornerRadius: (panelWidth * 0.030).clamped(to: 16...26),
            horizontalPadding: usesAccessibilityLayout
                ? (panelWidth * 0.05).clamped(to: 16...40)
                : (panelWidth * 0.08).clamped(to: 20...64),
            verticalPadding: usesAccessibilityLayout
                ? (panelHeight * 0.06).clamped(to: 20...48)
                : (panelHeight * 0.10).clamped(to: 28...72),
            contentSpacing: usesAccessibilityLayout
                ? (panelHeight * 0.05).clamped(to: 20...40)
                : (panelHeight * 0.09).clamped(to: 26...64),
            buttonSpacing: usesAccessibilityLayout
                ? max(panelHeight * 0.03, 12 * spacingScale)
                : max(panelHeight * 0.04, 16 * spacingScale),
            buttonHorizontalPadding: usesAccessibilityLayout
                ? (12 * spacingScale).clamped(to: 12...32)
                : (18 * spacingScale).clamped(to: 16...34)
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

#Preview("Default") {
    let storageService = StorageService()

    return ZStack {
        Color(white: 0.6)
            .ignoresSafeArea()

        ExitConfirmation(
            onContinueLearning: {},
            onDiscardProgress: {}
        )
    }
    .environmentObject(storageService)
    .environmentObject(SettingsViewModel(storageService: storageService))
}

#Preview("Accessibility 5") {
    let storageService = StorageService()

    return ZStack {
        Color(white: 0.6)
            .ignoresSafeArea()

        ExitConfirmation(
            onContinueLearning: {},
            onDiscardProgress: {}
        )
    }
    .dynamicTypeSize(.accessibility5)
    .environmentObject(storageService)
    .environmentObject(SettingsViewModel(storageService: storageService))
}
