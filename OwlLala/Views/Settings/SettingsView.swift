//
//  SettingsView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  THE one settings view of the app, sized for iPad Pro 11-inch. Two
//  presentations of the same surface:
//
//    • `SettingsView(viewModel:onDismiss:)` — the full-screen page opened
//      from the main menu ("Pengaturan").
//    • `SettingsView(viewModel:isModal: true, onDismiss:)` — the SAME page
//      rendered as a rounded card over a dimmed scrim, used by every caller
//      outside the main menu (e.g. the gameplay pause settings).
//
//  All logic lives in `SettingsViewModel` — this file is presentation only:
//  every control simply calls a view-model function (`setDraftBrightness`,
//  `setDraftTextSize`, `setFilterEnabled`, `selectSimulation`, `save`,
//  `cancel`). Styled per the Hi-Fi design: SF Pro Rounded type scale and the
//  #0042AA primary blue from `AppTheme.swift`.
//
//  Also hosted here:
//    • `SettingsSurface`      — the COMPLETE page (background + panel + back
//      button) both presentations render, so the modal is always exactly
//      this page in a modal frame.
//    • `SettingsPanelContent` — the panel body (title, sliders, filter,
//      and preview image).
//    • `SettingsSlider` / `SettingsToggle` — pure-SwiftUI controls. The system
//      `Slider`/`Toggle` are UIKit-backed and vanish under the whole-screen
//      color filter (see `DisplayFilters.swift`), so these are drawn with
//      shapes instead.
//

import SwiftUI

// MARK: - Settings View

/// The app's single settings view.
///
///   • Main menu (`.settings` destination): `SettingsView(viewModel:onDismiss:)`
///     — the surface fills the screen as a page.
///   • Everywhere else (e.g. gameplay pause): pass `isModal: true` from inside
///     the screen's `ZStack` — the SAME surface is scaled into a rounded card
///     over a dimmed scrim, so edits preview live on the content behind it.
struct SettingsView: View {

    /// The app-wide settings logic, shared through `ContentView` so the root
    /// can render `activeDisplaySettings` while this page edits the draft.
    @ObservedObject var viewModel: SettingsViewModel

    /// `false` (default) renders the full-screen page; `true` renders the same
    /// surface inside a modal card over a scrim.
    var isModal: Bool = false

    /// Invoked after save/cancel; the host removes this view from the tree
    /// (e.g. `MainMenuViewModel.clearDestination()` or clearing the gameplay
    /// overlay flag).
    let onDismiss: () -> Void

    var body: some View {
        Group {
            if isModal {
                modalPresentation
            } else {
                SettingsSurface(viewModel: viewModel, onDismiss: onDismiss)
            }
        }
        // Apply the draft category directly so both presentations and isolated
        // previews grow identically from X Small through AX5. Reapplying the
        // same environment value at the app root is idempotent, not additive.
        .textSizeAdjustment(for: viewModel.activeDisplaySettings)
        .onAppear {
            viewModel.beginEditing()
        }
        .navigationBarBackButtonHidden(true)
    }

