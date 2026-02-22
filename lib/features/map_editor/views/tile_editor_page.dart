import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gardens/providers/garden_providers.dart';
import '../providers/tile_editor_notifier.dart';
import '../widgets/tilemap_painter.dart';

class TileEditorPage extends ConsumerStatefulWidget {
  final String gardenId;

  const TileEditorPage({super.key, required this.gardenId});

  @override
  ConsumerState<TileEditorPage> createState() => _TileEditorPageState();
}

class _TileEditorPageState extends ConsumerState<TileEditorPage> {
  bool paintMode = false;
  Offset? selectionStart;
  Offset? selectionEnd;
  bool isSelecting = false;

  static const double tileSizeMeters = 0.2;
  static const double pixelsPerMeter = 100;

  @override
  Widget build(BuildContext context) {
    final gardenAsync = ref.watch(gardenProvider(widget.gardenId));

    return gardenAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (garden) {
        final tilesX = (garden.width / tileSizeMeters).ceil();
        final tilesY = (garden.length / tileSizeMeters).ceil();
        final tileSizePx = tileSizeMeters * pixelsPerMeter;

        final notifier = ref.read(
          tileEditorProvider(
            Size(tilesX.toDouble(), tilesY.toDouble()),
          ).notifier,
        );
        final state = ref.watch(
          tileEditorProvider(Size(tilesX.toDouble(), tilesY.toDouble())),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text("Tile Editor: ${garden.name}"),
            actions: [
              IconButton(
                icon: const Icon(Icons.park),
                onPressed: () => notifier.setBrush(TileType.soil),
              ),
              IconButton(
                icon: const Icon(Icons.grid_on),
                onPressed: () => notifier.setBrush(TileType.hard),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => notifier.setBrush(TileType.empty),
              ),
              IconButton(
                icon: Icon(paintMode ? Icons.edit : Icons.open_with),
                onPressed: () => setState(() => paintMode = !paintMode),
              ),
            ],
          ),
          body: InteractiveViewer(
            minScale: 0.2,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            constrained: false,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(tilesX * tileSizePx, tilesY * tileSizePx),
                  painter: GardenPainter(
                    tiles: state.tiles,
                    tileSize: tileSizePx,
                    selectionStart: selectionStart,
                    selectionEnd: selectionEnd,
                  ),
                ),
                if (paintMode)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (details) {
                        final x = (details.localPosition.dx / tileSizePx)
                            .floor();
                        final y = (details.localPosition.dy / tileSizePx)
                            .floor();
                        if (x >= 0 &&
                            x < state.tiles[0].length &&
                            y >= 0 &&
                            y < state.tiles.length) {
                          final newTiles = List<List<TileType>>.generate(
                            state.tiles.length,
                            (yi) => List.from(state.tiles[yi]),
                          );
                          newTiles[y][x] = state.currentBrush;
                          notifier.updateTiles(newTiles);
                        }
                      },
                      onDoubleTapDown: (details) {
                        isSelecting = true;
                        selectionStart = details.localPosition;
                        selectionEnd = details.localPosition;
                        setState(() {});
                      },
                      onPanUpdate: (details) {
                        if (isSelecting) {
                          selectionEnd = details.localPosition;
                          setState(() {});
                        }
                      },
                      onPanEnd: (details) {
                        if (isSelecting &&
                            selectionStart != null &&
                            selectionEnd != null) {
                          int x1 = (selectionStart!.dx / tileSizePx).floor();
                          int y1 = (selectionStart!.dy / tileSizePx).floor();
                          int x2 = (selectionEnd!.dx / tileSizePx).floor();
                          int y2 = (selectionEnd!.dy / tileSizePx).floor();

                          int left = x1 < x2 ? x1 : x2;
                          int right = x1 > x2 ? x1 : x2;
                          int top = y1 < y2 ? y1 : y2;
                          int bottom = y1 > y2 ? y1 : y2;

                          final newTiles = List<List<TileType>>.generate(
                            state.tiles.length,
                            (y) => List.from(state.tiles[y]),
                          );

                          for (int y = top; y <= bottom; y++) {
                            for (int x = left; x <= right; x++) {
                              newTiles[y][x] = state.currentBrush;
                            }
                          }

                          notifier.updateTiles(newTiles);

                          selectionStart = null;
                          selectionEnd = null;
                          isSelecting = false;
                          setState(() {});
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
