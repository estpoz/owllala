# Settings and Accessibility Implementation

## Purpose

This document explains the completed OwlLala Settings implementation, its
ownership boundaries, display behavior, persistence flow, accessibility
support, and automated test coverage.

Use it together with:

- [`DataModelsandBusinessRules.md`](DataModelsandBusinessRules.md)
- [`ViewModelResponsibilities.md`](ViewModelResponsibilities.md)
- [`TESTING.md`](TESTING.md)
- [`AGENTS.md`](AGENTS.md)

## Scope

OwlLala provides one shared Settings feature with two presentations:

- A full-screen Settings page opened from the Main Menu.
- An in-game Settings modal shown over Chapter Gameplay.

Both presentations use the same `SettingsViewModel`, edit the same draft, and
persist through the same `StorageService`.

The implemented settings are:

- Background brightness from `0.6` through `1.0`.
- Color-vision simulation:
  - Protanopia (`Red/Green`)
  - Deuteranopia (`Green/Red`)
  - Tritanopia (`Blue/Yellow`)
- App text size across all 12 native Dynamic Type categories:
  - X Small
  - Small
  - Medium
  - Large
  - Extra Large
  - Extra Extra Large
  - Extra Extra Extra Large
  - Accessibility 1–5

Audio and exit-confirmation preferences are not persisted Settings features in
the MVP.

## File Map

| File | Responsibility |
| --- | --- |
| `OwlLala/Models/Settings.swift` | Framework-independent persisted Settings model, normalization, Codable migration, text-size categories, and filter identifiers. |
| `OwlLala/Services/StorageService.swift` | The only Settings persistence owner. Encodes and decodes `Settings` through `UserDefaults`. |
| `OwlLala/ViewModels/SettingsViewModel.swift` | Draft-editing lifecycle, live preview state, save/cancel actions, and synchronization with shared storage. |
| `OwlLala/Views/Settings/SettingsView.swift` | Full-screen and modal Settings presentations, stationary navigation, controls, and layout behavior. |
| `OwlLala/Views/Settings/DisplayFilters.swift` | App-wide Dynamic Type mapping, background brightness, color-filter boundaries, and reusable screen containers. |
| `OwlLala/Views/Settings/ColorVisionFilter.metal` | GPU color-matrix shader used for color-vision simulation. |
| `OwlLala/Components/Buttons.swift` | Reusable fixed-size circular navigation and save controls. |
| `OwlLala/Components/SettingsChangesConfirmation.swift` | Confirmation UI for saving or discarding draft changes. |
| `OwlLala/ContentView.swift` | Creates and injects one shared `StorageService` and `SettingsViewModel`. |
| `OwlLalaTests/SettingsTests.swift` | Dedicated Settings model, service, ViewModel, mapping, matrix, and slider tests. |

## Architecture and Ownership

Settings follows the existing MVVM structure:

```text
ContentView
├── StorageService
│   └── persisted Settings
└── SettingsViewModel
    ├── savedSettings
    ├── draftSettings
    ├── activeDisplaySettings
    └── SettingsView
        ├── full-screen page
        └── gameplay modal
```

Ownership rules:

- `StorageService` is the only type that reads or writes `UserDefaults`.
- `SettingsViewModel` owns all editing actions and presentation state.
- `SettingsView` renders state and forwards user actions.
- Feature screens read the shared display state through environment-based
  modifiers and containers.
- Views do not encode, decode, or persist Settings directly.

## Settings Model

### Defaults

The safe default value is:

```text
Background brightness: 1.0
Active color filter: none
Retained filter: protanopia
Text size: Large
```

### Brightness Normalization

Brightness is normalized in the `Settings` initializer and mutator:

```text
value < 0.6  → 0.6
0.6...1.0   → unchanged
value > 1.0  → 1.0
```

Brightness only dims designated background layers. Foreground controls, text,
and learning illustrations must remain visually unchanged.

