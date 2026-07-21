import SwiftUI

struct TrainingModeView: View {
    @ObservedObject var viewModel: TrainingModeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var virtualIndex: Int = 1000
    
    // MARK: - Scaled Metric Layout Calibration Matrix
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleSize: CGFloat = 60
    @ScaledMetric(relativeTo: .title) private var babLabelSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            let nodeDiameter = screenWidth * 0.24
            let innerCoreDiameter = nodeDiameter * 0.93
            
            let startPointY = screenHeight * 0.79
            let peakPointY = screenHeight * 0.55
            let controlPointY = peakPointY - (startPointY - peakPointY)
            
            AppScreen {
                ZStack {
                    Color(red: 0.937, green: 0.953, blue: 0.957)
                        .ignoresSafeArea()

                    Image("PatternBG")
                        .resizable()
                        .scaledToFill()
                        .frame(width: screenWidth, height: screenHeight)
                        .ignoresSafeArea()
                }
            } content: {
                ZStack {
                // MARK: Endless Circular Roadmap Track Framework
                if !viewModel.items.isEmpty {
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: startPointY))
                            path.addQuadCurve(
                                to: CGPoint(x: screenWidth, y: startPointY),
                                control: CGPoint(x: screenWidth * 0.5, y: controlPointY)
                            )
                        }
                        .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [14, 14]))
                        
                        ForEach(-1...1, id: \.self) { offset in
                            let targetVirtualIndex = virtualIndex + offset
                            let actualIndex = determineModularIndex(targetVirtualIndex, total: viewModel.items.count)
                            let selectionItem = viewModel.items[actualIndex]
                            
                            let currentXPosition = screenWidth * (0.5 + CGFloat(offset) * 0.32)
                            let t: CGFloat = 0.5 + CGFloat(offset) * 0.32
                            let baseCurveY = (1 - t) * (1 - t) * startPointY + 2 * (1 - t) * t * controlPointY + t * t * startPointY
                            let currentYPosition = baseCurveY
                            
                            let calculatedOpacity = offset == 0 ? 1.0 : 0.85
                            
                            let rawOrder = selectionItem.chapter.order
                            let isComingSoon = rawOrder > 5
                            let labelTitleText = isComingSoon
                                ? "Cerita 2 : Bab \(rawOrder - 5)"
                                : "Cerita 1 : Bab \(rawOrder)"
                            
                            VStack(spacing: screenHeight * 0.02) {
                                ZStack(alignment: .center) {
                                    Circle()
                                        .stroke(
                                            offset == 0 ? Color(red: 0.0, green: 0.227, blue: 0.655) : Color(red: 0.0, green: 0.227, blue: 0.655).opacity(0.6),
                                            lineWidth: 10
                                        )
                                        .background(Circle().fill(Color.white))
                                        .frame(width: nodeDiameter, height: nodeDiameter)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                        
                                        let trainingAssetName = isComingSoon ? "chapterCover6" : "chapterCover\(rawOrder)"
                                        
                                        Image(trainingAssetName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: innerCoreDiameter * 0.8, height: innerCoreDiameter * 0.8)
                                    }
                                    .frame(width: innerCoreDiameter, height: innerCoreDiameter)
                                    .clipShape(Circle())
                                    
                                    if !selectionItem.isUnlocked || isComingSoon {
                                        Circle()
                                            .fill(Color.black.opacity(0.2))
                                            .frame(width: nodeDiameter, height: nodeDiameter)
                                        
                                        Image("LockIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: nodeDiameter * 0.35, height: nodeDiameter * 0.36)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        ForEach(0..<3) { starIndex in
                                            Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                .font(.system(size: babLabelSize, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                        }
                                    }
                                    .offset(y: -(nodeDiameter / 2 + babLabelSize * 0.9))
                                    .opacity(selectionItem.isUnlocked && !isComingSoon ? 1 : 0)
                                }
                                .onTapGesture {
                                    if offset == 0 {
                                        if selectionItem.isUnlocked && !isComingSoon {
                                            viewModel.selectedChapter = selectionItem.chapter
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                            virtualIndex += offset
                                        }
                                    }
                                }
                                
                                Text(labelTitleText)
                                    .font(.system(size: babLabelSize, weight: .bold, design: .rounded))
                                    .foregroundColor(isComingSoon ? .gray : .black)
                                    .padding(.top, 4)
                            }
                            .scaleEffect(offset == 0 ? 1.15 : 0.86)
                            .opacity(calculatedOpacity)
                            .position(x: currentXPosition, y: currentYPosition)
                            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: virtualIndex)
                        }
                    }
                    .frame(width: screenWidth, height: screenHeight)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -60 {
                                    virtualIndex += 1
                                } else if value.translation.width > 60 {
                                    virtualIndex -= 1
                                }
                            }
                    )
                    .zIndex(1) // Layer 1: Stays underneath headers
                }
                
                // MARK: Navigation Header Layer (Brought to top layer)
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            Button(action: {
                                viewModel.clearSelection()
                                viewModel.selectedChapter = nil
                                dismiss()
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: screenWidth * 0.035, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: screenWidth * 0.075, height: screenWidth * 0.075)
                                    .background(Color(red: 0.0, green: 0.227, blue: 0.655))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, screenWidth * 0.04)
                            Spacer()
                        }
                        
                        Text("Mode Berlatih")
                            .font(.system(size: largeTitleSize, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                    }
                    .padding(.top, screenHeight * 0.04)
                    
                    Spacer()
                }
                .zIndex(2) // Layer 2: Elevated to resolve complete hit-testing interaction bugs
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func determineModularIndex(_ index: Int, total: Int) -> Int {
        let remainder = index % total
        return remainder >= 0 ? remainder : remainder + total
    }
}

#Preview {
    let selectionVM = StorySelectionViewModel()
    let storageService = StorageService()

    if let realStory = selectionVM.items.first?.story {
        TrainingModeView(viewModel: TrainingModeViewModel(story: realStory))
            .previewInterfaceOrientation(.landscapeLeft)
            .environmentObject(storageService)
            .environmentObject(SettingsViewModel(storageService: storageService))
    }
}
