//
//  CompetencyDetailView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

// MARK: - Competency Detail View

/// Presents detailed learning guidance for one visual competency.
struct CompetencyDetailView: View {

    let item: CompetencyProgressItem
    let guidance: CompetencyGuidance
    let onClose: () -> Void

    // MARK: Styling

    private let textAccentColor = Color(red: 0.12, green: 0.40, blue: 0.88)
    private let closeButtonBackgroundColor = Color(red: 0.86, green: 0.93, blue: 1.0)
    private let panelColor = Color(red: 0.96, green: 0.98, blue: 1.0)
    private let borderColor = Color(red: 0.82, green: 0.87, blue: 1.0)

    // MARK: Dynamic Type Metrics

    @ScaledMetric(relativeTo: .largeTitle) private var titleFontSize: CGFloat = 26
    @ScaledMetric(relativeTo: .title3) private var sectionTitleFontSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var bodyFontSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var bulletFontSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var scoreFontSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var starFontSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var iconFontSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var closeIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var panelPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var bulletPanelPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var bulletPanelMinHeight: CGFloat = 122

    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding = max(proxy.size.width * 0.06, 32)
            let verticalPadding = max(proxy.size.height * 0.045, 24)

            AppFilteredScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    detailSection(
                        title: "Ringkasan Pembelajaran",
                        content: {
                            Text(guidance.learningSummary)
                                .font(.system(size: bodyFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(panelPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(panelBackground)
                        }
                    )

                    HStack(alignment: .top, spacing: 18) {
                        detailSection(
                            title: "Yang Sudah Dikuasai",
                            content: {
                                bulletPanel(guidance.masteredItems)
                            }
                        )

                        detailSection(
                            title: "Yang Masih Perlu Dilatih",
                            content: {
                                bulletPanel(guidance.practiceItems)
                            }
                        )
                    }

                    detailSection(
                        title: "Parent Tip",
                        content: {
                            Text(guidance.parentTip)
                                .font(.system(size: bodyFontSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(panelPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(panelBackground)
                        }
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .background(StatisticsBackground())
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            competencyIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(item.competency.statisticsDetailName)
                    .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(textAccentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 8) {
                    scoreStars

                    Text("(\(item.score)/\(item.maximumScore))")
                        .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.score) dari \(item.maximumScore)")
            }

            Spacer(minLength: 24)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: closeIconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(textAccentColor)
                    .frame(width: iconSize, height: iconSize)
                    .background(Circle().fill(closeButtonBackgroundColor))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
    }

    private var competencyIcon: some View {
        Image(systemName: item.competency.statisticsIconName)
            .font(.system(size: iconFontSize, weight: .bold))
            .foregroundStyle(item.competency.statisticsIconForeground)
            .frame(width: iconSize, height: iconSize)
            .background(Circle().fill(item.competency.statisticsIconBackground))
            .accessibilityHidden(true)
    }

    // MARK: Score

    private var scoreStars: some View {
        HStack(spacing: 4) {
            ForEach(1...item.maximumScore, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: starFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(index <= item.score ? Color.yellow : Color.gray.opacity(0.35))
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: Panels

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(panelColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 2)
            )
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: sectionTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(textAccentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bulletPanel(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { text in
                Text("- \(text)")
                    .font(.system(size: bulletFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(bulletPanelPadding)
        .frame(maxWidth: .infinity, minHeight: bulletPanelMinHeight, alignment: .topLeading)
        .background(panelBackground)
    }
}