### Color-Filter State

`colorVisionSimulation` stores the active simulation. A `nil` value means the
filter is off.

`lastColorVisionSimulation` remembers the most recently selected simulation.
This supports the following behavior:

```text
Select Tritanopia
→ disable Filter Warna
→ active filter becomes nil
→ retained filter remains Tritanopia
→ enable Filter Warna
→ Tritanopia is restored
```

### Text-Size Representation

`AppTextSize` is a framework-independent persisted enum. Its 12 cases map
one-to-one to SwiftUI `DynamicTypeSize` values in `DisplayFilters.swift`.

The model stays independent from SwiftUI; the view layer owns the native
Dynamic Type mapping.

### Codable Compatibility

Current payloads encode:

- `backgroundBrightness`
- optional `colorVisionSimulation`
- `lastColorVisionSimulation`
- `textSize`

Older payloads may contain a multiplier-based `textScale`. During decoding,
legacy values migrate as follows:

| Legacy scale | Migrated category |
| --- | --- |
| `< 1.05` | Large |
| `1.05..<1.15` | Extra Large |
| `1.15..<1.25` | Extra Extra Large |
| `1.25..<1.35` | Extra Extra Extra Large |
| `>= 1.35` | Accessibility 1 |

If both `textSize` and `textScale` exist, the modern `textSize` value takes
priority.

## Shared Draft-Editing Flow

### State

`SettingsViewModel` exposes:

```swift
@Published private(set) var savedSettings: Settings
@Published private(set) var draftSettings: Settings
@Published private(set) var isEditing: Bool
```

Additional derived state:

- `activeDisplaySettings`
  - Returns the draft while editing.
  - Returns saved settings while idle.
- `hasUnsavedChanges`
  - Compares the complete draft with the saved value.
- `isFilterEnabled`
  - Derives directly from the draft's active simulation.

Deriving the filter switch from `draftSettings` prevents the switch and active
filter from becoming inconsistent.

### Begin Editing

`beginEditing()`:

1. Reads the latest Settings from shared storage.
2. Copies them into `savedSettings`.
3. Copies them into `draftSettings`.
4. Marks the session as editing.

Calling `beginEditing()` again during an active session does nothing, so a
SwiftUI subtree rebuild cannot erase in-progress edits.

### Live Preview

While editing, app display modifiers read `activeDisplaySettings`, so:

- Brightness previews immediately.
- Text size previews immediately.
- Color-filter selection previews immediately.

The draft is not written to persistent storage until Save completes.

### Save

`save()`:

1. Reconstructs a normalized `Settings` value from the draft.
2. Persists it through `StorageService.updateSettings`.
3. Updates saved and draft state.
4. Ends the editing session.

The view asks for confirmation before saving when changes exist.

### Cancel

`cancel()`:

1. Reads the latest persisted Settings.
2. Restores saved and draft state.
3. Ends the editing session.

Closing without saving never persists the draft.

### External Storage Changes

`SettingsViewModel` subscribes to `StorageService.settings`.

- While idle, an external change updates saved state, draft state, and the
  active display.
- While editing, an external change updates saved state but does not overwrite
  the active draft.
- Cancel after an external change restores the newest persisted value.
- Save after an external change commits the active draft.

This allows the full-screen page and gameplay modal to share one Settings
source without losing an active editing session.

## Dynamic Type

### Native Mapping

The app does not apply an arbitrary text scale. Each `AppTextSize` maps to its
matching native Dynamic Type category.

```text
extraSmall             → xSmall
small                  → small
medium                 → medium
large                  → large
extraLarge             → xLarge
extraExtraLarge        → xxLarge
extraExtraExtraLarge   → xxxLarge
accessibility1...5     → accessibility1...5
```

### Device and In-App Preference

The app respects both:

- The incoming device Dynamic Type category.
- The in-app `Ukuran Teks` preference.

