//
//  SettingsTests.swift
//  OwlLalaTests
//
//  Comprehensive Settings TDD: model normalization and migration,
//  persistence, shared draft editing, Dynamic Type mapping, color-filter
//  matrices, and slider value calculations.
//

import Foundation
import SwiftUI
import Testing
@testable import OwlLala

// MARK: - Settings Test Helpers

@MainActor
private func makeSettingsStorage(
    firstChapterID: String = "chapter-1"
) -> StorageService {
    StorageService(
        firstChapterID: firstChapterID,
        userDefaults: UserDefaults(suiteName: UUID().uuidString)!
    )
}

@MainActor
private func makeSettingsViewModel() -> (
    storage: StorageService,
    viewModel: SettingsViewModel
) {
    let storage = makeSettingsStorage()
    return (storage, SettingsViewModel(storageService: storage))
}

@MainActor
private func allowSettingsPublisherToPropagate() async {
    for _ in 0..<8 {
        await Task.yield()
    }
}

@MainActor
private func decodeSettings(_ json: String) throws -> Settings {
    try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
}

@MainActor
private func settingsDecodingFails(_ json: String) -> Bool {
    do {
        _ = try decodeSettings(json)
        return false
    } catch {
        return true
    }
}

// MARK: - Settings Model Defaults and Normalization

@MainActor
@Suite("Settings Model — Defaults and Normalization")
struct SettingsModelDefaultsTests {

    @Test func defaultValueContainsTheDocumentedPreferences() {
        let settings = Settings.defaultValue

        #expect(settings.backgroundBrightness == 1.0)
        #expect(settings.colorVisionSimulation == nil)
        #expect(settings.lastColorVisionSimulation == .protanopia)
        #expect(settings.textSize == .large)
        #expect(settings.isColorVisionSimulationEnabled == false)
        #expect(settings == Settings())
    }

    @Test func brightnessBoundsMatchTheSupportedRange() {
        #expect(Settings.minimumBackgroundBrightness == 0.6)
        #expect(Settings.maximumBackgroundBrightness == 1.0)
        #expect(Settings.minimumBackgroundBrightness < Settings.maximumBackgroundBrightness)
    }

    @Test func initializerPreservesEveryInRangeBrightness() {
        for brightness in [0.6, 0.61, 0.75, 0.999, 1.0] {
            #expect(Settings(backgroundBrightness: brightness).backgroundBrightness == brightness)
        }
    }

    @Test func initializerClampsBrightnessOutsideTheSupportedRange() {
        #expect(Settings(backgroundBrightness: -100).backgroundBrightness == 0.6)
        #expect(Settings(backgroundBrightness: 0.59).backgroundBrightness == 0.6)
        #expect(Settings(backgroundBrightness: 1.01).backgroundBrightness == 1.0)
        #expect(Settings(backgroundBrightness: 100).backgroundBrightness == 1.0)
    }

    @Test func brightnessMutatorClampsAndCanReturnToAnInteriorValue() {
        var settings = Settings()

        settings.setBackgroundBrightness(-1)
        #expect(settings.backgroundBrightness == 0.6)

        settings.setBackgroundBrightness(4)
        #expect(settings.backgroundBrightness == 1.0)

        settings.setBackgroundBrightness(0.82)
        #expect(settings.backgroundBrightness == 0.82)
    }

    @Test func textSizeMutatorSupportsEveryCategory() {
        var settings = Settings()

        for size in AppTextSize.allCases {
            settings.setTextSize(size)
            #expect(settings.textSize == size)
        }
    }
}

// MARK: - Settings Color Filter Model

@MainActor
@Suite("Settings Model — Color Filters")
struct SettingsColorFilterModelTests {

    @Test func everySimulationCanBeEnabled() {
        for simulation in ColorVisionSimulation.allCases {
            var settings = Settings()

            settings.enableColorVisionSimulation(simulation)

            #expect(settings.colorVisionSimulation == simulation)
            #expect(settings.lastColorVisionSimulation == simulation)
            #expect(settings.isColorVisionSimulationEnabled)
        }
    }

    @Test func disablingAFilterRetainsItsSelection() {
        for simulation in ColorVisionSimulation.allCases {
            var settings = Settings(colorVisionSimulation: simulation)

            settings.disableColorVisionSimulation()

            #expect(settings.colorVisionSimulation == nil)
            #expect(settings.lastColorVisionSimulation == simulation)
            #expect(settings.isColorVisionSimulationEnabled == false)
        }
    }

    @Test func changingTheActiveFilterUpdatesTheRetainedSelection() {
        var settings = Settings(colorVisionSimulation: .protanopia)

        settings.enableColorVisionSimulation(.deuteranopia)
        settings.enableColorVisionSimulation(.tritanopia)

        #expect(settings.colorVisionSimulation == .tritanopia)
        #expect(settings.lastColorVisionSimulation == .tritanopia)
    }

