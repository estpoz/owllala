//
//  ChapterSelectionView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

struct ChapterSelectionView: View {
    @ObservedObject var viewModel: ChapterSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Core structural control parameter to handle the endless infinite looping track
    @State private var virtualIndex: Int = 1000
    
    // Explicit title mappings mandated by content specs
    private let chapterTitles = [
        "Bentuk Membantu Mika di Kelas",
        "Ikuti Tanda di Lorong Sekolah",
        "Cahaya Kecil di Loker Gelap",
        "Pola Rahasia di Taman Bermain",
        "Misi Besar di Kantin Sekolah"
    ]
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            // Dynamic proportional sizing constants mirroring the exact image layout
            let nodeDiameter = screenWidth * 0.24
            let titleBoxWidth = nodeDiameter * 1.15
            let titleBoxHeight = screenHeight * 0.12
            
            ZStack {
                // MARK: Background Canvas
                Color(red: 0.937, green: 0.953, blue: 0.957)
                    .ignoresSafeArea()
                
                Image(systemName: "square.dashed")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .foregroundColor(Color.gray.opacity(0.025))
                    .ignoresSafeArea()
                
                // MARK: Navigation Header Layer
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: screenWidth * 0.035, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: screenWidth * 0.075, height: screenWidth * 0.075)
                                    .background(Color(red: 0.0, green: 0.227, blue: 0.655))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, screenWidth * 0.04)
                            Spacer()
                        }
                        
                        Text("\(viewModel.story.title) : \(viewModel.story.subtitle ?? "")")
                            .font(.system(size: screenWidth * 0.042, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                    }
                    .padding(.top, screenHeight * 0.04)
                    
                    Spacer()
                }
                
                // MARK: Endless Circular Roadmap Track
                if !viewModel.items.isEmpty {
                    ZStack {
                        // Background connecting track path links
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { section in
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: nodeDiameter * 0.5))
                                    path.addLine(to: CGPoint(x: screenWidth * 0.35, y: nodeDiameter * 0.5))
                                }
                                .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [14, 14]))
                                .frame(width: screenWidth * 0.35, height: nodeDiameter)
                            }
                        }
                        .offset(x: -screenWidth * 0.2)
                        
                        // Active Node Items
                        HStack(spacing: screenWidth * 0.08) {
                            ForEach(-1...1, id: \.self) { offset in
                                let targetVirtualIndex = virtualIndex + offset
                                let actualIndex = determineModularIndex(targetVirtualIndex, total: viewModel.items.count)
                                let selectionItem = viewModel.items[actualIndex]
                                
                                VStack(spacing: screenHeight * 0.03) {
                                    ZStack(alignment: .top) {
                                        // Floating stars score row above the item node bubble
                                        HStack(spacing: 4) {
                                            ForEach(0..<3) { starIndex in
                                                Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                    .font(.system(size: screenWidth * 0.024, weight: .bold))
                                                    .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                            }
                                        }
                                        .offset(y: -screenHeight * 0.045)
                                        .opacity(selectionItem.isUnlocked ? 1 : 0)
                                        
                                        // Main circular image thumbnail element housing structure
                                        Circle()
                                            .fill(Color(red: 0.0, green: 0.227, blue: 0.655))
                                            .frame(width: nodeDiameter, height: nodeDiameter)
                                        
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                            
                                            // Fallback placeholder rendering when direct asset pipeline is empty
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.gray.opacity(0.5))
                                                .frame(width: nodeDiameter * 0.5, height: nodeDiameter * 0.5)
                                        }
                                        .frame(width: nodeDiameter * 0.93, height: nodeDiameter * 0.93)
                                        .offset(x: 0, y: (nodeDiameter * 0.07) / 2)
                                        .clipShape(Circle())
                                        
                                        // Padlock protection container matching user progression states
                                        if !selectionItem.isUnlocked {
                                            Circle()
                                                .fill(Color.black.opacity(0.3))
                                                .frame(width: nodeDiameter * 0.93, height: nodeDiameter * 0.93)
                                                .offset(x: 0, y: (nodeDiameter * 0.07) / 2)
                                            
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: nodeDiameter * 0.25, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(width: nodeDiameter * 0.35, height: nodeDiameter * 0.36)
                                                .background(Color(red: 0.059, green: 0.514, blue: 0.988))
                                                .clipShape(RoundedRectangle(cornerRadius: widthClamp(nodeDiameter * 0.08)))
                                                .offset(y: nodeDiameter * 0.32)
                                        }
                                    }
                                    .onTapGesture {
                                        if selectionItem.isUnlocked {
                                            viewModel.selectChapter(selectionItem.chapter)
                                        }
                                    }
                                    
                                    // Custom text info plates mapped underneath bubbles
                                    VStack(spacing: 4) {
                                        Text("Bab \(selectionItem.chapter.order)")
                                            .font(.system(size: screenWidth * 0.016, weight: .bold, design: .default))
                                            .foregroundColor(.black)
                                        
                                        Text(lookupChapterTitle(for: selectionItem.chapter.order))
                                            .font(.system(size: screenWidth * 0.015, weight: .medium, design: .default))
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .padding(.horizontal, 8)
                                    }
                                    .frame(width: titleBoxWidth, height: titleBoxHeight)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                }
                                // Center main viewing focal node gets full highlighting focus scale values
                                .scaleEffect(offset == 0 ? 1.12 : 0.86)
                                .opacity(offset == 0 ? 1.0 : 0.65)
                                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: virtualIndex)
                            }
                        }
                    }
                    .frame(width: screenWidth, height: screenHeight * 0.5)
                    .contentShape(Rectangle())
                    // Gesture management allowing endless track swiping cycles
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
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Methods
    
    private func determineModularIndex(_ index: Int, total: Int) -> Int {
        let remainder = index % total
        return remainder >= 0 ? remainder : remainder + total
    }
    
    private func lookupChapterTitle(for order: Int) -> String {
        let index = order - 1
        guard chapterTitles.indices.contains(index) else { return "" }
        return chapterTitles[index]
    }
    
    private func widthClamp(_ value: CGFloat) -> CGFloat {
        return max(value, 4.0)
    }
}


