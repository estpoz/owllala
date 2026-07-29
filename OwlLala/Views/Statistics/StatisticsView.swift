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
    @State private var selectedCompetency: Competency?
    @State private var pairedBulletPanelHeight: CGFloat = 0
    @State private var detailViewportHeight: CGFloat = 0
    @State private var detailContentHeight: CGFloat = 0

    // MARK: Styling

    private let selectedCardColor = AppColor.primary

    // MARK: Dynamic Type Metrics

    @ScaledMetric(relativeTo: .largeTitle) private var titleFontSize: CGFloat = 50
    @ScaledMetric(relativeTo: .title2) private var rowTitleFontSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var rowStarFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var rowScoreFontSize: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var rowMinHeight: CGFloat = 88
    @ScaledMetric(relativeTo: .title3) private var summaryTitleFontSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title) private var summaryValueFontSize: CGFloat = 42
    @ScaledMetric(relativeTo: .body) private var summaryValueSize: CGFloat = 72
    @ScaledMetric(relativeTo: .title3) private var detailTitleFontSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var detailBodyFontSize: CGFloat = 15
    @ScaledMetric(relativeTo: .body) private var detailPanelPadding: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var scrollIndicatorIconSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var scrollIndicatorHeight: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var scrollIndicatorStripHeight: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var pageIndicatorDotSize: CGFloat = 10

    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalPadding = max(size.width * 0.03, 24)
            let verticalPadding = max(size.height * 0.025, 18)
            let contentSpacing = max(size.height * 0.018, 14)
            let headerHeight = min(size.height * 0.16, 112)
            let summaryHeight = min(size.height * 0.16, max(summaryValueSize + 24, 96))
            let middleHeight = max(
                size.height
                    - (verticalPadding * 2)
                    - headerHeight
                    - summaryHeight
                    - (contentSpacing * 2),
                360
            )

            content(
                size: size,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                contentSpacing: contentSpacing,
                headerHeight: headerHeight,
                middleHeight: middleHeight,
                summaryHeight: summaryHeight
            )
        }
        .navigationBarBackButtonHidden(true)
        .background(StatisticsBackground())
        .onAppear {
            selectDefaultCompetencyIfNeeded()
        }
        .onChange(of: viewModel.competencyItems) { _, _ in
            selectDefaultCompetencyIfNeeded()
        }
    }

    // MARK: Responsive Layout

    private var shouldStackMainContent: Bool {
        // Extra-large Dynamic Type needs vertical flow so cards and detail text remain readable.
        switch dynamicTypeSize {
        case .xLarge,
             .xxLarge,
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

    private var effectiveTitleFontSize: CGFloat {
        if dynamicTypeSize > .accessibility3 {
            return 50.0 * 1.8
        }

        return titleFontSize
    }

    private var hasCompletedProgress: Bool {
        viewModel.completedChapterCount > 0
    }

    private var hasSelectedCompetencyProgress: Bool {
        (selectedItem?.score ?? 0) > 0
    }

    private var needsDetailScrollIndicator: Bool {
        detailContentHeight > detailViewportHeight + 1
    }

    private var selectedItem: CompetencyProgressItem? {
        if let selectedCompetency,
           let item = viewModel.competencyItem(for: selectedCompetency) {
            return item
        }

        return viewModel.competencyItems.first
    }

    private var selectedCompetencyIndex: Int {
        guard let selectedItem,
              let index = viewModel.competencyItems.firstIndex(where: { $0.competency == selectedItem.competency }) else {
            return 0
        }

        return index
    }

    private func selectDefaultCompetencyIfNeeded() {
        if let selectedCompetency,
           viewModel.competencyItem(for: selectedCompetency) != nil {
            return
        }

        selectedCompetency = viewModel.competencyItems.first?.competency
    }

    @ViewBuilder
    private func content(
        size: CGSize,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        contentSpacing: CGFloat,
        headerHeight: CGFloat,
        middleHeight: CGFloat,
        summaryHeight: CGFloat
    ) -> some View {
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
                .appAdaptiveColorFilter()

            HStack(alignment: .top, spacing: contentSpacing) {
                competencyList
                    .frame(width: size.width * 0.36, height: middleHeight, alignment: .top)
                    .appAdaptiveColorFilter()

                Divider()
                    .frame(height: middleHeight)

                selectedDetailScrollPanel
                    .frame(maxWidth: .infinity, minHeight: middleHeight, maxHeight: middleHeight, alignment: .top)
                    .clipped()
            }
            .padding(.leading, size.width * 0.04)
            .frame(height: middleHeight)

            summaryPanel
                .padding(.leading, size.width * 0.04)
                .frame(height: summaryHeight)
                .appAdaptiveColorFilter()
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
        ZStack(alignment: .top) {
            AppFilteredScrollView {
                VStack(spacing: contentSpacing) {
                    Color.clear
                        .frame(height: headerHeight)
                        .accessibilityHidden(true)

                    compactCompetencySelector
                        .frame(maxWidth: .infinity)

                    selectedDetailPanel
                        .frame(maxWidth: .infinity)

                    summaryPanel
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity)
            }

            header(width: size.width)
                .frame(height: headerHeight)
                .padding(.top, size.height * 0.02)
                .appAdaptiveColorFilter()
        }
        .background(StatisticsBackground())
    }

    // MARK: Header

    private func header(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            HStack {
                CircleIconButton(
                    systemImageName: "arrow.left",
                    accessibilityLabel: "Kembali",
                    action: goBack
                )
                .padding(.leading, width * 0.04)

                Spacer()
            }

            Text("Hasil Perkembangan")
                .font(.system(size: effectiveTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.067, green: 0.067, blue: 0.067))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .padding(.horizontal, width * 0.13)
                .frame(maxWidth: .infinity, alignment: .top)
                .accessibilityAddTraits(.isHeader)
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
                    selectedCompetency = item.competency
                } label: {
                    competencyRow(
                        item,
                        isSelected: hasCompletedProgress && item.competency == selectedItem?.competency
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.competency.displayName), \(item.score) dari \(item.maximumScore)")
                .accessibilityHint("Tampilkan detail kemampuan")
            }
        }
    }

    private var compactCompetencySelector: some View {
        HStack(alignment: .center, spacing: 12) {
            CircleIconButton(
                systemImageName: "chevron.left",
                accessibilityLabel: "Kemampuan sebelumnya",
                action: selectPreviousCompetency
            )
            .scaleEffect(0.58)

            VStack(spacing: 10) {
                if let selectedItem {
                    compactCompetencyCard(selectedItem)
                        .frame(maxWidth: .infinity)
                }

                competencyPageIndicator
            }
            .frame(maxWidth: .infinity)

            CircleIconButton(
                systemImageName: "chevron.right",
                accessibilityLabel: "Kemampuan berikutnya",
                action: selectNextCompetency
            )
            .scaleEffect(0.58)
        }
        .appAdaptiveColorFilter()
    }

    private var competencyPageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.competencyItems.indices, id: \.self) { index in
                Circle()
                    .fill(index == selectedCompetencyIndex ? AppColor.primary : Color.gray.opacity(0.35))
                    .frame(width: pageIndicatorDotSize, height: pageIndicatorDotSize)
            }
        }
    }

    private func compactCompetencyCard(_ item: CompetencyProgressItem) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.competency.displayName)
                    .font(.system(size: rowTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    ForEach(1...item.maximumScore, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: rowStarFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(index <= item.score ? Color.yellow : inactiveStarColor(isSelected: false))
                            .accessibilityHidden(true)
                    }
                }
            }

            Spacer(minLength: 12)

            Text("(\(item.score)/\(item.maximumScore))")
                .font(.system(size: rowScoreFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: rowMinHeight)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColor.primary, lineWidth: 3)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.competency.displayName), \(item.score) dari \(item.maximumScore)")
    }

    private func competencyRow(_ item: CompetencyProgressItem, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.competency.displayName)
                    .font(.system(size: rowTitleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white : Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                HStack(spacing: 4) {
                    ForEach(1...item.maximumScore, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: rowStarFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(index <= item.score ? Color.yellow : inactiveStarColor(isSelected: isSelected))
                            .accessibilityHidden(true)
                    }
                }
            }

            Spacer(minLength: 12)

            Text("(\(item.score)/\(item.maximumScore))")
                .font(.system(size: rowScoreFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: rowMinHeight)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? selectedCardColor : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? selectedCardColor : AppColor.primary, lineWidth: 3)
                )
        )
    }

    private func inactiveStarColor(isSelected: Bool) -> Color {
        isSelected ? Color.white.opacity(0.35) : Color.gray.opacity(0.30)
    }

    private func selectPreviousCompetency() {
        selectCompetency(offset: -1)
    }

    private func selectNextCompetency() {
        selectCompetency(offset: 1)
    }

    private func selectCompetency(offset: Int) {
        let items = viewModel.competencyItems
        guard !items.isEmpty else {
            return
        }

        let currentIndex = selectedItem.flatMap { selectedItem in
            items.firstIndex { $0.competency == selectedItem.competency }
        } ?? 0
        let nextIndex = (currentIndex + offset + items.count) % items.count
        selectedCompetency = items[nextIndex].competency
    }

    // MARK: Summary

    @ViewBuilder
    private var summaryPanel: some View {
        Group {
            if shouldStackMainContent {
                VStack(spacing: 0) {
                    summaryItem(
                        title: "Bintang Terkumpul",
                        value: viewModel.totalStars
                    )

                    summaryDivider

                    summaryItem(
                        title: "Bab Diselesaikan",
                        value: viewModel.completedChapterCount
                    )

                    summaryDivider

                    summaryItem(
                        title: "Cerita Ditamatkan",
                        value: viewModel.completedStoryCount
                    )
                }
            } else {
                HStack(spacing: 0) {
                    summaryItem(
                        title: "Bintang Terkumpul",
                        value: viewModel.totalStars
                    )

                    summaryDivider

                    summaryItem(
                        title: "Bab Diselesaikan",
                        value: viewModel.completedChapterCount
                    )

                    summaryDivider

                    summaryItem(
                        title: "Cerita Ditamatkan",
                        value: viewModel.completedStoryCount
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.black, lineWidth: 3)
                )
        )
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.45))
            .frame(
                width: shouldStackMainContent ? nil : 1,
                height: shouldStackMainContent ? 1 : nil
            )
    }

    @ViewBuilder
    private func summaryItem(
        title: String,
        value: Int
    ) -> some View {
        Group {
            if shouldStackMainContent {
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    summaryTitle(title)

                    Spacer(minLength: 8)

                    summaryValue(value)
                }
                .padding(.vertical, 16)
            } else {
                HStack(alignment: .center, spacing: 18) {
                    summaryTitle(title)

                    Spacer(minLength: 8)

                    summaryValue(value)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func summaryTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: summaryTitleFontSize, weight: .regular, design: .rounded))
            .foregroundStyle(.black)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }

    private func summaryValue(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: summaryValueFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(AppColor.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityLabel("\(value)")
    }

    // MARK: Inline Detail

    @ViewBuilder
    private var selectedDetailScrollPanel: some View {
        if hasSelectedCompetencyProgress {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    AppFilteredScrollView(.vertical, showsIndicators: false) {
                        selectedDetailPanel
                            .padding(.horizontal, 6)
                            .padding(.bottom, needsDetailScrollIndicator ? scrollIndicatorHeight + 8 : 8)
                            .background {
                                GeometryReader { contentProxy in
                                    Color.clear.preference(
                                        key: DetailContentHeightPreferenceKey.self,
                                        value: contentProxy.size.height
                                    )
                                }
                            }
                    }

                    if needsDetailScrollIndicator {
                        scrollMoreIndicator
                    }
                }
                .onAppear {
                    detailViewportHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, height in
                    detailViewportHeight = height
                }
                .onPreferenceChange(DetailContentHeightPreferenceKey.self) { height in
                    detailContentHeight = height
                }
            }
        } else {
            emptyStatisticsState
        }
    }

    private var scrollMoreIndicator: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color.white.opacity(0), location: 0),
                    Gradient.Stop(color: Color.white.opacity(0.24), location: 0.50),
                    Gradient.Stop(color: Color.white.opacity(0.72), location: 0.84),
                    Gradient.Stop(color: Color.white.opacity(1), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: scrollIndicatorHeight - scrollIndicatorStripHeight)

            ZStack {
                Color.white

                Image(systemName: "chevron.down")
                    .font(.system(size: scrollIndicatorIconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.primary)
                    .accessibilityHidden(true)
            }
            .frame(height: scrollIndicatorStripHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: scrollIndicatorHeight)
        .appAdaptiveColorFilter()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var selectedDetailPanel: some View {
        if hasSelectedCompetencyProgress,
           let selectedItem,
           let guidance = viewModel.guidance(
                for: selectedItem.competency,
                score: selectedItem.score
           ) {
            VStack(alignment: .leading, spacing: 10) {
                detailSection(title: "Ringkasan Pembelajaran") {
                    detailTextPanel(guidance.learningSummary)
                }

                progressDetailSections(guidance)

                detailSection(title: "Saran untuk Orang Tua") {
                    detailTextPanel(guidance.parentTip)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
        } else {
            emptyStatisticsState
        }
    }

    private var emptyStatisticsState: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Image("statsEmptyState")
                .resizable()
                .scaledToFit()
                .frame(width: min(width * 0.92, height * 1.12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Belum ada bintang terkumpul")
        }
        .frame(minHeight: shouldStackMainContent ? 500 : 360)
    }

    @ViewBuilder
    private func progressDetailSections(_ guidance: CompetencyGuidance) -> some View {
        if shouldStackMainContent {
            VStack(alignment: .leading, spacing: 10) {
                masteredDetailSection(guidance)
                practiceDetailSection(guidance)
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                masteredDetailSection(guidance, matchesPairedPanelHeight: true)
                practiceDetailSection(guidance, matchesPairedPanelHeight: true)
            }
            .onPreferenceChange(DetailBulletPanelHeightPreferenceKey.self) { height in
                pairedBulletPanelHeight = height
            }
        }
    }

    private func masteredDetailSection(
        _ guidance: CompetencyGuidance,
        matchesPairedPanelHeight: Bool = false
    ) -> some View {
        detailSection(title: "Yang Sudah Dikuasai") {
            bulletPanel(
                guidance.masteredItems,
                matchesPairedPanelHeight: matchesPairedPanelHeight
            )
        }
    }

    private func practiceDetailSection(
        _ guidance: CompetencyGuidance,
        matchesPairedPanelHeight: Bool = false
    ) -> some View {
        detailSection(title: "Yang Masih Perlu Dilatih") {
            bulletPanel(
                guidance.practiceItems,
                matchesPairedPanelHeight: matchesPairedPanelHeight
            )
        }
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: detailTitleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailTextPanel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: detailBodyFontSize, weight: .regular, design: .rounded))
            .foregroundStyle(.black)
            .fixedSize(horizontal: false, vertical: true)
            .padding(detailPanelPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(detailPanelBackground)
    }

    private func bulletPanel(
        _ items: [String],
        matchesPairedPanelHeight: Bool = false
    ) -> some View {
        let matchedHeight = matchesPairedPanelHeight && pairedBulletPanelHeight > 0
            ? pairedBulletPanelHeight
            : nil

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { text in
                Text("- \(text)")
                    .font(.system(size: detailBodyFontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(detailPanelPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            if matchesPairedPanelHeight {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: DetailBulletPanelHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            }
        }
        .frame(minHeight: matchedHeight, alignment: .topLeading)
        .background(detailPanelBackground)
    }

    private var detailPanelBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.90))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColor.primary, lineWidth: 3)
            )
    }

}

