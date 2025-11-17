# Beam of Lights - Development Instructions

## Project Overview
A minimalist puzzle game where players follow light beams through a grid to find the escape path. The game features calming visuals with gradient light beams that fade from bright to dim, creating a relaxing puzzle experience.

## Design Principles
- **Minimalist & Clean**: Simple geometric shapes, plenty of white space
- **Calming Colors**: Soft pastels, gradient light beams (bright at source → fading at end)
- **Smooth Animations**: Gentle transitions, no harsh movements
- **Relaxing Experience**: Brain-teasing but stress-free

---

## PHASE 1: Project Setup & Basic Structure

**Goal**: Create Xcode project with proper architecture

### Step 1.1: Create Project
- Create new iOS App project in Xcode
- Name: "BeamOfLights"
- Interface: SwiftUI
- Minimum iOS version: 16.0
- Create folder structure:
  - `Models/` (game data structures)
  - `Views/` (UI components)
  - `ViewModels/` (game logic)
  - `Resources/` (JSON levels, assets)

**Wait for approval before continuing**

---

## PHASE 2: Core Data Models

**Goal**: Define the game's data structure

### Step 2.1: Create Cell Model
- Create `Cell.swift` in Models folder
- Properties needed:
  - Direction enum (up, down, left, right, none)
  - Cell type enum (start, end, path, empty)
  - Position (row, column)
  - Light color (for visual variety)

### Step 2.2: Create Level Model
- Create `Level.swift` in Models folder
- Properties:
  - Grid size (rows, columns)
  - Array of cells
  - Level number
  - Difficulty (hearts: 3-5)
- Add Codable conformance for JSON

### Step 2.3: Create Sample JSON
- Create `levels.json` in Resources
- Add 3 simple test levels (3x3, 4x4, 5x5 grids)
- Simple paths to test with

**Wait for approval before continuing**

---

## PHASE 3: Game Logic (ViewModel)

**Goal**: Implement core game mechanics

### Step 3.1: Create GameViewModel
- Create `GameViewModel.swift` in ViewModels
- ObservableObject for SwiftUI
- Properties:
  - Current level
  - Game state (playing, won, lost)
  - Current path being traced
  - Hearts remaining

### Step 3.2: Implement Path Validation
- Method to check if path follows beam directions correctly
- Method to validate win condition (reached end cell)
- Method to handle wrong moves (lose heart)

### Step 3.3: Level Loading
- Method to load levels from JSON
- Method to move to next level
- Method to reset current level

**Wait for approval before continuing**

---

## PHASE 4: Continuous Path-Based Rendering ⚡ **UPDATED DESIGN**

**Goal**: Create continuous, connected light beam paths (no grid cells)

### Design Change Rationale:
- **OLD**: Grid-based cells with individual beams (disconnected)
- **NEW**: Continuous path rendering with connected light beams (like original game)
- Grid only used for coordinate positioning, not visual cells
- Beams flow continuously from start to end

### Step 4.1: Create PathRenderer
- Create `PathRenderer.swift` in Views
- Use Canvas API to draw continuous light beam paths
- Calculate connection points between cells
- Render smooth, connected beam segments
- Grid coordinates used for positioning only (invisible)

### Step 4.2: Create BeamSegment Shape
- Create `BeamSegment.swift` in Views
- Custom Shape for rendering single beam segment
- Handles horizontal, vertical, and corner connections
- Gradient from bright (source) → dim (end)
- Smooth corners where paths turn

### Step 4.3: Create GridView with Canvas
- Create `GridView.swift` in Views
- Use Canvas/GeometryReader for rendering
- Calculate dot positions from grid coordinates
- Render connected beam paths on top of dots
- Responsive sizing for different screens
- Start cell: glowing circle, End cell: glowing square

### Step 4.4: Wire to ViewModel
- Connect GridView to GameViewModel
- Display first level with continuous beams
- Test visual rendering (no interaction yet)

**Wait for approval before continuing**

---

## PHASE 5: Light Beam Graphics & Effects

**Goal**: Add beautiful gradients, glow effects, and animations

### Step 5.1: Gradient System
- LinearGradient along beam path direction
- Colors: soft blue, pink, purple, green, orange
- Bright at source → transparent at end
- Smooth color transitions

### Step 5.2: Glow & Shadow Effects
- Blur effect for outer glow
- Multiple shadow layers for depth
- Pulsing animation on start/end markers
- Increased glow for active path segments