    /// The modal state uses the same responsive surface at the card's actual
    /// size. It is not scaled down as a bitmap, so AX5 text and controls retain
    /// their intended accessibility dimensions and can scroll when necessary.
    private var modalPresentation: some View {
        GeometryReader { geometry in
            let cardWidth = min(geometry.size.width * 0.90, 1_000)
            let cardHeight = min(geometry.size.height * 0.88, 760)

            ZStack {
                // Dimmed backdrop over the content behind the card.
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                SettingsSurface(
                    viewModel: viewModel,
                    navigationSystemImageName: "xmark",
                    navigationAccessibilityLabel: "Tutup",
                    onDismiss: onDismiss
                )
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Shared Surface

/// The complete settings surface — white background, the settings panel, and
/// the back button — shared by BOTH presentations of `SettingsView`:
///
///   • Page (main menu → Pengaturan): shown full screen.
///   • Modal (`isModal: true`): the *same* surface inside a rounded card over
///     a scrim (e.g. gameplay overlay).
///
/// Because both render this one view, the modal's content is always exactly
/// the page's content, just in a modal frame.
struct SettingsSurface: View {

    /// The app-wide settings logic driving the panel.
    @ObservedObject var viewModel: SettingsViewModel

    /// The full page navigates back; the modal presents an explicit close icon.
    var navigationSystemImageName: String = "arrow.left"

    /// Spoken label matching the navigation icon's purpose.
    var navigationAccessibilityLabel: String = "Kembali"

    /// Invoked after save/cancel; the host removes the surface from the tree.
    let onDismiss: () -> Void

    /// Normal sizes fit the original fixed surface. Accessibility sizes need
    /// vertical scrolling to preserve Apple's native AX text dimensions.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Navigation geometry grows with the selected text size, but is capped so
    /// it remains a compact corner control beside the centered title.
    @ScaledMetric(relativeTo: .body) private var navigationDiameter: CGFloat = 70
    @ScaledMetric(relativeTo: .body) private var navigationPadding: CGFloat = 20

    var body: some View {
        ZStack(alignment: .topLeading) {
            if dynamicTypeSize.isAccessibilitySize {
                // The UIKit-backed scroll surface must stay outside a shader.
                // Live filter previews still update the gameplay behind this
                // modal, while the controls remain visible and reachable.
                AppScrollScreen(
                    showsIndicators: false,
                    appliesColorFilterToContent: false
                ) {
                    Color.white
                        .ignoresSafeArea()
                } content: {
                    panelContent
                }
            } else {
                // X Small through XXX Large fit without scrolling, allowing the
                // complete pure-SwiftUI panel to retain its live color preview.
                AppScreen {
                    Color.white
                        .ignoresSafeArea()
                } content: {
                    panelContent
                }
            }

            HStack {
                CircleIconButton(
                    systemImageName: navigationSystemImageName,
                    accessibilityLabel: navigationAccessibilityLabel
                ) {
                    viewModel.cancel()
                    onDismiss()
                }
                .scaleEffect(min(max(navigationDiameter / 98, 0.72), 1))

                Spacer()

                SaveChangesButton(hasChanges: viewModel.hasUnsavedChanges) {
                    viewModel.save()
                    onDismiss()
                }
                .scaleEffect(min(max(navigationDiameter / 98, 0.72), 1))
            }
            .padding(min(navigationPadding, 28))
            .appAdaptiveColorFilter()
        }
    }

    private var panelContent: some View {
        SettingsPanelContent(viewModel: viewModel)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared Panel Content

/// The settings panel body: "Pengaturan" title, brightness slider, text-size
/// slider ("Ukuran Teks"), color filter switch + options, and preview image —
/// laid out per the Hi-Fi mockup. Save is a reusable top-right action owned by
/// `SettingsSurface`.
///
/// Purely declarative — every interaction is forwarded to `SettingsViewModel`.
struct SettingsPanelContent: View {

    /// The settings logic this panel drives.
    @ObservedObject var viewModel: SettingsViewModel

    /// Asset-catalog name of the preview image.
    var previewImageAssetName: String = "settingReference"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Typography, control geometry, image dimensions, and spacing all react
    /// to the same Dynamic Type environment. Geometry is capped only where an
    /// unbounded value would consume the whole iPad width; text itself is never
    /// capped, including at Accessibility 5.
    @ScaledMetric(relativeTo: .largeTitle) private var titleFontSize: CGFloat = 44
    @ScaledMetric(relativeTo: .headline) private var labelFontSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var optionFontSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var smallAFontSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var largeAFontSize: CGFloat = 26
    @ScaledMetric(relativeTo: .caption) private var endpointFontSize: CGFloat = 11
    @ScaledMetric(relativeTo: .body) private var smallIconSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var largeIconSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var titleTopPadding: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var contentTopSpacing: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var columnSpacing: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var groupSpacing: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var contentBottomPadding: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var labelToControlSpacing: CGFloat = 6
    @ScaledMetric(relativeTo: .body) private var previewWidth: CGFloat = 340
    @ScaledMetric(relativeTo: .body) private var previewCornerRadius: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var radioOuterSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var radioInnerSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var scaledSliderAccessoryWidth: CGFloat = 40

    /// Both slider rows reserve identical columns for their endpoint content,
    /// so their visible tracks always begin and end at the same positions.
    private var sliderAccessoryWidth: CGFloat {
        min(scaledSliderAccessoryWidth, 84)
    }

    private enum PanelLayout {
        static let controlsMaxWidth: CGFloat = 690
        static let accessibilityContentMaxWidth: CGFloat = 760
        static let regularPreviewMaxWidth: CGFloat = 420
        static let accessibilityPreviewMaxWidth: CGFloat = 720
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Pengaturan")
                .font(.owlRounded(titleFontSize, .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 110)
                .padding(.top, min(titleTopPadding, 44))
                .colorVisionFilter(accessibilityContentSimulation)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityLayout
                } else {
                    regularLayout
                }
            }
            .padding(.bottom, min(contentBottomPadding, 72))
        }
        .frame(maxWidth: .infinity)
    }

    /// Side-by-side layout used from X Small through XXX Large. Both columns
    /// share a top edge and the complete composition is centered on the iPad.
    private var regularLayout: some View {
        HStack(alignment: .top, spacing: min(columnSpacing, 48)) {
            controls
                .frame(
                    maxWidth: PanelLayout.controlsMaxWidth,
                    alignment: .leading
                )

            previewImage
                .frame(width: min(previewWidth, PanelLayout.regularPreviewMaxWidth))
        }
        .frame(maxWidth: 1_100, alignment: .center)
        .padding(.horizontal, min(horizontalPadding, 80))
        .padding(.top, min(contentTopSpacing, 48))
    }

    /// AX1–AX5 layout. Controls and artwork use the same centered width so the
    /// page remains symmetrical; the surrounding `AppScrollScreen` prevents
    /// clipping while preserving the true accessibility text size.
    private var accessibilityLayout: some View {
        VStack(alignment: .center, spacing: min(groupSpacing * 2, 56)) {
            controls
                .frame(
                    maxWidth: PanelLayout.accessibilityContentMaxWidth,
                    alignment: .leading
                )
                .colorVisionFilter(accessibilityContentSimulation)

            previewImage
                .frame(
                    maxWidth: min(
                        previewWidth,
                        PanelLayout.accessibilityPreviewMaxWidth
                    )
                )
                .colorVisionFilter(accessibilityContentSimulation)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, min(horizontalPadding * 0.65, 48))
        .padding(.top, min(contentTopSpacing, 52))
    }

    /// The left column: brightness slider, text-size slider, filter switch,
    /// and filter options — grouped with the Hi-Fi's label→control rhythm.
    /// Each control calls straight into the view model.
    ///
    /// AX1–AX5 uses a ScrollView whose complete content cannot be wrapped in
    /// the color shader. Its pure SwiftUI foreground sections safely preview
    /// the selected simulation as separate islands instead. Standard sizes
    /// remain filtered once by the surrounding `AppScreen`.
    private var accessibilityContentSimulation: ColorVisionSimulation? {
        guard dynamicTypeSize.isAccessibilitySize,
              viewModel.isFilterEnabled
        else {
            return nil
        }

        return viewModel.draftSettings.colorVisionSimulation
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Kecerahan Latar Belakang")
                .font(.owlRounded(labelFontSize, .medium))
                .foregroundStyle(.black)

            HStack(spacing: min(labelToControlSpacing * 2, 20)) {
                Image(systemName: "sun.min")
                    .font(.system(size: smallIconSize, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: sliderAccessoryWidth)

                SettingsSlider(
                    value: Binding(
                        get: { viewModel.draftSettings.backgroundBrightness },
                        set: { viewModel.setDraftBrightness($0) }
                    ),
                    range: Settings.minimumBackgroundBrightness...Settings.maximumBackgroundBrightness,
                    accessibilityLabel: "Kecerahan Latar Belakang"
                )

                Image(systemName: "sun.max")
                    .font(.system(size: largeIconSize, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: sliderAccessoryWidth)
            }
            .padding(.top, min(labelToControlSpacing, 14))

            Text("Ukuran Teks")
                .font(.owlRounded(labelFontSize, .medium))
                .foregroundStyle(.black)
                .padding(.top, min(groupSpacing, 34))

            HStack(alignment: .center, spacing: min(labelToControlSpacing * 2, 20)) {
                textSizeEndpoint(
                    letterSize: smallAFontSize,
                    caption: "XS"
                )

                SettingsSlider(
                    value: Binding(
                        get: { Double(viewModel.draftSettings.textSize.index) },
                        set: {
                            viewModel.setDraftTextSize(
                                AppTextSize(nearestIndex: Int($0.rounded()))
                            )
                        }
                    ),
                    range: 0...Double(AppTextSize.allCases.count - 1),
                    step: 1,
                    accessibilityLabel: "Ukuran Teks",
                    accessibilityValue: textSizeAccessibilityName
                )

                textSizeEndpoint(
                    letterSize: largeAFontSize,
                    caption: "AX5"
                )
            }
            .padding(.top, min(labelToControlSpacing, 14))

            filterHeader
                .padding(.top, min(groupSpacing, 34))

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: min(labelToControlSpacing, 14)) {
                    ForEach(ColorVisionSimulation.allCases) { simulation in
                        simulationOption(simulation)
                    }
                }
            } else {
                HStack(spacing: 24) {
                    ForEach(ColorVisionSimulation.allCases) { simulation in
                        simulationOption(simulation)
                    }
                }
            }
        }
    }

    /// At AX sizes the switch moves below its label; this keeps both elements
    /// full-sized instead of compressing either side of one horizontal row.
    @ViewBuilder
    private var filterHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: min(labelToControlSpacing, 14)) {
                filterLabel
                filterToggle
            }
        } else {
            HStack(spacing: 12) {
                filterLabel
                filterToggle
            }
        }
    }

