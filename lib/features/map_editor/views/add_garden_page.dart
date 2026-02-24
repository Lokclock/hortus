import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';
import 'package:hortus_app/features/map_editor/widgets/tilemap_painter.dart';
import '../../gardens/providers/garden_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/firebase_providers.dart';

enum EditorScreen {
  choice, // aucune image
  image, // image affichée mais pas en édition
  tileEditor, // mode édition actif
}

class AddGardenPage extends ConsumerStatefulWidget {
  const AddGardenPage({super.key});

  @override
  ConsumerState<AddGardenPage> createState() => _AddGardenPageState();
}

class _AddGardenPageState extends ConsumerState<AddGardenPage> {
  final _formKey = GlobalKey<FormState>();

  EditorScreen screen = EditorScreen.choice;

  final nameCtrl = TextEditingController(text: "");
  final widthCtrl = TextEditingController(text: "20");
  final lengthCtrl = TextEditingController(text: "20");

  bool dimensionsCollapsed = false;

  bool paintMode = false;
  Offset? selectionStart;
  Offset? selectionEnd;
  bool isSelecting = false;

  static const double tileSizeMeters = 0.2;
  static const double pixelsPerMeter = 100;
  ui.Image? soilImage;
  ui.Image? hardImage;
  Map<int, Rect>? soilRects;
  Map<int, Rect>? hardRects;

  @override
  void initState() {
    super.initState();
    _tilesetFuture = loadTileset();
  }

  Future<void>? _tilesetFuture;

  Future<void> loadTileset() async {
    // Soil
    final soilData = await rootBundle.load('assets/tiles/tilemap_soil.png');
    final soilCodec = await ui.instantiateImageCodec(
      soilData.buffer.asUint8List(),
    );
    final soilFrame = await soilCodec.getNextFrame();
    soilImage = soilFrame.image;

    soilRects = generateAutoTileRects(
      tilePixelSize: 64,
      columns: 10,
      startIndex: 0,
      tileType: 'soil',
    );

    // Hard
    final hardData = await rootBundle.load('assets/tiles/tilemap_hard.png');
    final hardCodec = await ui.instantiateImageCodec(
      hardData.buffer.asUint8List(),
    );
    final hardFrame = await hardCodec.getNextFrame();
    hardImage = hardFrame.image;

    hardRects = generateAutoTileRects(
      tilePixelSize: 64,
      columns: 4,
      startIndex: 0,
      tileType: 'hard',
    );
  }
  // ============================================================
  // SAVE GARDEN
  // ============================================================

