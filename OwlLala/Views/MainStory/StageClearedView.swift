//
//  StageClearedView.swift
//  OwlLala
//
//  Created by Amanda on 15/07/26.
//


import SwiftUI

struct StoryChapterCompleteView: View {

    struct LearnedItem: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
    }

    var storyNumber: Int = 1
    var pageNumber: Int = 5
    var chapterTitle: String = "Chapter 1 – Shape Clue: The Classroom Search"
    var storyRecap: String = "Using the shape clue, Mika found her lunchbox!"
    var learnedItems: [LearnedItem] = [
        LearnedItem(symbol: "hexagon.fill", tint: Color(red: 0.02, green: 0.31, blue: 0.70)),
        LearnedItem(symbol: "leaf.fill", tint: Color(red: 0.86, green: 0.20, blue: 0.20)),
        LearnedItem(symbol: "book.closed.fill", tint: Color(red: 0.45, green: 0.30, blue: 0.65))
    ]
    var learnedDescription: String = "Shapes help us find objects, even when colors are confusing."
    var bottomBannerText: String = "Chapter 1 clue"
    var bottomBannerHighlight: String = "solved!"
    var onBack: () -> Void = {}
    var onFinish: () -> Void = {}

    @State private var showConfetti = true

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)

            ZStack {
                Color(red: 0.90, green: 0.90, blue: 0.92)
                    .ignoresSafeArea()

                VStack(spacing: baseUnit * 0.03) {
                    card(baseUnit: baseUnit)

                    HStack {
                        Spacer()
//                        finishButton(baseUnit: baseUnit)
                        PrimaryActionButton(title: "Selesai") {}
                        
                    }
                    .padding(.trailing, baseUnit * 0.02)
                }
                .padding(baseUnit * 0.035)

                if showConfetti {
                    ConfettiOverlay()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Card

    private func card(baseUnit: CGFloat) -> some View {
        VStack(spacing: baseUnit * 0.022) {
            headerBanner(baseUnit: baseUnit)

            subtitlePill(baseUnit: baseUnit)

            HStack(alignment: .top, spacing: baseUnit * 0.022) {
                storyPlaceholder(baseUnit: baseUnit)

                VStack(spacing: baseUnit * 0.018) {
                    clueSolvedMedallion(baseUnit: baseUnit)
                    whatWeLearnedBox(baseUnit: baseUnit)
                }
                .frame(width: baseUnit * 0.26)
            }

            bottomBanner(baseUnit: baseUnit)
        }
        .padding(baseUnit * 0.024)
        .background(
            RoundedRectangle(cornerRadius: baseUnit * 0.024)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: baseUnit * 0.024)
                .stroke(primaryBlue.opacity(0.35), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.12), radius: baseUnit * 0.015, x: 0, y: baseUnit * 0.006)
        .overlay(alignment: .topLeading) {
            HStack(spacing: 20){
//                CircleIconButton(
//                    systemImageName: "arrow.left",
//                    accessibilityLabel: "Kembali"
//                ) {}
                
                Spacer()
                
                VolumeButton(){}
                SettingsButton(){}
            }
            .offset(y: -18)
//            .ignoresSafeArea()
//            .padding(.top, 3)

        }
    }

    // MARK: - Header

    private func headerBanner(baseUnit: CGFloat) -> some View {
        VStack(spacing: -baseUnit * 0.012) {
            HStack(spacing: baseUnit * 0.006) {
                Image(systemName: "star.fill")
                Text(" STORY \(storyNumber) ")
                Image(systemName: "star.fill")
            }
            .font(.title2)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, baseUnit * 0.024)
            .padding(.vertical, baseUnit * 0.008)
            .background(
                Capsule().fill(primaryBlue)
            )
            .overlay(
                Capsule().stroke(.white, lineWidth: 2)
            )
            .zIndex(1)

            ZStack {
                RoundedRectangle(cornerRadius: baseUnit * 0.014)
                    .fill(woodBrown)
                    .overlay(
                        RoundedRectangle(cornerRadius: baseUnit * 0.014)
                            .stroke(.black.opacity(0.25), lineWidth: 2)
                    )

                Text(chapterTitle)
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                    .padding(.horizontal, baseUnit * 0.05)
                    .padding(.vertical, baseUnit * 0.02)

                leafDecoration(baseUnit: baseUnit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(baseUnit * 0.006)

                leafDecoration(baseUnit: baseUnit)
                    .scaleEffect(x: -1, y: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(baseUnit * 0.006)
            }
        }
    }

    private func leafDecoration(baseUnit: CGFloat) -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: baseUnit * 0.02))
            .foregroundStyle(Color(red: 0.35, green: 0.62, blue: 0.30))
            .rotationEffect(.degrees(-20))
    }

    private func subtitlePill(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.01) {
            Image(systemName: "star.fill")
                .foregroundStyle(gold)
            Text(storyRecap)
                .foregroundStyle(primaryBlue)
                .multilineTextAlignment(.center)
            Image(systemName: "star.fill")
                .foregroundStyle(gold)
        }
        .font(.subheadline)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, baseUnit * 0.02)
        .padding(.vertical, baseUnit * 0.01)
        .background(
            Capsule().fill(cream)
        )
        .overlay(
            Capsule().stroke(primaryBlue.opacity(0.25), lineWidth: 1.5)
        )
    }

    // MARK: - Story placeholder

    private func storyPlaceholder(baseUnit: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: baseUnit * 0.014)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            .foregroundStyle(primaryBlue.opacity(0.35))
            .background(
                RoundedRectangle(cornerRadius: baseUnit * 0.014)
                    .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
            )
            .overlay(
                VStack(spacing: baseUnit * 0.01) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: baseUnit * 0.05))
                        .foregroundStyle(primaryBlue.opacity(0.4))
                    Text("Story Image Placeholder")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryBlue.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
            )
            .aspectRatio(1.55, contentMode: .fit)
    }

    // MARK: - Clue solved medallion

    private func clueSolvedMedallion(baseUnit: CGFloat) -> some View {
        VStack(spacing: -baseUnit * 0.01) {
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: baseUnit * 0.012))
                        .foregroundStyle(gold)
                        .offset(
                            x: cos(Double(i) / 6 * .pi * 2) * baseUnit * 0.055,
                            y: sin(Double(i) / 6 * .pi * 2) * baseUnit * 0.055
                        )
                }

                Circle()
                    .fill(primaryBlue)
                    .overlay(Circle().stroke(gold, lineWidth: 3))
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: baseUnit * 0.03))
                            .foregroundStyle(gold)
                    )
                    .frame(width: baseUnit * 0.08, height: baseUnit * 0.08)
            }
            .frame(height: baseUnit * 0.11)

            Text("CLUE SOLVED!")
                .font(.subheadline)
                .fontWeight(.heavy)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, baseUnit * 0.016)
                .padding(.vertical, baseUnit * 0.008)
                .frame(maxWidth: .infinity)
                .background(primaryBlue)
                .clipShape(Capsule())
        }
    }

    private func whatWeLearnedBox(baseUnit: CGFloat) -> some View {
        VStack(spacing: baseUnit * 0.012) {
            HStack(spacing: baseUnit * 0.006) {
                Image(systemName: "star.fill")
                Text("What we learned")
                Image(systemName: "star.fill")
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, baseUnit * 0.008)
            .background(primaryBlue)

            HStack(spacing: baseUnit * 0.012) {
                ForEach(learnedItems) { item in
                    RoundedRectangle(cornerRadius: baseUnit * 0.008)
                        .fill(item.tint.opacity(0.12))
                        .overlay(
                            Image(systemName: item.symbol)
                                .font(.system(size: baseUnit * 0.02))
                                .foregroundStyle(item.tint)
                        )
                        .frame(width: baseUnit * 0.05, height: baseUnit * 0.05)
                }
            }
            .padding(.top, baseUnit * 0.006)

            Text(learnedDescription)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(primaryBlue)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, baseUnit * 0.012)
                .padding(.bottom, baseUnit * 0.014)
        }
        .background(cream)
        .overlay(
            RoundedRectangle(cornerRadius: baseUnit * 0.012)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(primaryBlue.opacity(0.4))
        )
        .clipShape(RoundedRectangle(cornerRadius: baseUnit * 0.012))
    }

    // MARK: - Bottom banner

    private func bottomBanner(baseUnit: CGFloat) -> some View {
        HStack(spacing: baseUnit * 0.008) {
            Image(systemName: "star.fill")
                .foregroundStyle(gold)

            Spacer()

            (
                Text(bottomBannerText + " ")
                    .foregroundStyle(.white)
                +
                Text(bottomBannerHighlight)
                    .foregroundStyle(gold)
            )
            .font(.title2)
            .fontWeight(.heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Spacer()

            Image(systemName: "star.fill")
                .foregroundStyle(gold)
        }
        .padding(.horizontal, baseUnit * 0.03)
        .padding(.vertical, baseUnit * 0.012)
        .background(
            Capsule().fill(primaryBlue)
        )
        .overlay(alignment: .leading) {
            Image(systemName: "leaf.fill")
                .font(.system(size: baseUnit * 0.018))
                .foregroundStyle(Color(red: 0.35, green: 0.62, blue: 0.30))
                .rotationEffect(.degrees(-20))
                .offset(x: -baseUnit * 0.012, y: baseUnit * 0.018)
        }
        .overlay(alignment: .trailing) {
            Image(systemName: "leaf.fill")
                .font(.system(size: baseUnit * 0.018))
                .foregroundStyle(Color(red: 0.35, green: 0.62, blue: 0.30))
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(20))
                .offset(x: baseUnit * 0.012, y: baseUnit * 0.018)
        }
    }


    private func pageBadge(baseUnit: CGFloat) -> some View {
        Text("Page \(pageNumber)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, baseUnit * 0.016)
            .padding(.vertical, baseUnit * 0.007)
            .background(
                Capsule().fill(primaryBlue)
            )
    }

    private func finishButton(baseUnit: CGFloat) -> some View {
        Button(action: onFinish) {
            Text("Selesai")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, baseUnit * 0.036)
                .padding(.vertical, baseUnit * 0.016)
                .background(
                    Capsule().fill(primaryBlue)
                )
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Selesai")
    }
}



#Preview(traits: .landscapeRight) {
    StoryChapterCompleteView()
}
