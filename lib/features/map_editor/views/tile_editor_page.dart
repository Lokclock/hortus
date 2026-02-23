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

  Widget _buildBottomBar(TileEditorNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolButton(Icons.park, Colors.brown, () {
            notifier.setBrush(TileType.soil);
            setState(() => paintMode = true);
          }),

          _toolButton(Icons.grid_on, Colors.grey, () {
            notifier.setBrush(TileType.hard);
            setState(() => paintMode = true);
          }),

          _toolButton(Icons.delete, Colors.red, () {
            notifier.setBrush(TileType.empty);
            setState(() => paintMode = true);
          }),

          _toolButton(Icons.open_with, Colors.blue, () {
            setState(() => paintMode = false);
          }),

          _toolButton(Icons.undo, Colors.white, notifier.undo),
          _toolButton(Icons.redo, Colors.white, notifier.redo),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

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
          appBar: AppBar(title: Text("Tile Editor: ${garden.name}")),
          body: Stack(
            children: [
              InteractiveViewer(
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

                          /// TAP = peindre une seule case
                          onTapDown: (details) {
                            if (!paintMode) return;

                            final x = (details.localPosition.dx / tileSizePx)
                                .floor();
                            final y = (details.localPosition.dy / tileSizePx)
                                .floor();

                            final width = state.tiles[0].length;
                            final height = state.tiles.length;

                            if (x >= 0 && x < width && y >= 0 && y < height) {
                              notifier.paintTile(x, y);
                            }
                          },

                          /// DOUBLE TAP = début sélection rectangle
                          onDoubleTapDown: (details) {
                            if (!paintMode) return;

                            isSelecting = true;
                            selectionStart = details.localPosition;
                            selectionEnd = details.localPosition;
                            setState(() {});
                          },

                          /// DRAG = soit pinceau soit sélection
                          onPanUpdate: (details) {
                            if (!paintMode) return;

                            /// --- MODE RECTANGLE ---
                            if (isSelecting) {
                              selectionEnd = details.localPosition;
                              setState(() {});
                              return;
                            }

                            /// --- MODE PINCEAU CONTINU ---
                            final x = (details.localPosition.dx / tileSizePx)
                                .floor();
                            final y = (details.localPosition.dy / tileSizePx)
                                .floor();

                            final width = state.tiles[0].length;
                            final height = state.tiles.length;

                            if (x >= 0 && x < width && y >= 0 && y < height) {
                              notifier.paintInterpolated(x, y);
                            }
                          },

                          /// FIN DU DRAG
                          onPanEnd: (details) {
                            if (!paintMode) return;

                            notifier.endPaint();

                            /// --- FIN SELECTION RECTANGLE ---
                            if (isSelecting &&
                                selectionStart != null &&
                                selectionEnd != null) {
                              int x1 = (selectionStart!.dx / tileSizePx)
                                  .floor();
                              int y1 = (selectionStart!.dy / tileSizePx)
                                  .floor();
                              int x2 = (selectionEnd!.dx / tileSizePx).floor();
                              int y2 = (selectionEnd!.dy / tileSizePx).floor();

                              final width = state.tiles[0].length;
                              final height = state.tiles.length;

                              /// clamp dans les limites du jardin
                              x1 = x1.clamp(0, width - 1);
                              x2 = x2.clamp(0, width - 1);
                              y1 = y1.clamp(0, height - 1);
                              y2 = y2.clamp(0, height - 1);

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
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildBottomBar(notifier),
              ),
            ],
          ),
        );
      },
    );
  }
}