    @Test func explicitRetainedSelectionIsPreservedByInitializer() {
        let settings = Settings(
            colorVisionSimulation: nil,
            lastColorVisionSimulation: .tritanopia
        )

        #expect(settings.colorVisionSimulation == nil)
        #expect(settings.lastColorVisionSimulation == .tritanopia)
    }

    @Test func simulationIdentifiersAndLabelsAreStableAndUnique() {
        let simulations = ColorVisionSimulation.allCases

        #expect(simulations.map(\.id) == [
            "protanopia",
            "deuteranopia",
            "tritanopia"
        ])
        #expect(simulations.map(\.displayName) == [
            "Red/Green",
            "Green/Red",
            "Blue/Yellow"
        ])
        #expect(Set(simulations.map(\.id)).count == simulations.count)
    }
}

// MARK: - App Text Size

@MainActor
@Suite("App Text Size")
struct AppTextSizeTests {

    @Test func allTwelveCategoriesHaveStableAscendingIndices() {
        #expect(AppTextSize.allCases.count == 12)

        for (index, size) in AppTextSize.allCases.enumerated() {
            #expect(size.index == index)
            #expect(size.id == size.rawValue)
        }
    }

    @Test func nearestIndexReturnsEveryExactCategory() {
        for (index, size) in AppTextSize.allCases.enumerated() {
            #expect(AppTextSize(nearestIndex: index) == size)
        }
    }

    @Test func nearestIndexClampsValuesBelowAndAboveTheSliderRange() {
        #expect(AppTextSize(nearestIndex: Int.min) == .extraSmall)
        #expect(AppTextSize(nearestIndex: -1) == .extraSmall)
        #expect(AppTextSize(nearestIndex: AppTextSize.allCases.count) == .accessibility5)
        #expect(AppTextSize(nearestIndex: Int.max) == .accessibility5)
    }

    @Test func rawValuesAreUniqueAndRoundTrip() {
        let rawValues = AppTextSize.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == AppTextSize.allCases.count)

        for size in AppTextSize.allCases {
            #expect(AppTextSize(rawValue: size.rawValue) == size)
        }
    }
}

// MARK: - Settings Codable

@MainActor
@Suite("Settings Codable")
struct SettingsCodableTests {

    @Test func everyTextSizeAndFilterCombinationRoundTrips() throws {
        let filters: [ColorVisionSimulation?] = [nil] + ColorVisionSimulation.allCases

        for textSize in AppTextSize.allCases {
            for filter in filters {
                let original = Settings(
                    backgroundBrightness: 0.73,
                    colorVisionSimulation: filter,
                    lastColorVisionSimulation: filter ?? .tritanopia,
                    textSize: textSize
                )

                let data = try JSONEncoder().encode(original)
                let decoded = try JSONDecoder().decode(Settings.self, from: data)

                #expect(decoded == original)
            }
        }
    }

    @Test func encodedPayloadUsesModernKeysAndOmitsLegacyTextScale() throws {
        let settings = Settings(
            backgroundBrightness: 0.8,
            colorVisionSimulation: .deuteranopia,
            textSize: .accessibility3
        )
        let data = try JSONEncoder().encode(settings)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object["backgroundBrightness"] != nil)
        #expect(object["colorVisionSimulation"] as? String == "deuteranopia")
        #expect(object["lastColorVisionSimulation"] as? String == "deuteranopia")
        #expect(object["textSize"] as? String == "accessibility3")
        #expect(object["textScale"] == nil)
    }

    @Test func nilActiveFilterIsOmittedButRetainedFilterIsEncoded() throws {
        let data = try JSONEncoder().encode(
            Settings(
                colorVisionSimulation: nil,
                lastColorVisionSimulation: .tritanopia
            )
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object["colorVisionSimulation"] == nil)
        #expect(object["lastColorVisionSimulation"] as? String == "tritanopia")
    }

    @Test func missingOptionalKeysUseSafeDefaults() throws {
        let decoded = try decodeSettings(
            #"{"backgroundBrightness":0.8}"#
        )

        #expect(decoded.backgroundBrightness == 0.8)
        #expect(decoded.colorVisionSimulation == nil)
        #expect(decoded.lastColorVisionSimulation == .protanopia)
        #expect(decoded.textSize == .large)
    }

    @Test func missingRetainedFilterDerivesItFromTheActiveFilter() throws {
        let decoded = try decodeSettings(
            #"{"backgroundBrightness":0.8,"colorVisionSimulation":"tritanopia"}"#
        )

        #expect(decoded.colorVisionSimulation == .tritanopia)
        #expect(decoded.lastColorVisionSimulation == .tritanopia)
    }

    @Test func extraUnknownKeysAreIgnored() throws {
        let decoded = try decodeSettings(
            #"{"backgroundBrightness":0.9,"textSize":"small","futureSetting":true}"#
        )

        #expect(decoded.backgroundBrightness == 0.9)
        #expect(decoded.textSize == .small)
    }

    @Test func decodedBrightnessIsNormalized() throws {
        let below = try decodeSettings(#"{"backgroundBrightness":-4}"#)
        let above = try decodeSettings(#"{"backgroundBrightness":4}"#)

        #expect(below.backgroundBrightness == 0.6)
        #expect(above.backgroundBrightness == 1.0)
    }

    @Test func missingRequiredBrightnessIsRejected() {
        #expect(settingsDecodingFails(#"{"textSize":"large"}"#))
    }

    @Test func wrongBrightnessTypeIsRejected() {
        #expect(settingsDecodingFails(#"{"backgroundBrightness":"bright"}"#))
    }

    @Test func unknownModernTextSizeIsRejected() {
        #expect(
            settingsDecodingFails(
                #"{"backgroundBrightness":1,"textSize":"gigantic"}"#
            )
        )
    }

    @Test func unknownColorFilterIsRejected() {
        #expect(
            settingsDecodingFails(
                #"{"backgroundBrightness":1,"colorVisionSimulation":"unknown"}"#
            )
        )
        #expect(
            settingsDecodingFails(
                #"{"backgroundBrightness":1,"lastColorVisionSimulation":"unknown"}"#
            )
        )
    }
}

