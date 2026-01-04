import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.12, blue: 0.15),
                    Color(red: 0.05, green: 0.08, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content based on game state
            switch gameManager.gameState {
            case .menu:
                MainMenuView()
                    .transition(.opacity)
            case .modeSelection:
                ModeSelectionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            case .playerSetup:
                PlayerSetupView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            case .playing:
                GameView()
                    .transition(.opacity)
            case .gameOver:
                GameOverView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameManager.gameState)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
