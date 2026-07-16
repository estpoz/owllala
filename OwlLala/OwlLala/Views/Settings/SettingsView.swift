//
//  SettingsView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  The full-screen Settings page opened from the main menu ("Pengaturan").
//
//  All logic lives in `SettingsViewModel` — this file is presentation only:
//  every control simply calls a view-model function (`setDraftBrightness`,
//  `setDraftTextScale`, `setFilterEnabled`, `selectSimulation`, `save`,
//  `cancel`). Styled per the Hi-Fi design: SF Pro Rounded type scale and the
//  #0042AA primary blue from `AppTheme.swift`.
//
//  This file also hosts the pieces shared with the gameplay overlay:
//    • `SettingsSurface`      — the COMPLETE page (background + panel + back
//      button), also rendered by `SettingsModalView` inside a card, so the
//      modal is always exactly this page in a modal frame.
//    • `SettingsPanelContent` — the panel body (title, sliders, filter,
//      image, save).
//    • `SettingsSlider` / `SettingsToggle` — pure-SwiftUI controls. The system
//      `Slider`/`Toggle` are UIKit-backed and vanish under the whole-screen
//      color filter (see `DisplayFilters.swift`), so these are drawn with
//      shapes instead.
//

import SwiftUI

// MARK: - Settings View (Main Menu)

/// The full-screen settings page, pushed from the main menu's navigation when
/// the `.settings` destination is selected.
struct SettingsView: View {

    /// The app-wide settings logic, shared through `ContentView` so the root
    /// can render `activeDisplaySettings` while this page edits the draft.
    @ObservedObject var viewModel: SettingsViewModel

    /// Invoked after save/cancel; the host removes this page from the tree
    /// (e.g. `MainMenuViewModel.clearDestination()`).
    let onDismiss: () -> Void

    var body: some View {
        SettingsSurface(viewModel: viewModel, onDismiss: onDismiss)
            .onAppear {
                viewModel.beginEditing()
            }
            .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Shared Surface

/// The complete settings surface — white background, the settings panel, and
/// the back button — shared by BOTH presentations:
///
///   • `SettingsView` shows it full screen (main menu → Pengaturan).
///   • `SettingsModalView` shows the *same* surface inside a rounded card over
///     a scrim (gameplay overlay).
///
/// Because both render this one view, the modal's content is always exactly
/// the page's content, just in a modal frame.
struct SettingsSurface: View {

    /// The app-wide settings logic driving the panel.
    @ObservedObject var viewModel: SettingsViewModel

    /// Bottom inset of the "Simpan" button. The full-screen page uses the
    /// default; the modal passes a larger value so its button sits higher.
    var saveBottomPadding: CGFloat = 40

    /// Invoked after save/cancel; the host removes the surface from the tree.
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Designated background layer: dims with "Kecerahan Latar
            // Belakang" while the controls and text above stay full-bright.
            Color.white
                .ignoresSafeArea()
                .appBackgroundBrightness()

            SettingsPanelContent(
                viewModel: viewModel,
                saveBottomPadding: saveBottomPadding
            ) {
                viewModel.save()
                onDismiss()
            }

            CircleIconButton(
                systemImageName: "arrow.left",
                accessibilityLabel: "Kembali"
            ) {
                viewModel.cancel()
                onDismiss()
            }
            .padding(32)
        }
    }
}

// MARK: - Shared Panel Content

/// The settings panel body: "Pengaturan" title, brightness slider, text-size
/// slider ("Ukuran Teks"), color filter switch + options, preview image, and
/// the "Simpan" button — laid out per the Hi-Fi mockup.
///
/// Purely declarative — every interaction is forwarded to `SettingsViewModel`.
struct SettingsPanelContent: View {

    /// The settings logic this panel drives.
    @ObservedObject var viewModel: SettingsViewModel

    /// Asset-catalog name of the preview image.
    var previewImageAssetName: String = "settingReference"

    /// Bottom inset of the "Simpan" button; overrides the Hi-Fi default so the
    /// modal can place its button higher than the full-screen page.
    var saveBottomPadding: CGFloat = PanelLayout.saveBottomPadding

    /// Invoked when the child taps "Simpan"; the host saves and dismisses.
    let onSave: () -> Void

