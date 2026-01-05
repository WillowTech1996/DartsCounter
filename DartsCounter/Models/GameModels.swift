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

    // Generate dart hits with location information for visualization
    func generateVisitDartHits(currentScore: Int) -> [DartHit] {
        let scores = generateVisitScore(currentScore: currentScore)
        return scores.map { score in
            scoreToDartHit(score)
        }
    }

    // Convert a score to a DartHit with segment and multiplier
    func scoreToDartHit(_ score: Int) -> DartHit {
        // Handle special cases
        if score == 50 {
            return DartHit(score: 50, segment: 50, multiplier: 1)
        }
        if score == 25 {
            return DartHit(score: 25, segment: 25, multiplier: 1)
        }
        if score == 0 {
            return DartHit(score: 0, segment: 0, multiplier: 0)
        }

        // Collect all valid ways to score this number
        var validOptions: [(segment: Int, multiplier: Int, probability: Double)] = []

        // Check for valid triples (score must divide by 3, result must be 1-20)
        if score % 3 == 0 {
            let segment = score / 3
            if segment >= 1 && segment <= 20 {
                // Triples are more common for high-value segments
                let probability: Double
                if segment == 20 { probability = 0.5 } // T20 is very common
                else if segment >= 19 { probability = 0.3 } // T19, T18 fairly common
                else if segment >= 15 { probability = 0.2 } // Mid triples less common
                else { probability = 0.1 } // Low triples rare
                validOptions.append((segment: segment, multiplier: 3, probability: probability))
            }
        }

        // Check for valid doubles (score must divide by 2, result must be 1-20)
        if score % 2 == 0 {
            let segment = score / 2
            if segment >= 1 && segment <= 20 {
                // Doubles are less common than singles during general play
                let probability: Double = 0.15
                validOptions.append((segment: segment, multiplier: 2, probability: probability))
            }
        }

        // Check for valid singles (score must be 1-20)
        if score >= 1 && score <= 20 {
            // Singles are most common
            validOptions.append((segment: score, multiplier: 1, probability: 0.5))
        }

        // If we have valid options, choose randomly based on probabilities
        if !validOptions.isEmpty {
            let random = Double.random(in: 0...1)
            var cumulative = 0.0

            for option in validOptions {
                cumulative += option.probability
                if random <= cumulative {
                    return DartHit(score: score, segment: option.segment, multiplier: option.multiplier)
                }
            }

            // Fallback to first option if we didn't hit any probability range
            let option = validOptions[0]
            return DartHit(score: score, segment: option.segment, multiplier: option.multiplier)
        }

        // If no valid options (score > 20 and not divisible by 2 or 3),
        // this is an invalid dart score in real darts, but handle it gracefully
        // Default to showing it as a miss or high single
        return DartHit(score: score, segment: 20, multiplier: 1)
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

        // Generate a target score based on average per dart
        let averagePerDart = averagePerVisit / 3.0
        let variance = standardDeviation / 3.0

        // Use normal distribution for target score
        let targetScore = randomNormal(mean: averagePerDart, standardDeviation: variance)
        let clampedTarget = max(0, min(60, targetScore))

        // Convert target score to a valid dart score
        let dartScore = generateValidDartScore(target: clampedTarget)

        // Don't bust
        if remainingScore - dartScore < 0 || remainingScore - dartScore == 1 {
            // Try to score something safe - aim for a lower score
            let safeTarget = Double(max(0, remainingScore - 2))
            return generateValidDartScore(target: min(safeTarget, clampedTarget))
        }

        return dartScore
    }

    // Generate a valid dart score (single 1-20, double 2-40, triple 3-60, or 25/50)
    private func generateValidDartScore(target: Double) -> Int {
        // List of all possible dart scores with their probabilities based on skill
        // Higher scores are harder to hit

        if target <= 0 {
            return 0 // Miss
        }

        // For very low targets, return singles
        if target <= 5 {
            return max(1, Int(target))
        }

        // Determine what type of score to aim for based on target
        let targetInt = Int(target.rounded())

        // High targets (45+) - aim for triples
        if targetInt >= 45 {
            // T20 (60), T19 (57), T18 (54), etc.
            let segments = [20, 19, 18, 17, 16, 15]
            let segment = segments.randomElement() ?? 20
            return segment * 3
        }

        // Medium-high targets (25-44) - mix of triples and singles
        if targetInt >= 25 {
            if Double.random(in: 0...1) < 0.6 {
                // Try for a triple
                let segments = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10]
                let segment = segments.randomElement() ?? 15
                return min(segment * 3, 60)
            } else {
                // Hit a high single
                let segment = Int.random(in: 15...20)
                return segment
            }
        }

        // Low-medium targets (6-24) - mostly singles, occasional double
        if Double.random(in: 0...1) < 0.15 && targetInt % 2 == 0 && targetInt <= 40 {
            // Occasional double
            return targetInt
        } else {
            // Hit a single
            return min(targetInt, 20)
        }
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
        let z = sqrt(-2.0 * log(u1)) * Darwin.cos(2.0 * .pi * u2)
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

// MARK: - Dart Hit (for visualization)
struct DartHit: Identifiable, Equatable {
    let id = UUID()
    let score: Int
    let segment: Int // 1-20, 25 (outer bull), 50 (bullseye)
    let multiplier: Int // 1 = single, 2 = double, 3 = triple, 0 = miss

    var displayString: String {
        if segment == 50 { return "BULLSEYE!" }
        if segment == 25 { return "25" }
        if multiplier == 0 { return "MISS" }

        switch multiplier {
        case 1: return "\(segment)"
        case 2: return "D\(segment)"
        case 3: return "T\(segment)"
        default: return "\(score)"
        }
    }

    // Equatable conformance - compare by id
    static func == (lhs: DartHit, rhs: DartHit) -> Bool {
        lhs.id == rhs.id
    }
}
