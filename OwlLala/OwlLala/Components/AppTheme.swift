//
//  AppTheme.swift
//  OwlLala
//
//  OVERVIEW
//  --------
//  The app's design tokens from the Hi-Fi design: the primary color and the
//  SF Pro Rounded type scale. Every screen should pull its colors and fonts
//  from here instead of hard-coding values, so the whole app restyles from one
//  place.
//
//  TYPE SCALE (SF Pro Rounded)
//  ---------------------------
//  Large Title : 60pt, Bold
//  Title 1     : 40pt, Medium
//  Button      : 44pt, Bold
//  Headline    : 32pt, Medium
//  Body        : 28pt, Regular
//
//  USAGE
//  -----
//      Text("Pengaturan")
//          .font(.owlLargeTitle)          // fixed size
//
//      // Or, when the view scales with Dynamic Type via @ScaledMetric:
//      .font(.owlRounded(AppFontSize.headline * scale, .medium))
//

import SwiftUI

// MARK: - Colors

/// The app's color tokens.
enum AppColor {

    /// Primary brand blue (#0042AA) — buttons, selected states, accents.
    static let primary = Color(red: 0 / 255, green: 66 / 255, blue: 170 / 255)
}

// MARK: - Font Sizes

/// Base point sizes of the SF Pro Rounded type scale. Multiply by a
/// `@ScaledMetric` factor when the text should follow Larger Text settings.
enum AppFontSize {

    /// Large Title — 60pt Bold. Screen titles like "Pengaturan".
    static let largeTitle: CGFloat = 60

    /// Title 1 — 40pt Medium. Section titles.
    static let title1: CGFloat = 40

    /// Button — 44pt Bold. Primary action labels like "Simpan".
    static let button: CGFloat = 44

    /// Headline — 32pt Medium. Control labels like "Kecerahan Latar Belakang".
    static let headline: CGFloat = 32

    /// Body — 28pt Regular. Regular content and option labels.
    static let body: CGFloat = 28
}

// MARK: - Fonts

extension Font {

    /// SF Pro Rounded at an arbitrary size/weight — use with a `@ScaledMetric`
    /// multiplier when the text should scale with Larger Text.
    ///
    /// - Parameters:
    ///   - size: Point size (usually an `AppFontSize` token times a scale).
    ///   - weight: Font weight from the type scale.
    /// - Returns: The rounded system font.
    static func owlRounded(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Large Title — SF Pro Rounded 60pt Bold (fixed size).
    static let owlLargeTitle = owlRounded(AppFontSize.largeTitle, .bold)

    /// Title 1 — SF Pro Rounded 40pt Medium (fixed size).
    static let owlTitle1 = owlRounded(AppFontSize.title1, .medium)

    /// Button — SF Pro Rounded 44pt Bold (fixed size).
    static let owlButton = owlRounded(AppFontSize.button, .bold)

    /// Headline — SF Pro Rounded 32pt Medium (fixed size).
    static let owlHeadline = owlRounded(AppFontSize.headline, .medium)

    /// Body — SF Pro Rounded 28pt Regular (fixed size).
    static let owlBody = owlRounded(AppFontSize.body, .regular)
}