// MARK: - Legacy Settings Migration

@MainActor
@Suite("Settings Legacy Text Migration")
struct SettingsLegacyMigrationTests {

    @Test func legacyScaleThresholdsMapToTheExpectedDynamicTypeCategories() throws {
        let cases: [(Double, AppTextSize)] = [
            (-10, .large),
            (1.0, .large),
            (1.049, .large),
            (1.05, .extraLarge),
            (1.149, .extraLarge),
            (1.15, .extraExtraLarge),
            (1.249, .extraExtraLarge),
            (1.25, .extraExtraExtraLarge),
            (1.349, .extraExtraExtraLarge),
            (1.35, .accessibility1),
            (50, .accessibility1)
        ]

        for (scale, expected) in cases {
            let decoded = try decodeSettings(
                #"{"backgroundBrightness":1,"textScale":\#(scale)}"#
            )
            #expect(decoded.textSize == expected)
        }
    }

    @Test func modernTextSizeTakesPriorityWhenLegacyScaleAlsoExists() throws {
        let decoded = try decodeSettings(
            #"{"backgroundBrightness":1,"textSize":"accessibility5","textScale":1.0}"#
        )

        #expect(decoded.textSize == .accessibility5)
    }

    @Test func invalidLegacyScaleTypeIsRejectedWhenNoModernValueExists() {
        #expect(
            settingsDecodingFails(
                #"{"backgroundBrightness":1,"textScale":"large"}"#
            )
        )
    }
}

// MARK: - Settings Persistence

@MainActor
@Suite("Settings Persistence")
struct SettingsPersistenceTests {

    @Test func emptyStorageStartsWithSettingsAndProgressDefaults() {
        let storage = makeSettingsStorage(firstChapterID: "first")

        #expect(storage.settings == .defaultValue)
        #expect(storage.userStats.isChapterUnlocked("first"))
        #expect(storage.userStats.completedChapterCount == 0)
    }

    @Test func updateSettingsChangesThePublishedValue() {
        let storage = makeSettingsStorage()
        let updated = Settings(
            backgroundBrightness: 0.74,
            colorVisionSimulation: .tritanopia,
            textSize: .accessibility4
        )

        storage.updateSettings(updated)

        #expect(storage.settings == updated)
    }

    @Test func settingsPersistAcrossStorageServiceInstances() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = StorageService(userDefaults: defaults)
        let expected = Settings(
            backgroundBrightness: 0.67,
            colorVisionSimulation: nil,
            lastColorVisionSimulation: .deuteranopia,
            textSize: .extraExtraExtraLarge
        )

        first.updateSettings(expected)
        let reloaded = StorageService(userDefaults: defaults)

