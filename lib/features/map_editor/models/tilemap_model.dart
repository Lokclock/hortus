enum TileType { empty, soil, path, grass, water, forbidden }

class TileMapData {
  final int rows;
  final int cols;
  final double tileSize;
  final List<int> sprites;
  final List<int> types;

  TileMapData({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.sprites,
    required this.types,
  });

  int index(int row, int col) => row * cols + col;

  void setTile(int row, int col, int spriteIndex, TileType type) {
    final i = index(row, col);
    sprites[i] = spriteIndex;
    types[i] = type.index;
  }

  TileType getType(int row, int col) {
    return TileType.values[types[index(row, col)]];
  }

  int getSprite(int row, int col) {
    return sprites[index(row, col)];
  }

  Map<String, dynamic> toMap() {
    return {
      'rows': rows,
      'cols': cols,
      'tileSize': tileSize,
      'sprites': sprites,
      'types': types,
    };
  }

  factory TileMapData.fromMap(Map<String, dynamic> map) {
    return TileMapData(
      rows: map['rows'],
      cols: map['cols'],
      tileSize: (map['tileSize'] as num).toDouble(),
      sprites: List<int>.from(map['sprites']),
      types: List<int>.from(map['types']),
    );
  }

  factory TileMapData.empty(int rows, int cols, double tileSize) {
    final count = rows * cols;
    return TileMapData(
      rows: rows,
      cols: cols,
      tileSize: tileSize,
      sprites: List.filled(count, 0),
      types: List.filled(count, TileType.empty.index),
    );
  }
}
