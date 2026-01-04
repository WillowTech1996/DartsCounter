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

        // Store score at start of visit (first dart)
        if currentVisit.isEmpty {
            scoreAtVisitStart = player.score
        }

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

        let newScore = player.score - visitTotal

        // Check for bust (score goes below 0 or to 1, or exactly 0 without double)
        if newScore < 0 || newScore == 1 {
            // Bust! Revert the visit
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
            gameState = .gameOver
            return
        }

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

    // MARK: - Checkout Suggestions
    func getCheckoutSuggestion(for score: Int) -> String? {
        guard score > 0 && score <= 170 else { return nil }

        let checkouts: [Int: String] = [
            2: "D1", 4: "D2", 6: "D3", 8: "D4", 10: "D5",
            12: "D6", 14: "D7", 16: "D8", 18: "D9", 20: "D10",
            22: "D11", 24: "D12", 26: "D13", 28: "D14", 30: "D15",
            32: "D16", 34: "D17", 36: "D18", 38: "D19", 40: "D20",

            // 41-50
            41: "9 → D16", 42: "10 → D16", 43: "11 → D16", 44: "12 → D16",
            45: "13 → D16", 46: "6 → D20", 47: "15 → D16", 48: "16 → D16",
            49: "17 → D16", 50: "10 → D20 or BULLSEYE!",

            // 51-60
            51: "11 → D20", 52: "12 → D20", 53: "13 → D20", 54: "14 → D20",
            55: "15 → D20", 56: "16 → D20", 57: "17 → D20", 58: "18 → D20",
            59: "19 → D20", 60: "20 → D20",

            // 61-70
            61: "25 → D18", 62: "10 → D26 or 14 → BULLSEYE!", 63: "13 → D25", 64: "16 → D24 or T16 → D8",
            65: "25 → D20 or 19 → D23", 66: "10 → D28 or 16 → D25", 67: "17 → D25 or 9 → D29",
            68: "18 → D25 or 16 → D26", 69: "19 → D25", 70: "18 → D26 or 10 → D30",

            // 71-80
            71: "13 → D29 or 11 → D30", 72: "12 → D30 or 16 → D28", 73: "13 → D30 or 17 → D28",
            74: "14 → D30 or T14 → D16", 75: "17 → D29 or 25 → BULLSEYE!", 76: "16 → D30 or T20 → D8",
            77: "15 → D31 or 19 → D29", 78: "18 → D30 or T18 → D12", 79: "13 → D33 or 19 → D30",
            80: "20 → D30 or T20 → D10",

            // 81-90
            81: "19 → D31 or T15 → D18", 82: "14 → D34 or BULLSEYE! → D16", 83: "17 → D33 or T17 → D16",
            84: "20 → D32 or T20 → D12", 85: "15 → D35 or T15 → D20", 86: "18 → D34 or T18 → D16",
            87: "17 → D35 or T17 → D18", 88: "16 → D36 or T20 → D14", 89: "19 → D35 or T19 → D16",
            90: "18 → D36 or T20 → D15",

            // 91-100
            91: "17 → D37 or T17 → D20", 92: "20 → D36 or T20 → D16", 93: "19 → D37 or T19 → D18",
            94: "18 → D38 or T18 → D20", 95: "19 → D38 or T19 → D19", 96: "20 → D38 or T20 → D18",
            97: "19 → D39 or T19 → D20", 98: "18 → D40 or T20 → D19", 99: "19 → D40 or T19 → 10 → D16",
            100: "20 → D40 or T20 → D20",

            // 101-110
            101: "T17 → BULLSEYE! or 17 → D42", 102: "T20 → D21", 103: "T19 → D23 or 19 → D42",
            104: "T18 → BULLSEYE! or T20 → D22", 105: "T19 → D24 or T20 → 5 → D20", 106: "T20 → D23",
            107: "T19 → BULLSEYE! or T19 → 10 → D20", 108: "T20 → D24", 109: "T20 → 9 → D20 or T19 → D26",
            110: "T20 → BULLSEYE! or T20 → 10 → D20",

            // 111-120
            111: "T19 → 14 → D20 or T20 → 11 → D20", 112: "T20 → D26", 113: "T19 → 16 → D20 or T20 → 13 → D20",
            114: "T20 → 14 → D20 or T19 → 17 → D20", 115: "T19 → 18 → D20 or T20 → 15 → D20", 116: "T20 → 16 → D20",
            117: "T19 → 20 → D20 or T20 → 17 → D20", 118: "T20 → 18 → D20", 119: "T19 → 12 → BULLSEYE! or T20 → 19 → D20",
            120: "T20 → 20 → D20",

            // 121-130
            121: "T17 → T18 → D5 or T20 → 11 → D25", 122: "T18 → 18 → D20 or T20 → 12 → D25", 123: "T19 → 16 → D25",
            124: "T20 → 14 → D25 or T20 → 14 → BULLSEYE!", 125: "T18 → 19 → BULLSEYE! or 25 → T20 → D20", 126: "T19 → 19 → D25",
            127: "T20 → 17 → D25 or T17 → 16 → D20", 128: "T18 → 14 → D20 or T20 → 18 → D25", 129: "T19 → 12 → D30 or T20 → 19 → D25",
            130: "T20 → 20 → D25 or T20 → BULLSEYE! → D10",

            // 131-140
            131: "T20 → 11 → D30 or T19 → 14 → D30", 132: "BULLSEYE! → BULLSEYE! → D16", 133: "T20 → 13 → D30",
            134: "T20 → 14 → D30", 135: "BULLSEYE! → T17 → D20 or T20 → 15 → D30", 136: "T20 → 16 → D30",
            137: "T20 → 17 → D30", 138: "T20 → 18 → D30", 139: "T20 → 19 → D30", 140: "T20 → 20 → D30",

            // 141-150
            141: "T20 → T19 → D12", 142: "T20 → T14 → D20 or T20 → 12 → BULLSEYE! → D8", 143: "T20 → T17 → D16",
            144: "T20 → T20 → D12", 145: "T20 → T19 → D14", 146: "T20 → T18 → D16", 147: "T20 → T17 → D18",
            148: "T20 → T20 → D14", 149: "T20 → T19 → D16", 150: "T20 → T18 → D18",

            // 151-160
            151: "T20 → T17 → D20", 152: "T20 → T20 → D16", 153: "T20 → T19 → D18", 154: "T20 → T18 → D20",
            155: "T20 → T19 → D19", 156: "T20 → T20 → D18", 157: "T20 → T19 → D20", 158: "T20 → T20 → D19",
            159: "T20 → T19 → 12 → D15", 160: "T20 → T20 → D20",

            // 161-170
            161: "T20 → T17 → BULLSEYE!", 162: "T20 → T20 → 12 → D15", 163: "T20 → T19 → 16 → D15",
            164: "T20 → T18 → BULLSEYE! or T19 → T19 → D20", 165: "T20 → T19 → 18 → D15", 166: "T20 → T20 → 16 → D15",
            167: "T20 → T19 → BULLSEYE!", 168: "T20 → T20 → 18 → D15", 169: "T20 → T19 → 12 → D20",
            170: "T20 → T20 → BULLSEYE!"
        ]

        return checkouts[score]
    }
}
