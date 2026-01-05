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
**Version**: 1.0.2
**Platform**: macOS 14.0+ (Sonoma)
**Framework**: SwiftUI
**Language**: Swift 5.9+

### What It Does
- 301 and 501 dart games
- Two-player local multiplayer OR single player vs bot
- Bot has 12 difficulty levels (Level N = ~N×10 average per visit)
- Visual dartboard showing bot dart hits with animations
- Sound effects for 180 announcements (MP3 playback)
- Checkout suggestions based on Winmau checkout table
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
│   │   └── GameModels.swift         # GameMode, Player, PlayerType, BotDifficulty, DartScore, DartHit
│   ├── Managers/
│   │   ├── GameManager.swift        # GameState, all game logic, scoring
│   │   └── SoundManager.swift       # Audio playback with AVAudioPlayer
│   ├── Sounds/
│   │   └── 180.mp3                  # 180 announcement audio
│   └── Views/
│       ├── ContentView.swift        # Root view - routes based on GameState
│       ├── MainMenuView.swift       # Landing screen with PLAY button
│       ├── ModeSelectionView.swift  # Choose 301 or 501
│       ├── PlayerSetupView.swift    # Player names, bot toggle, bot level
│       ├── GameView.swift           # Main gameplay UI (largest file)
│       ├── GameOverView.swift       # Winner screen, stats, play again
│       └── DartboardView.swift      # Visual dartboard with dart hit display
├── CLAUDE.md                        # This file
├── CHANGELOG.md                     # Version history
└── README.md                        # User documentation
```

### Key Types

| Type | File | Role |
|------|------|------|
| `GameManager` | Managers/GameManager.swift | **Central state manager** - injected via `@EnvironmentObject` |
| `SoundManager` | Managers/SoundManager.swift | Audio playback manager - MP3 sound effects |
| `GameState` | Managers/GameManager.swift | Enum: `.menu`, `.modeSelection`, `.playerSetup`, `.playing`, `.gameOver` |
| `GameMode` | Models/GameModels.swift | Enum: `.threeOhOne`, `.fiveOhOne` |
| `Player` | Models/GameModels.swift | ObservableObject - score, visits, dartsThrown, average |
| `PlayerType` | Models/GameModels.swift | Enum: `.human`, `.bot(level: Int)` |
| `BotDifficulty` | Models/GameModels.swift | Bot AI - generates valid dart scores with realistic distribution |
| `DartHit` | Models/GameModels.swift | Visualization model - score, segment, multiplier for dartboard display |
| `DartboardView` | Views/DartboardView.swift | Custom SwiftUI view - renders dartboard and dart markers |

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

## Current State (v1.0.2)

### Working Features ✅
- 301 and 501 game modes
- Two-player local multiplayer
- Bot opponent (12 levels, ~10-120 average)
- **Visual dartboard showing bot dart hits with 1-second animation**
- **Sound effects (180 announcement via MP3 playback)**
- **Checkout suggestions based on Winmau checkout table (2-170)**
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
- Additional sound effects (remaining scores, bust, game over)
- Statistics persistence
- Additional game modes (Cricket, Around the Clock)
- Keyboard shortcuts for score input

## Roadmap

### Priority 1 - Next Up
- [ ] Complete sound system (add remaining scores, bust, game over sounds)
- [ ] Keyboard shortcuts for faster score entry
- [ ] Improve bot checkout accuracy

### Priority 2 - Soon
- [ ] Persist statistics with SwiftData or UserDefaults
- [ ] Match play (best of X legs)
- [ ] Practice mode with scoring targets

### Priority 3 - Later
- [ ] Cricket game mode
- [ ] Around the Clock mode
- [ ] Online multiplayer
- [ ] Tournament bracket system

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
- `generateValidDartScore()` - ensures only valid dart scores (singles 1-20, doubles, triples, 25, 50)
- `scoreToDartHit()` - converts scores to DartHit for visualization
- `getCheckoutScore()` - checkout detection

### Adding Sound Effects
Sound system is in `SoundManager.swift`:
- Place MP3 files in `DartsCounter/Sounds/` folder
- Add files to Xcode project in Sounds group
- Call `playSound(named: "filename")` to play audio
- Supports automatic fallback search in multiple locations

## Session Log

### Session 1 (2025-01-04)
- Initial project creation
- All core features implemented
- Git repo initialised, tagged v0.1.0
- Pushed to GitHub

### Session 2 (2025-01-05)
- Added dartboard visualization with bot dart hit animations
- Implemented sound system with MP3 playback (180 announcement)
- Fixed critical scoring bug (double-counting visit totals)
- Fixed bot generating invalid dart scores
- Updated all checkout suggestions to match Winmau table
- Tagged v1.0.2 and pushed to both branches
