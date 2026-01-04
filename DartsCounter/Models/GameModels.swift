import Foundation

// MARK: - Game Mode
enum GameMode: String, CaseIterable, Identifiable {
    case threeOhOne = "301"
    case fiveOhOne = "501"
    
    var id: String { rawValue }
    
    var startingScore: Int {
        switch self {
        case .threeOhOne: return 301
        case .fiveOhOne: return 501
        }
    }
}

// MARK: - Player Type
enum PlayerType: Equatable {
    case human
    case bot(level: Int)
    
    var isBot: Bool {
        if case .bot = self { return true }
        return false
    }
    
    var botLevel: Int? {
        if case .bot(let level) = self { return level }
        return nil
    }
}

// MARK: - Bot Difficulty
struct BotDifficulty {
    let level: Int
    
    // Average score per 3-dart visit
    // Level 1 = 10, Level 2 = 20, ..., Level 12 = 120
    var averagePerVisit: Double {
        return Double(level * 10)
    }
    
    // Standard deviation for score variation
    var standardDeviation: Double {
        // Higher levels are more consistent
        return max(5, 30 - Double(level * 2))
    }
    
    // Generate a realistic 3-dart score
    func generateVisitScore(currentScore: Int) -> [Int] {
        var darts: [Int] = []
        var remainingScore = currentScore
        
        for dartIndex in 0..<3 {
            let dartScore = generateSingleDart(
                remainingScore: remainingScore,
                dartsLeft: 3 - dartIndex,
                isLastDart: dartIndex == 2
            )
            darts.append(dartScore)
            remainingScore -= dartScore
            
            // Stop if we've won or busted
            if remainingScore <= 1 && remainingScore != 0 {
                break
            }
            if remainingScore == 0 {
                break
            }
        }
        
        return darts
    }
    
    private func generateSingleDart(remainingScore: Int, dartsLeft: Int, isLastDart: Bool) -> Int {
        // If we can finish, try to finish based on skill level
        if let checkout = getCheckoutScore(for: remainingScore) {
            // Higher level bots are more likely to hit checkouts
            let checkoutProbability = Double(level) * 0.05 // 5% to 60% chance
            if Double.random(in: 0...1) < checkoutProbability {
                return checkout
            }
        }
        
        // Generate a score based on average per dart (average per visit / 3)
        let averagePerDart = averagePerVisit / 3.0
        let variance = standardDeviation / 3.0
        
        // Use normal distribution for realistic scoring
        let score = Int(randomNormal(mean: averagePerDart, standardDeviation: variance))
        let clampedScore = max(0, min(60, score)) // Max single dart is 60 (triple 20)
        
        // Don't bust
        if remainingScore - clampedScore < 0 || remainingScore - clampedScore == 1 {
            // Try to score something safe
            let safeScore = max(0, remainingScore - 2)
            return min(safeScore, clampedScore)
        }
        
        return clampedScore
    }
    
    // Simple checkouts (double to finish)
    private func getCheckoutScore(for score: Int) -> Int? {
        // Only return a checkout if it's a valid double-out
        if score >= 2 && score <= 40 && score % 2 == 0 {
            return score // Double out
        }
        if score == 50 {
            return 50 // Bullseye
        }
        return nil
    }
    
    private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
        // Box-Muller transform
        let u1 = Double.random(in: 0.0001...1)
        let u2 = Double.random(in: 0.0001...1)
        let z = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return z * standardDeviation + mean
    }
}

// MARK: - Player
class Player: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let type: PlayerType
    
    @Published var score: Int
    @Published var dartsThrown: Int = 0
    @Published var visits: [[Int]] = [] // History of 3-dart visits
    @Published var hasWon: Bool = false
    
    init(name: String, type: PlayerType, startingScore: Int) {
        self.name = name
        self.type = type
        self.score = startingScore
    }
    
    var average: Double {
        guard !visits.isEmpty else { return 0 }
        let totalScore = visits.flatMap { $0 }.reduce(0, +)
        return Double(totalScore) / Double(visits.count)
    }
    
    var highestVisit: Int {
        visits.map { $0.reduce(0, +) }.max() ?? 0
    }
    
    func reset(startingScore: Int) {
        score = startingScore
        dartsThrown = 0
        visits = []
        hasWon = false
    }
}

// MARK: - Dart Score
struct DartScore: Identifiable {
    let id = UUID()
    let value: Int
    let multiplier: Int // 1 = single, 2 = double, 3 = triple
    let segment: Int // 1-20, 25 (outer bull), 50 (bullseye)
    
    var displayString: String {
        if segment == 25 { return "25" }
        if segment == 50 { return "BULL" }
        
        switch multiplier {
        case 1: return "\(value)"
        case 2: return "D\(segment)"
        case 3: return "T\(segment)"
        default: return "\(value)"
        }
    }
    
    static let miss = DartScore(value: 0, multiplier: 0, segment: 0)
}
