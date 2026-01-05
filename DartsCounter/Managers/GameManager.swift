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
    private var scoreAtVisitStart: Int = 0 // Store score at start of visit for bust recovery
    private var isBotAnimating: Bool = false // Track if bot is currently throwing darts

    @Published var winner: Player?
    @Published var showBustMessage: Bool = false
    @Published var currentDartHits: [DartHit] = [] // For dartboard visualization

    private let soundManager = SoundManager.shared

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

        // Store score at start of visit (first dart)
        if currentVisit.isEmpty {
            scoreAtVisitStart = player.score

            // Announce remaining score at START of turn if on a checkout (≤170)
            if player.score <= 170 && player.score > 1 {
                soundManager.announceRemainingScore(player.score)
            }
        }

        currentVisit.append(score)
        player.dartsThrown += 1

        // Subtract just the individual dart score, not the cumulative total
        let newScore = player.score - score

        // Check for bust (score goes below 0 or to 1, or exactly 0 without double)
        // For simplicity, we'll just check if score goes to 1 or below 0
        if newScore < 0 || newScore == 1 {
            // Bust! Revert the visit
            soundManager.announceBust()
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
            soundManager.announceGameOver(winner: player.name)
            gameState = .gameOver
            return
        }

        // Update score temporarily for display
        player.score = newScore

        // If 3 darts thrown, announce the visit total only
        if currentVisit.count >= 3 {
            let visitTotal = currentVisit.reduce(0, +)

            // Announce the visit total
            soundManager.announceVisitTotal(visitTotal)

            endVisit(busted: false)
        }
    }

    func addVisitTotal(_ visitTotal: Int) {
        guard let player = currentPlayer, !player.hasWon else { return }

        // Clear any existing darts in current visit
        if !currentVisit.isEmpty {
            // Revert any partial visit
            let partial = currentVisit.reduce(0, +)
            player.score += partial
            player.dartsThrown -= currentVisit.count
            currentVisit = []
        }

        // Store score at start of visit
        scoreAtVisitStart = player.score

        // Announce remaining score at START of turn if on a checkout (≤170)
        if player.score <= 170 && player.score > 1 {
            soundManager.announceRemainingScore(player.score)
        }

        let newScore = player.score - visitTotal

        // Check for bust (score goes below 0 or to 1, or exactly 0 without double)
        if newScore < 0 || newScore == 1 {
            // Bust! Revert the visit
            soundManager.announceBust()
            showBustMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showBustMessage = false
            }
            player.visits.append([]) // Record a bust as empty visit
            nextPlayer()
            return
        }

        // Check for win
        if newScore == 0 {
            player.score = 0
            player.hasWon = true
            player.dartsThrown += 3 // Count as 3 darts
            currentVisit = [visitTotal] // Store as single entry for display
            player.visits.append(currentVisit)
            winner = player
            soundManager.announceGameOver(winner: player.name)
            gameState = .gameOver
            return
        }

        // Announce the visit total
        soundManager.announceVisitTotal(visitTotal)

        // Update score and record the visit
        player.score = newScore
        player.dartsThrown += 3 // Always count as 3 darts for a complete visit
        currentVisit = [visitTotal] // Store as single entry for display
        player.visits.append(currentVisit)

        // Move to next player
        nextPlayer()
    }
    
    func endVisit(busted: Bool) {
        guard let player = currentPlayer else { return }

        if busted {
            // Revert to score at start of visit
            player.score = scoreAtVisitStart
            player.visits.append([]) // Record a bust as empty visit
        } else {
            player.visits.append(currentVisit)
        }

        currentVisit = []

        // For bots during animation, don't immediately switch - let the dartboard animation complete
        // The executeBotTurn() function will handle the delay and switch
        if !isBotAnimating {
            nextPlayer()
        }
    }
    
    func undoLastDart() {
        guard let player = currentPlayer, !currentVisit.isEmpty else { return }
        
        let lastScore = currentVisit.removeLast()
        player.score += lastScore
        player.dartsThrown -= 1
    }
    
    func nextPlayer() {
        // Clear dart hits when switching players
        currentDartHits = []

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
        // Convert the same darts to dart hits for visualization (ensures sync)
        let dartHits = darts.map { bot.scoreToDartHit($0) }

        // Clear previous dart hits and mark bot as animating
        currentDartHits = []
        isBotAnimating = true

        // Animate the bot's darts being thrown (1 second between each dart)
        for (index, dart) in darts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) { [weak self] in
                guard let self = self else { return }

                // Check if game is still active and it's still bot's turn
                guard self.gameState == .playing,
                      self.currentPlayer?.id == player.id else {
                    self.isBotAnimating = false
                    return
                }

                // Add dart hit to visualization
                if index < dartHits.count {
                    self.currentDartHits.append(dartHits[index])
                }

                self.addScore(dart)
            }
        }

        // Keep dartboard visible for 1 second after last dart, then switch to next player
        let totalDartTime = Double(darts.count) * 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDartTime + 1.0) { [weak self] in
            guard let self = self else { return }

            // Clear animation flag and switch players
            self.isBotAnimating = false

            // Only switch if still showing this turn's darts and not game over
            if self.currentPlayer?.id == player.id && self.gameState == .playing {
                self.currentDartHits = []
                self.nextPlayer()
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

    // MARK: - Checkout Suggestions (Based on Winmau Checkout Table)
    func getCheckoutSuggestion(for score: Int) -> String? {
        guard score > 0 && score <= 170 else { return nil }

        let checkouts: [Int: String] = [
            // 2 DART FINISHES (41-81)
            41: "9 + D16", 42: "10 + D16", 43: "11 + D16", 44: "12 + D16", 45: "13 + D16",
            46: "6 + D20", 47: "7 + D20", 48: "16 + D16", 49: "17 + D16", 50: "18 + D16",
            51: "19 + D16", 52: "20 + D16", 53: "13 + D20", 54: "14 + D20", 55: "15 + D20",
            56: "16 + D20", 57: "17 + D20", 58: "18 + D20", 59: "19 + D20", 60: "20 + D20",
            61: "T15 + D8", 62: "T10 + D16", 63: "T13 + D12", 64: "T16 + D8", 65: "T19 + D4",
            66: "T14 + D12", 67: "T17 + D8", 68: "T20 + D4", 69: "T19 + D6", 70: "T18 + D8",
            71: "T13 + D16", 72: "T16 + D12", 73: "T19 + D8", 74: "T14 + D16", 75: "T17 + D12",
            76: "T20 + D8", 77: "T19 + D10", 78: "T18 + D12", 79: "T19 + D11", 80: "T20 + D10",
            81: "T19 + D12",

            // 3 DART FINISHES (82-121)
            82: "Bull + D16", 83: "T17 + D16", 84: "T20 + D12", 85: "T15 + D20", 86: "T18 + D16",
            87: "T17 + D18", 88: "T20 + D14", 89: "T19 + D16", 90: "T20 + D15", 91: "T17 + D20",
            92: "T20 + D16", 93: "T19 + D18", 94: "T18 + D20", 95: "T19 + D19", 96: "T20 + D18",
            97: "T19 + D20", 98: "T20 + D19", 99: "T19 + 10 + D16", 100: "T20 + D20",
            101: "T19 + 10 + D16", 102: "T16 + 14 + D20", 103: "T19 + 6 + D20", 104: "T16 + 16 + D20",
            105: "T20 + 13 + D16", 106: "T20 + 6 + D20", 107: "T19 + 10 + D20", 108: "T20 + 16 + D16",
            109: "T20 + 17 + D16", 110: "T20 + 10 + D20", 111: "T19 + 14 + D20", 112: "T20 + 20 + D16",
            113: "T19 + 16 + D20", 114: "T20 + 14 + D20", 115: "T20 + 15 + D20", 116: "T20 + 16 + D20",
            117: "T20 + 17 + D20", 118: "T20 + 18 + D20", 119: "T19 + 12 + Bull", 120: "T20 + 20 + D20",
            121: "T20 + 11 + Bull",

            // 3 DART FINISHES - Higher scores (122-170)
            122: "T18 + 18 + Bull", 123: "T19 + 16 + Bull", 124: "T20 + 14 + Bull", 125: "25 + T20 + D20",
            126: "T19 + 19 + Bull", 127: "T20 + 17 + Bull", 128: "18 + T20 + Bull", 129: "19 + T20 + Bull",
            130: "T20 + 20 + Bull", 131: "T20 + T13 + D16", 132: "25 + T19 + Bull", 133: "T20 + T19 + D8",
            134: "T20 + T14 + D16", 135: "25 + T20 + Bull", 136: "T20 + T20 + D8", 137: "T20 + T19 + D10",
            138: "T20 + T18 + D12", 139: "T19 + T14 + D20", 140: "T20 + T20 + D10", 141: "T20 + T19 + D12",
            142: "T20 + T14 + D20", 143: "T20 + T17 + D16", 144: "T20 + T20 + D12", 145: "T20 + T15 + D20",
            146: "T20 + T18 + D16", 147: "T20 + T17 + D18", 148: "T20 + T20 + D14", 149: "T20 + T19 + D16",
            150: "T20 + T18 + D18", 151: "T20 + T17 + D20", 152: "T20 + T20 + D16", 153: "T20 + T19 + D18",
            154: "T20 + T18 + D20", 155: "T20 + T19 + D19", 156: "T20 + T20 + D18", 157: "T20 + T19 + D20",
            158: "T20 + T20 + D19", 160: "T20 + T20 + D20", 161: "T20 + T17 + Bull", 164: "T20 + T18 + Bull",
            167: "T20 + T19 + Bull", 170: "T20 + T20 + Bull",

            // Direct doubles (2-40)
            2: "D1", 4: "D2", 6: "D3", 8: "D4", 10: "D5", 12: "D6", 14: "D7", 16: "D8", 18: "D9", 20: "D10",
            22: "D11", 24: "D12", 26: "D13", 28: "D14", 30: "D15", 32: "D16", 34: "D17", 36: "D18", 38: "D19", 40: "D20",

            // Odd numbers requiring setup (1-40)
            1: "Cannot finish", 3: "1 + D1", 5: "1 + D2", 7: "3 + D2", 9: "1 + D4", 11: "3 + D4",
            13: "5 + D4", 15: "7 + D4", 17: "1 + D8", 19: "3 + D8", 21: "5 + D8", 23: "7 + D8",
            25: "9 + D8", 27: "11 + D8", 29: "13 + D8", 31: "15 + D8", 33: "1 + D16", 35: "3 + D16",
            37: "5 + D16", 39: "7 + D16"
        ]

        return checkouts[score]
    }
}
