//
//  StageClearedView.swift
//  OwlLala
//
//  Created by Amanda on 15/07/26.
//

import SwiftUI

struct StageClearedView: View {

    var title: String?
    var subtitle: String = "Kamu berhasil menyelesaikan Bab 1"
    var starCount: Int = 3
    var maxStars: Int = 3
    var summaryText: String = "Kamu mengenali objek berdasarkan bentuknya."

    var onReplay: () -> Void = {}
    var onContinue: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let gold = Color(red: 0.95, green: 0.72, blue: 0.20)

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 80
    @ScaledMetric(relativeTo: .title) private var subtitleSize: CGFloat = 33
    @ScaledMetric(relativeTo: .title2) private var summarySize: CGFloat = 30
    @ScaledMetric(relativeTo: .largeTitle) private var starSize: CGFloat = 55

    private var resolvedTitle: String {
        if let title {
            return title
        }

        switch starCount {
        case 1:
            return "Baik!"
        case 2:
            return "Hebat!"
        default:
            return "Hebat Sekali!"
        }
    }

    private var usesAccessibilityLayout: Bool {
        switch dynamicTypeSize {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)
            let cardWidth = geometry.size.width * 0.85
            let cardHeight = geometry.size.height * 0.85

            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    Image("page1-4")
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .appBackgroundAdjustments()

                    AppFilteredScrollView(.vertical, showsIndicators: usesAccessibilityLayout) {
                        cardContent(
                            baseUnit: baseUnit,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight
                        )
                    }
                    .frame(width: cardWidth, height: cardHeight)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: baseUnit * 0.024))
                .overlay(
                    RoundedRectangle(cornerRadius: baseUnit * 0.024)
                        .stroke(.white.opacity(0.6), lineWidth: 3)
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Card content

    private func cardContent(
        baseUnit: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: contentSpacing(baseUnit: baseUnit)) {
            headerText(baseUnit: baseUnit, cardWidth: cardWidth)

            starRow(baseUnit: baseUnit)
                .padding(.top, baseUnit * 0.01)

            StageClearedText(
                summaryText,
                font: .system(size: summarySize, weight: .regular, design: .rounded),
                maxWidth: textColumnWidth(baseUnit: baseUnit, cardWidth: cardWidth),
                glowStrength: .strong
            )

            actionButtons(baseUnit: baseUnit)
                .padding(.top, baseUnit * 0.014)
        }
        .padding(baseUnit * 0.07)
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .topLeading)
    }

    private func headerText(baseUnit: CGFloat, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.01) {
            StageClearedText(
                resolvedTitle,
                font: .system(size: titleSize, weight: .heavy, design: .rounded),
                maxWidth: textColumnWidth(baseUnit: baseUnit, cardWidth: cardWidth),
                lineLimit: usesAccessibilityLayout ? 3 : 2,
                minimumScaleFactor: 0.7
            )

            StageClearedText(
                subtitle,
                font: .system(size: subtitleSize, weight: .semibold, design: .rounded),
                maxWidth: textColumnWidth(baseUnit: baseUnit, cardWidth: cardWidth)
            )
        }
    }

    private func textColumnWidth(baseUnit: CGFloat, cardWidth: CGFloat) -> CGFloat {
        let safeImageColumnWidth = min(baseUnit * 0.45, cardWidth * 0.48)

        if usesAccessibilityLayout {
            return safeImageColumnWidth
        }

        return min(baseUnit * 0.5, cardWidth * 0.56)
    }

    private func contentSpacing(baseUnit: CGFloat) -> CGFloat {
        usesAccessibilityLayout ? baseUnit * 0.028 : baseUnit * 0.02
    }

    // MARK: - Stars

    private func starRow(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.012) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(gold)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(starCount) dari \(maxStars) bintang")
    }

    // MARK: - Buttons

    private func actionButtons(baseUnit: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: baseUnit * 0.03) {
                StageReplayButton(action: onReplay)
                StageContinueButton(action: onContinue)
            }

            VStack(alignment: .leading, spacing: baseUnit * 0.02) {
                StageReplayButton(action: onReplay)
                StageContinueButton(action: onContinue)
            }
        }
    }
}

private enum StageClearedTextGlowStrength {
    case normal
    case strong
}

private struct StageClearedText: View {

    let text: String
    let font: Font
    let maxWidth: CGFloat
    let lineLimit: Int?
    let minimumScaleFactor: CGFloat
    let glowStrength: StageClearedTextGlowStrength

    init(
        _ text: String,
        font: Font,
        maxWidth: CGFloat,
        lineLimit: Int? = nil,
        minimumScaleFactor: CGFloat = 1.2,
        glowStrength: StageClearedTextGlowStrength = .normal
    ) {
        self.text = text
        self.font = font
        self.maxWidth = maxWidth
        self.lineLimit = lineLimit
        self.minimumScaleFactor = minimumScaleFactor
        self.glowStrength = glowStrength
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            textLayer(color: .white)
                .blur(radius: glowStrength == .strong ? 8 : 5)
                .opacity(glowStrength == .strong ? 1.0 : 0.95)

            if glowStrength == .strong {
                textLayer(color: .white)
                    .offset(x: -2, y: 0)
                    .opacity(0.95)

                textLayer(color: .white)
                    .offset(x: 2, y: 0)
                    .opacity(0.95)

                textLayer(color: .white)
                    .offset(x: 0, y: -2)
                    .opacity(0.95)
            }

            textLayer(color: .white)
                .offset(x: 0, y: glowStrength == .strong ? 2 : 1)
                .opacity(0.9)

            textLayer(color: .black)
        }
        .frame(maxWidth: maxWidth, alignment: .leading)
    }

    private func textLayer(color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxWidth, alignment: .leading)
    }
}

#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return NavigationStack {
        StageClearedView()
    }
    .environmentObject(storageService)
    .environmentObject(SettingsViewModel(storageService: storageService))
}
