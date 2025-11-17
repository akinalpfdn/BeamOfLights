# Beam of Lights - Development Instructions

## Project Overview
A minimalist sliding puzzle game where players tap light beams to make them slide linearly out of the canvas in their arrow direction. The game features calming visuals with comet-like gradient light beams that have a bright white tip fading to pale at the tail. The goal is to remove all intertwined beams from the canvas by tapping them in the correct order - if a beam hits another beam during its slide, it bounces back to its original position.

## Design Principles
- **Minimalist & Clean**: Simple geometric shapes, plenty of white space, no visual markers
- **Calming Colors**: Soft pastels, comet-like gradient beams (bright white at tip → fading pale at tail)
- **Smooth Animations**: Gentle sliding transitions, parallel beam movements, bounce-back effects
- **Relaxing Experience**: Brain-teasing but stress-free sliding puzzle mechanics

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

### Step 3.2: Implement Beam Sliding Logic
- Method to handle beam tap (start linear movement animation)
- Method to detect when beam exits canvas (successful removal)
- Method to detect beam-to-beam collision during movement
- Method to handle bounce-back animation when collision occurs
- Method to check win condition (all beams removed from canvas)
- Method to handle wrong moves (beam bounces back → lose heart)

### Step 3.3: Level Loading
- Method to load levels from JSON
- Method to move to next level
- Method to reset current level

**Wait for approval before continuing**

---

## PHASE 4: Beam Rendering & Tap Detection ⚡ **SLIDING PUZZLE MECHANICS**

**Goal**: Create individual beam rendering with tap detection for sliding mechanics

### Game Mechanics:
- **Tap a beam** → It slides linearly in its arrow direction
- **No obstacles** → Beam exits canvas (successful removal)
- **Hits another beam** → Bounce back to original position (lose heart)
- **Multiple beams** → Can slide simultaneously (parallel animations)
- **Win condition** → All beams successfully exit canvas

### Step 4.1: Create ContinuousBeamPath Renderer
- Create `ContinuousBeamPath.swift` in Views
- Use Canvas API to draw continuous light beam shapes
- Each beam is a continuous path from start point through all connected segments
- Support position offset for sliding animation
- Gradient: **lively white at tip (arrow end) → fading pale at tail (comet effect)**
- Grid coordinates used for positioning (invisible background dots)
- **No start/end markers** - gradient reveals direction naturally

### Step 4.2: Create BeamShape
- Create `BeamShape.swift` in Views
- Custom Shape for rendering tapered beam appearance
- Handles beam direction (up, down, left, right)
- Multi-layered glow effects for depth
- Smooth tapering toward arrow tip

### Step 4.3: Create GridView with Tap Detection
- Create `GridView.swift` in Views
- Use Canvas/GeometryReader for rendering
- Background: subtle dot grid at cell positions
- Render each beam as independent visual element
- Implement tap gesture recognizer to detect which beam was tapped
- Responsive sizing for different screens

### Step 4.4: Wire to ViewModel
- Connect GridView to GameViewModel
- Display first level with all beams
- Test tap detection (log which beam is tapped)
- No sliding animation yet (just detection)

**Wait for approval before continuing**

---

## PHASE 5: Sliding Animations & Visual Effects

**Goal**: Implement sliding mechanics with beautiful animations

### Step 5.1: Linear Sliding Animation
- withAnimation for smooth beam position changes
- Animate beam from current position in arrow direction
- Calculate exit point (edge of canvas)
- Support parallel animations (multiple beams moving simultaneously)
- Duration: ~0.8-1.2 seconds for smooth, calming movement

### Step 5.2: Bounce-Back Animation
- Detect collision point during slide animation
- Spring animation to bounce beam back to original position
- Red flash overlay on collision
- Shake effect on canvas for tactile feedback

### Step 5.3: Enhanced Gradient & Glow System
- LinearGradient along beam direction: **lively white at tip → fading pale at tail (comet effect)**
- Colors: soft blue, pink, purple, green, orange (pastel versions)
- Multi-layered glow effects for depth (stronger at tip, weaker at tail)
- Pulsing animation on beams (gentle breathing effect)
- Increased glow intensity during movement animation
- Subtle shadow beneath beams for elevation
- **No visual markers** - gradient naturally reveals beam direction

### Step 5.4: Exit Canvas Effect
- Fade out animation as beam exits canvas boundary
- Success particle effect (soft sparkles)
- Beam disappears from canvas after successful exit

**Wait for approval before continuing**

---

## PHASE 6: Collision Detection & Game Flow

**Goal**: Implement collision detection and complete game logic

### Step 6.1: Collision Detection System
- After animation completes, check beam's final position
- Detect if beam path intersects with another beam
- Collision check: compare beam segments (line-to-line intersection)
- If collision detected → trigger bounce-back animation
- If no collision → beam successfully exits, remove from canvas

### Step 6.2: Beam Removal & Win Condition
- Remove beam from active beams array when it exits canvas
- Check if all beams have been removed (win condition)
- Level complete screen with celebration animation
- Next level button

### Step 6.3: Heart System & Game Over
- Display hearts at top of screen (animated HeartView)
- Lose heart when beam bounces back (collision occurred)
- Heart break animation
- Game over screen when hearts = 0
- Try again button to reset level

### Step 6.4: Haptic Feedback
- Light haptic on beam tap
- Success haptic when beam exits canvas
- Error haptic on collision/bounce-back
- Heavy haptic on level complete

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
  "gridSize": {"rows": 5, "columns": 5},
  "difficulty": 3,
  "cells": [
    {"row": 1, "column": 0, "type": "path", "direction": "right", "color": "blue"},
    {"row": 1, "column": 1, "type": "path", "direction": "right", "color": "blue"},
    {"row": 1, "column": 2, "type": "path", "direction": "down", "color": "blue"},
    {"row": 2, "column": 2, "type": "path", "direction": "down", "color": "blue"},
    {"row": 3, "column": 2, "type": "end", "direction": "down", "color": "blue"},

    {"row": 2, "column": 0, "type": "path", "direction": "right", "color": "pink"},
    {"row": 2, "column": 1, "type": "path", "direction": "right", "color": "pink"},
    {"row": 2, "column": 2, "type": "end", "direction": "right", "color": "pink"}
  ]
}
```

**Notes:**
- Each beam is a continuous sequence of cells sharing the same color
- `type: "end"` marks the arrow tip (exit point) of each beam
- Grid is used for positioning; beams are intertwined and must be removed in correct order
- Tapping a beam slides it in the direction of its arrow (last cell's direction)

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