    /// Dynamic Type multipliers for the title, headlines, and body labels.
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .headline) private var labelScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var bodyScale: CGFloat = 1

    /// Layout constants measured from the Hi-Fi mockup so both surfaces keep
    /// the same margins and rhythm.
    private enum PanelLayout {
        /// Top inset of the "Pengaturan" title.
        static let titleTopPadding: CGFloat = 36
        /// Gap between the title and the content block.
        static let contentTopSpacing: CGFloat = 56
        /// Side margins of the content block (controls + image).
        static let horizontalPadding: CGFloat = 72
        /// Gap between the controls column and the preview image.
        static let columnSpacing: CGFloat = 56
        /// Width of the controls column.
        static let controlsMaxWidth: CGFloat = 700
        /// Vertical gap between a label and its own control.
        static let labelToControlSpacing: CGFloat = 6
        /// Vertical gap between one setting group and the next.
        static let groupSpacing: CGFloat = 22
        /// Bottom inset of the "Simpan" button.
        static let saveBottomPadding: CGFloat = 40
    }

    var body: some View {
        // NOTE: no ScrollView and no system Slider/Toggle — the subtree must
        // stay pure-SwiftUI so the whole-screen color filter can rasterize it
        // (see DisplayFilters.swift).
        VStack(spacing: 0) {
            // Large Title — SF Pro Rounded 60pt Bold, centered per the Hi-Fi.
            // Shrinks (never wraps) if the container is too narrow for the
            // scaled size, so the title stays on one line at every text size.
            Text("Pengaturan")
                .font(.owlRounded(AppFontSize.largeTitle * titleScale, .bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, PanelLayout.titleTopPadding)

            // Controls on the left, image on the right (Hi-Fi layout); falls
            // back to a vertical stack only when the width can't fit both.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PanelLayout.columnSpacing) {
                    controls
                        .frame(maxWidth: PanelLayout.controlsMaxWidth, alignment: .leading)

                    previewImage
                }
                .padding(.horizontal, PanelLayout.horizontalPadding)

                // Narrow/large-text fallback: controls above a smaller image so
                // everything still fits without scrolling.
                VStack(alignment: .leading, spacing: 24) {
                    controls

                    previewImage
                        .frame(maxWidth: 280)
                }
                .padding(.horizontal, 32)
            }
            .padding(.top, PanelLayout.contentTopSpacing)

            Spacer(minLength: 16)

            PrimaryActionButton(title: "Simpan", action: onSave)
                .padding(.bottom, saveBottomPadding)
                .padding(.top, 16)
        }
        // Larger Text support without a ScrollView (which the whole-screen
        // color filter can't rasterize): text grows with Dynamic Type up to
        // accessibility1 — the largest size at which every control still fits
        // both the full page and the modal card — and holds there, so the
        // layout never breaks at the extreme accessibility sizes.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// The left column: brightness slider, text-size slider, filter switch,
    /// and filter options — grouped with the Hi-Fi's label→control rhythm.
    /// Each control calls straight into the view model.
    /// Headline labels — SF Pro Rounded 32pt Medium.
    private var controls: some View {
        VStack(alignment: .leading, spacing: PanelLayout.labelToControlSpacing) {
            Text("Kecerahan Latar Belakang")
                .font(.owlRounded(AppFontSize.headline * labelScale, .medium))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 14) {
                Image(systemName: "sun.min")
                    .font(.system(size: 20 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)

                SettingsSlider(
                    value: Binding(
                        get: { viewModel.draftSettings.backgroundBrightness },
                        set: { viewModel.setDraftBrightness($0) }
                    ),
                    range: Settings.minimumBackgroundBrightness...Settings.maximumBackgroundBrightness,
                    accessibilityLabel: "Kecerahan Latar Belakang"
                )

                Image(systemName: "sun.max")
                    .font(.system(size: 26 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)
            }

            Text("Ukuran Teks")
                .font(.owlRounded(AppFontSize.headline * labelScale, .medium))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, PanelLayout.groupSpacing)

            // Text-size slider between a small and a large "A", per the Hi-Fi.
            HStack(spacing: 14) {
                Text("A")
                    .font(.owlRounded(20 * labelScale, .medium))
                    .foregroundStyle(.black)

                SettingsSlider(
                    value: Binding(
                        get: { viewModel.draftSettings.textScale },
                        set: { viewModel.setDraftTextScale($0) }
                    ),
                    range: Settings.minimumTextScale...Settings.maximumTextScale,
                    accessibilityLabel: "Ukuran Teks"
                )

                Text("A")
                    .font(.owlRounded(32 * labelScale, .medium))
                    .foregroundStyle(.black)
            }

            HStack(spacing: 16) {
                Text("Filter Warna")
                    .font(.owlRounded(AppFontSize.headline * labelScale, .medium))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                SettingsToggle(
                    isOn: Binding(
                        get: { viewModel.isFilterEnabled },
                        set: { viewModel.setFilterEnabled($0) }
                    ),
                    accessibilityLabel: "Filter Warna"
                )
            }
            .padding(.top, PanelLayout.groupSpacing)

            // Filter options in a row while they fit; at larger text sizes
            // they stack vertically instead of clipping off the edge.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 26) {
                    ForEach(ColorVisionSimulation.allCases) { simulation in
                        simulationOption(simulation)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(ColorVisionSimulation.allCases) { simulation in
                        simulationOption(simulation)
                    }
                }
            }
        }
    }

    /// One selectable filter option (radio dot + label). Disabled and greyed
    /// while the filter switch is off; selection goes through the view model.
    ///
    /// - Parameter simulation: The filter type this option selects.
    private func simulationOption(_ simulation: ColorVisionSimulation) -> some View {
        let isSelected = viewModel.isSimulationSelected(simulation)
        let isEnabled = viewModel.isFilterEnabled

        return Button {
            viewModel.selectSimulation(simulation)
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.78))
                        .frame(width: 22 * labelScale, height: 22 * labelScale)

                    if isSelected && isEnabled {
                        Circle()
                            .fill(AppColor.primary)
                            .frame(width: 22 * labelScale, height: 22 * labelScale)
                        Circle()
                            .fill(.white)
                            .frame(width: 8 * labelScale, height: 8 * labelScale)
                    }
                }

                // Body — SF Pro Rounded 28pt Regular. Shrinks rather than
                // wrapping so each option stays on one readable line.
                Text(simulation.displayName)
                    .font(.owlRounded(AppFontSize.body * bodyScale, .regular))
                    .foregroundStyle(
                        isEnabled
                            ? (isSelected ? AppColor.primary : .black)
                            : Color(white: 0.72)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            // 44pt minimum hit target for the whole dot + label row.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityLabel(simulation.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The preview artwork. Unfiltered here — the host applies the whole-screen
    /// filter, and filtering again would apply the matrix twice.
    @ViewBuilder
    private var previewImage: some View {
        Group {
            #if canImport(UIKit)
            if let uiImage = UIImage(named: previewImageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                previewPlaceholder
            }
            #else
            previewPlaceholder
            #endif
        }
        .frame(maxWidth: 420)
        .aspectRatio(3 / 2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        // NOT dimmed: images and other foreground content keep their colors
        // at every brightness level — only designated background layers dim.
        .accessibilityLabel("Pratinjau kecerahan latar belakang")
    }

    /// Gradient stand-in shown if the preview asset can't be loaded.
    private var previewPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.25),
                    Color(red: 0.90, green: 0.30, blue: 0.35),
                    Color(red: 0.25, green: 0.60, blue: 0.45),
                    Color(red: 0.20, green: 0.40, blue: 0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Shader-Safe Controls

/// A pure-SwiftUI slider used instead of the system `Slider`, which is
/// UIKit-backed and disappears under the whole-screen color filter. Supports
/// drag, tap-to-set, and VoiceOver increment/decrement.
struct SettingsSlider: View {

    /// The value being edited, kept within `range`.
    @Binding var value: Double

    /// The allowed value range (e.g. the Settings brightness bounds).
    let range: ClosedRange<Double>

    /// Spoken label for VoiceOver.
    let accessibilityLabel: String

    /// Thumb diameter in points.
    private let thumbSize: CGFloat = 26

    /// Track height in points.
    private let trackHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let travel = max(width - thumbSize, 1)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(white: 0.85))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(AppColor.primary)
                    .frame(width: thumbSize / 2 + fraction * travel, height: trackHeight)

                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(Color(white: 0.82), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 1)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: fraction * travel)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let tapped = (gesture.location.x - thumbSize / 2) / travel
                        let clamped = min(max(tapped, 0), 1)
                        value = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                    }
            )
        }
        // 44pt minimum hit target (Apple HIG); the track/thumb stay their
        // visual size, centered in the taller touch area.
        .frame(height: 44)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * 100)) persen")
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }
}

/// A pure-SwiftUI switch used instead of the system `Toggle`, for the same
/// shader-rasterization reason as `SettingsSlider`.
struct SettingsToggle: View {

    /// The on/off state being edited.
    @Binding var isOn: Bool

    /// Spoken label for VoiceOver.
    let accessibilityLabel: String

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                isOn.toggle()
            }
        } label: {
            Capsule()
                .fill(isOn ? Color.green : Color(white: 0.85))
                .frame(width: 58, height: 34)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        .padding(3)
                }
                // 44pt minimum hit target; the capsule keeps its visual size.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? "Aktif" : "Nonaktif")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - Preview

#Preview("Settings View") {
    let settingsViewModel = SettingsViewModel(storageService: StorageService())

    return SettingsView(viewModel: settingsViewModel, onDismiss: {})
        .environmentObject(settingsViewModel)
}
