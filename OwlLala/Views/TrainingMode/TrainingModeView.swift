import SwiftUI

struct TrainingModeView: View {
    @ObservedObject var viewModel: TrainingModeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var virtualIndex: Int = 1002
    @State private var pulseScale: CGFloat = 1.0
    
    // MARK: - Scaled Metric Layout Calibration Matrix
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleSize: CGFloat = 50
    @ScaledMetric(relativeTo: .title) private var babLabelSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            let nodeDiameter = screenWidth * 0.24
            let innerCoreDiameter = nodeDiameter * 0.93
            
            // MARK: Adaptive Layout & Font Size Hard Caps
            let isLargeLayout = dynamicTypeSize >= .accessibility2
            
            // Hard-stops font metric growth past AX3 scale factor to prevent vertical overflow
            let effectiveTitleSize: CGFloat = {
                if dynamicTypeSize > .accessibility3 {
                    return 50.0 * 1.8
                }
                return largeTitleSize
            }()
            
            // Pushes the roadmap curve LOWER down on screen in AX modes (matching ChapterSelectionView)
            let startPointY = screenHeight * (isLargeLayout ? 0.86 : 0.79)
            let peakPointY = screenHeight * (isLargeLayout ? 0.58 : 0.55)
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
                                let storyTitleText = isComingSoon ? "Cerita 2" : "Cerita 1"
                                let chapterTitleText = isComingSoon ? "Bab \(rawOrder - 5)" : "Bab \(rawOrder)"
                                
                                VStack(spacing: screenHeight * 0.005) {
                                    ZStack {
                                        // 1. The Pulsing Circle Component
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
                                        }
                                        .scaleEffect(offset == 0 ? pulseScale : 1.0)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseScale)
                                        
                                        // 2. Stationary Top Stars (Standard Non-AX Mode)
                                        if !isLargeLayout {
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
                                    
                                    // Original Full Label Typography Sizing
                                    VStack(spacing: -2) {
                                        Text(storyTitleText)
                                            .font(.system(size: babLabelSize * 0.85, weight: .bold, design: .rounded))
                                            .foregroundColor(isComingSoon ? .gray : .black)
                                        
                                        Text(chapterTitleText)
                                            .font(.system(size: babLabelSize, weight: .bold, design: .rounded))
                                            .foregroundColor(isComingSoon ? .gray : .black)
                                    }
                                    .multilineTextAlignment(.center)
                                    
                                    // Large Text Mode: Display stars safely below label text
                                    if isLargeLayout && selectionItem.isUnlocked && !isComingSoon {
                                        HStack(spacing: 6) {
                                            ForEach(0..<3) { starIndex in
                                                Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                    .font(.system(size: babLabelSize * 0.75, weight: .bold, design: .rounded))
                                                    .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                            }
                                        }
                                        .padding(.top, 0)
                                    }
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
                        .zIndex(1)
                    }
                    
                    // MARK: Safe Adaptive Navigation Header Layer
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            HStack {
                                BackButton(style: .filled) {
                                    viewModel.clearSelection()
                                    viewModel.selectedChapter = nil
                                    dismiss()
                                }
                                .padding(.leading, screenWidth * 0.04)
                                Spacer()
                            }
                            
                            Text("Mode Berlatih")
                                .font(.system(size: effectiveTitleSize, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                                .padding(.horizontal, screenWidth * 0.13)
                        }
                        .padding(.top, screenHeight * (isLargeLayout ? 0.02 : 0.04))
                        
                        Spacer()
                    }
                    .zIndex(2)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            pulseScale = 1.02
        }
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
