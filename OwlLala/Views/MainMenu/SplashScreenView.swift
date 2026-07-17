//
//  SplashScreenView.swift
//  OwlLala
//
//  Created by Amanda on 14/07/26.
//

import SwiftUI

struct SplashScreenView: View {

    /// Called automatically after the splash animation has had time to play.
    /// Hook this up to your navigation (e.g. flip a state var to show MainMenuView).
    var onFinished: () -> Void = {}

    @State private var hasAppeared = false
    @State private var isFloating = false
    @State private var sparklesActive = false

    private let autoDismissDelay: Double = 2.4

    private let sparkles: [Sparkle] = [
        Sparkle(x: 0.20, y: 0.22, size: 22, symbol: "sparkle", delay: 0.0, duration: 1.1),
        Sparkle(x: 0.80, y: 0.18, size: 16, symbol: "star.fill", delay: 0.3, duration: 1.4),
        Sparkle(x: 0.72, y: 0.62, size: 20, symbol: "sparkle", delay: 0.6, duration: 1.2),
        Sparkle(x: 0.14, y: 0.68, size: 14, symbol: "star.fill", delay: 0.9, duration: 1.5),
        Sparkle(x: 0.30, y: 0.80, size: 18, symbol: "sparkle", delay: 0.45, duration: 1.3),
        Sparkle(x: 0.86, y: 0.42, size: 24, symbol: "sparkle", delay: 0.15, duration: 1.6),
        Sparkle(x: 0.08, y: 0.42, size: 16, symbol: "star.fill", delay: 0.75, duration: 1.25),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SplashBackground()

                let mascotSize = geometry.size.width * 0.7

                ZStack {
                    ForEach(sparkles) { sparkle in
                        SparkleView(sparkle: sparkle, isActive: sparklesActive)
                    }

                    Image("splashScreen")
                        .resizable()
                        .scaledToFit()
                        .frame(width: mascotSize)
                        .shadow(color: Color(red: 0.02, green: 0.31, blue: 0.70).opacity(0.22), radius: 28, x: 0, y: 18)
                        .scaleEffect(hasAppeared ? 1.0 : 0.75)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: (hasAppeared && isFloating) ? -10 : 0)
                }
                .frame(width: mascotSize * 1.9, height: mascotSize * 1.9)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.62)) {
                hasAppeared = true
            }

            withAnimation(
                .easeInOut(duration: 1.6)
                    .repeatForever(autoreverses: true)
                    .delay(0.75)
            ) {
                isFloating = true
            }

            sparklesActive = true

            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                onFinished()
            }
        }
    }
}

private struct Sparkle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let symbol: String
    let delay: Double
    let duration: Double
}

private struct SparkleView: View {

    let sparkle: Sparkle
    let isActive: Bool

    @State private var isTwinkling = false

    var body: some View {
        GeometryReader { proxy in
            Image(systemName: sparkle.symbol)
                .font(.system(size: sparkle.size, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.16))
                .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.16).opacity(0.7), radius: 4)
                .scaleEffect(isTwinkling ? 1.0 : 0.4)
                .opacity(isTwinkling ? 1.0 : 0.0)
                .rotationEffect(.degrees(isTwinkling ? 14 : -14))
                .position(x: proxy.size.width * sparkle.x, y: proxy.size.height * sparkle.y)
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            guard active else { return }
            withAnimation(
                .easeInOut(duration: sparkle.duration)
                    .repeatForever(autoreverses: true)
                    .delay(sparkle.delay)
            ) {
                isTwinkling = true
            }
        }
    }
}

private struct SplashBackground: View {

    var body: some View {
        GeometryReader { geometry in
            Image("bgPattern")
                .resizable()
//                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview(traits: .landscapeRight) {
    SplashScreenView()
}