  Future<void> _saveGarden(TileEditorState state) async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserProvider);
    if (uid == null) return;

    final userDoc = await ref
        .read(firestoreProvider)
        .collection('users')
        .doc(uid)
        .get();

    final username = userDoc.data()?['username'] ?? "inconnu";

    await ref
        .read(gardenRepoProvider)
        .createGarden(
          name: nameCtrl.text,
          width: double.parse(widthCtrl.text),
          length: double.parse(lengthCtrl.text),
          ownerUsername: username,
          isPublic: false,
          isEditable: false,
          tiles: state.tiles,
        );

    if (mounted) Navigator.pop(context);
  }

  // ============================================================
  // DIMENSIONS -> GRID SIZE
  // ============================================================

  Size _computeGridSize() {
    final width = double.tryParse(widthCtrl.text) ?? 1;
    final length = double.tryParse(lengthCtrl.text) ?? 1;

    final tilesX = (width / tileSizeMeters).ceil();
    final tilesY = (length / tileSizeMeters).ceil();

    return Size(tilesX.toDouble(), tilesY.toDouble());
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _toolButton(
    IconData icon,
    Color color,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.25) : Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: active ? 3 : 2),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildBottomBar(TileEditorNotifier notifier, TileEditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolButton(
            Icons.grass,
            Colors.brown,
            state.currentBrush == TileType.soil && paintMode,
            () {
              notifier.setBrush(TileType.soil);
              setState(() => paintMode = true);
            },
          ),
          _toolButton(
            Icons.square,
            Colors.grey,
            state.currentBrush == TileType.hard && paintMode,
            () {
              notifier.setBrush(TileType.hard);
              setState(() => paintMode = true);
            },
          ),
          _toolButton(
            Icons.delete,
            Colors.red,
            state.currentBrush == TileType.empty && paintMode,
            () {
              notifier.setBrush(TileType.empty);
              setState(() => paintMode = true);
            },
          ),
          _toolButton(Icons.pan_tool, Colors.blue, !paintMode, () {
            setState(() => paintMode = false);
          }),
          _toolButton(Icons.undo, Colors.white, false, notifier.undo),
          _toolButton(Icons.redo, Colors.white, false, notifier.redo),
        ],
      ),
    );
  }

  Widget _buildChoiceScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nom du jardin"),
              validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Largeur (m)"),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: lengthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Longueur (m)",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  screen = EditorScreen.image;
                });
              },
              child: const Text("Choisir une image de carte"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  screen = EditorScreen.tileEditor;
                });
              },
              child: const Text("Créer une carte"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (screen) {
      case EditorScreen.choice:
        return _buildChoiceScreen();

      case EditorScreen.image:
        return imagePickerWidget(); // ton widget existant

      case EditorScreen.tileEditor:
        return tileMapEditor(); // ton éditeur
    }
  }

  Widget imagePickerWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Ici tu pourrais implémenter un sélecteur d'image"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Passer à l'éditeur de carte"),
          ),
        ],
      ),
    );
  }

  Widget tileMapEditor() {
    final gridSize = _computeGridSize();
    final tileSizePx = tileSizeMeters * pixelsPerMeter;

    final notifier = ref.read(tileEditorProvider(gridSize).notifier);
    final state = ref.watch(tileEditorProvider(gridSize));
    if (soilImage == null ||
        hardImage == null ||
        soilRects == null ||
        hardRects == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.2,
          maxScale: 8,
          boundaryMargin: const EdgeInsets.all(5000),
          constrained: false,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(
                  gridSize.width * tileSizePx,
                  gridSize.height * tileSizePx,
                ),
                painter: GardenPainter(
                  tiles: state.tiles,
                  tileSize: tileSizePx,
                  selectionStart: selectionStart,
                  selectionEnd: selectionEnd,
                  soilImage: soilImage!,
                  hardImage: hardImage!,
                  soilRects: soilRects!,
                  hardRects: hardRects!,
                ),
              ),

              if (paintMode)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,

                    onTapDown: (d) {
                      final x = (d.localPosition.dx / tileSizePx).floor();
                      final y = (d.localPosition.dy / tileSizePx).floor();
                      notifier.paintTile(x, y);
                    },

                    onDoubleTapDown: (d) {
                      isSelecting = true;
                      selectionStart = d.localPosition;
                      selectionEnd = d.localPosition;
                      setState(() {});
                    },

                    onPanUpdate: (d) {
                      if (isSelecting) {
                        selectionEnd = d.localPosition;
                        setState(() {});
                        return;
                      }

                      final x = (d.localPosition.dx / tileSizePx).floor();
                      final y = (d.localPosition.dy / tileSizePx).floor();

                      notifier.paintInterpolated(x, y);
                    },

                    onPanEnd: (_) {
                      notifier.endPaint();

                      if (isSelecting &&
                          selectionStart != null &&
                          selectionEnd != null) {
                        notifier.paintRectangle(
                          selectionStart!,
                          selectionEnd!,
                          tileSizePx,
                        );

                        isSelecting = false;
                        selectionStart = null;
                        selectionEnd = null;
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
          child: _buildBottomBar(notifier, state),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final width = double.tryParse(widthCtrl.text) ?? 1;
    final length = double.tryParse(lengthCtrl.text) ?? 1;
    final tilesX = (width / tileSizeMeters).ceil();
    final tilesY = (length / tileSizeMeters).ceil();
    final gridSize = _computeGridSize();
    final state = ref.watch(tileEditorProvider(gridSize));
    switch (screen) {
      case EditorScreen.choice:
        return AppBar(title: Text("Créer un jardin"));

      case EditorScreen.image:
      case EditorScreen.tileEditor:
        return AppBar(
          title: Text(nameCtrl.text),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveGarden(state),
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                screen = EditorScreen.choice;
                ref
                    .read(tileEditorProvider(gridSize).notifier)
                    .reset(tilesX, tilesY);
              });
            },
          ),
        );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Form(key: _formKey, child: _buildBody()),
    );
  }
}
