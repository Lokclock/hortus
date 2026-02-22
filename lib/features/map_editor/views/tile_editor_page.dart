import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/gardens/models/garden_model.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';
import '../models/tilemap_model.dart';
import '../models/zone_model.dart';
import '../widgets/tilemap_painter.dart';

class TileEditorPage extends ConsumerStatefulWidget {
  final String gardenId;

  const TileEditorPage({super.key, required this.gardenId});

  @override
  ConsumerState<TileEditorPage> createState() => _TileEditorPageState();
}

class _TileEditorPageState extends ConsumerState<TileEditorPage> {
  late TileMapData map;

  TileType selectedType = TileType.soil;
  ZoneType selectedZoneType = ZoneType.soil;

  bool isPainting = false;
  int? lastPaintedIndex;
  bool initialized = false;
  List<ui.Image> tileset = [];
  bool loading = true;

  List<Zone> zones = [];

  // Transformation pour zoom/drag
  double scale = 1.0;
  Offset offset = Offset.zero;
  Offset lastFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    map = TileMapData.empty(20, 20, 32);
    _initMapAndTileset();
  }

  Future<void> _initMapAndTileset() async {
    // TileMap vide par défaut ou Firestore plus tard
    map = TileMapData.empty(20, 20, 32);

    // Charge l'image complète du tileset
    final tilemapImage = await loadTilemapImage('assets/tiles/tilemap.png');

    // Exemple : 12 lignes x 24 colonnes dans l'image
    const int tilesetRows = 12;
    const int tilesetCols = 24;

    final tileWidth = tilemapImage.width ~/ tilesetCols;
    final tileHeight = tilemapImage.height ~/ tilesetRows;

    List<ui.Image> loadedTileset = [];

    for (int y = 0; y < tilesetRows; y++) {
      for (int x = 0; x < tilesetCols; x++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final srcRect = Rect.fromLTWH(
          x * tileWidth.toDouble(),
          y * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );

        final dstRect = Rect.fromLTWH(
          0,
          0,
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );
        canvas.drawImageRect(tilemapImage, srcRect, dstRect, Paint());

        final tileImage = await recorder.endRecording().toImage(
          tileWidth,
          tileHeight,
        );
        loadedTileset.add(tileImage);
      }
    }

    setState(() {
      tileset = loadedTileset;
      loading = false;
    });
  }

  Future<ui.Image> loadTilemapImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _initMapIfNeeded(Garden garden) {
    if (initialized) return;
    if (garden.tilemap != null) {
      map = TileMapData.fromMap(garden.tilemap!);
    } else {
      map = TileMapData.empty(20, 20, 32);
    }
    initialized = true;
  }

  void _handleTouch(Offset localPos) {
    // Transforme la position selon le zoom/offset
    final local = (localPos - offset) / scale;

    // Définir la zone en carré fixe (ex : 1 tile)
    const tileSize = 32.0;
    final rect = Rect.fromLTWH(
      (local.dx ~/ tileSize) * tileSize,
      (local.dy ~/ tileSize) * tileSize,
      tileSize,
      tileSize,
    );

    setState(() {
      zones.add(Zone(rect: rect, type: selectedZoneType));
    });
  }

  Future<void> _renderTiles() async {
    // Exemple simple : remplit les zones soil avec sprite 1 et hard avec sprite 2
    for (var zone in zones) {
      final startRow = (zone.rect.top ~/ map.tileSize).toInt();
      final endRow = (zone.rect.bottom ~/ map.tileSize).toInt();
      final startCol = (zone.rect.left ~/ map.tileSize).toInt();
      final endCol = (zone.rect.right ~/ map.tileSize).toInt();

      for (int r = startRow; r < endRow; r++) {
        for (int c = startCol; c < endCol; c++) {
          map.setTile(
            r,
            c,
            zone.type == ZoneType.soil ? 1 : 2,
            zone.type == ZoneType.soil ? TileType.soil : TileType.forbidden,
          );
        }
      }
    }

    setState(() {
      zones.clear(); // on efface les zones après rendu
    });
  }

  Future<void> _saveMap() async {
    final repo = ref.read(gardenRepoProvider);
    await repo.updateGardenTilemap(widget.gardenId, map.toMap());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Map sauvegardée")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gardenAsync = ref.watch(gardenProvider(widget.gardenId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tile Editor"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveMap),
          IconButton(icon: const Icon(Icons.brush), onPressed: _renderTiles),
        ],
      ),
      body: gardenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (garden) {
          _initMapIfNeeded(garden);

          if (loading) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
              _buildZoneTypePalette(),
              Expanded(
                child: InteractiveViewer(
                  scaleEnabled: true,
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: GestureDetector(
                    onPanStart: (d) => _handleTouch(d.localPosition),
                    onPanUpdate: (d) => _handleTouch(d.localPosition),
                    onTapDown: (d) => _handleTouch(d.localPosition),
                    child: CustomPaint(
                      painter: TileMapPainter(map, tileset, zones: zones),
                      size: Size(
                        map.cols * map.tileSize,
                        map.rows * map.tileSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZoneTypePalette() {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ZoneType.values.map((type) {
          return GestureDetector(
            onTap: () => setState(() => selectedZoneType = type),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedZoneType == type
                      ? Colors.black
                      : Colors.transparent,
                  width: 3,
                ),
                color: type == ZoneType.soil ? Colors.brown : Colors.grey,
              ),
              child: Text(type.name),
            ),
          );
        }).toList(),
      ),
    );
  }
}
