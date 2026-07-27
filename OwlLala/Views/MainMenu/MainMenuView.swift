//
//  MainMenuView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

struct MainMenuView: View {

    /// The app's shared storage, injected by `ContentView` via the environment.
    @EnvironmentObject private var storageService: StorageService

    /// The app-wide settings logic, injected by `ContentView` via the
    /// environment — the SAME instance the root reads for display adjustments,
    /// so edits made on the settings page apply and persist app-wide.
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    @StateObject private var viewModel = MainMenuViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let baseUnit = min(geometry.size.width, geometry.size.height)

                AppScreen {
                    Image("bgPattern")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } content: {
                    HStack(spacing: 50) {
                        OwlMascotView()
                            .frame(
                                width: geometry.size.width * 0.4,
                                height: geometry.size.width * 0.4
                            )
                            .zIndex(1)

                        VStack(spacing: baseUnit * 0.025) {
                            ForEach(viewModel.menuItems, id: \.self) { destination in
                                MainMenuButton(
                                    title: title(for: destination),
                                    baseUnit: baseUnit,
                                    action: {
                                        viewModel.select(destination)
                                    }
                                )
                            }
                        }
                        .frame(width: geometry.size.width * 0.38)
                    }
                    .frame(width: geometry.size.width * 0.615)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .ignoresSafeArea()
            .navigationDestination(item: $viewModel.destination) { destination in
                // Choke point: every destination automatically gets the display
                // adjustments — screens need zero adjustment lines themselves.
                destinationView(for: destination)
                    .autoDisplayAdjustments()
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    @ViewBuilder
    // NOTE: destinations are NOT wrapped in appDisplayAdjustments here — every
    // screen applies its own adjustments at its root (see DisplayFilters.swift).
    // Wrapping here too would run the color matrix twice, and pushed screens
    // (chapter selection → gameplay → stage cleared) would escape a wrapper on
    // the router anyway.
    private func destinationView(for destination: MainMenuViewModel.Destination) -> some View {
        switch destination {
        case .mainStory:
            // Custom structural wrapper that handles clean navigation state routing for the main book catalog selection
            StorySelectionRouterView(mainMenuViewModel: viewModel)
                .environmentObject(storageService)
        case .trainingMode:
            // Training Mode launches from the same static story catalog used by Statistics and story selection.
            if let storyOne = StoryCatalog.stories.first(where: { $0.isAvailable }) {
                TrainingModeRouterView(story: storyOne, storageService: storageService)
            } else {
                Text("Error Loading Content")
                    .appDisplayAdjustments()
            }
        case .statistics:
            // Combines shared persisted progress with the static story catalog for competency mapping.
            StatisticsView(
                viewModel: StatisticsViewModel(
                    stories: StoryCatalog.stories,
                    storageService: storageService
                ),
                onBack: {
                    viewModel.clearDestination()
                }
            )
        case .settings:
            // Uses the SHARED settings view model (not a new store), so edits
            // preview and persist app-wide; back/Simpan pops by clearing the
            // destination.
            SettingsView(viewModel: settingsViewModel) {
                viewModel.clearDestination()
            }
        }
    }

    private func title(for destination: MainMenuViewModel.Destination) -> String {
        switch destination {
        case .mainStory:
            return "Cerita Utama"
        case .trainingMode:
            return "Mode Berlatih"
        case .statistics:
            return "Perkembangan"
        case .settings:
            return "Pengaturan"
        }
    }
}

// MARK: - Story Selection Navigation Router Intermediary View

private struct StorySelectionRouterView: View {
    @ObservedObject var mainMenuViewModel: MainMenuViewModel
    @StateObject private var storySelectionVM = StorySelectionViewModel()
    @State private var isShowingStoryCleared = false
    @EnvironmentObject private var storageService: StorageService

    var body: some View {
        StorySelectionView(viewModel: storySelectionVM)
            .navigationDestination(item: $storySelectionVM.selectedStory) { story in
                // Choke point: pushed screens inherit adjustments automatically.
                ChapterSelectionRouterView(
                    story: story,
                    storageService: storageService,
                    onStoryCompletion: {
                        storySelectionVM.clearSelection()
                        isShowingStoryCleared = true
                    }
                )
                .autoDisplayAdjustments()
            }
            .fullScreenCover(isPresented: $isShowingStoryCleared) {
                StoryClearedView(
                    onContinue: {
                        isShowingStoryCleared = false
                    }
                )
                .appTextSizeAdjustment()
                .appIndependentColorFilterScope()
                .presentationBackground(.clear)
            }
    }
}

private struct ChapterSelectionRouterView: View {
    @StateObject private var chapterSelectionVM: ChapterSelectionViewModel
    private let story: Story
    private let storageService: StorageService
    private let onStoryCompletion: () -> Void

    init(
        story: Story,
        storageService: StorageService,
        onStoryCompletion: @escaping () -> Void
    ) {
        self.story = story
        self.storageService = storageService
        self.onStoryCompletion = onStoryCompletion
        _chapterSelectionVM = StateObject(
            wrappedValue: ChapterSelectionViewModel(
                story: story,
                storageService: storageService
            )
        )
    }

    var body: some View {
        ChapterSelectionView(viewModel: chapterSelectionVM)
            .navigationDestination(item: $chapterSelectionVM.selectedChapter) { chapter in
                // Choke point: pushed screens inherit adjustments automatically.
                ChapterGamePlayView(
                    viewModel: ChapterGameplayViewModel(
                        chapter: chapter,
                        source: .mainStory,
                        nextChapterID: nextChapterID(after: chapter),
                        storageService: storageService
                    ),
                    onStoryCompletion: onStoryCompletion
                )
                .autoDisplayAdjustments()
            }
    }

    private func nextChapterID(after chapter: Chapter) -> String? {
        guard let currentIndex = story.chapters.firstIndex(of: chapter) else {
            return nil
        }

        let nextIndex = story.chapters.index(after: currentIndex)
        guard story.chapters.indices.contains(nextIndex) else {
            return nil
        }

        return story.chapters[nextIndex].id
    }
}

private struct TrainingModeRouterView: View {
    @StateObject private var trainingModeVM: TrainingModeViewModel
    private let storageService: StorageService

    init(story: Story, storageService: StorageService) {
        self.storageService = storageService
        _trainingModeVM = StateObject(
            wrappedValue: TrainingModeViewModel(
                story: story,
                storageService: storageService
            )
        )
    }

    var body: some View {
        TrainingModeView(viewModel: trainingModeVM)
            .navigationDestination(item: $trainingModeVM.selectedChapter) { chapter in
                // Choke point: pushed screens inherit adjustments automatically.
                ChapterGamePlayView(
                    viewModel: ChapterGameplayViewModel(
                        chapter: chapter,
                        source: .training,
                        storageService: storageService
                    )
                )
                .autoDisplayAdjustments()
            }
    }
}

private struct MainMenuButton: View {

    let title: String
    let baseUnit: CGFloat
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var minHeight: CGFloat = 72
    @ScaledMetric(relativeTo: .title2) private var horizontalPadding: CGFloat = 34

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .padding(.horizontal, horizontalPadding)
                .background(
                    Capsule()
                        .fill(Color(red: 0.02, green: 0.31, blue: 0.70))
                )
                .overlay(
                    Capsule()
                        .stroke(.black, lineWidth: max(2.5, baseUnit * 0.0055))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct OwlMascotView: View {

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            Image("owlCircle")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.black, lineWidth: max(3, size * 0.012))
                )
                .shadow(color: .black.opacity(0.18), radius: size * 0.033, x: 0, y: size * 0.0164)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}


#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return MainMenuView()
        .environmentObject(storageService)
        .environmentObject(SettingsViewModel(storageService: storageService))
}
