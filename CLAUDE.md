# CLAUDE.md - Darts Counter Project Context

> This file provides context for Claude Code. It will be read automatically when you start a session in this directory.

## Quick Reference

```bash
# Build the project
xcodebuild -project DartsCounter.xcodeproj -scheme DartsCounter -configuration Debug build

# Build and show errors only
xcodebuild -project DartsCounter.xcodeproj -scheme DartsCounter -configuration Debug build 2>&1 | grep -E "(error:|warning:|BUILD)"

# Clean build
xcodebuild -project DartsCounter.xcodeproj -scheme DartsCounter clean build

# Open in Xcode
open DartsCounter.xcodeproj
```

## Project Overview

**App**: Darts Counter - a native macOS darts scoring application  
**Version**: 0.1.0  
**Platform**: macOS 14.0+ (Sonoma)  
**Framework**: SwiftUI  
**Language**: Swift 5.9+  

### What It Does
- 301 and 501 dart games
- Two-player local multiplayer OR single player vs bot
- Bot has 12 difficulty levels (Level N = ~N×10 average per visit)
- Tracks statistics: average, darts thrown, best visit
- Enforces standard rules: double-out required, bust detection

## Architecture

### File Structure
```
DartsCounter/
├── DartsCounter.xcodeproj/          # Xcode project
├── DartsCounter/
│   ├── DartsCounterApp.swift        # @main entry point
│   ├── Models/
│   │   └── GameModels.swift         # GameMode, Player, PlayerType, BotDifficulty, DartScore
│   ├── Managers/
│   │   └── GameManager.swift        # GameState, all game logic, scoring
│   └── Views/
│       ├── ContentView.swift        # Root view - routes based on GameState
│       ├── MainMenuView.swift       # Landing screen with PLAY button
│       ├── ModeSelectionView.swift  # Choose 301 or 501
│       ├── PlayerSetupView.swift    # Player names, bot toggle, bot level
│       ├── GameView.swift           # Main gameplay UI (largest file)
│       └── GameOverView.swift       # Winner screen, stats, play again
├── CLAUDE.md                        # This file
├── CHANGELOG.md                     # Version history
└── README.md                        # User documentation
```

### Key Types

| Type | File | Role |
|------|------|------|
| `GameManager` | Managers/GameManager.swift | **Central state manager** - injected via `@EnvironmentObject` |
| `GameState` | Managers/GameManager.swift | Enum: `.menu`, `.modeSelection`, `.playerSetup`, `.playing`, `.gameOver` |
| `GameMode` | Models/GameModels.swift | Enum: `.threeOhOne`, `.fiveOhOne` |
| `Player` | Models/GameModels.swift | ObservableObject - score, visits, dartsThrown, average |
| `PlayerType` | Models/GameModels.swift | Enum: `.human`, `.bot(level: Int)` |
| `BotDifficulty` | Models/GameModels.swift | Bot AI - generates realistic scores using normal distribution |

### State Flow
```
MainMenuView → ModeSelectionView → PlayerSetupView → GameView ↔ GameOverView
     ↑                ↑                   ↑              ↓           ↓
     └────────────────┴───────────────────┴──────────────┴───────────┘
                                    (goBack / resetGame)
```

### State Management Pattern
- `GameManager` is created once in `DartsCounterApp.swift`
- Injected via `.environmentObject(gameManager)`
- All views access via `@EnvironmentObject var gameManager: GameManager`
- Views call methods on `gameManager` to trigger state changes

## Code Style

### Swift Conventions
- Use `// MARK: - Section Name` for organisation
- Prefer `guard` for early returns
- Use trailing closure syntax
- Extract subviews when a view exceeds ~50 lines

### Naming
- Views: `SomethingView.swift`
- Managers: `SomethingManager.swift`  
- Models: Descriptive nouns (`Player`, `GameMode`)

### Commit Messages
Format: `type: description`

Types:
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code change that doesn't add features or fix bugs
- `docs:` documentation only
- `style:` formatting, no code change

## Current State (v0.1.0)

### Working Features ✅
- 301 and 501 game modes
- Two-player local multiplayer
- Bot opponent (12 levels, ~10-120 average)
- Singles/Doubles/Triples scoring tabs
- Real-time statistics display
- Visit history per player
- Undo last dart
- Manual "Next" to end turn early
- Bust detection with overlay
- Game over screen with play again

### Known Issues 🐛
None currently tracked

### Not Yet Implemented
- Checkout suggestions
- Sound effects
- Statistics persistence
- Additional game modes (Cricket, Around the Clock)

## Roadmap

### Priority 1 - Next Up
- [ ] Checkout suggestions for scores ≤170
- [ ] Improve bot checkout accuracy

### Priority 2 - Soon
- [ ] Sound effects (dart throw, bust, checkout, 180)
- [ ] Persist statistics with SwiftData or UserDefaults

### Priority 3 - Later
- [ ] Cricket game mode
- [ ] Around the Clock mode
- [ ] Visual dartboard input option
- [ ] Match play (best of X legs)

## Common Tasks

### Adding a New View
1. Create `NewView.swift` in `DartsCounter/Views/`
2. Add `@EnvironmentObject var gameManager: GameManager`
3. Add new case to `GameState` if needed
4. Add routing in `ContentView.swift`

### Adding a New Game Mode
1. Add case to `GameMode` enum in `GameModels.swift`
2. Update `startingScore` computed property
3. Add selection UI in `ModeSelectionView.swift`
4. Handle any mode-specific rules in `GameManager`

### Modifying Bot Behaviour
All bot logic is in `BotDifficulty` struct in `GameModels.swift`:
- `averagePerVisit` - target score per 3 darts
- `standardDeviation` - consistency (lower = more consistent)
- `generateVisitScore()` - main scoring algorithm
- `getCheckoutScore()` - checkout detection

## Session Log

### Session 1 (2025-01-04)
- Initial project creation
- All core features implemented
- Git repo initialised, tagged v0.1.0
- Pushed to GitHub
