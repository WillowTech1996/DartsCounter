import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var hoveredMode: GameMode?
    
    var body: some View {
        VStack(spacing: 40) {
            // Header with back button
            HStack {
                Button(action: {
                    gameManager.goBack()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // Title
            VStack(spacing: 10) {
                Text("SELECT MODE")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose your game type")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            // Mode buttons
            HStack(spacing: 40) {
                ForEach(GameMode.allCases) { mode in
                    ModeCard(mode: mode, isHovered: hoveredMode == mode) {
                        gameManager.selectMode(mode)
                    }
                    .onHover { isHovered in
                        hoveredMode = isHovered ? mode : nil
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModeCard: View {
    let mode: GameMode
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Score display
                Text(mode.rawValue)
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                // Decorative dartboard
                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Description
                Text("Starting Score")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(width: 200, height: 250)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isHovered ? 0.15 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isHovered ?
                                    LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: isHovered ? .red.opacity(0.3) : .clear, radius: 20)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModeSelectionView()
        .environmentObject(GameManager())
        .frame(width: 800, height: 600)
        .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}