        #expect(reloaded.settings == expected)
    }

    @Test func updateSettingsNormalizesBrightnessBeforePublishingAndSaving() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        var input = Settings()
        input.backgroundBrightness = -10

        let storage = StorageService(userDefaults: defaults)
        storage.updateSettings(input)
        let reloaded = StorageService(userDefaults: defaults)

        #expect(storage.settings.backgroundBrightness == 0.6)
        #expect(reloaded.settings.backgroundBrightness == 0.6)
    }

    @Test func resettingClearsPersistedSettingsAndRestoresDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = StorageService(
            firstChapterID: "custom-first",
            userDefaults: defaults
        )
        storage.updateSettings(
            Settings(
                backgroundBrightness: 0.7,
                colorVisionSimulation: .protanopia,
                textSize: .accessibility5
            )
        )
        storage.updateUserStats {
            $0.recordCompletedGame(chapterID: "custom-first", earnedStars: 3)
        }

        storage.resetToDefaults()
        let reloaded = StorageService(
            firstChapterID: "custom-first",
            userDefaults: defaults
        )

        #expect(storage.settings == .defaultValue)
        #expect(reloaded.settings == .defaultValue)
        #expect(storage.userStats.completedChapterCount == 0)
        #expect(reloaded.userStats.isChapterUnlocked("custom-first"))
    }

    @Test func changingSettingsDoesNotChangeUserProgress() {
        let storage = makeSettingsStorage()
        storage.updateUserStats {
            $0.recordCompletedGame(chapterID: "chapter-1", earnedStars: 2)
            $0.unlockChapter("chapter-2")
        }
        let progressBeforeSettingsChange = storage.userStats

        storage.updateSettings(
            Settings(
                backgroundBrightness: 0.6,
                colorVisionSimulation: .deuteranopia,
                textSize: .accessibility2
            )
        )

        #expect(storage.userStats == progressBeforeSettingsChange)
    }

    @Test func changingProgressDoesNotChangeSettings() {
        let storage = makeSettingsStorage()
        let settings = Settings(
            backgroundBrightness: 0.71,
            colorVisionSimulation: .tritanopia,
            textSize: .small
        )
        storage.updateSettings(settings)

        storage.updateUserStats {
            $0.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
        }

        #expect(storage.settings == settings)
    }

    @Test func isolatedUserDefaultsSuitesDoNotShareSettings() {
        let first = makeSettingsStorage()
        let second = makeSettingsStorage()

        first.updateSettings(
            Settings(
                backgroundBrightness: 0.6,
                colorVisionSimulation: .protanopia,
                textSize: .accessibility5
            )
        )

        #expect(first.settings != second.settings)
        #expect(second.settings == .defaultValue)
    }
}

// MARK: - Settings Dynamic Type Mapping

@MainActor
@Suite("Settings Dynamic Type Mapping")
struct SettingsDynamicTypeMappingTests {

    @Test func everyPersistedTextSizeMapsToItsNativeDynamicTypeSize() {
        let cases: [(AppTextSize, DynamicTypeSize)] = [
            (.extraSmall, .xSmall),
            (.small, .small),
            (.medium, .medium),
            (.large, .large),
            (.extraLarge, .xLarge),
            (.extraExtraLarge, .xxLarge),
            (.extraExtraExtraLarge, .xxxLarge),
            (.accessibility1, .accessibility1),
            (.accessibility2, .accessibility2),
            (.accessibility3, .accessibility3),
            (.accessibility4, .accessibility4),
            (.accessibility5, .accessibility5)
        ]

        for (appSize, expectedDynamicSize) in cases {
            let settings = Settings(textSize: appSize)
            #expect(settings.preferredDynamicTypeSize == expectedDynamicSize)
        }
    }

    @Test func mappingCoversEveryAppTextSizeExactlyOnce() {
        let mappedSizes = AppTextSize.allCases.map {
            Settings(textSize: $0).preferredDynamicTypeSize
        }

        #expect(mappedSizes.count == AppTextSize.allCases.count)
        #expect(Set(mappedSizes).count == AppTextSize.allCases.count)
    }
}

// MARK: - Color Filter Matrices

@MainActor
@Suite("Color Filter Matrices")
struct SettingsColorFilterMatrixTests {

    @Test func identityMatrixIsAnExactThreeByThreeIdentity() {
        #expect(ColorVisionSimulation.identityMatrix == [
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        ])
    }

    @Test func everySimulationMatrixHasNineFiniteCoefficients() {
        for simulation in ColorVisionSimulation.allCases {
            let matrix = simulation.simulationMatrix
            let coefficientsAreFinite = matrix.allSatisfy { $0.isFinite }

            #expect(matrix.count == 9)
            #expect(coefficientsAreFinite)
        }
    }

    @Test func everySimulationActuallyChangesColors() {
        for simulation in ColorVisionSimulation.allCases {
            #expect(simulation.simulationMatrix != ColorVisionSimulation.identityMatrix)
        }
    }

    @Test func everySimulationMatrixPreservesNeutralWhite() {
        for simulation in ColorVisionSimulation.allCases {
            let matrix = simulation.simulationMatrix

            for rowStart in stride(from: 0, to: matrix.count, by: 3) {
                let rowSum = matrix[rowStart] + matrix[rowStart + 1] + matrix[rowStart + 2]
                #expect(abs(rowSum - 1) < 0.000_01)
            }
        }
    }

    @Test func eachSimulationUsesADistinctMatrix() {
        let matrices = ColorVisionSimulation.allCases.map(\.simulationMatrix)

        for firstIndex in matrices.indices {
            for secondIndex in matrices.indices where firstIndex != secondIndex {
                #expect(matrices[firstIndex] != matrices[secondIndex])
            }
        }
    }
}

// MARK: - SettingsViewModel Lifecycle

@MainActor
@Suite("SettingsViewModel — Editing Lifecycle")
struct SettingsViewModelLifecycleTests {

