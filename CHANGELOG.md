# Changelog

All notable changes to Darts Counter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Checkout suggestions for finishable scores
- Sound effects
- Statistics persistence

---

## [0.1.0] - 2025-01-04

### Added
- Initial release
- **Game Modes**
  - 301 game mode
  - 501 game mode
- **Player Options**
  - Two-player local multiplayer
  - Single player vs Bot
  - 12 bot difficulty levels (Level 1 = ~10 avg, Level 12 = ~120 avg)
- **Scoring System**
  - Singles tab (1-20, 25, Bull, Miss)
  - Doubles tab (D1-D20, D25)
  - Triples tab (T1-T20)
  - Undo last dart functionality
  - Manual "Next" to end turn early
- **Game Rules**
  - Double-out required
  - Bust detection with automatic score reversion
  - Visual bust overlay notification
- **Statistics**
  - Real-time average per visit
  - Darts thrown counter
  - Best visit tracking
  - Recent visits history
- **UI/UX**
  - Dark theme optimised for gameplay
  - Animated screen transitions
  - Active player highlighting
  - Current visit total display
  - Dart indicators showing throw progress
- **Bot AI**
  - Normal distribution-based scoring for realistic variance
  - Skill-based checkout probability
  - Animated dart throwing with delays

### Technical
- SwiftUI-based architecture
- ObservableObject state management
- Minimum macOS 14.0 (Sonoma)

---

## Version Guidelines

- **MAJOR** (1.0.0): First public release / breaking changes
- **MINOR** (0.x.0): New features (game modes, major UI changes)
- **PATCH** (0.0.x): Bug fixes, small improvements
