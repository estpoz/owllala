//
//  StatisticsView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

// MARK: - Statistics View

/// Shows the child's progress summary and visual competency scores.
struct StatisticsView: View {

    @ObservedObject var viewModel: StatisticsViewModel
    let onBack: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedItem: CompetencyProgressItem?

    // MARK: Styling

    private let accentColor = Color(red: 0.12, green: 0.40, blue: 0.88)
    private let darkBlue = Color(red: 0.02, green: 0.16, blue: 0.45)
    private let borderColor = Color(red: 0.82, green: 0.87, blue: 1.0)
    private let panelColor = Color(red: 0.97, green: 0.98, blue: 1.0)
    private let backIconSize: CGFloat = 44
    private let backButtonSize: CGFloat = 112

    // MARK: Dynamic Type Metrics

    @ScaledMetric(relativeTo: .largeTitle) private var titleFontSize: CGFloat = 68
    @ScaledMetric(relativeTo: .title2) private var rowTitleFontSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var rowIconFontSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var rowIconSize: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var rowStarFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var rowScoreFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var rowChevronFontSize: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var rowMinHeight: CGFloat = 88
    @ScaledMetric(relativeTo: .title3) private var summaryTitleFontSize: CGFloat = 23
    @ScaledMetric(relativeTo: .title) private var summaryValueFontSize: CGFloat = 38
    @ScaledMetric(relativeTo: .body) private var summaryIconFontSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var summaryValueSize: CGFloat = 64

    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalPadding = max(size.width * 0.03, 24)
            let verticalPadding = max(size.height * 0.025, 18)
            let contentSpacing = max(size.height * 0.018, 14)
            let headerHeight = min(size.height * 0.16, max(backButtonSize, 112))
            let summaryHeight = min(size.height * 0.16, max(summaryValueSize + 24, 96))
            let middleHeight = max(
                size.height
                    - (verticalPadding * 2)
                    - headerHeight
                    - summaryHeight
                    - (contentSpacing * 2),
                360
            )

