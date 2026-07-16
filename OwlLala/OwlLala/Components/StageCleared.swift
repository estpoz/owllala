//
//  StageCleared.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI
// MARK: - Confetti

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xRatio: CGFloat
    let color: Color
    let sizeRatio: CGFloat
    let delay: Double
    let duration: Double
    let spin: Double
    let isCircle: Bool
}

public struct ConfettiOverlay: View {

    private let colors: [Color] = [
        Color(red: 1.0, green: 0.78, blue: 0.16),
        Color(red: 0.02, green: 0.31, blue: 0.70),
        Color(red: 0.35, green: 0.62, blue: 0.30),
        Color(red: 0.86, green: 0.20, blue: 0.20),
        Color(red: 0.45, green: 0.30, blue: 0.65)
    ]

    @State private var pieces: [ConfettiPiece] = []

    public var body: some View {
        GeometryReader { geometry in
            let baseUnit = min(geometry.size.width, geometry.size.height)

            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, baseUnit: baseUnit, screenHeight: geometry.size.height)
                        .position(x: geometry.size.width * piece.xRatio, y: 0)
                }
            }
            .onAppear {
                pieces = (0..<45).map { _ in
                    ConfettiPiece(
                        xRatio: CGFloat.random(in: 0.02...0.98),
                        color: colors.randomElement()!,
                        sizeRatio: CGFloat.random(in: 0.008...0.016),
                        delay: Double.random(in: 0...0.6),
                        duration: Double.random(in: 1.8...2.8),
                        spin: Double.random(in: 180...540),
                        isCircle: Bool.random()
                    )
                }
            }
        }
    }
}

private struct ConfettiPieceView: View {

    let piece: ConfettiPiece
    let baseUnit: CGFloat
    let screenHeight: CGFloat

    @State private var hasFallen = false

    var body: some View {
        Group {
            if piece.isCircle {
                Circle().fill(piece.color)
            } else {
                RoundedRectangle(cornerRadius: 2).fill(piece.color)
            }
        }
        .frame(width: baseUnit * piece.sizeRatio, height: baseUnit * piece.sizeRatio * 1.6)
        .rotationEffect(.degrees(hasFallen ? piece.spin : 0))
        .offset(y: hasFallen ? screenHeight + 40 : -20)
        .opacity(hasFallen ? 0.0 : 1.0)
        .onAppear {
            withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                hasFallen = true
            }
        }
    }
}
