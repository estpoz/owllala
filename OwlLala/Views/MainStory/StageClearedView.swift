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
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 80
    @ScaledMetric(relativeTo: .title) private var subtitleSize: CGFloat = 33
    @ScaledMetric(relativeTo: .title2) private var summarySize: CGFloat = 30
    
    // Baru: Scaled metrics untuk ikon bintang dan tombol agar ikut membesar
    @ScaledMetric(relativeTo: .largeTitle) private var starSize: CGFloat = 55
    @ScaledMetric(relativeTo: .largeTitle) private var buttonIconSize: CGFloat = 70

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)
            let cardWidth = geometry.size.width * 0.85
            let cardHeight = geometry.size.height * 0.85

            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                // Centralized scroll container keeps accessibility scrolling
                // compatible with the saved color-vision filter.
                AppFilteredScrollView(.vertical, showsIndicators: true) {
                    cardContent(baseUnit: baseUnit, cardWidth: cardWidth)
                }
                .frame(width: cardWidth, height: cardHeight)
                .background(
                    Image("1-4")
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .appBackgroundAdjustments()
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
        VStack(alignment: .leading, spacing: 0) {
            
            VStack(alignment: .leading, spacing: baseUnit * 0.02) {
                VStack(alignment: .leading, spacing: baseUnit * 0.01) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        // ↓ shadow berlapis → glow tipis mengikuti liku huruf
                        .shadow(color: .white.opacity(0.95), radius: 2,  x: 2, y: 0)
                        .shadow(color: .white.opacity(0.90), radius: 6,  x: 2, y: 0)
                        .shadow(color: .white.opacity(0.90), radius: 12, x: 2, y: 2)

                    Text(subtitle)
                        .font(.system(size: subtitleSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(width: baseUnit * 0.45, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .white.opacity(0.95), radius: 2,  x: 2, y: 0)
                        .shadow(color: .white.opacity(0.90), radius: 6,  x: 2, y: 0)
                        .shadow(color: .white.opacity(0.90), radius: 12, x: 2, y: 2)
                }

                starRow(baseUnit: baseUnit)
                    .padding(.top, baseUnit * 0.01)

                Text(summaryText)
                    .font(.system(size: summarySize, weight: .regular, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: baseUnit * 0.45, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .white.opacity(0.95), radius: 2,  x: 2, y: 2)
                    .shadow(color: .white.opacity(0.95), radius: 6,  x: 2, y: 2)
                    .shadow(color: .white.opacity(0.95), radius: 12, x: 2, y: 2)

                actionButtons(baseUnit: baseUnit)
                    .padding(.top, baseUnit * 0.014)
            }
            .frame(maxWidth: cardWidth * 0.8, alignment: .leading)
            
        }
        .padding(baseUnit * 0.07)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Stars

    private func starRow(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.012) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < starCount ? "star.fill" : "star")
                    // Baru: Menggunakan parameter @ScaledMetric starSize
                    .font(.system(size: starSize))
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
                        // Baru: Menggunakan parameter @ScaledMetric buttonIconSize
                        .font(.system(size: buttonIconSize, weight: .semibold))
                        .foregroundStyle(navy)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ulangi bab")

            Button(action: onContinue) {
                Image(systemName: "play.circle")
                    // Baru: Menggunakan parameter @ScaledMetric buttonIconSize (+ 5 agar play circle sedikit lebih besar)
                    .font(.system(size: buttonIconSize + 5, weight: .semibold))
                    .foregroundStyle(navy)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lanjutkan")
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