    private var filterLabel: some View {
        Text("Filter Warna")
            .font(.owlRounded(labelFontSize, .medium))
            .foregroundStyle(.black)
    }

    private var filterToggle: some View {
        SettingsToggle(
            isOn: Binding(
                get: { viewModel.isFilterEnabled },
                set: { viewModel.setFilterEnabled($0) }
            ),
            accessibilityLabel: "Filter Warna"
        )
    }

    private func textSizeEndpoint(
        letterSize: CGFloat,
        caption: String
    ) -> some View {
        VStack(spacing: 0) {
            Text("A")
                .font(.owlRounded(letterSize, .medium))
                .foregroundStyle(.black)

            Text(caption)
                .font(.owlRounded(endpointFontSize, .medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: sliderAccessoryWidth)
        .accessibilityHidden(true)
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
                // Classic radio per the reference photo: selected = blue ring
                // with a blue center dot; unselected = small grey disc.
                ZStack {
                    if isSelected && isEnabled {
                        Circle()
                            .stroke(AppColor.primary, lineWidth: 2)
                            .frame(
                                width: min(radioOuterSize, 34),
                                height: min(radioOuterSize, 34)
                            )
                        Circle()
                            .fill(AppColor.primary)
                            .frame(
                                width: min(radioInnerSize, 17),
                                height: min(radioInnerSize, 17)
                            )
                    } else {
                        Circle()
                            .fill(Color(white: 0.78))
                            .frame(
                                width: min(radioOuterSize * 0.82, 30),
                                height: min(radioOuterSize * 0.82, 30)
                            )
                    }
                }
                .frame(
                    width: min(radioOuterSize, 34),
                    height: min(radioOuterSize, 34)
                )

                Text(simulation.displayName)
                    .font(.owlRounded(optionFontSize, .regular))
                    .foregroundStyle(isEnabled ? .black : AppColor.disabledText)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .aspectRatio(3 / 2, contentMode: .fit)
        .clipShape(
            RoundedRectangle(
                cornerRadius: min(previewCornerRadius, 18),
                style: .continuous
            )
        )
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
                .font(.system(size: min(titleFontSize, 88), weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var textSizeAccessibilityName: String {
        switch viewModel.draftSettings.textSize {
        case .extraSmall:
            return "X Kecil"
        case .small:
            return "Kecil"
        case .medium:
            return "Sedang"
        case .large:
            return "Besar"
        case .extraLarge:
            return "Ekstra Besar"
        case .extraExtraLarge:
            return "Ekstra Ekstra Besar"
        case .extraExtraExtraLarge:
            return "Ekstra Ekstra Ekstra Besar"
        case .accessibility1:
            return "Aksesibilitas 1"
        case .accessibility2:
            return "Aksesibilitas 2"
        case .accessibility3:
            return "Aksesibilitas 3"
        case .accessibility4:
            return "Aksesibilitas 4"
        case .accessibility5:
            return "Aksesibilitas 5"
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

    /// Optional interval for a discrete slider such as the 12 text sizes.
    var step: Double? = nil

    /// Spoken label for VoiceOver.
    let accessibilityLabel: String

    /// Optional spoken value; continuous sliders fall back to a percentage.
    var accessibilityValue: String? = nil

    @ScaledMetric(relativeTo: .body) private var scaledThumbSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var scaledTrackHeight: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var scaledControlHeight: CGFloat = 44

    private var thumbSize: CGFloat { min(scaledThumbSize, 34) }
    private var trackHeight: CGFloat { min(scaledTrackHeight, 7) }
    private var controlHeight: CGFloat { min(max(scaledControlHeight, 44), 72) }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let travel = max(width - thumbSize, 1)
            let rangeLength = max(range.upperBound - range.lowerBound, 0.000_001)
            let fraction = (value - range.lowerBound) / rangeLength

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(white: 0.85))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(AppColor.primary)
                    .frame(width: thumbSize / 2 + fraction * travel, height: trackHeight)

                Circle()
                    .fill(AppColor.primary)
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
                        value = adjustedValue(
                            range.lowerBound + clamped * rangeLength
                        )
                    }
            )
        }
        // 44pt minimum hit target (Apple HIG); the track/thumb stay their
        // visual size, centered in the taller touch area.
        .frame(height: controlHeight)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(spokenValue)
        .accessibilityAdjustableAction { direction in
            let adjustment = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment:
                value = adjustedValue(value + adjustment)
            case .decrement:
                value = adjustedValue(value - adjustment)
            @unknown default:
                break
            }
        }
    }

    private var spokenValue: String {
        if let accessibilityValue {
            return accessibilityValue
        }

        let rangeLength = max(range.upperBound - range.lowerBound, 0.000_001)
        let percentage = Int(((value - range.lowerBound) / rangeLength) * 100)
        return "\(percentage) persen"
    }

    private func adjustedValue(_ proposedValue: Double) -> Double {
        let clamped = min(max(proposedValue, range.lowerBound), range.upperBound)
        guard let step, step > 0 else {
            return clamped
        }

        let offset = ((clamped - range.lowerBound) / step).rounded() * step
        return min(max(range.lowerBound + offset, range.lowerBound), range.upperBound)
    }
}

/// A pure-SwiftUI switch used instead of the system `Toggle`, for the same
/// shader-rasterization reason as `SettingsSlider`.
struct SettingsToggle: View {

