/// GridSize model - represents the dimensions of the game grid
/// Ported from Swift: BeamOfLights/Models/Level.swift
class GridSize {
  final int rows;
  final int columns;

  const GridSize({
    required this.rows,
    required this.columns,
  });

  /// Create GridSize from JSON
  factory GridSize.fromJson(Map<String, dynamic> json) {
    return GridSize(
      rows: json['rows'] as int,
      columns: json['columns'] as int,
    );
  }

  /// Convert GridSize to JSON
  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridSize && other.rows == rows && other.columns == columns;
  }

  @override
  int get hashCode => Object.hash(rows, columns);

  @override
  String toString() => 'GridSize(rows: $rows, columns: $columns)';
}
