class TileMap {
  final int width;
  final int height;
  final List<int> tiles;

  TileMap({required this.width, required this.height, required this.tiles});

  int getTile(int x, int y) => tiles[y * width + x];

  TileMap copyWithTile(int x, int y, int value) {
    final newTiles = List<int>.from(tiles);
    newTiles[y * width + x] = value;

    return TileMap(width: width, height: height, tiles: newTiles);
  }

  TileMap paintRect(int x1, int y1, int x2, int y2, int value) {
    final newTiles = List<int>.from(tiles);

    final minX = x1 < x2 ? x1 : x2;
    final maxX = x1 > x2 ? x1 : x2;
    final minY = y1 < y2 ? y1 : y2;
    final maxY = y1 > y2 ? y1 : y2;

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        newTiles[y * width + x] = value;
      }
    }

    return TileMap(width: width, height: height, tiles: newTiles);
  }

  Map<String, dynamic> toMap() => {'w': width, 'h': height, 'tiles': tiles};

  factory TileMap.fromMap(Map<String, dynamic> map) {
    return TileMap(
      width: map['w'],
      height: map['h'],
      tiles: List<int>.from(map['tiles']),
    );
  }
}