The larger category wins. The in-app preference may increase the app's text
size but never reduces a larger system accessibility preference.

`ContentView` applies text sizing once to the shared navigation tree, allowing
the environment value to flow into pushed screens.

### Layout Behavior

- X Small through XXX Large use the fixed, non-scrolling Settings layout.
- Accessibility 1–5 use a scrolling content area so controls and labels remain
  reachable without clipping.
- The navigation header stays outside the scrolling content.
- The circular navigation and save buttons remain fixed at `98pt`; they do not
  grow with Dynamic Type.
- The `Pengaturan` title remains fixed at `44pt`.

## Stationary Navigation Header

Settings follows Chapter Selection's navigation placement:

- Horizontal side margin: `4%` of the available width.
- Top margin: `4%` of the available height at every Dynamic Type size.

The header contains:

- Reusable back or close button on the leading side.
- Centered `Pengaturan` title.
- Reusable save button on the trailing side.

The header is rendered as a separate top layer in `SettingsSurface`. Only the
Settings panel content scrolls, so button and title positions do not move when:

- Dynamic Type changes.
- Filter selection changes.
- Brightness changes.
- The accessibility content area scrolls.

## Background Brightness

Background brightness uses a black overlay with opacity derived from:

```text
overlay opacity = 1.0 - backgroundBrightness
```

Examples:

| Brightness | Black overlay |
| --- | --- |
| `1.0` | `0%` |
| `0.8` | `20%` |
| `0.6` | `40%` |

The overlay ignores hit testing so it cannot block controls.

## Color-Vision Simulation

### Shader

`ColorVisionFilter.metal` applies a row-major `3x3` RGB matrix to rendered
pixels.

`DisplayFilters.swift` supplies:

- An identity matrix when no simulation is active.
- A full-severity matrix for each supported simulation.

Using the identity matrix instead of structurally removing the shader keeps the
SwiftUI view hierarchy stable when the filter is toggled.

### Filter Boundaries

The color shader must run exactly once for each rendered layer.

OwlLala uses an environment ownership marker so nested backgrounds and content
do not apply the same matrix twice.

Key APIs:

- `appDisplayAdjustments()`
- `appAdaptiveColorFilter()`
- `appBackgroundAdjustments()`
- `AppScreen`
- `AppScrollScreen`
- `AppFilteredScrollView`

### UIKit Limitation

SwiftUI `colorEffect` cannot reliably rasterize UIKit-backed descendants such
as:

- `NavigationStack`
- `ScrollView`
- System `Slider`
- System `Toggle`
- `UIViewRepresentable`

For this reason:

- The shader is applied inside navigation boundaries, not around the root
  `NavigationStack`.
- Scrolling screens keep the UIKit scroll container outside the shader and
  filter pure-SwiftUI content islands.
- Settings uses custom SwiftUI-drawn slider and toggle controls.

## Reusable Settings Controls

### `SettingsSlider`

The custom slider supports:

- Dragging.
- Tap-to-set.
- Continuous ranges.
- Discrete stepped ranges.
- VoiceOver increment and decrement.
- A minimum accessible hit target.

`SettingsSliderValue` contains its pure calculations:

- Range clamping.
- Step snapping.
- Value-to-fraction conversion.
- Touch-position conversion.
- VoiceOver percentage calculation.

Separating this math allows deterministic unit tests without changing the
rendered control.

### `SettingsToggle`

The custom toggle is drawn entirely with SwiftUI shapes so it remains visible
inside a color-filtered subtree. It exposes an Indonesian accessibility value:

- `Aktif`
- `Nonaktif`

### Navigation and Save Buttons

Settings reuses `CircleIconButton` and `SaveChangesButton` from
`Components/Buttons.swift`.

The save button:

- Is grey and disabled when no draft changes exist.
- Becomes active when the draft differs from saved Settings.
- Uses confirmation before persistence.

## Test Coverage

