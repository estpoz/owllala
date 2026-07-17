//
//  CompetencyGraph.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

// MARK: - Competency Graph

/// Draws the five-point visual competency radar chart used by Statistics.
struct CompetencyGraph: View {

    let items: [CompetencyProgressItem]

    // MARK: Styling

    private let gridLevels = 5
    private let graphColor = Color(red: 0.12, green: 0.40, blue: 0.92)
    private let gridColor = Color(red: 0.74, green: 0.78, blue: 0.88)

    // MARK: Dynamic Type Metrics

    @ScaledMetric(relativeTo: .title2) private var titleFontSize: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var labelFontSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 24

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            Text("Kemampuan Visual")
                .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.02, green: 0.16, blue: 0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityAddTraits(.isHeader)

            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)

                ZStack {
                    Canvas { context, canvasSize in
                        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                        let radius = min(canvasSize.width, canvasSize.height) * 0.34
                        let orderedItems = graphItems

                        drawGrid(in: &context, center: center, radius: radius)
                        drawAxis(in: &context, center: center, radius: radius)
                        drawValues(
                            in: &context,
                            center: center,
                            radius: radius,
                            items: orderedItems
                        )
                    }

                    ForEach(Array(graphItems.enumerated()), id: \.element.id) { index, item in
                        let labelPoint = point(
                            index: index,
                            count: graphItems.count,
                            radius: size * 0.46,
                            center: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        )

                        Text(shortLabel(for: item.competency))
                            .font(.system(size: labelFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.02, green: 0.09, blue: 0.28))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: size * 0.26)
                            .position(labelPoint)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.94))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.86, green: 0.90, blue: 1.0), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: Graph Data

    private var graphItems: [CompetencyProgressItem] {
        // Missing progress still renders as the real empty state: 0 out of 5.
        StatisticsViewModel.competencyOrder.map { competency in
            items.first { $0.competency == competency } ?? CompetencyProgressItem(
                competency: competency,
                score: 0,
                maximumScore: 5,
                chapterID: ""
            )
        }
    }

    private var accessibilitySummary: String {
        graphItems
            .map { "\($0.competency.displayName) \($0.score) dari \($0.maximumScore)" }
            .joined(separator: ", ")
    }

    // MARK: Drawing

    private func drawGrid(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat
    ) {
        for level in 1...gridLevels {
            let levelRadius = radius * CGFloat(level) / CGFloat(gridLevels)
            let path = polygonPath(
                count: graphItems.count,
                radius: levelRadius,
                center: center
            )
            context.stroke(
                path,
                with: .color(gridColor.opacity(0.8)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
            )
        }
    }

    private func drawAxis(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat
    ) {
        for index in graphItems.indices {
            var path = Path()
            path.move(to: center)
            path.addLine(to: point(
                index: index,
                count: graphItems.count,
                radius: radius,
                center: center
            ))
            context.stroke(path, with: .color(gridColor.opacity(0.6)), lineWidth: 1.2)
        }
    }

    private func drawValues(
        in context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        items: [CompetencyProgressItem]
    ) {
        guard items.count > 2 else {
            return
        }

        let path = Path { path in
            for (index, item) in items.enumerated() {
                let progress = CGFloat(item.score) / CGFloat(max(item.maximumScore, 1))
                let point = point(
                    index: index,
                    count: items.count,
                    radius: radius * progress,
                    center: center
                )

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }

        context.fill(path, with: .color(graphColor.opacity(0.18)))
        context.stroke(path, with: .color(graphColor), lineWidth: 3)

        for (index, item) in items.enumerated() {
            let progress = CGFloat(item.score) / CGFloat(max(item.maximumScore, 1))
            let valuePoint = point(
                index: index,
                count: items.count,
                radius: radius * progress,
                center: center
            )
            let marker = Path(ellipseIn: CGRect(
                x: valuePoint.x - 6,
                y: valuePoint.y - 6,
                width: 12,
                height: 12
            ))
            context.fill(marker, with: .color(graphColor))
        }
    }

    // MARK: Geometry

    private func polygonPath(
        count: Int,
        radius: CGFloat,
        center: CGPoint
    ) -> Path {
        Path { path in
            for index in 0..<count {
                let point = point(
                    index: index,
                    count: count,
                    radius: radius,
                    center: center
                )

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    private func point(
        index: Int,
        count: Int,
        radius: CGFloat,
        center: CGPoint
    ) -> CGPoint {
        let angle = (-CGFloat.pi / 2) + (2 * CGFloat.pi * CGFloat(index) / CGFloat(max(count, 1)))
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    // MARK: Labels

    private func shortLabel(for competency: Competency) -> String {
        switch competency {
        case .labelSymbol:
            return "Label/Simbol"

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
    "Competency Graph - iPad Landscape",
    traits: .fixedLayout(width: 800, height: 800)
) {
    CompetencyGraph(items: [])
        .frame(width: 620, height: 620)
        .padding(48)
        .background(StatisticsBackground())
}
#endif
