//
//  SettingsView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  The full-screen Settings page opened from the main menu's settings button
//  (`SettingsButton` in `Components/Buttons.swift`).
//
//  All logic lives in `SettingsViewModel` — this file is presentation only:
//  every control simply calls a view-model function (`setDraftBrightness`,
//  `setFilterEnabled`, `selectSimulation`, `save`, `cancel`).
//
//  This file also hosts the pieces shared with the gameplay overlay:
//    • `SettingsPanelContent` — the panel body used by both `SettingsView`
//      and `SettingsModalView`, so the two surfaces can never drift apart.
//    • `SettingsSlider` / `SettingsToggle` — pure-SwiftUI controls. The system
//      `Slider`/`Toggle` are UIKit-backed and vanish under the whole-screen
//      color filter (see `DisplayFilters.swift`), so these are drawn with
//      shapes instead.
//

import SwiftUI

// MARK: - Settings View (Main Menu)

/// The full-screen settings page, shown as an in-tree overlay from the main
/// menu (`MainMenuView` presents it when the `.settings` destination is
/// selected).
///
/// It renders inside the app's single view tree — NOT as a `fullScreenCover` —
/// so the root `displayAdjustments(for:)` in `ContentView` covers it too, and
/// changes preview live on every screen at once while editing.
struct SettingsView: View {

    /// The app-wide settings logic, shared through `ContentView` so the root
    /// can render `activeDisplaySettings` while this page edits the draft.
    @ObservedObject var viewModel: SettingsViewModel

    /// Invoked after save/cancel; the host removes this page from the tree
    /// (e.g. `MainMenuViewModel.clearDestination()`).
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .ignoresSafeArea()

            SettingsPanelContent(viewModel: viewModel) {
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
            .padding(24)
        }
        .onAppear {
            viewModel.beginEditing()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Shared Panel Content

/// The settings panel body shared by `SettingsView` (full screen) and
/// `SettingsModalView` (gameplay overlay): title, brightness slider, color
/// filter switch + options, preview image, and the save button.
///
/// Purely declarative — every interaction is forwarded to `SettingsViewModel`.
struct SettingsPanelContent: View {

    /// The settings logic this panel drives.
    @ObservedObject var viewModel: SettingsViewModel

    /// Asset-catalog name of the preview image.
    var previewImageAssetName: String = "settingReference"

    /// Invoked when the child taps "Simpan"; the host saves and dismisses.
    let onSave: () -> Void

    /// Dynamic Type multipliers for the title and body labels.
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title3) private var labelScale: CGFloat = 1

    /// The brand blue shared with the components in `Buttons.swift`.
    private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)

    var body: some View {
        // NOTE: no ScrollView and no system Slider/Toggle — the subtree must
        // stay pure-SwiftUI so the whole-screen color filter can rasterize it
        // (see DisplayFilters.swift).
        VStack(spacing: 0) {
            Text("Pengaturan")
                .font(.system(size: 52 * titleScale, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 28)

            // Controls beside the image when there's width; stacked when not.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 48) {
                    controls
                        .frame(maxWidth: 460, alignment: .leading)

                    previewImage
                }
                .padding(.horizontal, 56)

                VStack(alignment: .leading, spacing: 32) {
                    controls
                    previewImage
                }
                .padding(.horizontal, 32)
            }
            .padding(.top, 44)

            Spacer(minLength: 16)

            PrimaryActionButton(title: "Simpan", action: onSave)
                .padding(.vertical, 28)
        }
    }

    /// The left column: brightness slider, filter switch, and filter options.
    /// Each control calls straight into the view model.
    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Kecerahan Latar Belakang")
                .font(.system(size: 24 * labelScale, weight: .bold))
                .foregroundStyle(.black)

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

            HStack(spacing: 16) {
                Text("Filter Warna")
                    .font(.system(size: 24 * labelScale, weight: .bold))
                    .foregroundStyle(.black)

                SettingsToggle(
                    isOn: Binding(
                        get: { viewModel.isFilterEnabled },
                        set: { viewModel.setFilterEnabled($0) }
                    ),
                    accessibilityLabel: "Filter Warna"
                )
            }
            .padding(.top, 6)

            HStack(spacing: 26) {
                ForEach(ColorVisionSimulation.allCases) { simulation in
                    simulationOption(simulation)
                }
            }
            .padding(.top, 2)
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
                            .fill(primaryBlue)
                            .frame(width: 22 * labelScale, height: 22 * labelScale)
                        Circle()
                            .fill(.white)
                            .frame(width: 8 * labelScale, height: 8 * labelScale)
                    }
                }

                Text(simulation.displayName)
                    .font(.system(size: 20 * labelScale, weight: .semibold))
                    .foregroundStyle(
                        isEnabled
                            ? (isSelected ? primaryBlue : .black)
                            : Color(white: 0.72)
                    )
            }
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    .fill(.blue)
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
        .frame(height: 32)
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? "Aktif" : "Nonaktif")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - Preview

#Preview("Settings View") {
    SettingsView(
        viewModel: SettingsViewModel(storageService: StorageService()),
        onDismiss: {}
    )
}
