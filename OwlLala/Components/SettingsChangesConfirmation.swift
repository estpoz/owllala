//
//  SettingsChangesConfirmation.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  A reusable modal (dialog) shown when the child tries to leave the Settings
//  screen while it still has unsaved changes. It asks whether to keep ("Simpan")
//  or discard ("Buang Perubahan") those edits before closing. Like
//  `ExitConfirmation`, it renders its own dimmed full-screen backdrop plus a
//  centered card, so it is meant to be placed in a `ZStack` on top of the
//  Settings surface — it is not a pushed/navigated screen.
//
//  WHERE IT IS USED
//  ----------------
//  Presentation-only component: it owns no state and talks to its parent purely
//  through the three closures below. `SettingsView` shows it when its close
//  control is tapped and `SettingsViewModel.hasUnsavedChanges` is `true`:
//
//      ZStack {
//          SettingsSurface(...)
//          if isConfirmingClose {
//              SettingsChangesConfirmation(
//                  onSave:    { viewModel.save();   onDismiss() },
//                  onDiscard: { viewModel.cancel(); onDismiss() },
//                  onCancel:  { isConfirmingClose = false }
//              )
//          }
//      }
//

import SwiftUI

// MARK: - Settings Changes Confirmation Dialog

/// A confirmation dialog shown before leaving Settings with unsaved changes.
///
/// The view is fully self-contained and responsive: it sizes its card from the
/// available space (`makeLayout(for:)`) and scales its text with the system
/// Dynamic Type setting, so it works across iPad sizes and accessibility text
/// sizes without the caller configuring anything. It also reflects the app's
/// background brightness and color filter, matching every other surface.
///
/// All copy is fixed Indonesian, matching the rest of the app.
struct SettingsChangesConfirmation: View {

    /// Which question the dialog asks, so one component serves both moments the
    /// child can leave their edits in an undecided state.
    enum Mode {
        /// Tapped Save: "apply these changes?" — confirm or go back to editing.
        case confirmSave
        /// Tapped Close with unsaved edits: "save them, or throw them away?"
        case unsavedOnClose
    }

    /// The question this presentation asks. Defaults to the close case so
    /// existing call sites keep their behaviour.
    var mode: Mode = .unsavedOnClose

    /// Invoked when the child chooses to keep their edits ("Simpan").
    ///
    /// The host should persist the draft settings and dismiss Settings. This
    /// component does not dismiss itself — the parent controls visibility.
    let onSave: () -> Void

    /// Invoked when the child chooses to throw their edits away
    /// ("Buang Perubahan"). Only shown in `.unsavedOnClose`; the host should
    /// discard the draft and dismiss Settings.
    var onDiscard: (() -> Void)? = nil

    /// Invoked when the child decides to keep editing — taps outside the card,
    /// or taps "Batal" in `.confirmSave`. The host hides this dialog and leaves
    /// Settings open.
    let onCancel: () -> Void

    /// The question shown at the top of the card.
    private var titleText: String {
        switch mode {
        case .confirmSave:
            return "Simpan perubahan pengaturan? \n Pengaturan baru akan dipakai di seluruh aplikasi"
        case .unsavedOnClose:
            return "Simpan perubahan pengaturan? \n Perubahan yang belum disimpan akan hilang"
        }
    }

    /// The label of the outlined (secondary) button.
    private var secondaryTitle: String {
        switch mode {
        case .confirmSave:
            return "Batal"
        case .unsavedOnClose:
            return "Buang Perubahan"
        }
    }

    /// What the outlined button does: go back to editing, or discard the edits.
    private func performSecondaryAction() {
        switch mode {
        case .confirmSave:
            onCancel()
        case .unsavedOnClose:
            (onDiscard ?? onCancel)()
        }
    }

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
                // Dimmed backdrop that covers the whole screen. Tapping it keeps
                // the child in Settings (a light-touch "cancel").
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onCancel() }
                    .accessibilityLabel("Tetap di Pengaturan")
                    .accessibilityAddTraits(.isButton)

                // The card sizes to its content (no fixed height) so there is no
                // empty gap under the buttons. Title and button labels WRAP
                // (never truncate), so every text stays readable at every size.
                VStack(spacing: 0) {
                    // Question / title — SF Pro Rounded Bold, black, centered.
                    Text(titleText)
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
                        // Primary action: keep the edits (filled blue).
                        Button(action: onSave) {
                            Text("Simpan")
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

                        // Secondary action: go back to editing, or throw the
                        // edits away, depending on the mode (outlined).
                        Button(action: performSecondaryAction) {
                            Text(secondaryTitle)
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
    /// size, returning them together in a `SettingsConfirmationLayout`.
    ///
    /// The rules mirror `ExitConfirmation` so both dialogs feel identical: sizes
    /// are proportional to the panel and then clamped to sensible bounds, which
    /// keeps the card readable from small split-view widths up to a full iPad,
    /// and taller at accessibility text sizes.
    ///
    /// - Parameter size: The space the dialog is being presented in.
    /// - Returns: A fully-resolved `SettingsConfirmationLayout`.
    private func makeLayout(for size: CGSize) -> SettingsConfirmationLayout {
        let shortestSide = min(size.width, size.height)
        let isCompact = shortestSide < 500
        let isLarge = size.width >= 900 && size.height >= 700
        let usesAccessibilityLayout = dynamicTypeSize.isAccessibilitySize
        let panelWidthRatio: CGFloat = usesAccessibilityLayout
            ? (isCompact ? 0.96 : 0.90)
            : (isCompact ? 0.90 : (isLarge ? 0.66 : 0.76))
        let panelWidth = (size.width * panelWidthRatio).clamped(to: 280...900)
        let panelHeightRatio: CGFloat = usesAccessibilityLayout
            ? 0.92
            : (isCompact ? 0.72 : 0.64)
        let panelHeight = (size.height * panelHeightRatio).clamped(to: 320...820)
        let titleBaseSize = (panelWidth * (isCompact ? 0.070 : 0.058)).clamped(to: 28...46)
        let buttonBaseSize = (panelWidth * (isCompact ? 0.045 : 0.038)).clamped(to: 19...30)
        let buttonMaxWidth = (
            panelWidth * (usesAccessibilityLayout ? 0.82 : (isCompact ? 0.78 : 0.56))
        )
        .clamped(to: 230...680)

        return SettingsConfirmationLayout(
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
/// `SettingsChangesConfirmation`, produced by `makeLayout(for:)`. `private`
/// because it is an implementation detail of this file only.
private struct SettingsConfirmationLayout {
    let panelWidth: CGFloat
    let panelHeight: CGFloat
    let panelCornerRadius: CGFloat
    let titleFontSize: CGFloat
    let buttonFontSize: CGFloat
    let buttonMaxWidth: CGFloat
    let primaryButtonHeight: CGFloat
    let secondaryButtonHeight: CGFloat
    let buttonCornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let contentSpacing: CGFloat
    let buttonSpacing: CGFloat
    let buttonHorizontalPadding: CGFloat
}

// MARK: - Helpers

private extension CGFloat {
    /// Clamps the value into `range`. Used throughout `makeLayout(for:)` to cap
    /// the proportional sizes so the card never becomes too small to read or too
    /// large for the screen.
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

        SettingsChangesConfirmation(
            onSave: {},
            onDiscard: {},
            onCancel: {}
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

        SettingsChangesConfirmation(
            onSave: {},
            onDiscard: {},
            onCancel: {}
        )
    }
    .dynamicTypeSize(.accessibility5)
    .environmentObject(storageService)
    .environmentObject(SettingsViewModel(storageService: storageService))
}
