import Foundation
import SwiftUI

// MARK: - Game State
enum GameState {
    case menu
    case modeSelection
    case playerSetup
    case playing
    case gameOver
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var gameMode: GameMode = .fiveOhOne
    @Published var isVsBot: Bool = false
    @Published var botLevel: Int = 6
    
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var currentVisit: [Int] = [] // Current 3-dart visit scores
    
    @Published var winner: Player?
    @Published var showBustMessage: Bool = false
    
    var currentPlayer: Player? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    var otherPlayer: Player? {
        guard players.count == 2 else { return nil }
        return players[1 - currentPlayerIndex]
    }
    
    // MARK: - Navigation
    func goToModeSelection() {
        gameState = .modeSelection
    }
    
    func selectMode(_ mode: GameMode) {
        gameMode = mode
        gameState = .playerSetup
    }
    
    func goBack() {
        switch gameState {
        case .modeSelection:
            gameState = .menu
        case .playerSetup:
            gameState = .modeSelection
        case .playing:
            gameState = .menu
            resetGame()
        case .gameOver:
            gameState = .menu
            resetGame()
        default:
            break
        }
    }
    
    // MARK: - Game Setup
    func startGame(player1Name: String, player2Name: String, vsBot: Bool, botLevel: Int) {
        self.isVsBot = vsBot
        self.botLevel = botLevel
        
        players = [
            Player(name: player1Name.isEmpty ? "Player 1" : player1Name,
                   type: .human,
                   startingScore: gameMode.startingScore)
        ]
        
        if vsBot {
            players.append(
                Player(name: "Bot (Level \(botLevel))",
                       type: .bot(level: botLevel),
                       startingScore: gameMode.startingScore)
            )
        } else {
            players.append(
                Player(name: player2Name.isEmpty ? "Player 2" : player2Name,
                       type: .human,
                       startingScore: gameMode.startingScore)
            )
        }
        
        currentPlayerIndex = 0
        currentVisit = []
        winner = nil
        gameState = .playing
    }
    
    func resetGame() {
        players = []
        currentPlayerIndex = 0
        currentVisit = []
        winner = nil
        showBustMessage = false
    }
    
    func playAgain() {
        for player in players {
            player.reset(startingScore: gameMode.startingScore)
        }
        currentPlayerIndex = 0
        currentVisit = []
        winner = nil
        showBustMessage = false
        gameState = .playing
    }
    
    // MARK: - Scoring
    func addScore(_ score: Int) {
        guard let player = currentPlayer, !player.hasWon else { return }
        
        currentVisit.append(score)
        player.dartsThrown += 1
        
        let visitTotal = currentVisit.reduce(0, +)
        let newScore = player.score - visitTotal
        
        // Check for bust (score goes below 0 or to 1, or exactly 0 without double)
        // For simplicity, we'll just check if score goes to 1 or below 0
        if newScore < 0 || newScore == 1 {
            // Bust! Revert the visit
            showBustMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showBustMessage = false
            }
            endVisit(busted: true)
            return
        }
        
        // Check for win
        if newScore == 0 {
            player.score = 0
            player.hasWon = true
            player.visits.append(currentVisit)
            winner = player
            gameState = .gameOver
            return
        }
        
        // Update score temporarily for display
        player.score = newScore
        
        // If 3 darts thrown, end the visit
        if currentVisit.count >= 3 {
            endVisit(busted: false)
        }
    }
    
    func endVisit(busted: Bool) {
        guard let player = currentPlayer else { return }
        
        if busted {
            // Revert to score before this visit
            let visitTotal = currentVisit.reduce(0, +)
            player.score += visitTotal
            player.visits.append([]) // Record a bust as empty visit
        } else {
            player.visits.append(currentVisit)
        }
        
        currentVisit = []
        nextPlayer()
    }
    
    func undoLastDart() {
        guard let player = currentPlayer, !currentVisit.isEmpty else { return }
        
        let lastScore = currentVisit.removeLast()
        player.score += lastScore
        player.dartsThrown -= 1
    }
    
    func nextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        currentVisit = []
        
        // If next player is a bot, execute their turn
        if let player = currentPlayer, player.type.isBot {
            executeBotTurn()
        }
    }
    
    // MARK: - Bot Logic
    func executeBotTurn() {
        guard let player = currentPlayer,
              case .bot(let level) = player.type else { return }
        
        let bot = BotDifficulty(level: level)
        let darts = bot.generateVisitScore(currentScore: player.score)
        
        // Animate the bot's darts being thrown
        for (index, dart) in darts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) { [weak self] in
                guard let self = self else { return }
                
                // Check if game is still active and it's still bot's turn
                guard self.gameState == .playing,
                      self.currentPlayer?.id == player.id else { return }
                
                self.addScore(dart)
            }
        }
    }
    
    // MARK: - Quick Score Buttons
    var quickScores: [[Int]] {
        [
            [1, 2, 3, 4, 5, 6],
            [7, 8, 9, 10, 11, 12],
            [13, 14, 15, 16, 17, 18],
            [19, 20, 25, 50, 0, -1] // -1 is for "Clear"
        ]
    }
    
    var doubleScores: [Int] {
        [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 32, 36, 40, 50]
    }
    
    var tripleScores: [Int] {
        [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60]
    }
}
