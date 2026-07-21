//
//  StoryClearedView.swift
//  OwlLala
//
//  Created by Amanda on 17/07/26.
//

import SwiftUI

// MARK: - Height / width measuring preference keys

/// Tracks the tallest measured height among a set of views (used to make
/// the learning point cards match each other's height).
private struct MaxHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Tracks the rendered width of the story title text (used to size the
/// intro box to match it).
private struct TitleWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct StoryClearedView: View {

    struct LearningPoint: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let description: String
    }

    var storyTitle: String = "Hebat! Story 1 Selesai!"
    var introMessage: String = "Kamu sudah belajar mengenali benda tanpa bergantung pada warna. Yuk, lihat apa saja yang sudah kamu kuasai!"
    var sectionHeading: String = "Kamu Belajar Menggunakan:"
    var tipText: String = "Sekarang kamu tahu bahwa warna bukan satu-satunya cara untuk mengenali dunia di sekitarmu."
    var tipHighlight: String = "Terus gunakan berbagai petunjuk ini di petualangan berikutnya!"
    var buttonTitle: String = "Lanjut Belajar"
    var mascotImageName: String = "owlCircle"

    var learningPoints: [LearningPoint] = [
        LearningPoint(symbol: "square.on.circle", title: "Bentuk", description: "Mengenali objek berdasarkan bentuknya."),
        LearningPoint(symbol: "tag.fill", title: "Tulisan, Simbol, dan Label", description: "Menggunakan tulisan, simbol, dan label sebagai penunjuk arah."),
        LearningPoint(symbol: "sun.max.fill", title: "Terang dan Gelap (Kontras)", description: "Membedakan benda berdasarkan tingkat terang dan gelapnya."),
        LearningPoint(symbol: "water.waves", title: "Pola dan Tekstur", description: "Menemukan perbedaan melalui pola dan tekstur permukaan."),
        LearningPoint(symbol: "brain.head.profile", title: "Menggabungkan Semua Petunjuk", description: "Menggabungkan semua petunjuk untuk mengenali benda dalam situasi sehari-hari.")
    ]

    var onContinue: () -> Void = {}

    private let navy = Color(red: 0.02, green: 0.31, blue: 0.70)
    private let ink = Color.black

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 60
    @ScaledMetric(relativeTo: .body) private var introSize: CGFloat = 25
    @ScaledMetric(relativeTo: .title2) private var sectionHeadingSize: CGFloat = 35
    @ScaledMetric(relativeTo: .title) private var cardSymbolSize: CGFloat = 36 // <-- Baru: Skala untuk Simbol Card
    @ScaledMetric(relativeTo: .headline) private var cardTitleSize: CGFloat = 22
    @ScaledMetric(relativeTo: .footnote) private var cardDescriptionSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var tipSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var tipSymbolSize: CGFloat = 32 // <-- Baru: Skala untuk Simbol Tip
    @ScaledMetric(relativeTo: .title2) private var buttonTextSize: CGFloat = 30

    /// Minimum width for each learning point card. Scales with Dynamic Type
    /// so that as text size increases, fewer cards fit per row in the grid
    /// below and the extra cards automatically wrap onto new rows instead
    /// of squeezing/overflowing.
    @ScaledMetric(relativeTo: .headline) private var cardMinWidth: CGFloat = 180

    /// Measured width of the rendered story title — used so the intro box
    /// matches the title's own width instead of stretching full-width.
    @State private var titleWidth: CGFloat = 0

    /// Tallest measured learning point card — applied to every card so they
    /// all share the same height regardless of how much text they contain.
    @State private var learningCardHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)
            let cardWidth = geometry.size.width * 0.88
            let cardHeight = geometry.size.height * 0.9

            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                AppFilteredScrollView(.vertical, showsIndicators: true) {
                    cardContent(baseUnit: baseUnit, cardWidth: cardWidth)
                        .padding(baseUnit * 0.05)
                }
                .frame(width: cardWidth, height: cardHeight)
                .background(Color.white.appBackgroundAdjustments())
                .clipShape(RoundedRectangle(cornerRadius: baseUnit * 0.024))
                    .overlay(
                        RoundedRectangle(cornerRadius: baseUnit * 0.024)
                            .stroke(navy.opacity(0.15), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(TitleWidthPreferenceKey.self) { titleWidth = $0 }
        .onPreferenceChange(MaxHeightPreferenceKey.self) { learningCardHeight = $0 }
    }

    // MARK: - Card content

    private func cardContent(baseUnit: CGFloat, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.018) {
            header(baseUnit: baseUnit, cardWidth: cardWidth)

            Text(sectionHeading)
                .font(.system(size: sectionHeadingSize, weight: .bold, design: .rounded))
                .foregroundStyle(ink)

            learningPointsGrid(baseUnit: baseUnit)

            tipBox(baseUnit: baseUnit)
            
            // Asumsi tombol ini sudah ada di file terpisah
             PrimaryActionButton(title: buttonTitle, action: onContinue)
        }
        .padding(baseUnit * 0.02)
    }

    // MARK: - Header

    private func header(baseUnit: CGFloat, cardWidth: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {

            // Layout normal (Horizontal)
            HStack(alignment: .top, spacing: baseUnit * 0.02) {
                // isExpanded: false karena ini mode bersampingan
                headerText(baseUnit: baseUnit, isExpanded: false)

                Spacer()

                mascot(baseUnit: baseUnit)
            }

            // Kalau tidak muat otomatis pindah ke bawah (Vertical)
            VStack(alignment: .leading, spacing: baseUnit * 0.03) {
                // isExpanded: true agar introBox bisa memanjang maksimal
                headerText(baseUnit: baseUnit, isExpanded: true)

                HStack {
                    mascot(baseUnit: baseUnit)
                }
            }
        }
    }
    
    private func headerText(baseUnit: CGFloat, isExpanded: Bool) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.014) {

            Text(storyTitle)
                .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { titleProxy in
                        Color.clear
                            .preference(key: TitleWidthPreferenceKey.self, value: titleProxy.size.width)
                    }
                )
                .padding(.bottom, 20)

            introBox(baseUnit: baseUnit, isExpanded: isExpanded)
        }
    }

    private func mascot(baseUnit: CGFloat) -> some View {
        Image(mascotImageName)
            .resizable()
            .scaledToFill()
            .frame(width: baseUnit * 0.25, height: baseUnit * 0.25)
            .clipShape(Circle())
    }

    // MARK: - Intro box
    
    // Sesuaikan frame berdasarkan parameter isExpanded
    private func introBox(baseUnit: CGFloat, isExpanded: Bool) -> some View {
        Text(introMessage)
            .font(.system(size: introSize, weight: .regular, design: .rounded))
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
            // Jika masuk layout vertikal, lebarkan maksimal. Jika normal, pakai batas asli.
            .frame(maxWidth: isExpanded ? .infinity : baseUnit - 350, alignment: .leading)
            .padding(baseUnit * 0.016)
            .background(
                RoundedRectangle(cornerRadius: baseUnit * 0.014)
                    .stroke(ink, lineWidth: 1.5)
            )
    }

    // MARK: - Learning points grid

    private func learningPointsGrid(baseUnit: CGFloat) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: cardMinWidth), spacing: baseUnit * 0.012)],
            alignment: .leading,
            spacing: baseUnit * 0.012
        ) {
            ForEach(learningPoints) { point in
                learningPointCard(point, baseUnit: baseUnit)
            }
        }
    }

    private func learningPointCard(_ point: LearningPoint, baseUnit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: baseUnit * 0.01) {
            Image(systemName: point.symbol)
                // Menggunakan @ScaledMetric (cardSymbolSize) agar ikon membesar otomatis
                .font(.system(size: cardSymbolSize, weight: .semibold))
                .foregroundStyle(navy)
                // Hapus .frame(height: ...) agar ikon tidak terpotong saat font menjadi besar

            Text(point.title)
                .font(.system(size: cardTitleSize, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                // Gunakan minHeight, bukan height kaku.
                .frame(minHeight: cardTitleSize * 1.3 * 2, alignment: .top)

            Text(point.description)
                .font(.system(size: cardDescriptionSize, weight: .regular, design: .rounded))
                .foregroundStyle(ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(baseUnit * 0.014)
        .background(
            GeometryReader { cardProxy in
                Color.clear
                    .preference(key: MaxHeightPreferenceKey.self, value: cardProxy.size.height)
            }
        )
        // Gunakan minHeight agar box bisa beradaptasi jika ada teks yang luar biasa panjang
        .frame(minHeight: learningCardHeight > 0 ? learningCardHeight : nil, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: baseUnit * 0.012)
                .stroke(ink, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(point.title). \(point.description)")
    }

    // MARK: - Tip box

    private func tipBox(baseUnit: CGFloat) -> some View {
        HStack(alignment: .top, spacing: baseUnit * 0.014) {
            Image(systemName: "lightbulb.fill")
                // Menggunakan @ScaledMetric (tipSymbolSize) agar ikon membesar otomatis
                .font(.system(size: tipSymbolSize))
                .foregroundStyle(navy)
                .padding(.top, 4) // Memberi jarak atas sedikit agar sejajar dengan teks

            (
                Text(tipText + " ")
                    .fontWeight(.regular)
                +
                Text(tipHighlight)
                    .fontWeight(.bold)
            )
            .font(.system(size: tipSize, design: .rounded))
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(baseUnit * 0.016)
        .background(
            RoundedRectangle(cornerRadius: baseUnit * 0.014)
                .stroke(ink, lineWidth: 1.5)
        )
    }
}

#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return StoryClearedView()
        .environmentObject(storageService)
        .environmentObject(SettingsViewModel(storageService: storageService))
}