// MARK: - SwiftUI Preview

#Preview {
    let mockChapters = (1...5).map { index -> Chapter in
        let competency: Competency = [.shape, .labelSymbol, .brightnessContrast, .pattern, .context][index - 1]
        return Chapter(
            id: "chapter-\(index)",
            order: index,
            title: "Bab \(index)",
            subtitle: nil,
            description: "Deskripsi bab \(index)",
            thumbnailAssetName: "",
            competency: competency,
            storyPages: [],
            gameConfiguration: GameConfiguration(
                question: GameQuestion(
                    id: "q\(index)",
                    prompt: "Pertanyaan \(index)",
                    promptImageAssetName: nil,
                    answerOptions: [],
                    correctAnswerID: "",
                    hintText: ""
                )
            ),
            learningSummary: LearningSummary(
                successMessage: "",
                explanation: "",
                mainIllustrationAssetName: "",
                exampleAssetNames: []
            )
        )
    }
    
    let mockStory = Story(
        id: "story-1",
        order: 1,
        title: "Cerita 1",
        subtitle: "Hilangnya Kotak Bekal",
        description: "Bantu Lala menemukan kotak bekalnya.",
        coverAssetName: "",
        availability: .available,
        chapters: mockChapters,
        completionSummary: nil
    )
    
    // Create a vanilla instance of StorageService
    let mockStorage = StorageService()
    
    // NOTE: If you can't modify userStats because the setter is private,
    // call the exact saving method you implemented in StorageService here.
    // For example, if you have a save method:
    // var initialStats = UserStats(firstChapterID: "chapter-1")
    // initialStats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
    // initialStats.unlockChapter("chapter-2")
    // mockStorage.save(userStats: initialStats)
    
    let viewModel = ChapterSelectionViewModel(
        story: mockStory,
        storageService: mockStorage
    )
    
    NavigationStack {
        ChapterSelectionView(viewModel: viewModel)
    }
}
