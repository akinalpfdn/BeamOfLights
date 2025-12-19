import 'package:flutter_test/flutter_test.dart';
import 'package:beam_of_light/services/level_service.dart';
import 'package:beam_of_light/services/beam_builder.dart';
import 'package:beam_of_light/models/level.dart';
import 'package:beam_of_light/models/cell.dart';
import 'package:beam_of_light/models/grid_size.dart';
import 'package:beam_of_light/models/beam.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: Level Loading & Beam Building', () {
    group('LevelService', () {
      test('loads all levels from JSON', () async {
        final levels = await LevelService.loadAllLevels();

        expect(levels, isNotEmpty);
        expect(levels.length, greaterThan(0));

        print('✅ Loaded ${levels.length} level(s)');
      });

      test('caches levels after first load', () async {
        // First load
        final levels1 = await LevelService.loadAllLevels();

        // Second load should return cached version
        final levels2 = await LevelService.loadAllLevels();

        expect(identical(levels1, levels2), isTrue);
      });

      test('getLevel returns correct level by index', () async {
        final level = await LevelService.getLevel(0);

        expect(level, isNotNull);
        expect(level!.levelNumber, greaterThan(0));
      });

      test('getLevel returns null for invalid index', () async {
        final level = await LevelService.getLevel(999);
        expect(level, isNull);
      });

      test('getLevelCount returns correct count', () async {
        final count = await LevelService.getLevelCount();
        expect(count, greaterThan(0));
      });

      test('validateLevel checks level validity', () async {
        final level = await LevelService.getLevel(0);
        expect(level, isNotNull);

        final isValid = LevelService.validateLevel(level!);
        expect(isValid, isTrue);

        print('✅ Level ${level.levelNumber} is valid');
      });
    });

    group('BeamBuilder', () {
      test('builds beams from simple straight path', () {
        // Create a simple level with one horizontal beam
        final cells = [
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.path,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 2,
              type: CellType.path,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 3,
              type: CellType.end,
              direction: Direction.none,
              color: 'blue'),
        ];

        final level = Level(
          levelNumber: 1,
          gridSize: const GridSize(rows: 5, columns: 5),
          difficulty: 3,
          cells: cells,
        );

        final beams = BeamBuilder.buildBeams(level);

        expect(beams.length, 1);
        expect(beams.first.cells.length, 4);
        expect(beams.first.color, 'blue');
        expect(beams.first.direction, Direction.right);

        print('✅ Built beam with ${beams.first.cells.length} cells, direction: ${beams.first.direction}');
      });

      test('builds beams with turns', () {
        // Create a beam that turns
        final cells = [
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'red'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.path,
              direction: Direction.down,
              color: 'red'), // Turn down
          Cell(
              row: 1,
              column: 1,
              type: CellType.path,
              direction: Direction.right,
              color: 'red'),
          Cell(
              row: 1,
              column: 2,
              type: CellType.end,
              direction: Direction.none,
              color: 'red'),
        ];

        final level = Level(
          levelNumber: 1,
          gridSize: const GridSize(rows: 5, columns: 5),
          difficulty: 3,
          cells: cells,
        );

        final beams = BeamBuilder.buildBeams(level);

        expect(beams.length, 1);
        expect(beams.first.cells.length, 4);
        expect(beams.first.direction, Direction.right); // Last direction before end
      });

      test('builds multiple beams from level', () {
        // Create level with two beams
        final cells = [
          // Blue beam (horizontal)
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.end,
              direction: Direction.none,
              color: 'blue'),
          // Red beam (vertical)
          Cell(
              row: 1,
              column: 0,
              type: CellType.start,
              direction: Direction.down,
              color: 'red'),
          Cell(
              row: 2,
              column: 0,
              type: CellType.end,
              direction: Direction.none,
              color: 'red'),
        ];

        final level = Level(
          levelNumber: 1,
          gridSize: const GridSize(rows: 5, columns: 5),
          difficulty: 3,
          cells: cells,
        );

        final beams = BeamBuilder.buildBeams(level);

        expect(beams.length, 2);
        expect(beams.map((b) => b.color).toSet(), {'blue', 'red'});

        print('✅ Built ${beams.length} beams from level');
      });

      test('builds beams from actual level JSON', () async {
        final level = await LevelService.getLevel(0);
        expect(level, isNotNull);

        final beams = BeamBuilder.buildBeams(level!);

        expect(beams, isNotEmpty);

        print('✅ Built ${beams.length} beams from Level ${level.levelNumber}');

        // Print details of first beam
        if (beams.isNotEmpty) {
          final firstBeam = beams.first;
          print('   First beam: ${firstBeam.color}, ${firstBeam.cells.length} cells, direction: ${firstBeam.direction}');

          // Validate the beam
          final isValid = BeamBuilder.validateBeamPath(firstBeam);
          print('   Valid: $isValid');
        }
      });

      test('validateBeamPath checks beam validity', () {
        final validCells = [
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.end,
              direction: Direction.none,
              color: 'blue'),
        ];

        final validBeam = Beam(cells: validCells, color: 'blue');
        expect(BeamBuilder.validateBeamPath(validBeam), isTrue);

        // Invalid beam (no end cell)
        final invalidCells = [
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.path,
              direction: Direction.right,
              color: 'blue'),
        ];

        final invalidBeam = Beam(cells: invalidCells, color: 'blue');
        expect(BeamBuilder.validateBeamPath(invalidBeam), isFalse);
      });

      test('debugBeamPath outputs readable path information', () {
        final cells = [
          Cell(
              row: 0,
              column: 0,
              type: CellType.start,
              direction: Direction.right,
              color: 'blue'),
          Cell(
              row: 0,
              column: 1,
              type: CellType.path,
              direction: Direction.down,
              color: 'blue'),
          Cell(
              row: 1,
              column: 1,
              type: CellType.end,
              direction: Direction.none,
              color: 'blue'),
        ];

        final beam = Beam(cells: cells, color: 'blue');
        final debugOutput = BeamBuilder.debugBeamPath(beam);

        expect(debugOutput, contains('blue'));
        expect(debugOutput, contains('3 cells'));
        expect(debugOutput, contains('→')); // Right arrow
        expect(debugOutput, contains('↓')); // Down arrow
        expect(debugOutput, contains('•')); // End marker

        print('\n📊 Debug output:\n$debugOutput');
      });
    });

    group('Integration: Full Level Processing', () {
      test('loads level and builds all beams correctly', () async {
        final level = await LevelService.getLevel(0);
        expect(level, isNotNull);

        final beams = BeamBuilder.buildBeams(level!);

        expect(beams, isNotEmpty);

        print('\n🎮 Level ${level.levelNumber} Processing:');
        print('   Grid: ${level.gridSize.rows}x${level.gridSize.columns}');
        print('   Difficulty: ${level.difficulty} hearts');
        print('   Total cells: ${level.cells.length}');
        print('   Beams: ${beams.length}');

        // Verify all beams
        int validBeams = 0;
        for (final beam in beams) {
          if (BeamBuilder.validateBeamPath(beam)) {
            validBeams++;
          }
        }

        print('   Valid beams: $validBeams/${beams.length}');

        expect(validBeams, equals(beams.length));
      });
    });
  });
}
