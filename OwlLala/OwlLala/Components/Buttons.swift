//
//  Buttons.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

// MARK: - Shared Palette

private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)

// MARK: - Circle Icon Button

/// The round blue icon button used for back and close actions.
struct CircleIconButton: View {
    let systemImageName: String
    let accessibilityLabel: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: 26 * buttonScale, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64 * buttonScale, height: 64 * buttonScale)
                .background(primaryBlue, in: Circle())
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Primary Action Button

/// The filled blue button used for confirmation actions.
struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24 * buttonScale, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 56 * buttonScale)
                .frame(minHeight: 60 * buttonScale)
                .background(primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Settings Screen

/// The full-screen settings page opened from the main menu's settings button.
///
/// Presentation only: the hosting view supplies the draft values and receives
/// changes through the bindings and callbacks (usually via `SettingsViewModel`).
struct SettingsScreen: View {
    @Binding var brightness: Double
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    var previewImageAssetName: String = "settings_preview"
    let onSave: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .ignoresSafeArea()

            SettingsPanelBody(
                brightness: $brightness,
                colorVisionSimulation: $colorVisionSimulation,
                previewImageAssetName: previewImageAssetName,
                saveTitle: "Simpan",
                onSave: onSave
            )

            CircleIconButton(
                systemImageName: "arrow.left",
                accessibilityLabel: "Kembali",
                action: onBack
            )
            .padding(24)
        }
    }
}

// MARK: - Settings Overlay

/// The modal settings card shown over gameplay.
///
/// Presentation only: the hosting view supplies the draft values and receives
/// changes through the bindings and callbacks (usually via `SettingsViewModel`).
struct SettingsOverlay: View {
    @Binding var brightness: Double
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    var previewImageAssetName: String = "settings_preview"
    let onSave: () -> Void
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = min(geometry.size.width * 0.82, 900)
            let panelHeight = min(geometry.size.height * 0.86, 720)

            ZStack {
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    SettingsPanelBody(
                        brightness: $brightness,
                        colorVisionSimulation: $colorVisionSimulation,
                        previewImageAssetName: previewImageAssetName,
                        saveTitle: "Simpan",
                        onSave: onSave
                    )

                    CircleIconButton(
                        systemImageName: "xmark",
                        accessibilityLabel: "Tutup",
                        action: onClose
                    )
                    .padding(20)
                }
                .frame(width: panelWidth, height: panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Shared Panel Body

/// The settings content shared by `SettingsScreen` and `SettingsOverlay`:
/// title, brightness slider, color-filter selection, preview image, and save.
private struct SettingsPanelBody: View {
    @Binding var brightness: Double
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    let previewImageAssetName: String
    let saveTitle: String
    let onSave: () -> Void

    @State private var isFilterEnabled = false

    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title3) private var labelScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            Text("Pengaturan")
                .font(.system(size: 52 * titleScale, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 28)

            ScrollView {
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
            }

            PrimaryActionButton(title: saveTitle, action: onSave)
                .padding(.vertical, 28)
        }
        .onAppear {
            isFilterEnabled = colorVisionSimulation != nil
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Kecerahan Latar Belakang")
                .font(.system(size: 24 * labelScale, weight: .bold))
                .foregroundStyle(.black)

            HStack(spacing: 14) {
                Image(systemName: "sun.min")
                    .font(.system(size: 20 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)

                Slider(
                    value: $brightness,
                    in: Settings.minimumBackgroundBrightness...Settings.maximumBackgroundBrightness
                )
                .tint(.blue)
                .accessibilityLabel("Kecerahan Latar Belakang")

                Image(systemName: "sun.max")
                    .font(.system(size: 26 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)
            }

            HStack(spacing: 16) {
                Text("Filter Warna")
                    .font(.system(size: 24 * labelScale, weight: .bold))
                    .foregroundStyle(.black)

                Toggle("", isOn: $isFilterEnabled)
                    .labelsHidden()
                    .accessibilityLabel("Filter Warna")
                    .onChange(of: isFilterEnabled) { _, isEnabled in
                        if !isEnabled {
                            colorVisionSimulation = nil
                        }
                    }
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

    private func simulationOption(_ simulation: ColorVisionSimulation) -> some View {
        let isSelected = colorVisionSimulation == simulation

        return Button {
            colorVisionSimulation = simulation
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.78))
                        .frame(width: 22 * labelScale, height: 22 * labelScale)

                    if isSelected && isFilterEnabled {
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
                        isFilterEnabled
                            ? (isSelected ? primaryBlue : .black)
                            : Color(white: 0.72)
                    )
            }
        }
        .disabled(!isFilterEnabled)
        .accessibilityLabel(simulation.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

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

// MARK: - Previews

#Preview("Settings Screen") {
    @Previewable @State var brightness = 0.8
    @Previewable @State var simulation: ColorVisionSimulation?

    SettingsScreen(
        brightness: $brightness,
        colorVisionSimulation: $simulation,
        onSave: {},
        onBack: {}
    )
}

#Preview("Settings Overlay") {
    @Previewable @State var brightness = 0.8
    @Previewable @State var simulation: ColorVisionSimulation?

    ZStack {
        Color(white: 0.85)
            .ignoresSafeArea()

        SettingsOverlay(
            brightness: $brightness,
            colorVisionSimulation: $simulation,
            onSave: {},
            onClose: {}
        )
    }
}
