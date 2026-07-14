//
//  ExitConfirmation.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

struct ExitConfirmation: View {
    let onContinueLearning: () -> Void
    let onDiscardProgress: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title2) private var buttonScale: CGFloat = 1
    @ScaledMetric(relativeTo: .body) private var spacingScale: CGFloat = 1

    private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)

    var body: some View {
        GeometryReader { geometry in
            let layout = makeLayout(for: geometry.size)

            ZStack {
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Text("Apa kamu yakin mau\nkehilangan progress\nbelajarmu?")
                            .font(.system(size: layout.titleFontSize, weight: .bold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(layout.titleFontSize * 0.18)
                            .padding(.horizontal, layout.horizontalPadding)
                            .padding(.top, layout.verticalPadding)

                        VStack(spacing: layout.buttonSpacing) {
                            Button(action: onContinueLearning) {
                                Text("Kembali Belajar")
                                    .font(.system(size: layout.buttonFontSize, weight: .regular))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, layout.buttonHorizontalPadding)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: layout.primaryButtonHeight)
                                    .background(primaryBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: layout.buttonCornerRadius, style: .continuous))
                            }

                            Button(action: onDiscardProgress) {
                                Text("Hilangkan progress")
                                    .font(.system(size: layout.buttonFontSize, weight: .regular))
                                    .foregroundStyle(primaryBlue)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, layout.buttonHorizontalPadding)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: layout.secondaryButtonHeight)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: layout.buttonCornerRadius, style: .continuous)
                                            .stroke(primaryBlue, lineWidth: 3)
                                    }
                            }
                        }
                        .frame(maxWidth: layout.buttonMaxWidth)
                        .padding(.top, layout.contentSpacing)
                        .padding(.horizontal, layout.horizontalPadding)
                        .padding(.bottom, layout.verticalPadding)

                        Spacer(minLength: 0)
                    }
                }
                .frame(width: layout.panelWidth, height: layout.panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: layout.panelCornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
            }
        }
    }

    private func makeLayout(for size: CGSize) -> ModalLayout {
        let shortestSide = min(size.width, size.height)
        let isCompact = shortestSide < 500
        let isLarge = size.width >= 900 && size.height >= 700
        let panelWidthRatio: CGFloat = isCompact ? 0.90 : (isLarge ? 0.66 : 0.76)
        let panelHeightRatio: CGFloat = dynamicTypeSize.isAccessibilitySize ? 0.88 : (isCompact ? 0.72 : 0.64)
        let panelWidth = (size.width * panelWidthRatio).clamped(to: 280...820)
        let panelHeight = (size.height * panelHeightRatio).clamped(to: 320...760)
        let titleBaseSize = (panelWidth * (isCompact ? 0.070 : 0.058)).clamped(to: 28...46)
        let buttonBaseSize = (panelWidth * (isCompact ? 0.045 : 0.038)).clamped(to: 19...30)
        let buttonMaxWidth = (panelWidth * (isCompact ? 0.78 : 0.56)).clamped(to: 230...440)

        return ModalLayout(
            panelWidth: panelWidth,
            panelHeight: panelHeight,
            panelCornerRadius: (panelWidth * 0.032).clamped(to: 18...28),
            titleFontSize: titleBaseSize * titleScale,
            buttonFontSize: buttonBaseSize * buttonScale,
            buttonMaxWidth: buttonMaxWidth,
            primaryButtonHeight: max(panelHeight * 0.13, 52 * buttonScale),
            secondaryButtonHeight: max(panelHeight * 0.12, 48 * buttonScale),
            buttonCornerRadius: (panelWidth * 0.024).clamped(to: 14...20),
            horizontalPadding: (panelWidth * 0.08).clamped(to: 20...64),
            verticalPadding: (panelHeight * 0.10).clamped(to: 28...72),
            contentSpacing: (panelHeight * 0.09).clamped(to: 26...64),
            buttonSpacing: max(panelHeight * 0.04, 16 * spacingScale),
            buttonHorizontalPadding: (18 * spacingScale).clamped(to: 16...34)
        )
    }
}

private struct ModalLayout {
    let panelWidth: CGFloat
    let panelHeight: CGFloat
    let panelCornerRadius: CGFloat
    let titleFontSize: CGFloat
    let buttonFontSize: CGFloat
    let buttonMaxWidth: CGFloat
    let primaryButtonHeight: CGFloat
    let secondaryButtonHeight: CGFloat
    let buttonCornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let contentSpacing: CGFloat
    let buttonSpacing: CGFloat
    let buttonHorizontalPadding: CGFloat
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ExitConfirmation(
        onContinueLearning: {},
        onDiscardProgress: {}
    )
}
