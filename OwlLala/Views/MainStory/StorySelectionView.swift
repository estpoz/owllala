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
            ZStack(alignment: .bottom) {
                // Changing to .scaledToFit prevents image cropping on the bottom/top edges
                Image("storyCover\(item.story.order)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: width * 0.08))
                    .opacity(item.isAvailable ? 1.0 : 0.6)
                
                // Overlay Text Layer
                if item.isAvailable {
                    VStack(spacing: 0) {
                        Spacer()
                        Text(item.story.title)
                            .font(.system(size: titleSize, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .underline()
                            .lineLimit(1)
                            .padding(.horizontal, width * 0.08)
                            .padding(.bottom, height * 0.27)
                    }
                    .frame(width: width, height: height)
                    
                } else {
                    VStack(spacing: 4) {
                        Spacer()
                        Text(item.story.title)
                            .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        Text("Coming Soon")
                            .font(.system(size: subtitleSize, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, width * 0.06)
                    .padding(.bottom, height * 0.21)
                    .frame(width: width, height: height)
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