            ZStack {
                if shouldStackMainContent {
                    stackedContent(
                        size: size,
                        horizontalPadding: horizontalPadding,
                        verticalPadding: verticalPadding,
                        contentSpacing: contentSpacing,
                        headerHeight: headerHeight
                    )
                } else {
                    sideBySideContent(
                        size: size,
                        horizontalPadding: horizontalPadding,
                        verticalPadding: verticalPadding,
                        contentSpacing: contentSpacing,
                        headerHeight: headerHeight,
                        middleHeight: middleHeight,
                        summaryHeight: summaryHeight
                    )
                }

                if let selectedItem, let guidance = viewModel.guidance(for: selectedItem.competency) {
                    detailOverlay(item: selectedItem, guidance: guidance)
                }
            }
        }
        .background(StatisticsBackground())
    }

    // MARK: Responsive Layout

    private var shouldStackMainContent: Bool {
        // Large Dynamic Type needs vertical flow so the graph and cards do not overlap.
        switch dynamicTypeSize {
        case .xxLarge,
             .xxxLarge,
             .accessibility1,
             .accessibility2,
             .accessibility3,
             .accessibility4,
             .accessibility5:
            return true

        default:
            return false
        }
    }

    private func sideBySideContent(
        size: CGSize,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        contentSpacing: CGFloat,
        headerHeight: CGFloat,
        middleHeight: CGFloat,
        summaryHeight: CGFloat
    ) -> some View {
        VStack(spacing: contentSpacing) {
            header(width: size.width)
                .frame(height: headerHeight)

            HStack(alignment: .top, spacing: contentSpacing) {
                CompetencyGraph(items: viewModel.competencyItems)
                    .frame(
                        minWidth: 420,
                        idealWidth: size.width * 0.52,
                        maxWidth: size.width * 0.56
                    )

                competencyList
                    .frame(
                        minWidth: 340,
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .top
                    )
            }
            .frame(height: middleHeight)

            summaryPanel
                .frame(height: summaryHeight)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StatisticsBackground())
    }

    private func stackedContent(
        size: CGSize,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        contentSpacing: CGFloat,
        headerHeight: CGFloat
    ) -> some View {
        ScrollView {
            VStack(spacing: contentSpacing) {
                header(width: size.width)
                    .frame(height: headerHeight)

                CompetencyGraph(items: viewModel.competencyItems)
                    .frame(
                        maxWidth: min(size.width - (horizontalPadding * 2), 680),
                        minHeight: 420
                    )

                competencyList
                    .frame(maxWidth: .infinity)

                summaryPanel
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
        }
        .background(StatisticsBackground())
    }

    // MARK: Header

    private func header(width: CGFloat) -> some View {
        HStack(spacing: 28) {
            Button(action: goBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: backIconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: backButtonSize, height: backButtonSize)
                    .background(Circle().fill(Color(red: 0.02, green: 0.28, blue: 0.70)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Text("Hasil Perkembangan")
                .font(.system(size: min(width * 0.055, titleFontSize), weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityAddTraits(.isHeader)

            Color.clear
                .frame(width: backButtonSize, height: backButtonSize)
                .accessibilityHidden(true)
        }
    }

    private func goBack() {
        onBack()
        dismiss()
    }

    // MARK: Competency Rows

    private var competencyList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.competencyItems) { item in
                Button {
                    selectedItem = item
                } label: {
                    competencyRow(item)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.competency.displayName), \(item.score) dari \(item.maximumScore)")
                .accessibilityHint("Buka detail kemampuan")
            }
        }
    }

    private func competencyRow(_ item: CompetencyProgressItem) -> some View {
        HStack(spacing: 16) {
            Image(systemName: item.competency.statisticsIconName)
                .font(.system(size: rowIconFontSize, weight: .bold))
                .foregroundStyle(item.competency.statisticsIconForeground)
                .frame(width: rowIconSize, height: rowIconSize)
                .background(Circle().fill(item.competency.statisticsIconBackground))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.competency.displayName)
                    .font(.system(size: rowTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                HStack(spacing: 4) {
                    ForEach(1...item.maximumScore, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: rowStarFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(index <= item.score ? Color.yellow : Color.gray.opacity(0.35))
                            .accessibilityHidden(true)
                    }
                }
            }

            Spacer(minLength: 12)

            Text("(\(item.score)/\(item.maximumScore))")
                .font(.system(size: rowScoreFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: "chevron.right")
                .font(.system(size: rowChevronFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: rowMinHeight)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(panelColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderColor, lineWidth: 3)
                )
        )
    }

    // MARK: Summary

    private var summaryPanel: some View {
        HStack(spacing: 22) {
            summaryItem(
                title: "Bintang Terkumpul",
                value: viewModel.totalStars,
                symbolName: "star.fill"
            )

            Divider()
                .frame(height: 54)

            summaryItem(
                title: "Bab Diselesaikan",
                value: viewModel.completedChapterCount,
                symbolName: "checkmark.seal.fill"
            )

            Divider()
                .frame(height: 54)

            summaryItem(
                title: "Cerita Ditamatkan",
                value: viewModel.completedStoryCount,
                symbolName: "book.closed.fill"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(panelColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderColor, lineWidth: 3)
                )
        )
    }

    private func summaryItem(
        title: String,
        value: Int,
        symbolName: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: summaryIconFontSize, weight: .bold))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: summaryTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Spacer(minLength: 8)

            Text("\(value)")
                .font(.system(size: summaryValueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(darkBlue)
                .frame(width: summaryValueSize, height: summaryValueSize)
                .background(Circle().fill(Color(red: 0.86, green: 0.90, blue: 1.0)))
                .overlay(Circle().stroke(borderColor, lineWidth: 2))
                .accessibilityLabel("\(value)")
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Detail Presentation

    private func detailOverlay(
        item: CompetencyProgressItem,
        guidance: CompetencyGuidance
    ) -> some View {
        GeometryReader { proxy in
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedItem = nil
                }

            CompetencyDetailView(
                item: item,
                guidance: guidance,
                onClose: {
                    selectedItem = nil
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .frame(
                width: proxy.size.width * 0.92,
                height: proxy.size.height * 0.88
            )
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 8)
        }
        .transition(.opacity)
    }

}

// MARK: - Statistics Background

/// Reuses the app's subtle pattern asset behind Statistics screens.
struct StatisticsBackground: View {

    var body: some View {
        Image("bgPattern")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .background(Color.white)
    }
}

// MARK: - Competency Statistics Styling

extension Competency {

    /// The compact title used on the competency detail cards.
    var statisticsDetailName: String {
        switch self {
        case .labelSymbol:
            return "Teks/Simbol"

        case .pattern:
            return "Pola"

        case .context:
            return "Konteks"

        case .shape:
            return "Bentuk"

        case .brightnessContrast:
            return "Kecerahan/Kontras"
        }
    }

    /// Temporary SF Symbol used until final competency artwork is available.
    var statisticsIconName: String {
        switch self {
        case .labelSymbol:
            return "textformat"

        case .pattern:
            return "square.grid.3x3.fill"

        case .context:
            return "star.fill"

        case .shape:
            return "cube.fill"

        case .brightnessContrast:
            return "sun.max.fill"
        }
    }

    var statisticsIconForeground: Color {
        switch self {
        case .labelSymbol:
            return Color(red: 0.12, green: 0.40, blue: 0.88)

        case .pattern:
            return Color(red: 0.95, green: 0.68, blue: 0.0)

        case .context:
            return Color(red: 0.1, green: 0.70, blue: 0.28)

        case .shape:
            return Color(red: 0.44, green: 0.25, blue: 0.90)

        case .brightnessContrast:
            return Color(red: 0.98, green: 0.43, blue: 0.08)
        }
    }

    var statisticsIconBackground: Color {
        switch self {
        case .labelSymbol:
            return Color(red: 0.86, green: 0.93, blue: 1.0)

        case .pattern:
            return Color(red: 1.0, green: 0.93, blue: 0.62)

        case .context:
            return Color(red: 0.80, green: 0.96, blue: 0.84)

        case .shape:
            return Color(red: 0.88, green: 0.80, blue: 1.0)

        case .brightnessContrast:
            return Color(red: 1.0, green: 0.88, blue: 0.70)
        }
    }
}

#if DEBUG
// MARK: - Preview

#Preview(
    "Statistics - iPad Landscape",
    traits: .fixedLayout(width: 1366, height: 1024)
) {
    StatisticsView(
        viewModel: StatisticsViewModel(
            stories: [],
            storageService: StorageService(
                userDefaults: UserDefaults(suiteName: "OwlLala.StatisticsViewPreview") ?? .standard
            )
        ),
        onBack: {}
    )
}
#endif