    @Test func initializationMirrorsPersistedSettingsWithoutEditing() {
        let storage = makeSettingsStorage()
        let persisted = Settings(
            backgroundBrightness: 0.72,
            colorVisionSimulation: .deuteranopia,
            textSize: .extraLarge
        )
        storage.updateSettings(persisted)

        let viewModel = SettingsViewModel(storageService: storage)

        #expect(viewModel.savedSettings == persisted)
        #expect(viewModel.draftSettings == persisted)
        #expect(viewModel.activeDisplaySettings == persisted)
        #expect(viewModel.isEditing == false)
        #expect(viewModel.hasUnsavedChanges == false)
        #expect(viewModel.isFilterEnabled)
    }

    @Test func beginEditingStartsFromTheLatestPersistedSettings() {
        let context = makeSettingsViewModel()
        let latest = Settings(
            backgroundBrightness: 0.66,
            colorVisionSimulation: .tritanopia,
            textSize: .accessibility1
        )
        context.storage.updateSettings(latest)

        context.viewModel.beginEditing()

        #expect(context.viewModel.isEditing)
        #expect(context.viewModel.savedSettings == latest)
        #expect(context.viewModel.draftSettings == latest)
        #expect(context.viewModel.activeDisplaySettings == latest)
    }

    @Test func repeatedBeginEditingDoesNotEraseInProgressChanges() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.7)
        context.viewModel.setDraftTextSize(.accessibility5)

        context.viewModel.beginEditing()

        #expect(context.viewModel.draftSettings.backgroundBrightness == 0.7)
        #expect(context.viewModel.draftSettings.textSize == .accessibility5)
        #expect(context.viewModel.hasUnsavedChanges)
    }

    @Test func activeDisplaySettingsUsesDraftOnlyDuringEditing() {
        let context = makeSettingsViewModel()
        let saved = context.viewModel.savedSettings

        context.viewModel.setDraftBrightness(0.7)
        #expect(context.viewModel.activeDisplaySettings == saved)

        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.7)
        #expect(context.viewModel.activeDisplaySettings.backgroundBrightness == 0.7)
    }

    @Test func hasUnsavedChangesTracksChangesAndReversions() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        #expect(context.viewModel.hasUnsavedChanges == false)

        context.viewModel.setDraftBrightness(0.7)
        #expect(context.viewModel.hasUnsavedChanges)

        context.viewModel.setDraftBrightness(
            context.viewModel.savedSettings.backgroundBrightness
        )
        #expect(context.viewModel.hasUnsavedChanges == false)

        context.viewModel.setDraftTextSize(.extraSmall)
        #expect(context.viewModel.hasUnsavedChanges)
    }

    @Test func saveCommitsEveryDraftFieldAndEndsEditing() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.8)
        context.viewModel.setDraftTextSize(.accessibility4)
        context.viewModel.enableSimulation(.tritanopia)

        context.viewModel.save()

        #expect(context.viewModel.isEditing == false)
        #expect(context.viewModel.hasUnsavedChanges == false)
        #expect(context.storage.settings.backgroundBrightness == 0.8)
        #expect(context.storage.settings.textSize == .accessibility4)
        #expect(context.storage.settings.colorVisionSimulation == .tritanopia)
        #expect(context.viewModel.savedSettings == context.storage.settings)
        #expect(context.viewModel.draftSettings == context.storage.settings)
        #expect(context.viewModel.activeDisplaySettings == context.storage.settings)
    }

    @Test func savingWithoutChangesIsSafeAndIdempotent() {
        let context = makeSettingsViewModel()
        let original = context.storage.settings
        context.viewModel.beginEditing()

        context.viewModel.save()
        context.viewModel.save()

        #expect(context.storage.settings == original)
        #expect(context.viewModel.savedSettings == original)
        #expect(context.viewModel.draftSettings == original)
        #expect(context.viewModel.isEditing == false)
    }

    @Test func cancelDiscardsEveryDraftFieldAndEndsEditing() {
        let context = makeSettingsViewModel()
        let original = context.storage.settings
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.6)
        context.viewModel.setDraftTextSize(.accessibility5)
        context.viewModel.enableSimulation(.deuteranopia)

        context.viewModel.cancel()

        #expect(context.viewModel.isEditing == false)
        #expect(context.viewModel.hasUnsavedChanges == false)
        #expect(context.viewModel.savedSettings == original)
        #expect(context.viewModel.draftSettings == original)
        #expect(context.storage.settings == original)
    }

    @Test func repeatedCancelIsSafeAndKeepsThePersistedValue() {
        let context = makeSettingsViewModel()
        let original = context.storage.settings

        context.viewModel.cancel()
        context.viewModel.cancel()

        #expect(context.viewModel.savedSettings == original)
        #expect(context.viewModel.draftSettings == original)
        #expect(context.viewModel.isEditing == false)
    }
}

// MARK: - SettingsViewModel Values