### Step 5.3: Path Animation
- Animate beam appearance (fade in)
- Gentle pulsing opacity on inactive beams
- Highlight active path with brighter glow
- Smooth transitions when path changes

**Wait for approval before continuing**

---

## PHASE 6: User Interaction

**Goal**: Implement touch-based path tracing

### Step 6.1: Add Gesture Recognizers
- DragGesture on GridView
- Track which cells user touches in sequence
- Highlight touched cells with glow effect

### Step 6.2: Path Validation Feedback
- Correct path: cells stay illuminated (brighter)
- Wrong turn: red glow + shake animation + lose heart
- Complete path: success animation

### Step 6.3: Heart System UI
- Display hearts at top of screen
- Lose animation when wrong move
- Game over screen when hearts = 0

**Wait for approval before continuing**

---

## PHASE 7: Level Screen & Navigation

**Goal**: Create level selection and game flow

### Step 7.1: Create LevelCardView
- Preview of level layout (miniature)
- Level number
- Difficulty (hearts)
- Locked/unlocked state

### Step 7.2: Create LevelSelectionView
- Grid of level cards
- Smooth scroll
- Unlock system (complete previous to unlock next)

### Step 7.3: Navigation Flow
- Main menu → Level selection → Game screen
- Back buttons
- Level complete → show next level option
- Smooth transitions

**Wait for approval before continuing**

---

## PHASE 8: Polish & Animations

**Goal**: Add final touches for calming experience

### Step 8.1: Success Animation
- Particle effect when level completed
- Soft light burst
- Gentle confetti

### Step 8.2: Sound Effects (Optional)
- Soft "ping" for correct move
- Gentle "whoosh" for beam travel
- Calming ambient background music (very subtle)
- Settings to mute

### Step 8.3: Haptic Feedback
- Light haptic on correct touch
- Medium haptic on wrong move
- Success haptic pattern on level complete

### Step 8.4: Color Themes
- Light mode (default): white background, pastel beams
- Dark mode: dark blue/purple background, brighter beams
- Auto-adjust based on system settings

**Wait for approval before continuing**

---

## PHASE 9: Content & Testing

**Goal**: Add real levels and test thoroughly

### Step 9.1: Create More Levels
- 20-30 levels total for initial release
- Progressive difficulty
- Vary grid sizes (3x3 to 7x7)
- Test each level manually

### Step 9.2: Performance Optimization
- Ensure 60fps on all supported devices
- Optimize gradient rendering
- Lazy loading for level selection

### Step 9.3: Bug Testing
- Test edge cases
- Different screen sizes
- iOS version compatibility
- Memory leaks check

**Wait for approval before continuing**

---

## PHASE 10: Final Touches

**Goal**: Prepare for release/user-generated content

### Step 10.1: App Icon & Launch Screen
- Design minimalist app icon (light beam icon)
- Simple animated launch screen

### Step 10.2: Onboarding
- Quick tutorial level
- Explain game mechanics visually
- Skip option for returning users

### Step 10.3: Settings Screen
- Sound toggle
- Haptics toggle
- Reset progress option
- Credits/about

**Wait for approval before continuing**

---

## Future Phase: Level Editor (Not in this document)
This will be a separate phase after the core game is complete and tested.

---

## Technical Notes

### JSON Level Format Example
```json
{
  "levelNumber": 1,
  "gridSize": {"rows": 3, "columns": 3},
  "difficulty": 3,
  "cells": [
    {"row": 0, "col": 0, "type": "start", "direction": "right", "color": "blue"},
    {"row": 0, "col": 1, "type": "path", "direction": "down", "color": "blue"},
    ...
  ]
}
```

### Color Palette Suggestions
- Soft Blue: #A8D8EA
- Soft Pink: #FFB6C1  
- Soft Purple: #D4B5F0
- Soft Green: #B4E7CE
- Soft Orange: #FFD4A3

### SwiftUI Architecture
- Use MVVM pattern
- Keep Views simple and reusable
- BusinessLogic in ViewModels
- Models are Codable structs

---

## Approval Workflow
After completing each phase:
1. Run and test the app
2. Show result to user
3. Wait for "continue" or feedback
4. Make adjustments if needed
5. Move to next phase only after approval

Remember: **Calm, minimal, beautiful** - every decision should serve these principles.