All Settings-specific tests live in:

```text
OwlLalaTests/SettingsTests.swift
```

The file contains 82 test functions across 13 suites.

| Suite | Coverage |
| --- | --- |
| Settings Model — Defaults and Normalization | Default values, brightness bounds, clamping, and text-size mutation. |
| Settings Model — Color Filters | Enable, disable, retained selection, identifiers, and display labels. |
| App Text Size | All 12 cases, stable indices, raw values, and index clamping. |
| Settings Codable | Round trips, optional fields, unknown fields, invalid payloads, and normalization. |
| Settings Legacy Text Migration | Every legacy threshold and modern-key precedence. |
| Settings Persistence | Defaults, update, reload, reset, isolation, and separation from `UserStats`. |
| Settings Dynamic Type Mapping | Exact one-to-one mapping for all categories. |
| Color Filter Matrices | Identity, dimensions, finite coefficients, distinct matrices, and neutral-white preservation. |
| SettingsViewModel — Editing Lifecycle | Initialization, begin, preview, unsaved state, save, cancel, and idempotence. |
| SettingsViewModel — Brightness and Text Size | Bounds, persistence timing, and every text-size category. |
| SettingsViewModel — Color Filters | Toggle behavior, selection guards, retention, save, cancel, and derived switch state. |
| SettingsViewModel — Shared Storage Synchronization | Idle updates, draft protection, save/cancel conflicts, and multiple ViewModels. |
| Settings Slider Value Logic | Clamping, snapping, fractions, touch geometry, degenerate ranges, and percentages. |

Each storage test uses a unique `UserDefaults` suite and never touches the
application's real persisted data.

## Verified Validation

The complete `OwlLalaTests` target was run on:

```text
iPad Pro 11-inch (M5)
iOS Simulator 26.5
```

Latest verified result:

```text
127 passed
0 failed
0 skipped
```

Test command:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -quiet \
  -project /Users/stanleyyoung/Documents/ADA/CVDApp/OwlLala.xcodeproj \
  -scheme OwlLala \
  -destination 'platform=iOS Simulator,id=68CCA33A-7EBF-406D-BFEE-970F409AFD74' \
  -derivedDataPath /private/tmp/CVDAppSettingsSplitTests \
  -resultBundlePath /private/tmp/CVDAppSettingsSplitTests.xcresult \
  -only-testing:OwlLalaTests \
  test
```

Standalone build command:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -quiet \
  -project /Users/stanleyyoung/Documents/ADA/CVDApp/OwlLala.xcodeproj \
  -scheme OwlLala \
  -destination 'platform=iOS Simulator,id=68CCA33A-7EBF-406D-BFEE-970F409AFD74' \
  -derivedDataPath /private/tmp/CVDAppStationaryHeaderSplitBuild \
  build
```

## Known Limitations

- Unit tests validate matrix values, state, mapping, persistence, and control
  calculations; they do not compare rendered pixels.
- Pixel-level Metal verification would require a dedicated rendering or
  snapshot-test strategy.
- SwiftUI layout appearance should still be manually checked at X Small,
  XXX Large, Accessibility 1, and Accessibility 5 on a supported iPad
  landscape simulator.
- The project currently emits an unrelated asset-catalog warning because
  `page5-4 2.jpg` is an unassigned child in the `page5-4` image set.

## Extension Rules

When adding another Settings preference:

1. Add only mutable user preference data to `Settings`.
2. Normalize it inside the model.
3. Persist only through `StorageService`.
4. Add a focused mutation method to `SettingsViewModel`.
5. Render it from `draftSettings`.
6. Preview through `activeDisplaySettings` when appropriate.
7. Add model, persistence, ViewModel, migration, and boundary tests to
   `SettingsTests.swift`.
8. Keep UIKit-backed content outside Metal shader boundaries.
9. Preserve the stationary navigation header.
10. Update this document and the relevant business rules.