@MainActor
@Suite("SettingsViewModel — Brightness and Text Size")
struct SettingsViewModelValueTests {

    @Test func draftBrightnessSupportsBoundsAndInteriorValues() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        for value in [0.6, 0.77, 1.0] {
            context.viewModel.setDraftBrightness(value)
            #expect(context.viewModel.draftSettings.backgroundBrightness == value)
        }
    }

    @Test func draftBrightnessClampsInvalidSliderInputs() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        context.viewModel.setDraftBrightness(-1)
        #expect(context.viewModel.draftSettings.backgroundBrightness == 0.6)

        context.viewModel.setDraftBrightness(2)
        #expect(context.viewModel.draftSettings.backgroundBrightness == 1.0)
    }

    @Test func everyTextSizeCanBePreviewedAndSaved() {
        for size in AppTextSize.allCases {
            let context = makeSettingsViewModel()
            context.viewModel.beginEditing()

            context.viewModel.setDraftTextSize(size)
            #expect(context.viewModel.draftSettings.textSize == size)
            #expect(context.viewModel.activeDisplaySettings.textSize == size)

            context.viewModel.save()
            #expect(context.storage.settings.textSize == size)
        }
    }

    @Test func draftMutatorsDoNotPersistBeforeSave() {
        let context = makeSettingsViewModel()
        let original = context.storage.settings
        context.viewModel.beginEditing()

        context.viewModel.setDraftBrightness(0.6)
        context.viewModel.setDraftTextSize(.accessibility5)

        #expect(context.storage.settings == original)
        #expect(context.viewModel.savedSettings == original)
        #expect(context.viewModel.draftSettings != original)
    }
}

// MARK: - SettingsViewModel Color Filters

@MainActor
@Suite("SettingsViewModel — Color Filters")
struct SettingsViewModelColorFilterTests {

    @Test func enablingTheSwitchUsesTheDefaultRetainedSimulation() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        context.viewModel.setFilterEnabled(true)

        #expect(context.viewModel.isFilterEnabled)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == .protanopia)
        #expect(context.viewModel.isSimulationSelected(.protanopia))
    }

    @Test func everyFilterCanBeSelectedWhileTheSwitchIsOn() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setFilterEnabled(true)

        for simulation in ColorVisionSimulation.allCases {
            context.viewModel.selectSimulation(simulation)

            #expect(context.viewModel.isFilterEnabled)
            #expect(context.viewModel.draftSettings.colorVisionSimulation == simulation)
            #expect(context.viewModel.isSimulationSelected(simulation))
        }
    }

    @Test func selectingAFilterWhileTheSwitchIsOffIsIgnored() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        context.viewModel.selectSimulation(.tritanopia)

        #expect(context.viewModel.isFilterEnabled == false)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == nil)
        #expect(context.viewModel.draftSettings.lastColorVisionSimulation == .protanopia)
    }

    @Test func switchingOffRetainsAndSwitchingOnRestoresTheSelection() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setFilterEnabled(true)
        context.viewModel.selectSimulation(.deuteranopia)

        context.viewModel.setFilterEnabled(false)

        #expect(context.viewModel.isFilterEnabled == false)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == nil)
        #expect(context.viewModel.isSimulationSelected(.deuteranopia))

        context.viewModel.setFilterEnabled(true)

        #expect(context.viewModel.isFilterEnabled)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == .deuteranopia)
    }

    @Test func repeatedSwitchValuesAreIdempotent() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        context.viewModel.setFilterEnabled(true)
        context.viewModel.setFilterEnabled(true)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == .protanopia)

        context.viewModel.setFilterEnabled(false)
        context.viewModel.setFilterEnabled(false)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == nil)
        #expect(context.viewModel.draftSettings.lastColorVisionSimulation == .protanopia)
    }

    @Test func directEnableAndDisableKeepDerivedSwitchStateSynchronized() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()

        context.viewModel.enableSimulation(.tritanopia)
        #expect(context.viewModel.isFilterEnabled)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == .tritanopia)

        context.viewModel.disableSimulation()
        #expect(context.viewModel.isFilterEnabled == false)
        #expect(context.viewModel.draftSettings.colorVisionSimulation == nil)
        #expect(context.viewModel.draftSettings.lastColorVisionSimulation == .tritanopia)
    }

    @Test func filterDraftIsNotPersistedUntilSave() {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.enableSimulation(.deuteranopia)

        #expect(context.storage.settings.colorVisionSimulation == nil)

        context.viewModel.save()

        #expect(context.storage.settings.colorVisionSimulation == .deuteranopia)
    }

    @Test func cancellingRestoresTheSavedSwitchAndSelection() {
        let storage = makeSettingsStorage()
        storage.updateSettings(
            Settings(
                colorVisionSimulation: nil,
                lastColorVisionSimulation: .tritanopia
            )
        )
        let viewModel = SettingsViewModel(storageService: storage)
        viewModel.beginEditing()
        viewModel.setFilterEnabled(true)
        viewModel.selectSimulation(.deuteranopia)

        viewModel.cancel()

        #expect(viewModel.isFilterEnabled == false)
        #expect(viewModel.draftSettings.colorVisionSimulation == nil)
        #expect(viewModel.isSimulationSelected(.tritanopia))
    }
}

