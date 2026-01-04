import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var player1Name: String = ""
    @State private var player2Name: String = ""
    @State private var vsBot: Bool = false
    @State private var botLevel: Int = 6
    
    var body: some View {
        VStack(spacing: 30) {
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
                
                // Mode badge
                Text(gameMode.rawValue)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // Title
            Text("PLAYER SETUP")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Player Type Toggle
            VStack(spacing: 15) {
                Text("Game Type")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 0) {
                    PlayerTypeButton(title: "2 Players", isSelected: !vsBot) {
                        vsBot = false
                    }
                    PlayerTypeButton(title: "vs Bot", isSelected: vsBot) {
                        vsBot = true
                    }
                }
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Player inputs
            VStack(spacing: 20) {
                // Player 1
                PlayerNameInput(
                    title: "Player 1",
                    placeholder: "Enter name",
                    text: $player1Name,
                    icon: "person.fill"
                )
                
                // Player 2 or Bot
                if vsBot {
                    BotLevelSelector(level: $botLevel)
                } else {
                    PlayerNameInput(
                        title: "Player 2",
                        placeholder: "Enter name",
                        text: $player2Name,
                        icon: "person.fill"
                    )
                }
            }
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Start Game Button
            Button(action: {
                gameManager.startGame(
                    player1Name: player1Name,
                    player2Name: player2Name,
                    vsBot: vsBot,
                    botLevel: botLevel
                )
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "target")
                        .font(.title2)
                    Text("START GAME")
                        .font(.title2.bold())
                }
                .foregroundColor(.white)
                .frame(width: 280, height: 60)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: .green.opacity(0.5), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameMode: GameMode {
        gameManager.gameMode
    }
}

struct PlayerTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 140, height: 45)
                .background(
                    isSelected ?
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct PlayerNameInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .frame(width: 25)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct BotLevelSelector: View {
    @Binding var level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.orange)
                Text("Bot Difficulty")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Level \(level)")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            // Level description
            Text(levelDescription)
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
            
            // Slider
            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Slider(value: Binding(
                    get: { Double(level) },
                    set: { level = Int($0) }
                ), in: 1...12, step: 1)
                .accentColor(.orange)
                
                Text("12")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Average display
            HStack {
                Text("Average per visit:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(level * 10)")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    var levelDescription: String {
        switch level {
        case 1...3: return "Beginner - Great for learning"
        case 4...6: return "Intermediate - Casual player"
        case 7...9: return "Advanced - Pub player level"
        case 10...12: return "Expert - Professional level"
        default: return ""
        }
    }
}

#Preview {
    PlayerSetupView()
        .environmentObject(GameManager())
        .frame(width: 800, height: 600)
        .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}
