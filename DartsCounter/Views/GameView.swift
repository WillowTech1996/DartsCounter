import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showScoreInput: Bool = false
    @State private var customScore: String = ""
    @State private var keyboardBuffer: String = ""
    @FocusState private var isGameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            GameHeader()

            // Main content
            HStack(spacing: 0) {
                // Player 1 Score Panel
                if let player1 = gameManager.players.first {
                    PlayerScorePanel(
                        player: player1,
                        isActive: gameManager.currentPlayerIndex == 0
                    )
                }

                // Center - Scoring Area
                CenterScoringArea(
                    showScoreInput: $showScoreInput,
                    customScore: $customScore,
                    keyboardBuffer: $keyboardBuffer
                )

                // Player 2 Score Panel
                if gameManager.players.count > 1 {
                    PlayerScorePanel(
                        player: gameManager.players[1],
                        isActive: gameManager.currentPlayerIndex == 1
                    )
                }
            }
        }
        .focusable()
        .focused($isGameFocused)
        .onAppear {
            isGameFocused = true
        }
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
        .overlay {
            // Bust message overlay
            if gameManager.showBustMessage {
                BustOverlay()
            }
        }
    }

    // MARK: - Keyboard Handling
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Only handle input for human players
        guard let currentPlayer = gameManager.currentPlayer,
              !currentPlayer.type.isBot else {
            return .ignored
        }

        let char = keyPress.characters

        // Handle backspace/delete (check character first, as key enum might not work)
        if char == "\u{7F}" || char == "\u{08}" || keyPress.key == .delete || keyPress.key == .deleteForward {
            if !keyboardBuffer.isEmpty {
                keyboardBuffer.removeLast()
            }
            return .handled
        }

        // Handle number input
        if let digit = Int(char), digit >= 0 && digit <= 9 {
            keyboardBuffer.append(char)

            // Check if we should auto-submit
            if shouldAutoSubmit(buffer: keyboardBuffer) {
                submitScore()
            }
            return .handled
        }

        // Handle enter/return to force submit
        if char == "\r" || char == "\n" || keyPress.key == .return {
            submitScore()
            return .handled
        }

        // Handle escape to clear buffer
        if char == "\u{1B}" || keyPress.key == .escape {
            keyboardBuffer = ""
            return .handled
        }

        return .ignored
    }

    private func shouldAutoSubmit(buffer: String) -> Bool {
        guard let score = Int(buffer) else { return false }

        // If score is already at max (180), submit immediately
        if score >= 180 { return true }

        // If buffer is 3 digits, submit
        if buffer.count >= 3 { return true }

        // Check if any valid score could start with this buffer
        // Valid scores: 0-180
        let nextPossibleMin = score * 10

        // If the minimum possible next value would exceed 180, submit now
        if nextPossibleMin > 180 { return true }

        return false
    }

    private func submitScore() {
        guard let visitTotal = Int(keyboardBuffer), visitTotal >= 0 && visitTotal <= 180 else {
            keyboardBuffer = ""
            return
        }

        gameManager.addVisitTotal(visitTotal)
        keyboardBuffer = ""
    }
}

// MARK: - Game Header
struct GameHeader: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            // Back button
            Button(action: {
                gameManager.goBack()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                    Text("Quit")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Game mode
            Text(gameManager.gameMode.rawValue)
                .font(.title.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            // Current visit display
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    DartIndicator(
                        score: index < gameManager.currentVisit.count ? gameManager.currentVisit[index] : nil,
                        isActive: index == gameManager.currentVisit.count
                    )
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .background(Color.black.opacity(0.3))
    }
}

struct DartIndicator: View {
    let score: Int?
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(score != nil ? Color.orange : Color.white.opacity(0.1))
                .frame(width: 35, height: 35)
            
            if let score = score {
                Text("\(score)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            } else if isActive {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 35, height: 35)
            }
        }
    }
}