// MARK: - SettingsViewModel External Synchronization

@MainActor
@Suite("SettingsViewModel — Shared Storage Synchronization")
struct SettingsViewModelSynchronizationTests {

    @Test func externalChangeUpdatesSavedDraftAndDisplayWhileIdle() async {
        let context = makeSettingsViewModel()
        let external = Settings(
            backgroundBrightness: 0.69,
            colorVisionSimulation: .protanopia,
            textSize: .accessibility2
        )

        context.storage.updateSettings(external)
        await allowSettingsPublisherToPropagate()

        #expect(context.viewModel.savedSettings == external)
        #expect(context.viewModel.draftSettings == external)
        #expect(context.viewModel.activeDisplaySettings == external)
        #expect(context.viewModel.isFilterEnabled)
    }

    @Test func externalChangeUpdatesSavedButDoesNotOverwriteAnActiveDraft() async {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.7)
        context.viewModel.setDraftTextSize(.accessibility5)
        let draftBeforeExternalChange = context.viewModel.draftSettings
        let external = Settings(
            backgroundBrightness: 0.9,
            colorVisionSimulation: .tritanopia,
            textSize: .small
        )

        context.storage.updateSettings(external)
        await allowSettingsPublisherToPropagate()

        #expect(context.viewModel.savedSettings == external)
        #expect(context.viewModel.draftSettings == draftBeforeExternalChange)
        #expect(context.viewModel.activeDisplaySettings == draftBeforeExternalChange)
        #expect(context.viewModel.hasUnsavedChanges)
    }

    @Test func cancelAfterExternalChangeUsesTheNewestPersistedSettings() async {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.6)
        let external = Settings(
            backgroundBrightness: 0.88,
            colorVisionSimulation: .deuteranopia,
            textSize: .extraExtraLarge
        )
        context.storage.updateSettings(external)
        await allowSettingsPublisherToPropagate()

        context.viewModel.cancel()

        #expect(context.viewModel.savedSettings == external)
        #expect(context.viewModel.draftSettings == external)
        #expect(context.viewModel.activeDisplaySettings == external)
    }

    @Test func saveAfterExternalChangeCommitsTheActiveDraft() async {
        let context = makeSettingsViewModel()
        context.viewModel.beginEditing()
        context.viewModel.setDraftBrightness(0.65)
        context.viewModel.setDraftTextSize(.accessibility4)
        let activeDraft = context.viewModel.draftSettings

        context.storage.updateSettings(
            Settings(
                backgroundBrightness: 0.95,
                colorVisionSimulation: .protanopia,
                textSize: .small
            )
        )
        await allowSettingsPublisherToPropagate()

        context.viewModel.save()
        await allowSettingsPublisherToPropagate()

        #expect(context.storage.settings == activeDraft)
        #expect(context.viewModel.savedSettings == activeDraft)
        #expect(context.viewModel.draftSettings == activeDraft)
    }

    @Test func twoViewModelsShareSavedChangesThroughOneStorageService() async {
        let storage = makeSettingsStorage()
        let first = SettingsViewModel(storageService: storage)
        let second = SettingsViewModel(storageService: storage)
        first.beginEditing()
        first.setDraftBrightness(0.76)
        first.setDraftTextSize(.accessibility3)
        first.enableSimulation(.tritanopia)

        first.save()
        await allowSettingsPublisherToPropagate()

        #expect(second.savedSettings == storage.settings)
        #expect(second.draftSettings == storage.settings)
        #expect(second.activeDisplaySettings == storage.settings)
    }

    @Test func editingSecondViewModelKeepsItsDraftWhenFirstViewModelSaves() async {
        let storage = makeSettingsStorage()
        let first = SettingsViewModel(storageService: storage)
        let second = SettingsViewModel(storageService: storage)
        second.beginEditing()
        second.setDraftBrightness(0.63)
        let secondDraft = second.draftSettings

        first.beginEditing()
        first.setDraftTextSize(.accessibility5)
        first.save()
        await allowSettingsPublisherToPropagate()

        #expect(second.savedSettings == storage.settings)
        #expect(second.draftSettings == secondDraft)
        #expect(second.activeDisplaySettings == secondDraft)
    }
}

// MARK: - Settings Slider Value Logic

@MainActor
@Suite("Settings Slider Value Logic")
struct SettingsSliderValueTests {

    @Test func continuousAdjustmentClampsToBounds() {
        let range = 0.6...1.0

        #expect(SettingsSliderValue.adjusted(-1, in: range) == 0.6)
        #expect(SettingsSliderValue.adjusted(0.8, in: range) == 0.8)
        #expect(SettingsSliderValue.adjusted(2, in: range) == 1.0)
    }

