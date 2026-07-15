//
//  MainMenuView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

struct MainMenuView: View {

    @StateObject private var viewModel = MainMenuViewModel()
    @Namespace private var owlNamespace
    @State private var isExpanded = false
    @State private var isPulsing = false

    var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)

            ZStack {
                MainMenuBackground()

                if isExpanded {
                    HStack(spacing: -geometry.size.width * 0.085) {
                        OwlMascotView()
                            .matchedGeometryEffect(id: "owl", in: owlNamespace)
                            .frame(
                                width: geometry.size.width * 0.45,
                                height: geometry.size.width * 0.45
                            )
                            .zIndex(1)

                        VStack(spacing: baseUnit * 0.03) {
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
                        .frame(width: geometry.size.width * 0.48)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    }
                    .frame(width: geometry.size.width * 0.615)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    VStack(spacing: baseUnit * 0.045) {
                        OwlMascotView()
                            .matchedGeometryEffect(id: "owl", in: owlNamespace)
                            .frame(
                                width: geometry.size.width * 0.5,
                                height: geometry.size.width * 0.5
                            )
                            .scaleEffect(isPulsing ? 1.06 : 1.0)
                            .contentShape(Circle())
                            .onTapGesture {
                                isPulsing = false
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                                    isExpanded = true
                                }
                            }
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.1)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    isPulsing = true
                                }
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityLabel("Tekan Aku untuk Memulai")

                        Text("Tekan Aku untuk Memulai")
                            .font(.system(size: baseUnit * 0.038, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.02, green: 0.31, blue: 0.70))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .transition(.opacity)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .ignoresSafeArea()
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

    @ScaledMetric(relativeTo: .title2)
    private var fontSize: CGFloat = 28

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(
                    .system(
                        size: min(fontSize, baseUnit * 0.06),
                        weight: .bold,
                        design: .rounded
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: baseUnit * 0.112)
                .padding(.horizontal, baseUnit * 0.05)
//                .padding(.leading, 50)
                .background(
                    Capsule()
                        .fill(Color(red: 0.02, green: 0.31, blue: 0.70))
                )
                .overlay(
                    Capsule()
                        .stroke(.black, lineWidth: max(2.5, baseUnit * 0.0055))
                )
        }
        .buttonStyle(.plain)
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
    MainMenuView()
}
