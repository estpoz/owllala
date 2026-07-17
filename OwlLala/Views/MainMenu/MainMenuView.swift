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
    
    /// A temporary internal view model reference used to resolve Story 1 parameters
    /// for Training Mode navigation routing safely without static mock leaks.
    @StateObject private var helperCatalog = StorySelectionViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let baseUnit = min(geometry.size.width, geometry.size.height)

                ZStack {
                    // Designated background layer: only this dims with the
                    // "Kecerahan Latar Belakang" setting — the owl, buttons,
                    // and text stay at full brightness (Settings model rule).
                    Image("bgPattern")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .appBackgroundBrightness()

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
            // Applied INSIDE the NavigationStack (per screen), never around it:
            // the stack is UIKit-backed and the color shader can't rasterize
            // it (yellow "no entry" placeholder). The menu itself is pure
            // SwiftUI, so the full adjustments are safe here.
            .appDisplayAdjustments()
            .navigationDestination(item: $viewModel.destination) { destination in
                destinationView(for: destination)
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: MainMenuViewModel.Destination) -> some View {
        switch destination {
        case .mainStory:
            // Custom structural wrapper that handles clean navigation state routing for the main book catalog selection
            StorySelectionRouterView(mainMenuViewModel: viewModel)
                .environmentObject(storageService)
                .appDisplayAdjustments()
        case .trainingMode:
            // Directly paths to Training Mode using the catalog data instance payload, skipping book selection layout bounds
            if let storyOne = helperCatalog.items.first?.story {
                TrainingModeView(viewModel: TrainingModeViewModel(story: storyOne, storageService: storageService))
                    .appDisplayAdjustments()
            } else {
                Text("Error Loading Content")
                    .appDisplayAdjustments()
            }
        case .statistics:
            // Uses the app's shared storage so real progress is shown.
            // Color filter skipped: StatisticsView contains a ScrollView
            // (UIKit-backed), which the shader can't rasterize — it still
            // gets brightness and text size.
            StatisticsView(
                viewModel: StatisticsViewModel(
                    stories: [],
                    storageService: storageService
                ),
                onBack: {
                    viewModel.clearDestination()
                }
            )
            .appDisplayAdjustments(includeColorFilter: false)
        case .settings:
            // Uses the SHARED settings view model (not a new store), so edits
            // preview and persist app-wide; back/Simpan pops by clearing the
            // destination. Pure SwiftUI, so the full adjustments are safe.
            SettingsView(viewModel: settingsViewModel) {
                viewModel.clearDestination()
            }
            .appDisplayAdjustments()
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
    @EnvironmentObject private var storageService: StorageService

    var body: some View {
        StorySelectionView(viewModel: storySelectionVM)
            .navigationDestination(item: $storySelectionVM.selectedStory) { story in
                ChapterSelectionView(viewModel: ChapterSelectionViewModel(story: story, storageService: storageService))
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

            Image("homeScreen")
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
