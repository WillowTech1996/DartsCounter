# CLAUDE.md - Project Context for AI Assistant

> **Purpose**: Share this file with Claude at the start of new chat sessions to maintain project continuity. Update this file after each significant development session.

## Project Overview

**Name**: Darts Counter  
**Platform**: macOS (native SwiftUI)  
**Min OS**: macOS 14.0 (Sonoma)  
**Current Version**: 0.1.0  
**Last Updated**: 2025-01-04  

### What This App Does
A native macOS darts scoring application supporting 301 and 501 game modes. Players can compete against each other locally or against a bot with 12 difficulty levels (averaging 10-120 points per 3-dart visit).

## Architecture

### Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **State Management**: ObservableObject + @Published + @EnvironmentObject
- **Minimum Deployment**: macOS 14.0

### Project Structure
```
DartsCounter/
├── DartsCounter.xcodeproj/
├── DartsCounter/
│   ├── DartsCounterApp.swift       # @main entry point
│   ├── Models/
│   │   └── GameModels.swift        # GameMode, PlayerType, Player, BotDifficulty, DartScore
│   ├── Managers/
│   │   └── GameManager.swift       # GameState enum, all game logic
│   └── Views/
│       ├── ContentView.swift       # Root view with state-based navigation
│       ├── MainMenuView.swift      # Start screen with PLAY button
│       ├── ModeSelectionView.swift # 301/501 selection
│       ├── PlayerSetupView.swift   # Names, bot toggle, bot level slider
│       ├── GameView.swift          # Main gameplay (scoring, stats, panels)
│       └── GameOverView.swift      # Winner display, play again options
├── CLAUDE.md                       # This file
├── CHANGELOG.md                    # Version history
└── README.md                       # User-facing documentation
```

### Key Classes/Types

| Type | Location | Purpose |
|------|----------|---------|
| `GameManager` | Managers/ | Central state manager, injected via @EnvironmentObject |
| `GameState` | Managers/GameManager.swift | Enum: .menu, .modeSelection, .playerSetup, .playing, .gameOver |
| `GameMode` | Models/ | Enum: .threeOhOne (301), .fiveOhOne (501) |
| `Player` | Models/ | ObservableObject with score, visits, stats |
| `PlayerType` | Models/ | Enum: .human, .bot(level: Int) |
| `BotDifficulty` | Models/ | Bot AI logic with normal distribution scoring |

### State Flow
```
MainMenu → ModeSelection → PlayerSetup → Playing ↔ GameOver
                ↑              ↑            ↓         ↓
                └──────────────┴────────────┴─────────┘
                              (goBack / reset)
```

## Design Decisions

### Already Decided
1. **Double-out required**: Must finish on a double or bullseye (standard rules)
2. **Bust handling**: Score reverts to start of visit if going <0 or =1
3. **Bot AI**: Uses Box-Muller normal distribution for realistic scoring variance
4. **Scoring UI**: Tab-based (Singles/Doubles/Triples) rather than dartboard visual
5. **Dark theme**: Optimised for focus during gameplay
6. **No persistence yet**: Games don't save between sessions

### Open Questions
- Should we add checkout suggestions? (Common routes for finishes)
- Should we add sound effects?
- Should we persist game history/statistics?
- Should we add more game modes (Cricket, Around the Clock)?

## Current State

### What Works ✅
- 301 and 501 game modes
- 2-player local multiplayer
- Bot opponent with 12 difficulty levels
- Singles/Doubles/Triples scoring tabs
- Real-time statistics (average, darts thrown, best visit)
- Visit history display
- Undo last dart
- Manual "Next" to end turn early
- Bust detection with visual overlay
- Game over screen with winner stats
- Play again / new game options

### Known Issues 🐛
- None currently tracked

### Limitations
- No checkout suggestions
- No sound effects
- No persistence (stats reset on app close)
- No network multiplayer

## Roadmap / Backlog

### Priority 1 (Next)
- [ ] Add checkout suggestions for finishable scores
- [ ] Improve bot checkout logic (currently basic)

### Priority 2 (Soon)
- [ ] Sound effects (dart throw, bust, checkout)
- [ ] Statistics persistence (UserDefaults or SwiftData)

### Priority 3 (Later)
- [ ] Cricket game mode
- [ ] Around the Clock game mode
- [ ] Visual dartboard input option
- [ ] Match play (best of X legs)
- [ ] Network multiplayer

## Code Conventions

### Swift Style
- Use `// MARK: -` for section organisation
- Prefer `guard` for early returns
- Use trailing closures
- Keep views small, extract subviews liberally

### Naming
- Views: `*View.swift` (e.g., `GameView.swift`)
- View Models/Managers: `*Manager.swift`
- Models: Descriptive noun (e.g., `Player`, `GameMode`)

### State Management
- `GameManager` is the single source of truth
- Inject via `.environmentObject(gameManager)` at root
- Child views access via `@EnvironmentObject var gameManager: GameManager`

## How to Continue Development

### Starting a New Chat Session
1. Upload this `CLAUDE.md` file
2. Briefly describe what you want to work on
3. If relevant, also upload specific Swift files you want to modify

### After Making Changes
1. Update the "Current State" section
2. Move completed items from Roadmap to "What Works"
3. Add any new issues to "Known Issues"
4. Update "Last Updated" date
5. Commit with descriptive message
6. Update CHANGELOG.md

### Commit Message Format
```
type: brief description

- Detail 1
- Detail 2
```
Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`

## Session History

### Session 1 (2025-01-04)
- Initial project creation
- Implemented 301/501 game modes
- Added 2-player and vs-bot modes
- Created full UI flow (menu → mode → setup → game → game over)
- Bot AI with 12 difficulty levels
- Basic scoring with Singles/Doubles/Triples tabs
- Git repository initialised
