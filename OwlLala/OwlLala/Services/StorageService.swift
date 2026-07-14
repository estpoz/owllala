//
//  StorageService.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Storage Service

/// Owns persisted user progress and settings for the application.
///
/// `StorageService` is the only type that reads from or writes to `UserDefaults`.
@MainActor
final class StorageService: ObservableObject {

    @Published private(set) var userStats: UserStats
    @Published private(set) var settings: Settings

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let defaultFirstChapterID: String

    private enum StorageKey {
        static let userStats = "owlLala.userStats"
        static let settings = "owlLala.settings"
    }

    /// Creates storage with safe defaults when persisted data is unavailable.
    init(
        firstChapterID: String = "chapter-1",
        userDefaults: UserDefaults = .standard
    ) {
        self.defaultFirstChapterID = firstChapterID
        self.userDefaults = userDefaults
        self.userStats = Self.loadValue(
            forKey: StorageKey.userStats,
            from: userDefaults,
            decoder: decoder,
            defaultValue: UserStats(firstChapterID: firstChapterID)
        )
        self.settings = Self.loadValue(
            forKey: StorageKey.settings,
            from: userDefaults,
            decoder: decoder,
            defaultValue: Settings.defaultValue
        )
    }

    /// Applies a mutation to user progress and persists the resulting value.
    func updateUserStats(_ update: (inout UserStats) -> Void) {
        var updatedStats = userStats
        update(&updatedStats)
        userStats = updatedStats
        save(userStats, forKey: StorageKey.userStats)
    }

    /// Replaces the saved settings with a normalized settings value.
    func updateSettings(_ settings: Settings) {
        let normalizedSettings = Settings(
            backgroundBrightness: settings.backgroundBrightness,
            colorVisionSimulation: settings.colorVisionSimulation
        )

        self.settings = normalizedSettings
        save(normalizedSettings, forKey: StorageKey.settings)
    }

    /// Clears saved values and restores in-memory defaults.
    func resetToDefaults() {
        userDefaults.removeObject(forKey: StorageKey.userStats)
        userDefaults.removeObject(forKey: StorageKey.settings)
        userStats = UserStats(firstChapterID: defaultFirstChapterID)
        settings = Settings.defaultValue
    }

    private func save<Value: Encodable>(_ value: Value, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            reportStorageError(error, context: "Failed to encode value for key \(key).")
        }
    }

    private static func loadValue<Value: Decodable>(
        forKey key: String,
        from userDefaults: UserDefaults,
        decoder: JSONDecoder,
        defaultValue: Value
    ) -> Value {
        guard let data = userDefaults.data(forKey: key) else {
            return defaultValue
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            reportStorageError(error, context: "Failed to decode value for key \(key).")
            return defaultValue
        }
    }

    private static func reportStorageError(_ error: Error, context: String) {
        #if DEBUG
        assertionFailure("\(context) \(error)")
        #else
        print("\(context) \(error)")
        #endif
    }

    private func reportStorageError(_ error: Error, context: String) {
        Self.reportStorageError(error, context: context)
    }
}
