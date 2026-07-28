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

    private let starBlue = Color(red: 0.0, green: 0.227, blue: 0.655)
    private let ink = Color.black

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title) private var subtitleSize: CGFloat = 30
    @ScaledMetric(relativeTo: .title2) private var summarySize: CGFloat = 24
    @ScaledMetric(relativeTo: .largeTitle) private var starSize: CGFloat = 52

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
            let cardWidth = geometry.size.width * 0.86
            let cardHeight = geometry.size.height * 0.82

            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    Image("page1-4")
                        .resizable()
                        .frame(width: cardWidth, height: cardHeight)
                        .appBackgroundAdjustments()

                    AppFilteredScrollView(.vertical, showsIndicators: usesAccessibilityLayout) {
                        cardContent(
                            baseUnit: baseUnit,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight
                        )
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .padding(.top, 30)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: baseUnit * 0.018, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 8)
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
        textColumn(baseUnit: baseUnit, cardWidth: cardWidth)
            .padding(.leading, cardWidth * 0.075)
            .padding(.top, cardHeight * 0.1)
            .padding(.bottom, cardHeight * 0.08)
            .frame(width: cardWidth, alignment: .topLeading)
    }

    private func textColumn(baseUnit: CGFloat, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.018) {
            starRow(baseUnit: baseUnit)

            Text(resolvedTitle)
                .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .lineLimit(usesAccessibilityLayout ? 3 : 2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: subtitleSize, weight: .semibold, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.black.opacity(0.28))
                .frame(height: max(2, baseUnit * 0.003))
                .padding(.vertical, baseUnit * 0.004)

            Text(summaryText)
                .font(.system(size: summarySize, weight: .regular, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, baseUnit * 0.006)

            actionButtons(baseUnit: baseUnit)
        }
        .frame(maxWidth: min(cardWidth * 0.38, baseUnit * 0.55), alignment: .leading)
    }

    // MARK: - Stars

    private func starRow(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.012) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    .font(.system(size: starSize, weight: .bold))
                    .foregroundStyle(starBlue)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(starCount) dari \(maxStars) bintang")
    }

    // MARK: - Buttons

    private func actionButtons(baseUnit: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: baseUnit * 0.014) {
                PrimaryActionButton(title: "Lanjut", action: onContinue)
                PrimaryActionButton(title: "Ulangi", style: .outlined, action: onReplay)
            }

            VStack(alignment: .leading, spacing: baseUnit * 0.014) {
                PrimaryActionButton(title: "Lanjut", action: onContinue)
                PrimaryActionButton(title: "Ulangi", style: .outlined, action: onReplay)
            }
        }
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
