//
//  StageClearedView.swift
//  OwlLala
//
//  Created by Amanda on 15/07/26.
//


import SwiftUI

struct StageClearedView: View {

    var title: String = "Hebat Sekali!"
    var subtitle: String = "Kamu berhasil menyelesaikan Bab 1"
    var starCount: Int = 3
    var maxStars: Int = 3
    var summaryText: String = "Kamu mengenali objek berdasarkan bentuknya."

    var onReplay: () -> Void = {}
    var onContinue: () -> Void = {}

    private let navy = Color(red: 0.02, green: 0.31, blue: 0.70)
    private let gold = Color(red: 0.95, green: 0.72, blue: 0.20)

    // Custom scaled sizes — bigger than the built-in text styles,
    // but still respects the user's Dynamic Type / accessibility settings.
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 75
    @ScaledMetric(relativeTo: .title) private var subtitleSize: CGFloat = 35
    @ScaledMetric(relativeTo: .title2) private var summarySize: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)
            let cardWidth = geometry.size.width * 0.85
            let cardHeight = geometry.size.height * 0.85

            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                cardContent(baseUnit: baseUnit, cardWidth: cardWidth)
                    .frame(width: cardWidth, height: cardHeight)
                    .background(
                        Image("1-4")
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: cardHeight)
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: baseUnit * 0.024))
                    .overlay(
                        RoundedRectangle(cornerRadius: baseUnit * 0.024)
                            .stroke(.white.opacity(0.6), lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Card content

    private func cardContent(baseUnit: CGFloat, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.02) {
            VStack(alignment: .leading, spacing: baseUnit * 0.01) {
                Text(title)
                    .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.system(size: subtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
            }

            starRow(baseUnit: baseUnit)
                .padding(.top, baseUnit * 0.01)

            Text(summaryText)
                .font(.system(size: summarySize, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: cardWidth * 0.4, alignment: .leading)

            actionButtons(baseUnit: baseUnit)
                .padding(.top, baseUnit * 0.014)
        }
        .padding(.leading, baseUnit * 0.07)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, baseUnit * 0.07)
    }

    // MARK: - Stars

    private func starRow(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.012) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    .font(.system(size: baseUnit * 0.075))
                    .foregroundStyle(gold)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(starCount) dari \(maxStars) bintang")
    }

    // MARK: - Buttons

    private func actionButtons(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.02) {
            Button(action: onReplay) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: baseUnit * 0.07, weight: .semibold))
                    .foregroundStyle(navy)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ulangi bab")

            Button(action: onContinue) {
                Image(systemName: "play.circle")
                    .font(.system(size: baseUnit * 0.08, weight: .semibold))
                    .foregroundStyle(navy)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lanjutkan")
        }
    }
}

#Preview(traits: .landscapeRight) {
    StageClearedView()
}
