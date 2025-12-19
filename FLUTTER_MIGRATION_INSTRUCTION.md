# Swift to Flutter Migration Plan: Beam of Lights Game

## 📋 Executive Summary

**Migration Approach**: Incremental, phase-by-phase with user confirmation gates
**Rendering Engine**: Flame (Flutter game engine)
**State Management**: Provider pattern (replacing MVVM)
**Target Platforms**: iOS & Android
**Performance Goal**: Stable 60fps
**Migration Strategy**: Gameplay-first, visual polish later

---

## 🎯 Migration Overview

### Source Codebase Analysis
- **Total Lines**: ~1,941 lines of Swift code
- **Architecture**: MVVM (SwiftUI + SpriteKit)
- **Key Files**:
  - [GameViewModel.swift](BeamOfLights/ViewModels/GameViewModel.swift) (330 lines) - Core game logic
  - [GameScene.swift](BeamOfLights/Views/GameScene.swift) (541 lines) - SpriteKit rendering
  - [Level.swift](BeamOfLights/Models/Level.swift) (67 lines) - Data models
  - [Cell.swift](BeamOfLights/Models/Cell.swift) (61 lines) - Grid cell model

### Critical Game Mechanics to Port
1. **Grid System**: 25×25 cells at 50pt fixed size
2. **Collision Detection**: Path-based collision checking (`willCollideWithOtherBeam`)
3. **Beam Building**: Connect cells by following direction arrows (`buildConnectedPath`)
4. **Sliding Path**: Calculate beam trajectory (`getBeamSlidingPath`)
5. **Animations**: 0.6s slide-out, bounce-back on collision
6. **Neon Rendering**: 4-layer glow effect (outer haze, inner glow, white core, animated tip)

---

## 📦 Phase-by-Phase Implementation Plan

### **Phase 1: Foundation & Dependencies Setup**
**Complexity**: 🟢 Low
**Estimated Time**: 1-2 days
**Dependencies**: None

#### Objectives
- Set up Flutter project with Flame engine
- Configure asset management
- Establish directory structure

