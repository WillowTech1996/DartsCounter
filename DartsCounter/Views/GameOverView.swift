import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 20)
            
            // Winner announcement
            VStack(spacing: 15) {
                Text("WINNER!")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                if let winner = gameManager.winner {
                    HStack {
                        if winner.type.isBot {
                            Image(systemName: "cpu")
                                .font(.title)
                        }
                        Text(winner.name)
                            .font(.system(size: 35, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                }
            }
            
            // Game stats
            if let player1 = gameManager.players.first,
               let player2 = gameManager.players.last {
                HStack(spacing: 50) {
                    PlayerStatCard(player: player1, isWinner: player1.hasWon)
                    
                    Text("VS")
                        .font(.title.bold())
                        .foregroundColor(.gray)
                    
                    PlayerStatCard(player: player2, isWinner: player2.hasWon)
                }
                .padding(.top, 20)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    gameManager.playAgain()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 180, height: 55)
                    .background(
                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    gameManager.goBack()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "house")
                        Text("Main Menu")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 180, height: 55)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PlayerStatCard: View {
    @ObservedObject var player: Player
    let isWinner: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Player name
            HStack {
                if player.type.isBot {
                    Image(systemName: "cpu")
                }
                Text(player.name)
                    .font(.headline)
            }
            .foregroundColor(isWinner ? .orange : .gray)
            
            // Final score
            Text("\(player.score)")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .foregroundColor(isWinner ? .green : .white)
            
            // Stats
            VStack(spacing: 8) {
                HStack {
                    Text("Average")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f", player.average))
                        .foregroundColor(.white)
                        .bold()
                }
                
                HStack {
                    Text("Darts Thrown")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(player.dartsThrown)")
                        .foregroundColor(.white)
                        .bold()
                }
                
                HStack {
                    Text("Best Visit")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(player.highestVisit)")
                        .foregroundColor(.white)
                        .bold()
                }
                
                HStack {
                    Text("Visits")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(player.visits.count)")
                        .foregroundColor(.white)
                        .bold()
                }
            }
            .font(.subheadline)
        }
        .padding(25)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isWinner ? Color.orange : Color.clear, lineWidth: 2)
                )
        )
    }
}

#Preview {
    let manager = GameManager()
    manager.startGame(player1Name: "Jacob", player2Name: "", vsBot: true, botLevel: 6)
    manager.winner = manager.players.first
    manager.players.first?.hasWon = true
    manager.players.first?.score = 0
    manager.gameState = .gameOver
    
    return GameOverView()
        .environmentObject(manager)
        .frame(width: 1000, height: 700)
        .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}
