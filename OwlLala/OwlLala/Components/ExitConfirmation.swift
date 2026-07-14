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

    private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)
    private let borderBlue = Color(red: 0.34, green: 0.39, blue: 1.00)

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = min(geometry.size.width * 0.92, 1040)
            let panelHeight = min(geometry.size.height * 0.86, 874)
            let titleFontSize = min(panelWidth * 0.052, 54)
            let buttonFontSize = min(panelWidth * 0.035, 36)
            let buttonWidth = min(panelWidth * 0.44, 454)

            ZStack {
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Apa kamu yakin mau\nkehilangan progress\nbelajarmu?")
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(titleFontSize * 0.18)
                        .minimumScaleFactor(0.7)
                        .padding(.top, panelHeight * 0.10)

                    VStack(spacing: panelHeight * 0.04) {
                        Button(action: onContinueLearning) {
                            Text("Kembali Belajar")
                                .font(.system(size: buttonFontSize, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: buttonWidth, height: panelHeight * 0.12)
                                .background(primaryBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }

                        Button(action: onDiscardProgress) {
                            Text("Hilangkan progress")
                                .font(.system(size: buttonFontSize, weight: .regular))
                                .foregroundStyle(primaryBlue)
                                .frame(width: buttonWidth, height: panelHeight * 0.11)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(primaryBlue, lineWidth: 4)
                                }
                        }
                    }
                    .padding(.top, panelHeight * 0.09)

                    Spacer(minLength: 0)
                }
                .frame(width: panelWidth, height: panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(borderBlue, lineWidth: 4)
                }
            }
        }
    }
}

#Preview {
    ExitConfirmation(
        onContinueLearning: {},
        onDiscardProgress: {}
    )
}
