import SwiftUI

struct ChapterSelectionView: View {
    @ObservedObject var viewModel: ChapterSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var virtualIndex: Int = 1000
    
    var body: some View {
        GeometryReader { fullScreenGeo in
            let screenWidth = fullScreenGeo.size.width
            let screenHeight = fullScreenGeo.size.height
            
            let nodeDiameter = screenWidth * 0.24
            let titleBoxWidth = nodeDiameter * 1.15
            let titleBoxHeight = screenHeight * 0.12
            
            let startPointY = screenHeight * 0.8
            let peakPointY = screenHeight * 0.5
            let controlPointY = peakPointY - (startPointY - peakPointY)
            
            ZStack {
                Color(red: 0.937, green: 0.953, blue: 0.957)
                    .ignoresSafeArea()
                
                Image(systemName: "square.dashed")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: screenHeight)
                    .foregroundColor(Color.gray.opacity(0.025))
                    .ignoresSafeArea()
                
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
                            let currentYPosition = baseCurveY + (nodeDiameter * 0.20)
                            
                            let calculatedOpacity = offset == 0 ? 1.0 : 0.85
                            
                            VStack(spacing: screenHeight * 0.02) {
                                ZStack(alignment: .top) {
                                    Circle()
                                        .fill(Color(red: 0.0, green: 0.227, blue: 0.655))
                                        .frame(width: nodeDiameter, height: nodeDiameter)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                        
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gray.opacity(0.5))
                                            .frame(width: nodeDiameter * 0.5, height: nodeDiameter * 0.5)
                                    }
                                    .frame(width: nodeDiameter * 0.93, height: nodeDiameter * 0.93)
                                    .offset(x: 0, y: (nodeDiameter * 0.07) / 2)
                                    .clipShape(Circle())
                                    
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
                                    
                                    HStack(spacing: 6) {
                                        ForEach(0..<3) { starIndex in
                                            Image(systemName: starIndex < selectionItem.bestStars ? "star.fill" : "star")
                                                .font(.system(size: screenWidth * 0.024, weight: .bold))
                                                .foregroundColor(Color(red: 0.0, green: 0.227, blue: 0.655))
                                        }
                                    }
                                    .offset(y: -screenHeight * 0.07)
                                    .opacity(selectionItem.isUnlocked ? 1 : 0)
                                }
                                .onTapGesture {
                                    if selectionItem.isUnlocked {
                                        viewModel.selectChapter(selectionItem.chapter)
                                    }
                                }
                                
                                VStack(spacing: 4) {
                                    Text("Bab \(selectionItem.chapter.order)")
                                        .font(.system(size: screenWidth * 0.016, weight: .bold, design: .default))
                                        .foregroundColor(.black)
                                    
                                    Text(selectionItem.chapter.title)
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
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func determineModularIndex(_ index: Int, total: Int) -> Int {
        let remainder = index % total
        return remainder >= 0 ? remainder : remainder + total
    }
    
    private func widthClamp(_ value: CGFloat) -> CGFloat {
        return max(value, 4.0)
    }
}

struct ChapterSelectionPreviewContainer: View {
    let viewModel: ChapterSelectionViewModel
    
    init() {
        let titles = [
            "Bentuk Membantu Mika di Kelas",
            "Ikuti Tanda di Lorong Sekolah",
            "Cahaya Kecil di Loker Gelap",
            "Pola Rahasia di Taman Bermain",
            "Misi Besar di Kantin Sekolah"
        ]
        
        let mockChapters = (1...5).map { index -> Chapter in
            Chapter(
                id: "chapter-\(index)",
                order: index,
                title: titles[index - 1],
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
                gameConfiguration: GameConfiguration(question: GameQuestion(id: "q\(index)", prompt: "", promptImageAssetName: nil, answerOptions: [], correctAnswerID: "", hintText: "")),
                learningSummary: LearningSummary(successMessage: "", explanation: "", mainIllustrationAssetName: "", exampleAssetNames: [])
            )
        }
        let mockStory = Story(id: "story-1", order: 1, title: "Cerita 1", subtitle: "Hilangnya Kotak Bekal", description: "", coverAssetName: "", availability: .available, chapters: mockChapters, completionSummary: nil)
        
        let previewSuiteName = "owlLala.preview.suite.\(UUID().uuidString)"
        let volatileDefaults = UserDefaults(suiteName: previewSuiteName) ?? .standard
        let storage = StorageService(firstChapterID: "chapter-1", userDefaults: volatileDefaults)
        
        self.viewModel = ChapterSelectionViewModel(story: mockStory, storageService: storage)
    }
    
    var body: some View {
        NavigationStack {
            ChapterSelectionView(viewModel: viewModel)
        }
    }
}

#Preview {
    ChapterSelectionPreviewContainer()
}
