//
//  ChapterSelectionView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 17/07/26.
//

import SwiftUI

// MARK: - Chapter Selection View

struct ChapterSelectionView: View {
    
    // MARK: - Dependencies & Environment
    
    @ObservedObject var viewModel: ChapterSelectionViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // MARK: - View State
    
    /// Virtual index tracking continuous scroll position for the carousel. Defaults to base 1000 to enable infinite scrolling.
    @State private var virtualIndex: Int = 1000
    
    /// Scale factor for the active chapter node pulse animation.
    @State private var pulseScale: CGFloat = 1.0
    
    // MARK: - Scaled Metric Layout Calibration Matrix
    
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleSize: CGFloat = 50
    @ScaledMetric(relativeTo: .title) private var babLabelSize: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var hintTextSize: CGFloat = 24
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            let nodeDiameter = screenWidth * 0.24
            let innerCoreDiameter = nodeDiameter * 0.93
            
            // MARK: Adaptive Layout & Font Size Hard Caps
            let isLargeLayout = dynamicTypeSize >= .accessibility1
            
            // Hard-stops font metric growth past AX3 scale factor to prevent overlap blowout
            let effectiveTitleSize: CGFloat = {
                if dynamicTypeSize > .accessibility3 {
                    return 50.0 * 1.8
                }
                return largeTitleSize
            }()
            
            // Curve anchor coordinates for quadratic Bézier layout math
            let startPointY = screenHeight * (isLargeLayout ? 0.86 : 0.79)
            let peakPointY = screenHeight * (isLargeLayout ? 0.65 : 0.55)
            let controlPointY = peakPointY - (startPointY - peakPointY)
            
            AppScreen {
                // MARK: Background Layer
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
                            // Full edge-to-edge roadmap track image asset
                            Image("lineStroke")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenWidth)
                                .ignoresSafeArea(edges: .horizontal)
                                .position(x: screenWidth * 0.5, y: peakPointY + (nodeDiameter * 0.25))
                            
                            // Render active center node (offset 0) alongside visible neighbor nodes (-1 and 1)
                            ForEach(-1...1, id: \.self) { offset in
                                let targetVirtualIndex = virtualIndex + offset
                                let actualIndex = determineModularIndex(targetVirtualIndex, total: viewModel.items.count)
                                let selectionItem = viewModel.items[actualIndex]
                                
                                // Parametric curve evaluation (t in [0.0...1.0])
                                let currentXPosition = screenWidth * (0.5 + CGFloat(offset) * 0.32)
                                let t: CGFloat = 0.5 + CGFloat(offset) * 0.32
                                let baseCurveY = (1 - t) * (1 - t) * startPointY + 2 * (1 - t) * t * controlPointY + t * t * startPointY
                                let currentYPosition = baseCurveY
                                
                                let calculatedOpacity = offset == 0 ? 1.0 : 0.85
                                
                                VStack(spacing: screenHeight * 0.01) {
                                    ZStack {
                                        // MARK: 1. Node Artwork Component
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
                                                
                                                Image("chapterCover\(selectionItem.chapter.order)")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: innerCoreDiameter * 0.8, height: innerCoreDiameter * 0.8)
                                            }
                                            .frame(width: innerCoreDiameter, height: innerCoreDiameter)
                                            .clipShape(Circle())
                                            
                                            // Lock Overlay
                                            if !selectionItem.isUnlocked {
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
                                        
                                        // MARK: 2. Top Stars Component (Standard Mode)
                                        if !isLargeLayout {
                                            HStack(spacing: 6) {
                                                ForEach(0..<3) { starIndex in
                                                    Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                        .font(.system(size: babLabelSize, weight: .bold, design: .rounded))
                                                        .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                                }
                                            }
                                            .offset(y: -(nodeDiameter / 2 + babLabelSize * 0.9))
                                            .opacity(selectionItem.isUnlocked ? 1 : 0)
                                        }
                                    }
                                    .onTapGesture {
                                        if offset == 0 {
                                            if selectionItem.isUnlocked {
                                                viewModel.selectChapter(selectionItem.chapter)
                                            }
                                        } else {
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                                virtualIndex += offset
                                            }
                                        }
                                    }
                                    
