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

                ZStack {
                    MainMenuBackground()

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
                destinationView(for: destination)
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: MainMenuViewModel.Destination) -> some View {
        switch destination {
        case .mainStory:
            Text("Story Selection View")
//            StorySelectionView()
        case .trainingMode:
            Text("Training Mode View")
//            TrainingModeView()
        case .statistics:
            // Uses the app's shared storage so real progress is shown.
            StatisticsView(
                viewModel: StatisticsViewModel(
                    stories: [],
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

private struct MainMenuBackground: View {

    private let columns = Array(repeating: GridItem(.fixed(86), spacing: 24), count: 14)
    private let symbols = [
        "book.closed",
        "lightbulb",
        "paintpalette",
        "questionmark.circle",
        "pencil",
        "sparkles"
    ]

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.99, blue: 0.98)

            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(0..<84, id: \.self) { index in
                    Image(systemName: symbols[index % symbols.count])
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(Color(red: 0.66, green: 0.79, blue: 0.78).opacity(0.16))
                        .rotationEffect(.degrees(Double((index % 5) - 2) * 12))
                        .frame(width: 86, height: 64)
                }
            }
            .padding(32)
        }
    }
}

#Preview(traits: .landscapeRight) {
    let storageService = StorageService()

    return MainMenuView()
        .environmentObject(storageService)
        .environmentObject(SettingsViewModel(storageService: storageService))
}
