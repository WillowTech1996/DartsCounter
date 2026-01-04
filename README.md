# Darts Counter - macOS Application

A native macOS darts scoring application built with SwiftUI.

## Features

- **Game Modes**: 301 and 501
- **Player Options**:
  - Two-player mode (human vs human)
  - Single player vs Bot (12 difficulty levels)
- **Bot AI**: Each level has a different average per 3-dart visit
  - Level 1: ~10 average
  - Level 6: ~60 average (casual player)
  - Level 12: ~120 average (professional)
- **Keyboard Input**: Fast score entry with intelligent auto-submit
- **Checkout Suggestions**: Recommended outs for scores 2-170
- **Scoring Interface**:
  - Singles, Doubles, and Triples tabs
  - Quick score buttons
  - Undo functionality
- **Statistics**: Real-time tracking of averages, darts thrown, and best visits
- **Bust Detection**: Automatic score reversion when busting

## Requirements

- macOS 14.0 (Sonoma) or later

## Installation

### Option 1: Download Pre-built App (Recommended)

1. Download the latest `DartsCounter.dmg` from the [Releases](https://github.com/WillowTech1996/DartsCounter/releases) page
2. Open the downloaded DMG file
3. Drag **Darts Counter** to the **Applications** folder shortcut
4. Eject the DMG
5. Open **Darts Counter** from your Applications folder
6. If macOS blocks the app (Gatekeeper):
   - Open **System Settings** → **Privacy & Security**
   - Scroll down and click **Open Anyway** next to the Darts Counter warning
   - Click **Open** in the confirmation dialog

### Option 2: Build from Source

1. Clone this repository
2. Open `DartsCounter.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities (if needed)
4. Build and run (⌘R)

## Project Structure

```
DartsCounter/
├── DartsCounterApp.swift      # App entry point
├── Models/
│   └── GameModels.swift       # Game mode, Player, Bot logic
├── Managers/
│   └── GameManager.swift      # Game state and scoring logic
├── Views/
│   ├── ContentView.swift      # Main navigation container
│   ├── MainMenuView.swift     # Home screen
│   ├── ModeSelectionView.swift # 301/501 selection
│   ├── PlayerSetupView.swift  # Player names & bot settings
│   ├── GameView.swift         # Main gameplay screen
│   └── GameOverView.swift     # Winner display & stats
└── Assets.xcassets/           # App icons and colors
```

## How to Play

1. Launch the app and click **PLAY**
2. Select your game mode (301 or 501)
3. Choose between 2 Players or vs Bot
4. If playing vs Bot, select difficulty (1-12)
5. Enter player name(s) and click **START GAME**
6. **Score Entry** - Choose your preferred method:

   **Keyboard (Fastest)**:
   - Type the visit total (e.g., "100" for a 100-point visit)
   - Auto-submits when no higher valid score is possible
   - Press Enter to force submit
   - Press Backspace to correct mistakes
   - Press Escape to clear

   **Buttons (Dart-by-Dart)**:
   - **Singles tab**: Numbers 1-20, 25, BULLSEYE! (50), Miss
   - **Doubles tab**: D1-D20, BULLSEYE!
   - **Triples tab**: T1-T20
   - The game automatically advances after 3 darts

7. Click **Undo** to remove the last dart
8. Click **Next** to manually end your turn early
9. **Checkout suggestions** appear when you're on a finish (2-170)

## Darts Rules Implemented

- Double-out required (must finish on a double or bullseye)
- Bust rule: Score reverts if you go below 0 or hit exactly 1
- Standard scoring: Singles, doubles (2x), triples (3x), bullseye (50)

## Future Enhancements (ideas)

- [ ] Cricket mode
- [ ] Around the Clock mode
- [ ] Sound effects
- [ ] Game history/statistics persistence
- [ ] Custom checkout suggestions
- [ ] Multiplayer over network

## License

MIT License - feel free to modify and use as you wish!