                                    // MARK: 3. Label & Accessibility Stars Component
                                    Text("Bab \(selectionItem.chapter.order)")
                                        .font(.system(size: babLabelSize, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    // Large Text Mode: Display stars below text to prevent top overlap
                                    if isLargeLayout && selectionItem.isUnlocked {
                                        HStack(spacing: 6) {
                                            ForEach(0..<3) { starIndex in
                                                Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                    .font(.system(size: babLabelSize * 0.8, weight: .bold, design: .rounded))
                                                    .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                            }
                                        }
                                        .padding(.top, 2)
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
                    
                    // MARK: Navigation Header & Footer Hint Layer
                    VStack(spacing: 0) {
                        // Header
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
                            
                            Text("\(viewModel.story.title) : \(viewModel.story.subtitle ?? "")")
                                .font(.system(size: effectiveTitleSize, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                                .padding(.horizontal, screenWidth * 0.13)
                        }
                        .padding(.top, screenHeight * (isLargeLayout ? 0.02 : 0.04))
                        
                        Spacer()
                        
                        // Bottom Swipe Hint Label (Hidden in AX Mode)
                        if !isLargeLayout {
                            Text("Geser untuk lihat bab selanjutnya")
                                .font(.system(size: hintTextSize, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.black.opacity(0.25))
                                .multilineTextAlignment(.center)
                                .padding(.bottom, screenHeight * 0.04)
                        }
                    }
                    .zIndex(2)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $viewModel.selectedChapter) { chapter in
            ChapterGamePlayView(
                viewModel: ChapterGameplayViewModel(
                    chapter: chapter,
                    source: .mainStory,
                    nextChapterID: viewModel.nextChapterID(for: chapter),
                    storageService: viewModel.storageService ?? StorageService()
                ),
                onChapterCompleted: { completedID in
                    viewModel.recordChapterCompletion(completedID)
                }
            )
            .environmentObject(settingsViewModel)
        }
        .onAppear {
            pulseScale = 1.02
            focusOnLatestUnlockedChapter()
        }
    }
    
    // MARK: - Auto-Focus Engine
    
    /// Smoothly scrolls the roadmap track to center on the appropriate chapter upon appearance.
    private func focusOnLatestUnlockedChapter() {
        guard !viewModel.items.isEmpty else { return }

        let targetIndex: Int
        
        if let playedID = viewModel.lastPlayedChapterID ?? viewModel.selectedChapter?.id,
           let playedIndex = viewModel.items.firstIndex(where: { $0.chapter.id == playedID }) {
            
            let didFinishChapter = (viewModel.lastCompletedChapterID == playedID)
            
            if didFinishChapter {
                // Rule 1: Finished chapter -> advance to next index
                let nextIndex = playedIndex + 1
                targetIndex = min(nextIndex, viewModel.items.count - 1)
            } else {
                // Rule 2: Exited / Canceled -> keep current index
                targetIndex = playedIndex
            }
        } else {
            // Fresh launch fallback
            targetIndex = viewModel.items.lastIndex(where: { $0.isUnlocked }) ?? 0
        }

        // Align with modular virtualIndex baseline (1000)
        let baseOffset = 1000
        let remainder = baseOffset % viewModel.items.count
        let alignedBase = baseOffset - remainder

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            virtualIndex = alignedBase + targetIndex
        }
        
        viewModel.clearCompletionState()
    }
    
    // MARK: - Math Helpers
    
    /// Wraps arbitrary virtual index offsets into a valid array index bounds.
    private func determineModularIndex(_ index: Int, total: Int) -> Int {
        let remainder = index % total
        return remainder >= 0 ? remainder : remainder + total
    }
}

// MARK: - Preview

#Preview {
    let selectionVM = StorySelectionViewModel()
    let storageService = StorageService()

    if let realStory = selectionVM.items.first?.story {
        ChapterSelectionView(viewModel: ChapterSelectionViewModel(story: realStory, storageService: storageService))
            .environmentObject(storageService)
            .environmentObject(SettingsViewModel(storageService: storageService))
    }
}