    /// The on/off state being edited.
    @Binding var isOn: Bool

    /// Spoken label for VoiceOver.
    let accessibilityLabel: String

    @ScaledMetric(relativeTo: .body) private var scaledWidth: CGFloat = 48
    @ScaledMetric(relativeTo: .body) private var scaledHeight: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var scaledInset: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var scaledHitHeight: CGFloat = 44

    private var switchWidth: CGFloat { min(scaledWidth, 72) }
    private var switchHeight: CGFloat { min(scaledHeight, 42) }
    private var switchInset: CGFloat { min(scaledInset, 5) }
    private var hitHeight: CGFloat { min(max(scaledHitHeight, 44), 70) }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                isOn.toggle()
            }
        } label: {
            // Use the same OwlLala blue as the settings sliders so all active
            // controls share one clear visual state.
            Capsule()
                .fill(isOn ? AppColor.primary : Color(white: 0.85))
                .frame(width: switchWidth, height: switchHeight)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        .padding(switchInset)
                }
                // 44pt minimum hit target; the capsule keeps its visual size.
                .frame(minHeight: hitHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? "Aktif" : "Nonaktif")
        .accessibilityAddTraits(.isToggle)
    }
}

// MARK: - Preview

#Preview("Settings Page") {
    let settingsViewModel = SettingsViewModel(storageService: StorageService())

    return SettingsView(viewModel: settingsViewModel, onDismiss: {})
        .environmentObject(settingsViewModel)
}

#Preview("Settings Modal") {
    let settingsViewModel = SettingsViewModel(storageService: StorageService())

    return ZStack {
        Color(white: 0.85)
            .ignoresSafeArea()

        SettingsView(viewModel: settingsViewModel, isModal: true, onDismiss: {})
    }
    .environmentObject(settingsViewModel)
}
