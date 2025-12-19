import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:beam_of_light/models/cell.dart';
import 'package:beam_of_light/models/grid_size.dart';
import 'package:beam_of_light/models/level.dart';
import 'package:beam_of_light/models/beam.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Data Models', () {
    test('Cell enum parsing works correctly', () {
      expect(CellType.fromString('start'), CellType.start);
      expect(CellType.fromString('end'), CellType.end);
      expect(CellType.fromString('path'), CellType.path);
      expect(CellType.fromString('empty'), CellType.empty);

      expect(Direction.fromString('up'), Direction.up);
      expect(Direction.fromString('down'), Direction.down);
      expect(Direction.fromString('left'), Direction.left);
      expect(Direction.fromString('right'), Direction.right);
      expect(Direction.fromString('none'), Direction.none);
    });

    test('Cell JSON deserialization works', () {
      final json = {
        'row': 5,
        'column': 10,
        'type': 'start',
        'direction': 'right',
        'color': '#FFD5C8',
      };

      final cell = Cell.fromJson(json);
      expect(cell.row, 5);
      expect(cell.column, 10);
      expect(cell.type, CellType.start);
      expect(cell.direction, Direction.right);
      expect(cell.color, '#FFD5C8');
    });

    test('GridSize JSON deserialization works', () {
      final json = {'rows': 25, 'columns': 25};
      final gridSize = GridSize.fromJson(json);
      expect(gridSize.rows, 25);
      expect(gridSize.columns, 25);
    });

    test('Level JSON deserialization works', () {
      final json = {
        'levelNumber': 1,
        'gridSize': {'rows': 25, 'columns': 25},
        'difficulty': 4,
        'cells': [
          {
            'row': 0,
            'column': 0,
            'type': 'start',
            'direction': 'right',
            'color': '#FFD5C8'
          },
          {
            'row': 0,
            'column': 1,
            'type': 'path',
            'direction': 'right',
            'color': '#FFD5C8'
          },
          {
            'row': 0,
            'column': 2,
            'type': 'end',
            'direction': 'none',
            'color': '#FFD5C8'
          },
        ],
      };

      final level = Level.fromJson(json);
      expect(level.levelNumber, 1);
      expect(level.gridSize.rows, 25);
      expect(level.gridSize.columns, 25);
      expect(level.difficulty, 4);
      expect(level.cells.length, 3);
      expect(level.startCell, isNotNull);
      expect(level.endCell, isNotNull);
    });

    test('Beam direction calculation works correctly', () {
      // Create a simple beam with start → path → end
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
            type: CellType.end,
            direction: Direction.none,
            color: 'blue'),
      ];

      final beam = Beam(cells: cells, color: 'blue');

      // Direction should be 'right' from the second-to-last cell
      // (since last cell is an end cell with direction.none)
      expect(beam.direction, Direction.right);
    });

    test('levels.json loads successfully', () async {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      expect(jsonString, isNotEmpty);

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final levelsData = LevelsData.fromJson(jsonData);

      expect(levelsData.levels, isNotEmpty);
      expect(levelsData.levels.length, greaterThan(0));

      // Verify first level has valid structure
      final firstLevel = levelsData.levels.first;
      expect(firstLevel.levelNumber, greaterThan(0));
      expect(firstLevel.gridSize.rows, greaterThan(0));
      expect(firstLevel.gridSize.columns, greaterThan(0));
      expect(firstLevel.difficulty, greaterThanOrEqualTo(3));
      expect(firstLevel.difficulty, lessThanOrEqualTo(5));
      expect(firstLevel.cells, isNotEmpty);

      print('✅ Loaded ${levelsData.levels.length} levels from JSON');
      print('📊 First level: ${firstLevel.toString()}');
    });
  });
}