    @Test func zeroAndNegativeStepsBehaveAsContinuousValues() {
        let range = 0.0...10.0

        #expect(SettingsSliderValue.adjusted(4.4, in: range, step: 0) == 4.4)
        #expect(SettingsSliderValue.adjusted(4.4, in: range, step: -1) == 4.4)
    }

    @Test func steppedAdjustmentSnapsToTheNearestStepFromLowerBound() {
        let range = 0.0...11.0

        #expect(SettingsSliderValue.adjusted(0.49, in: range, step: 1) == 0)
        #expect(SettingsSliderValue.adjusted(0.5, in: range, step: 1) == 1)
        #expect(SettingsSliderValue.adjusted(5.49, in: range, step: 1) == 5)
        #expect(SettingsSliderValue.adjusted(5.5, in: range, step: 1) == 6)
        #expect(SettingsSliderValue.adjusted(10.8, in: range, step: 1) == 11)
    }

    @Test func steppingUsesTheActualLowerBoundAsItsOrigin() {
        let range = 0.6...1.0

        #expect(SettingsSliderValue.adjusted(0.69, in: range, step: 0.1) == 0.7)
        #expect(SettingsSliderValue.adjusted(0.84, in: range, step: 0.1) == 0.8)
        #expect(SettingsSliderValue.adjusted(0.86, in: range, step: 0.1) == 0.9)
    }

    @Test func fractionMapsBoundsAndMidpointAndClampsOverflow() {
        let range = 0.6...1.0

        #expect(SettingsSliderValue.fraction(for: 0.6, in: range) == 0)
        #expect(abs(SettingsSliderValue.fraction(for: 0.8, in: range) - 0.5) < 0.000_001)
        #expect(SettingsSliderValue.fraction(for: 1.0, in: range) == 1)
        #expect(SettingsSliderValue.fraction(for: -5, in: range) == 0)
        #expect(SettingsSliderValue.fraction(for: 5, in: range) == 1)
    }

    @Test func degenerateRangeHasAStableZeroFractionAndPercentage() {
        let range = 0.5...0.5

        #expect(SettingsSliderValue.adjusted(-1, in: range) == 0.5)
        #expect(SettingsSliderValue.fraction(for: 0.5, in: range) == 0)
        #expect(SettingsSliderValue.percentage(for: 0.5, in: range) == 0)
    }

    @Test func touchLocationAccountsForTheThumbAtBothTrackEdges() {
        let range = 0.0...10.0
        let trackWidth = 100.0
        let thumbSize = 20.0

        #expect(
            SettingsSliderValue.value(
                at: 10,
                trackWidth: trackWidth,
                thumbSize: thumbSize,
                in: range
            ) == 0
        )
        #expect(
            SettingsSliderValue.value(
                at: 50,
                trackWidth: trackWidth,
                thumbSize: thumbSize,
                in: range
            ) == 5
        )
        #expect(
            SettingsSliderValue.value(
                at: 90,
                trackWidth: trackWidth,
                thumbSize: thumbSize,
                in: range
            ) == 10
        )
    }

    @Test func touchLocationClampsOutsideTheTrack() {
        let range = 0.0...11.0

        #expect(
            SettingsSliderValue.value(
                at: -100,
                trackWidth: 100,
                thumbSize: 20,
                in: range,
                step: 1
            ) == 0
        )
        #expect(
            SettingsSliderValue.value(
                at: 1_000,
                trackWidth: 100,
                thumbSize: 20,
                in: range,
                step: 1
            ) == 11
        )
    }

    @Test func touchLocationAppliesDiscreteStepSnapping() {
        let value = SettingsSliderValue.value(
            at: 47,
            trackWidth: 100,
            thumbSize: 20,
            in: 0.0...11.0,
            step: 1
        )

        #expect(value == 5)
    }

    @Test func narrowTrackStillProducesBoundedValues() {
        let lower = SettingsSliderValue.value(
            at: -20,
            trackWidth: 10,
            thumbSize: 20,
            in: 0.0...1.0
        )
        let upper = SettingsSliderValue.value(
            at: 30,
            trackWidth: 10,
            thumbSize: 20,
            in: 0.0...1.0
        )

        #expect(lower == 0)
        #expect(upper == 1)
    }

    @Test func percentageRoundsAndClampsForVoiceOver() {
        let range = 0.0...1.0

        #expect(SettingsSliderValue.percentage(for: -1, in: range) == 0)
        #expect(SettingsSliderValue.percentage(for: 0.004, in: range) == 0)
        #expect(SettingsSliderValue.percentage(for: 0.005, in: range) == 1)
        #expect(SettingsSliderValue.percentage(for: 0.499, in: range) == 50)
        #expect(SettingsSliderValue.percentage(for: 1.5, in: range) == 100)
    }
}
