import SwiftUI

struct StorySelectionView: View {
    @ObservedObject var viewModel: StorySelectionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // MARK: - Scaled Metric Dynamic Type Dimensions
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleSize: CGFloat = 60
    @ScaledMetric(relativeTo: .title) private var title1Size: CGFloat = 40
    @ScaledMetric(relativeTo: .headline) private var headlineSize: CGFloat = 32
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            // Layout dimensions scale beautifully with font size changes
            let baseBookWidth = screenWidth * 0.22
            let bookWidth = baseBookWidth * (title1Size / 40.0)
            let bookHeight = bookWidth * 1.314
            
            ZStack {
                Color(red: 0.937, green: 0.953, blue: 0.957)
                    .ignoresSafeArea()
                
                Image("PatternBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Area
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
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
                        
                        Text("Cerita Utama")
                            .font(.system(size: largeTitleSize, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.067, green: 0.067, blue: 0.067))
                    }
                    .padding(.top, screenHeight * 0.04)
                    
                    Spacer(minLength: 0)
                    
                    // Adaptive Layout: Switches from HStack to Scrollable VStack for accessibility text sizes
                    if dynamicTypeSize.isAccessibilitySize {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: screenHeight * 0.04) {
                                contentGridItems(width: bookWidth, height: bookHeight)
                            }
                            .padding(.vertical, screenHeight * 0.04)
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        HStack(spacing: screenWidth * 0.045) {
                            contentGridItems(width: bookWidth, height: bookHeight)
                        }
                        .padding(.horizontal, screenWidth * 0.06)
                    }
                    
                    Spacer(minLength: screenHeight * 0.1)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Grid Child Render Loop
    @ViewBuilder
    private func contentGridItems(width: CGFloat, height: CGFloat) -> some View {
        ForEach(viewModel.items) { item in
            StoryBookView(
                item: item,
                width: width,
                height: height,
                titleSize: title1Size,
                subtitleSize: headlineSize
            ) {
                viewModel.selectStory(item.story)
            }
        }
    }
}

// MARK: - Reusable Book Card Item Component

struct StoryBookView: View {
    let item: StorySelectionItem
    let width: CGFloat
    let height: CGFloat
    let titleSize: CGFloat
    let subtitleSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: width * 0.08)
                        .fill(item.isAvailable ? Color(red: 0.278, green: 0.412, blue: 0.533) : Color(red: 0.733, green: 0.314, blue: 0.306))
                        .frame(width: width, height: height)
                    
                    VStack {
                        Spacer()
                        UnevenRoundedRectangle(bottomLeadingRadius: width * 0.08, bottomTrailingRadius: width * 0.08)
                            .fill(Color(red: 0.863, green: 0.886, blue: 0.898))
                            .frame(height: height * 0.065)
                    }
                    .frame(width: width, height: height)
                    
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
                    
                    if item.isAvailable {
                        VStack(spacing: 0) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.white)
                                    .frame(width: width * 0.68, height: height * 0.36)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                                
                                Image(systemName: "person.crop.square.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray.opacity(0.6))
                                    .frame(width: width * 0.3, height: width * 0.3)
                            }
                            .padding(.top, height * 0.13)
                            
                            Spacer()
                            
                            Text(item.story.title)
                                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .underline()
                                .lineLimit(1)
                                .padding(.horizontal, width * 0.08)
                                .padding(.bottom, height * 0.18)
                        }
                        .frame(width: width, height: height)
                        
                    } else {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.black.opacity(0.15))
                                .frame(width: width * 0.68, height: height * 0.1)
                                .padding(.top, height * 0.15)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: width * 0.2, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: width * 0.26, height: width * 0.27)
                                .background(Color(red: 0.059, green: 0.514, blue: 0.988))
                                .clipShape(RoundedRectangle(cornerRadius: width * 0.06))
                                .padding(.top, height * 0.03)
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text(item.story.title)
                                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                                Text("Coming Soon")
                                    .font(.system(size: subtitleSize, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, width * 0.06)
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
#Preview {
    let mockStory1 = Story(id: "story-1", order: 1, title: "Cerita 1", subtitle: "Hilangnya Kotak Bekal", description: "", coverAssetName: "", availability: .available, chapters: [], completionSummary: nil)
    let mockStory2 = Story(id: "story-2", order: 2, title: "Cerita 2", subtitle: "Segera Hadir", description: "", coverAssetName: "", availability: .comingSoon, chapters: [], completionSummary: nil)
    let mockStory3 = Story(id: "story-3", order: 3, title: "Cerita 3", subtitle: "Segera Hadir", description: "", coverAssetName: "", availability: .comingSoon, chapters: [], completionSummary: nil)
    
    let viewModel = StorySelectionViewModel(stories: [mockStory1, mockStory2, mockStory3])
    
    NavigationStack {
        StorySelectionView(viewModel: viewModel)
    }
}
