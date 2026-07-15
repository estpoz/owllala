//
//  StorySelectionView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import SwiftUI

struct StorySelectionView: View {
    @ObservedObject var viewModel: StorySelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            // Capture overall screen context metrics to create responsive ratios
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            // Proportional layout scaling factors
            let bookWidth = screenWidth * 0.22  // Scales book elements perfectly across display tracking
            let bookHeight = bookWidth * 1.314  // Maintains the explicit custom book aspect ratio
            
            ZStack {
                // MARK: Background Layer
                Color(red: 0.937, green: 0.953, blue: 0.957)
                    .ignoresSafeArea()
                
                // Background Decorative Asset Grid Track
                Image(systemName: "square.dashed")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .foregroundColor(Color.gray.opacity(0.025))
                    .ignoresSafeArea()
                
                // MARK: Interface Layout Elements
                VStack(spacing: 0) {
                    
                    // Top Header Bar Architecture
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
                        
                        Text("Cerita Utama")
                            .font(.system(size: screenWidth * 0.042, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                    }
                    .padding(.top, screenHeight * 0.04)
                    
                    Spacer(minLength: 0)
                    
                    // Horizontal Grid Row Arrangement
                    HStack(spacing: screenWidth * 0.045) {
                        ForEach(viewModel.items) { item in
                            StoryBookView(
                                item: item,
                                width: bookWidth,
                                height: bookHeight,
                                onTap: {
                                    viewModel.selectStory(item.story)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, screenWidth * 0.06)
                    
                    Spacer(minLength: screenHeight * 0.1)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

struct StoryBookView: View {
    let item: StorySelectionItem
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // Base Outer Book Silhouette Dimensions
                    RoundedRectangle(cornerRadius: width * 0.08)
                        .fill(item.isAvailable ? Color(red: 0.278, green: 0.412, blue: 0.533) : Color(red: 0.733, green: 0.314, blue: 0.306))
                        .frame(width: width, height: height)
                    
                    // White paper edge trim baseline placeholder at the bottom of the book layout
                    VStack {
                        Spacer()
                        UnevenRoundedRectangle(bottomLeadingRadius: width * 0.08, bottomTrailingRadius: width * 0.08)
                            .fill(Color(red: 0.863, green: 0.886, blue: 0.898))
                            .frame(height: height * 0.065)
                    }
                    .frame(width: width, height: height)
                    
                    // Left Book Spine Binding Accents (Drawn in gold blocks)
                    HStack {
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.941, green: 0.659, blue: 0.239))
                                .frame(width: width * 0.07, height: height * 0.022)
                                .padding(.top, height * 0.1)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.941, green: 0.659, blue: 0.239))
                                .frame(width: width * 0.07, height: height * 0.022)
                                .padding(.top, height * 0.015)
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.941, green: 0.659, blue: 0.239))
                                .frame(width: width * 0.07, height: height * 0.022)
                                .padding(.bottom, height * 0.015)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.941, green: 0.659, blue: 0.239))
                                .frame(width: width * 0.07, height: height * 0.022)
                                .padding(.bottom, height * 0.1)
                        }
                        .padding(.leading, width * 0.03)
                        Spacer()
                    }
                    .frame(width: width, height: height)
                    
                    // MARK: Contextual Overlay Layout Blocks
                    if item.isAvailable {
                        // Unlocked Playable Story Graphic Assembly
                        VStack(spacing: 0) {
                            // Target Cover Image Display Block Layout
                            ZStack {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.white)
                                    .frame(width: width * 0.68, height: height * 0.36)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                                
                                // Placeholder vector graphics layout mimicking the character picture box
                                Image(systemName: "person.crop.square.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray.opacity(0.6))
                                    .frame(width: width * 0.3, height: width * 0.3)
                            }
                            .padding(.top, height * 0.13)
                            
                            Spacer()
                            
                            Text(item.story.title)
                                .font(.system(size: width * 0.118, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                                .underline()
                                .padding(.bottom, height * 0.18)
                        }
                        .frame(width: width, height: height)
                        
                    } else {
                        // Locked / Coming Soon Content Representation
                        VStack(spacing: 0) {
                            
                            // Dark red indicator accent strip matching mockup background element layout
                            Rectangle()
                                .fill(Color.black.opacity(0.15))
                                .frame(width: width * 0.68, height: height * 0.1)
                                .padding(.top, height * 0.15)
                            
                            // Security Padlock Container Design Architecture
                            Image(systemName: "lock.fill")
                                .font(.system(size: width * 0.2, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: width * 0.26, height: width * 0.27)
                                .background(Color(red: 0.059, green: 0.514, blue: 0.988))
                                .clipShape(RoundedRectangle(cornerRadius: width * 0.06))
                                .padding(.top, height * 0.03)
                            
                            Spacer()
                            
                            VStack(spacing: 2) {
                                Text(item.story.title)
                                    .font(.system(size: width * 0.093, weight: .medium, design: .default))
                                Text("Coming Soon")
                                    .font(.system(size: width * 0.073, weight: .medium, design: .default))
                            }
                            .foregroundColor(.white)
                            .padding(.bottom, height * 0.16)
                        }
                        .frame(width: width, height: height)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
// MARK: - SwiftUI Preview

#Preview {
    // 1. Build a mock array of chapters to satisfy the Story model constraints
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
    
    // 2. Setup the stories matching your MVP layout criteria
    let mockStories = [
        Story(
            id: "story-1",
            order: 1,
            title: "Cerita 1",
            subtitle: "Hilangnya Kotak Bekal",
            description: "Bantu Lala menemukan kotak bekalnya.",
            coverAssetName: "",
            availability: .available,
            chapters: mockChapters,
            completionSummary: nil
        ),
        Story(
            id: "story-2",
            order: 2,
            title: "Cerita 2",
            subtitle: "Segera Hadir",
            description: "Segera hadir.",
            coverAssetName: "",
            availability: .comingSoon,
            chapters: [],
            completionSummary: nil
        ),
        Story(
            id: "story-3",
            order: 3,
            title: "Cerita 3",
            subtitle: "Segera Hadir",
            description: "Segera hadir.",
            coverAssetName: "",
            availability: .comingSoon,
            chapters: [],
            completionSummary: nil
        )
    ]
    
    // 3. Instantiate the ViewModel with mock context data
    let viewModel = StorySelectionViewModel(stories: mockStories)
    
    // 4. Return the configured view wrapped in a NavigationStack to match iPad landscape layout
    NavigationStack {
        StorySelectionView(viewModel: viewModel)
    }
}