// MARK: - Detail Panel Height Preference

private struct DetailBulletPanelHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct DetailContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
            .appBackgroundAdjustments()
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

}

#if DEBUG
// MARK: - Preview

#Preview(
    "Statistics - iPad Landscape",
    traits: .fixedLayout(width: 1366, height: 1024)
) {
    let storageService = StorageService(
        userDefaults: UserDefaults(suiteName: "OwlLala.StatisticsViewPreview") ?? .standard
    )

    // Preview-only progress seed: keeps the Statistics preview representative
    // without changing app runtime data or bypassing `StorageService`.
    storageService.resetToDefaults()
    storageService.updateUserStats { stats in
        stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
        stats.recordCompletedGame(chapterID: "chapter-2", earnedStars: 2)
        stats.recordCompletedGame(chapterID: "chapter-3", earnedStars: 1)
        stats.recordCompletedGame(chapterID: "chapter-4", earnedStars: 3)
    }

    return StatisticsView(
        viewModel: StatisticsViewModel(
            stories: StoryCatalog.stories,
            storageService: storageService
        ),
        onBack: {}
    )
    // Required by the background-brightness modifier on the screen backdrop.
    .environmentObject(SettingsViewModel(storageService: storageService))
}

#Preview(
    "Statistics - Empty State",
    traits: .fixedLayout(width: 1366, height: 1024)
) {
    let storageService = StorageService(
        userDefaults: UserDefaults(suiteName: "OwlLala.StatisticsViewEmptyPreview") ?? .standard
    )

    storageService.resetToDefaults()

    return StatisticsView(
        viewModel: StatisticsViewModel(
            stories: StoryCatalog.stories,
            storageService: storageService
        ),
        onBack: {}
    )
    .environmentObject(SettingsViewModel(storageService: storageService))
}
#endif