#### Technical Tasks
1. Add dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flame: ^1.18.0
     provider: ^6.1.0
     uuid: ^4.0.0

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^6.0.0
   ```

2. Create directory structure:
   ```
   lib/
   ├── models/          # Data models (Cell, Level, Beam)
   ├── game/            # Flame game components
   │   ├── components/  # Beam, Grid, Camera components
   │   ├── rendering/   # Neon effects, custom painters
   │   └── animations/  # Slide, bounce animations
   ├── services/        # Level loading, collision detection
   ├── providers/       # State management (GameProvider)
   ├── widgets/         # UI overlays (hearts, win/lose screens)
   └── utils/           # Constants, helpers
   ```

3. Copy `levels.json` from Swift project to `assets/`

4. Create `lib/utils/constants.dart`:
   ```dart
   class GameConstants {
     static const double gridCellSize = 50.0;
     static const double slideAnimationDuration = 0.6;
     static const double bounceAnimationDuration = 0.3;
     // Color mappings, z-positions, etc.
   }
   ```

#### Files to Create
- `beam_of_light/pubspec.yaml` (modify)
- `beam_of_light/assets/levels.json` (copy from Swift)
- `beam_of_light/lib/utils/constants.dart` (new)

#### Verification Criteria
- ✅ `flutter pub get` runs successfully
- ✅ No dependency conflicts
- ✅ App launches with Flame game window (black background)
- ✅ `levels.json` loads via `rootBundle.loadString()`
- ✅ Runs on both iOS and Android emulators

#### User Confirmation
**Before proceeding**: Confirm dependencies installed and basic Flame game window displays.

---

### **Phase 2: Core Data Models**
**Complexity**: 🟢 Low
**Estimated Time**: 1 day
**Dependencies**: Phase 1

#### Objectives
- Port Swift data models to Dart
- Implement JSON serialization
- Validate data integrity

#### Technical Tasks
1. Create `lib/models/cell.dart`:
   - Port from [Cell.swift](BeamOfLights/Models/Cell.swift:1-61)
   - Enums: `CellType` (start, end, path, empty), `Direction` (up, down, left, right, none)
   - Properties: `row`, `column`, `type`, `direction`, `color`
   - JSON deserialization: `factory Cell.fromJson(Map<String, dynamic> json)`

2. Create `lib/models/grid_size.dart`:
   - Properties: `rows`, `columns`
   - JSON deserialization

3. Create `lib/models/level.dart`:
   - Port from [Level.swift](BeamOfLights/Models/Level.swift:1-68)
   - Properties: `levelNumber`, `gridSize`, `difficulty`, `cells`
   - Helper methods: `cellAt(row, column)`, `startCell`, `endCell`
   - Container: `LevelsData` class for JSON root

4. Create `lib/models/beam.dart`:
   - Port from [GameViewModel.swift](BeamOfLights/ViewModels/GameViewModel.swift:28-61)
   - Properties: `id` (UUID), `cells` (List<Cell>), `color`, `isSliding`
   - Computed property: `direction` (from last cell's arrow)

#### Files to Create
- `beam_of_light/lib/models/cell.dart`
- `beam_of_light/lib/models/grid_size.dart`
- `beam_of_light/lib/models/level.dart`
- `beam_of_light/lib/models/beam.dart`

#### Verification Criteria
- ✅ Level JSON parses successfully
- ✅ All levels load from `levels.json` (print count to console)
- ✅ Beam direction correctly calculated from cell chain
- ✅ Debug output shows correct level data structure

#### User Confirmation
**Before proceeding**: Verify JSON parsing works and level data displays correctly in console.

---

### **Phase 3: Level Loading & Beam Building**
**Complexity**: 🟡 Medium
**Estimated Time**: 1-2 days
**Dependencies**: Phase 2

#### Objectives
- Implement level loading service
- Port beam building algorithm
- Validate beam connectivity

#### Technical Tasks
1. Create `lib/services/level_service.dart`:
   ```dart
   class LevelService {
     static Future<List<Level>> loadAllLevels() async {
       final jsonString = await rootBundle.loadString('assets/levels.json');
       final jsonData = json.decode(jsonString);
       final levelsData = LevelsData.fromJson(jsonData);
       return levelsData.levels;
     }
   }
   ```

2. Create `lib/services/beam_builder.dart`:
   - Port `buildBeams()` from [GameViewModel.swift:149-167](BeamOfLights/ViewModels/GameViewModel.swift:149-167)
   - Port `buildConnectedPath()` from [GameViewModel.swift:170-189](BeamOfLights/ViewModels/GameViewModel.swift:170-189)
   - Port `findNextCell()` from [GameViewModel.swift:191-207](BeamOfLights/ViewModels/GameViewModel.swift:191-207)
   - Group cells by color, follow direction arrows to build ordered paths

#### Files to Create
- `beam_of_light/lib/services/level_service.dart`
- `beam_of_light/lib/services/beam_builder.dart`

#### Verification Criteria
- ✅ All levels load successfully
- ✅ Beams built correctly (print beam count per level)
- ✅ Beam paths follow cell directions accurately
- ✅ Start-to-end connectivity validated for each beam

#### User Confirmation
**Before proceeding**: Confirm beam building algorithm works and prints correct beam structures.

---

### **Phase 4: Game State Management (Provider)**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 3

#### Objectives
- Implement game state with Provider
- Port core collision detection logic
- Handle game events (win/lose/reset)

#### Technical Tasks
1. Create `lib/providers/game_provider.dart`:
   - Port from [GameViewModel.swift:64-330](BeamOfLights/ViewModels/GameViewModel.swift:64-330)
   - Properties: `currentLevel`, `gameState`, `heartsRemaining`, `activeBeams`, `currentLevelIndex`
   - Methods: `loadLevel()`, `resetLevel()`, `nextLevel()`

2. Create `lib/services/collision_service.dart`:
   - Port `willCollideWithOtherBeam()` from [GameViewModel.swift:266-279](BeamOfLights/ViewModels/GameViewModel.swift:266-279)
   - Port `getBeamSlidingPath()` from [GameViewModel.swift:282-311](BeamOfLights/ViewModels/GameViewModel.swift:282-311)
   - Check if beam path intersects any existing beam cells

3. Implement tap handling:
   - Port `tapBeam()` from [GameViewModel.swift:212-230](BeamOfLights/ViewModels/GameViewModel.swift:212-230)
   - Collision → `handleCollision()` (lose heart, bounce)
   - Success → `handleSuccess()` (remove beam, check win)

4. Game state enum:
   ```dart
   enum GameState { playing, won, lost }
   ```

5. Event stream for animations:
   ```dart
   enum GameAction {
     slideOut,
     bounce,
     reset,
   }
   ```

#### Files to Create
- `beam_of_light/lib/providers/game_provider.dart`
- `beam_of_light/lib/services/collision_service.dart`

#### Verification Criteria
- ✅ Game state updates correctly on user actions
- ✅ Collision detection accurately identifies beam intersections
- ✅ Hearts decrement on collision
- ✅ Win condition triggers when all beams removed
- ✅ Provider notifies listeners on state changes
- ✅ Debug mode prints collision paths and hit detection results

#### User Confirmation
**Before proceeding**: Test collision logic manually (print results), verify state transitions work.

---

### **Phase 5: Flame Game Foundation**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 4

#### Objectives
- Set up Flame game structure
- Implement grid rendering
- Create camera system with zoom/pan

#### Technical Tasks
1. Create `lib/game/beam_of_lights_game.dart`:
   ```dart
   class BeamOfLightsGame extends FlameGame {
     @override
     Future<void> onLoad() async {
       camera = CameraComponent.withFixedResolution(width: 800, height: 600);
       world = GameWorld();
       await addAll([camera, world]);
     }
   }
   ```

2. Create `lib/game/components/grid_component.dart`:
   - Render 25×25 grid at 50pt cell size
   - White dots at each grid intersection (low opacity)
   - Centered in world space

3. Implement camera controls:
   - Port zoom logic from [GameScene.swift:74-94](BeamOfLights/Views/GameScene.swift:74-94)
   - Zoom range: 1.0 (fit entire grid) to 3.0 (close-up)
   - Pan with drag gestures (use `DragCallbacks`)
   - Clamp camera bounds to grid + padding

4. Update `lib/main.dart`:
   ```dart
   void main() {
     runApp(GameWidget(game: BeamOfLightsGame()));
   }
   ```

#### Files to Create
- `beam_of_light/lib/game/beam_of_lights_game.dart`
- `beam_of_light/lib/game/components/grid_component.dart`
- `beam_of_light/lib/game/components/game_world.dart`
- `beam_of_light/lib/main.dart` (modify)

#### Verification Criteria
- ✅ Grid renders correctly at 25×25
- ✅ Camera zoom in/out works smoothly (pinch gesture)
- ✅ Pan gesture moves camera within bounds
- ✅ Grid stays centered and properly sized
- ✅ 60fps maintained during camera movement

#### User Confirmation
**Before proceeding**: Test grid rendering and camera controls on real device. Confirm smooth performance.

---

### **Phase 6: Basic Beam Rendering**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 5

#### Objectives
- Render beams as simple colored paths
- Implement tap detection
- Connect rendering to game state

#### Technical Tasks
1. Create `lib/game/components/beam_component.dart`:
   - Extend `PositionComponent`
   - Render beam as connected line segments (start → end)
   - Initial width: 8-10 pixels (simple colored line, no neon yet)
   - Convert cell positions to world coordinates

2. Implement tap detection:
   - Override `containsLocalPoint()` to check if tap is within beam bounds
   - Return tapped beam to `GameProvider`

3. Create `lib/game/components/beam_renderer.dart`:
   - Manage all `BeamComponent` instances
   - Add/remove beams based on `GameProvider.activeBeams`
   - Update positions when beams slide

4. Render start/end markers:
   - Simple circles at beam start and end positions
   - Different colors for start (green) vs end (red)

#### Files to Create
- `beam_of_light/lib/game/components/beam_component.dart`
- `beam_of_light/lib/game/components/beam_renderer.dart`
- `beam_of_light/lib/game/components/start_end_marker.dart`

#### Verification Criteria
- ✅ All beams render at correct positions
- ✅ Beam colors match level data
- ✅ Tap detection works (can identify which beam tapped)
- ✅ Beams update when game state changes
- ✅ Start/end markers visible and positioned correctly

#### User Confirmation
**Before proceeding**: Verify beams render correctly, tap detection works, and state updates trigger re-renders.

---

### **Phase 7: Beam Animation System**
**Complexity**: 🟠 High
**Estimated Time**: 3-4 days
**Dependencies**: Phase 6

#### Objectives
- Implement slide-out animation (0.6s)
- Implement bounce animation on collision
- Smooth 60fps animations

#### Technical Tasks
1. Create `lib/game/animations/slide_animation.dart`:
   - Port from [GameScene.swift:193-238](BeamOfLights/Views/GameScene.swift:193-238)
   - Duration: 0.6 seconds
   - Eased curve: `t * t` (quadratic ease-in)
   - Move beam along direction vector to exit point
   - Remove component on completion

2. Create `lib/game/animations/bounce_animation.dart`:
   - Port from [GameScene.swift:242-275](BeamOfLights/Views/GameScene.swift:242-275)
   - Duration: 0.3 seconds
   - Small movement in direction (10-15% of cell size)
   - Spring-back with overshoot
   - Flash white overlay effect

3. Use Flame's animation system:
   - `MoveEffect` for slide movement
   - `SequenceEffect` for bounce sequence
   - Callbacks to `GameProvider` on animation complete

4. Block input during animations:
   - Set flag in `GameProvider` to prevent taps during animation

#### Files to Create
- `beam_of_light/lib/game/animations/slide_animation.dart`
- `beam_of_light/lib/game/animations/bounce_animation.dart`
- `beam_of_light/lib/game/components/beam_component.dart` (modify for animations)

#### Verification Criteria
- ✅ Slide animations complete in 0.6s
- ✅ Bounce animations feel responsive and springy
- ✅ Animations don't stutter or drop frames (60fps)
- ✅ User can't tap beams during animations
- ✅ Animation callbacks trigger state updates correctly
- ✅ Multiple beams can animate simultaneously without conflicts

#### User Confirmation
**Before proceeding**: Test animations on real device. Confirm smooth performance and correct timing.

---

### **Phase 8: Neon Visual Effects**
**Complexity**: 🔴 High
**Estimated Time**: 4-5 days
**Dependencies**: Phase 7

#### Objectives
- Implement 4-layer neon glow effect
- Achieve authentic neon light appearance
- Maintain 60fps with effects

#### Technical Tasks
1. Create `lib/game/rendering/neon_beam_painter.dart`:
   - Port from [GameScene.swift:373-442](BeamOfLights/Views/GameScene.swift:373-442)
   - Implement 4-layer rendering:
     1. **Outer Haze**: Large blur, 15% opacity, additive blend
     2. **Inner Glow**: Medium blur, 60% opacity, additive blend
     3. **White Core**: Thin line, 90% white, normal blend
     4. **Animated Tip**: Pulsing glow at beam tip, additive blend

2. Use Flutter's `MaskFilter.blur()` for glow:
   ```dart
   final paint = Paint()
     ..color = beamColor.withOpacity(0.6)
     ..strokeWidth = cellSize * 0.2
     ..strokeCap = StrokeCap.round
     ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0)
     ..blendMode = BlendMode.plus; // Additive blending
   ```

3. Implement tip animation:
   - Opacity oscillation (0.6 to 1.0)
   - Duration: 1.5s loop
   - Sine wave easing for smoothness

4. Optimize rendering:
   - Cache static layers as textures
   - Use `Canvas.saveLayer()` efficiently
   - Consider custom shaders if performance issues

#### Files to Create
- `beam_of_light/lib/game/rendering/neon_beam_painter.dart`
- `beam_of_light/lib/game/rendering/beam_shape.dart` (custom path generation)
- `beam_of_light/lib/game/components/beam_component.dart` (modify for neon rendering)

#### Verification Criteria
- ✅ Neon glow effect looks authentic and vibrant
- ✅ Beams have professional light quality
- ✅ Tip animation pulses smoothly
- ✅ 60fps maintained with 10+ beams on screen
- ✅ Effects look good on different screen sizes
- ✅ Performance tested on older devices (iPhone 8, Pixel 4a)

#### User Confirmation
**Before proceeding**: Verify neon effects match Swift version quality. Test performance on target devices.

---

### **Phase 9: UI Layer & Game HUD**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 4

#### Objectives
- Create hearts display (lives)
- Add level indicator
- Implement win/lose screens
- Add reset/menu buttons

#### Technical Tasks
1. Create `lib/widgets/hearts_widget.dart`:
   - Port from [HeartView.swift](BeamOfLights/Views/HeartView.swift:1-68)
   - Render heart icons (3-5 based on difficulty)
   - Animate heart loss with scale/fade effect
   - Position in top-right corner

2. Create `lib/widgets/level_indicator_widget.dart`:
   - Display "Level X" text
   - Position in top-left corner

3. Create `lib/widgets/win_screen.dart`:
   - "Level Complete!" message
   - Animated celebration effect
   - Auto-advance to next level (1.5s delay)

4. Create `lib/widgets/lose_screen.dart`:
   - "Out of Hearts" message
   - "Retry" and "Menu" buttons

5. Create `lib/widgets/game_hud.dart`:
   - Stack overlay UI on top of Flame game
   - Handle z-ordering (UI above game)
   - Responsive layout

6. Implement shake effect on collision:
   - Brief screen shake (0.2s, 2-3 pixel amplitude)

#### Files to Create
- `beam_of_light/lib/widgets/hearts_widget.dart`
- `beam_of_light/lib/widgets/level_indicator_widget.dart`
- `beam_of_light/lib/widgets/win_screen.dart`
- `beam_of_light/lib/widgets/lose_screen.dart`
- `beam_of_light/lib/widgets/game_hud.dart`
- `beam_of_light/lib/main.dart` (modify to integrate HUD)

#### Verification Criteria
- ✅ Hearts display correctly (count matches difficulty)
- ✅ Hearts animate on loss
- ✅ Level indicator shows current level
- ✅ Win screen appears after clearing all beams
- ✅ Lose screen appears when hearts = 0
- ✅ Retry button resets current level
- ✅ UI elements don't block game interaction

#### User Confirmation
**Before proceeding**: Test all UI overlays. Verify responsive layout on different screen sizes.

---

### **Phase 10: Performance Optimization**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 8

#### Objectives
- Achieve stable 60fps on target devices
- Optimize rendering pipeline
- Reduce memory usage

#### Technical Tasks
1. Profile with Flutter DevTools:
   - Identify frame drops and jank
   - Analyze widget rebuild frequency
   - Check for unnecessary repaints

2. Optimize beam rendering:
   - Implement object pooling for beam components
   - Cache neon glow textures
   - Use `RepaintBoundary` for static UI elements

3. Optimize state management:
   - Minimize `notifyListeners()` calls
   - Use `Selector` widgets for granular rebuilds
   - Batch state updates

4. Optimize collision detection:
   - Early exit conditions
   - Spatial partitioning if needed

5. Memory optimization:
   - Dispose unused resources
   - Clear animation controllers
   - Monitor memory leaks

6. Add performance monitoring overlay (debug mode):
   - FPS counter
   - Frame time graph
   - Memory usage indicator

#### Files to Modify
- `beam_of_light/lib/game/components/beam_component.dart` (object pooling)
- `beam_of_light/lib/game/rendering/neon_beam_painter.dart` (caching)
- `beam_of_light/lib/providers/game_provider.dart` (batch updates)
- `beam_of_light/lib/utils/performance_monitor.dart` (new - debug overlay)

#### Verification Criteria
- ✅ Consistent 60fps on iPhone 11 / Pixel 5
- ✅ No frame drops during animations
- ✅ Stable 60fps with 15+ beams on screen
- ✅ Memory usage stays below 150MB
- ✅ Widget rebuild count minimized
- ✅ No memory leaks after 10 level cycles

#### User Confirmation
**Before proceeding**: Review performance metrics. Confirm stable 60fps on target devices.

---

### **Phase 11: Polish & Final Touches**
**Complexity**: 🟡 Medium
**Estimated Time**: 2-3 days
**Dependencies**: Phase 9

#### Objectives
- Add sound effects
- Enhance visual feedback
- Improve user experience

#### Technical Tasks
1. Add sound effects (use `audioplayers` package):
   - Tap sound
   - Slide success sound
   - Collision sound
   - Win/lose sounds

2. Add haptic feedback:
   - Use `HapticFeedback.mediumImpact()` on slide
   - Use `HapticFeedback.heavyImpact()` on collision

3. Enhance particle effects:
   - Collision sparks
   - Win celebration particles

4. Add settings screen:
   - Sound on/off toggle
   - Haptic feedback toggle

5. Add tutorial overlay for first launch

#### Files to Create
- `beam_of_light/lib/services/audio_service.dart`
- `beam_of_light/lib/widgets/settings_screen.dart`
- `beam_of_light/lib/widgets/tutorial_overlay.dart`
- `beam_of_light/pubspec.yaml` (add `audioplayers` dependency)

#### Verification Criteria
- ✅ All sound effects play at appropriate times
- ✅ Haptic feedback works on supported devices
- ✅ Settings persist across app restarts
- ✅ Tutorial appears on first launch only

#### User Confirmation
**Before proceeding**: Test all polish features. Confirm professional feel.

---

### **Phase 12: Testing & Bug Fixing**
**Complexity**: 🟡 Medium
**Estimated Time**: 3-4 days
**Dependencies**: Phase 11

#### Objectives
- Comprehensive testing across devices
- Fix critical bugs
- Ensure platform parity

#### Technical Tasks
1. Write unit tests:
   - Model serialization/deserialization
   - Collision detection logic
   - Beam path building algorithm
   - Target: 80%+ code coverage

2. Write widget tests:
   - Hearts widget updates
   - Win/lose screens
   - Tap detection

3. Write integration tests:
   - Complete level playthrough
   - Win/lose scenarios

4. Manual testing:
   - Test all levels on iOS and Android
   - Test on multiple device sizes
   - Test edge cases (rapid tapping, rotation, backgrounding)

5. Performance testing:
   - 20+ level marathon (memory leaks)
   - Older device testing (iPhone 8, Pixel 4a)

#### Files to Create
- `beam_of_light/test/models/` - Unit tests
- `beam_of_light/test/services/` - Service tests
- `beam_of_light/test/widgets/` - Widget tests
- `beam_of_light/integration_test/` - Integration tests

#### Verification Criteria
- ✅ All unit tests pass (80%+ coverage)
- ✅ All widget tests pass
- ✅ Integration tests complete without errors
- ✅ No crashes during 30-minute play session
- ✅ All levels completable
- ✅ Performance meets targets

#### User Confirmation
**Before proceeding**: Review test results. Confirm all critical bugs fixed.

---

### **Phase 13: Deployment Preparation**
**Complexity**: 🟢 Low
**Estimated Time**: 2-3 days
**Dependencies**: Phase 12

#### Objectives
- Prepare for App Store and Play Store
- Final build configuration
- Marketing assets

#### Technical Tasks
1. iOS Setup:
   - Configure app icons (all sizes)
   - Create launch screen
   - Set bundle identifier
   - Configure signing certificates
   - Build release IPA: `flutter build ipa --release`

2. Android Setup:
   - Configure app icons (all densities)
   - Create adaptive icon
   - Set application ID
   - Configure signing (keystore)
   - Build release AAB: `flutter build appbundle --release`

3. Create store assets:
   - App screenshots (5-10 per platform)
   - App icon (1024×1024)
   - Feature graphic (Android)

4. Write store metadata:
   - App name: "Beam of Lights"
   - Short description
   - Full description
   - Keywords
   - Privacy policy URL

#### Files to Modify
- `beam_of_light/ios/Runner/Info.plist`
- `beam_of_light/android/app/src/main/AndroidManifest.xml`
- `beam_of_light/android/app/build.gradle`
- `beam_of_light/pubspec.yaml` (version number)

#### Verification Criteria
- ✅ Release builds install and run correctly
- ✅ App icons display properly
- ✅ No debug code in release build
- ✅ App size under 50MB
- ✅ All store assets created
- ✅ TestFlight/Internal testing uploaded

#### User Confirmation
**Before proceeding**: Final smoke test on release builds. Confirm ready for submission.

---

## 🎯 Critical Success Factors

### Performance Targets
- **60fps**: Stable frame rate during gameplay
- **Memory**: < 150MB usage
- **App Size**: < 50MB download size
- **Load Time**: < 2s from launch to gameplay

### Quality Standards
- Visual quality matches or exceeds Swift version
- Neon effects look professional and vibrant
- Animations feel smooth and responsive
- UI is intuitive and polished

### Platform Parity
- Feature parity across iOS and Android
- No platform-specific bugs
- Consistent performance on both platforms

---

## 📊 Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Foundation | 1-2 days | 2 days |
| Phase 2: Data Models | 1 day | 3 days |
| Phase 3: Level Loading | 1-2 days | 5 days |
| Phase 4: Game State | 2-3 days | 8 days |
| Phase 5: Flame Foundation | 2-3 days | 11 days |
| Phase 6: Beam Rendering | 2-3 days | 14 days |
| Phase 7: Animations | 3-4 days | 18 days |
| Phase 8: Neon Effects | 4-5 days | 23 days |
| Phase 9: UI/HUD | 2-3 days | 26 days |
| Phase 10: Optimization | 2-3 days | 29 days |
| Phase 11: Polish | 2-3 days | 32 days |
| Phase 12: Testing | 3-4 days | 36 days |
| Phase 13: Deployment | 2-3 days | 39 days |
| **Total** | **~39 days** | **~8 weeks** |

---

## 🔄 Workflow Process

### Before Each Phase
1. **Review plan** for the phase
2. **Confirm objectives** are clear
3. **Ask questions** if anything is unclear

### During Each Phase
1. **Implement features** as specified
2. **Test incrementally** as you go
3. **Document issues** encountered

### After Each Phase
1. **Run verification tests** for that phase
2. **Show progress** to user
3. **Get confirmation** before proceeding
4. **Adjust plan** if needed based on learnings

### Feedback Loop
- User reviews progress after each phase
- User provides feedback and suggestions
- Plan adjustments made collaboratively
- Continue to next phase only after user approval

---

## 📝 Notes

- **Gameplay-first approach**: Basic rendering before neon effects
- **Incremental testing**: Verify each phase before moving forward
- **Performance monitoring**: Profile frequently, optimize early
- **User collaboration**: Confirm at each phase boundary
- **Flexibility**: Adjust plan based on discoveries during implementation

---

**Ready to begin?** Please confirm to start with **Phase 1: Foundation & Dependencies Setup**.