// MARK: - Player Score Panel
struct PlayerScorePanel: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var player: Player
    let isActive: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Player name and indicator
            HStack {
                if player.type.isBot {
                    Image(systemName: "cpu")
                        .foregroundColor(.orange)
                }
                Text(player.name)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(isActive ? Color.orange : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Score
            Text("\(player.score)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundColor(isActive ? .white : .gray)
                .animation(.spring(response: 0.3), value: player.score)

            // Checkout suggestion
            if let checkout = gameManager.getCheckoutSuggestion(for: player.score) {
                VStack(spacing: 4) {
                    Text("CHECKOUT")
                        .font(.caption2.bold())
                        .foregroundColor(.green.opacity(0.8))
                    Text(checkout)
                        .font(.caption.bold())
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.scale.combined(with: .opacity))
            }

            // Stats
            VStack(spacing: 8) {
                StatRow(label: "Average", value: String(format: "%.1f", player.average))
                StatRow(label: "Darts", value: "\(player.dartsThrown)")
                StatRow(label: "Best Visit", value: "\(player.highestVisit)")
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()
            
            // Recent visits
            if !player.visits.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ForEach(player.visits.suffix(5).reversed(), id: \.self) { visit in
                        let total = visit.reduce(0, +)
                        Text(total == 0 ? "BUST" : "\(total)")
                            .font(.caption)
                            .foregroundColor(total == 0 ? .red : .white.opacity(0.6))
                    }
                }
            }
        }
        .frame(width: 200)
        .padding(.vertical, 30)
        .background(
            isActive ?
                Color.white.opacity(0.05) :
                Color.clear
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

// MARK: - Center Scoring Area
struct CenterScoringArea: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var showScoreInput: Bool
    @Binding var customScore: String
    @Binding var keyboardBuffer: String
    @State private var selectedTab: ScoreTab = .singles

    enum ScoreTab: String, CaseIterable {
        case singles = "Singles"
        case doubles = "Doubles"
        case triples = "Triples"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Show dartboard when bot is playing, otherwise show visit total
            Group {
                if let currentPlayer = gameManager.currentPlayer, currentPlayer.type.isBot && !gameManager.currentDartHits.isEmpty {
                    VStack(spacing: 15) {
                        Text("\(currentPlayer.name) is throwing...")
                            .font(.title2.bold())
                            .foregroundColor(.orange)

                        HStack(spacing: 30) {
                            // Dartboard on the left
                            DartboardView(dartHits: gameManager.currentDartHits, size: 220)
                                .frame(width: 250, height: 250)

                            // Dart scores on the right
                            VStack(spacing: 15) {
                                ForEach(Array(gameManager.currentDartHits.enumerated()), id: \.element.id) { index, hit in
                                    HStack(spacing: 15) {
                                        // Dart number circle
                                        ZStack {
                                            Circle()
                                                .fill(dartColor(index + 1))
                                                .frame(width: 40, height: 40)
                                            Text("\(index + 1)")
                                                .font(.title3.bold())
                                                .foregroundColor(.white)
                                        }

                                        // Dart score and description
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(hit.displayString)
                                                .font(.title.bold())
                                                .foregroundColor(.white)
                                            Text("\(hit.score) points")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            }
                            .frame(width: 220)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Current visit total and keyboard buffer
                    VStack(spacing: 5) {
                        Text("Visit Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameManager.currentVisit.reduce(0, +))")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        // Keyboard input buffer display
                        if !keyboardBuffer.isEmpty {
                            VStack(spacing: 2) {
                                Text("Typing Visit Total")
                                    .font(.caption2)
                                    .foregroundColor(.blue.opacity(0.8))
                                HStack(spacing: 4) {
                                    Image(systemName: "keyboard")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(keyboardBuffer)
                                        .font(.title2.bold())
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .animation(.spring(response: 0.3), value: keyboardBuffer)

            // Score entry tabs
            Picker("Score Type", selection: $selectedTab) {
                ForEach(ScoreTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 350)
            
            // Score buttons based on tab
            ScrollView {
                switch selectedTab {
                case .singles:
                    SinglesGrid()
                case .doubles:
                    DoublesGrid()
                case .triples:
                    TriplesGrid()
                }
            }
            .frame(maxHeight: 280)
            
            // Action buttons
            HStack(spacing: 15) {
                // Undo button
                Button(action: {
                    gameManager.undoLastDart()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 45)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(gameManager.currentVisit.isEmpty)
                .opacity(gameManager.currentVisit.isEmpty ? 0.5 : 1)
                
                // Next Player button (force end visit)
                Button(action: {
                    gameManager.endVisit(busted: false)
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 45)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    func dartColor(_ dartNumber: Int) -> Color {
        switch dartNumber {
        case 1: return .yellow
        case 2: return .cyan
        case 3: return .purple
        default: return .orange
        }
    }
}

// MARK: - Score Grids
struct SinglesGrid: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    let scores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25, 50, 0]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(scores, id: \.self) { score in
                ScoreButton(score: score, label: scoreLabel(score), color: scoreColor(score)) {
                    gameManager.addScore(score)
                }
            }
        }
        .padding(.horizontal)
    }
    
    func scoreLabel(_ score: Int) -> String {
        if score == 25 { return "25" }
        if score == 50 { return "BULLSEYE!" }
        if score == 0 { return "MISS" }
        return "\(score)"
    }
    
    func scoreColor(_ score: Int) -> Color {
        if score == 50 { return .red }
        if score == 25 { return .green }
        if score == 0 { return .gray }
        return .orange
    }
}

struct DoublesGrid: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    let baseScores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(baseScores, id: \.self) { base in
                ScoreButton(score: base * 2, label: "D\(base)", color: .green) {
                    gameManager.addScore(base * 2)
                }
            }
            // Bullseye (D25)
            ScoreButton(score: 50, label: "BULLSEYE!", color: .red) {
                gameManager.addScore(50)
            }
        }
        .padding(.horizontal)
    }
}

struct TriplesGrid: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    let baseScores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(baseScores, id: \.self) { base in
                ScoreButton(score: base * 3, label: "T\(base)", color: .purple) {
                    gameManager.addScore(base * 3)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ScoreButton: View {
    let score: Int
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(color.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }) {}
    }
}

// MARK: - Bust Overlay
struct BustOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("BUST!")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundColor(.red)
                
                Text("Score reverted")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    let manager = GameManager()
    manager.startGame(player1Name: "Jacob", player2Name: "", vsBot: true, botLevel: 6)
    
    return GameView()
        .environmentObject(manager)
        .frame(width: 1000, height: 700)
        .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}
