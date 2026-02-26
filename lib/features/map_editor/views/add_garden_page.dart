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
  final TransformationController _transformationController =
      TransformationController();

  bool gridVisible = false;

  @override
  void initState() {
    super.initState();
    _tilesetFuture = loadTileset();
    _transformationController.addListener(() {
      setState(() {});
    });
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
    final hardData = await rootBundle.load('assets/tiles/tilemap_hard_v2.png');
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
          _toolButton(Icons.grid_4x4, Colors.cyan, gridVisible, () {
            setState(() => gridVisible = !gridVisible);
          }),
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
    final zoom = _transformationController.value.getMaxScaleOnAxis();
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
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
        gridVisible
            ? Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BlueprintScalePainter(
                      zoom: _transformationController.value.getMaxScaleOnAxis(),
                      pixelsPerMeter: pixelsPerMeter,
                    ),
                  ),
                ),
              )
            : SizedBox(),

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

class BlueprintScalePainter extends CustomPainter {
  final double pixelsPerMeter;
  final double zoom;

  BlueprintScalePainter({required this.pixelsPerMeter, required this.zoom});

  // ============================================================
  // CONFIG
  // ============================================================

  static const List<double> _steps = [
    0.1,
    0.2,
    0.5,
    1,
    2,
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    1000,
  ];

  static const double _minReadablePx = 60;

  // ============================================================
  // STEP SELECTION
  // ============================================================

  double _chooseMainStep(double ppm) {
    for (final step in _steps) {
      if (step * ppm >= _minReadablePx) {
        return step;
      }
    }
    return _steps.last;
  }

  List<double> _subdivisionsFor(double step) {
    if (step <= 0.1) return const [];

    if (step == 0.2) return const [0.1];
    if (step == 0.5) return const [0.1];
    if (step == 1) return const [0.1];
    if (step == 2) return const [0.5];
    if (step == 5) return const [1];
    if (step == 10) return const [1];
    if (step == 20) return const [5];
    if (step == 50) return const [10];
    if (step == 100) return const [20];

    return const [];
  }

  // ============================================================
  // PAINT
  // ============================================================

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ppm = pixelsPerMeter * zoom;

    final mainStep = _chooseMainStep(ppm);
    final subSteps = _subdivisionsFor(mainStep);

    // ------------------------------------------------------------
    // Background
    // ------------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const ui.Color.fromARGB(15, 11, 30, 45),
    );

    // ------------------------------------------------------------
    // Subdivisions (fine grid)
    // ------------------------------------------------------------
    final subPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.15)
      ..strokeWidth = 1;

    for (final sub in subSteps) {
      final stepPx = sub * ppm;
      if (stepPx < 20) continue;

      _drawGrid(canvas, size, center, stepPx, subPaint);
    }

    // ------------------------------------------------------------
    // Main grid
    // ------------------------------------------------------------
    final mainPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.35)
      ..strokeWidth = 1.5;

    final mainStepPx = mainStep * ppm;
    _drawGrid(canvas, size, center, mainStepPx, mainPaint);

    // ------------------------------------------------------------
    // Axes
    // ------------------------------------------------------------
    final axisPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.7)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );

    // ------------------------------------------------------------
    // Labels (ONLY main step)
    // ------------------------------------------------------------
    final textStyle = TextStyle(
      color: Colors.cyanAccent.withOpacity(1),
      fontSize: 14,
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, Offset pos) {
      tp.text = TextSpan(text: text, style: textStyle);
      tp.layout();
      tp.paint(canvas, pos);
    }

    int i = 1;

    for (double dx = mainStepPx; dx < size.width / 2; dx += mainStepPx, i++) {
      final distance = i * mainStep;
      drawLabel(
        _formatStep(distance),
        Offset(center.dx + dx + 4, center.dy + 4),
      );
    }

    i = 1;
    for (double dx = mainStepPx; dx < size.width / 2; dx += mainStepPx, i++) {
      final distance = i * mainStep;
      drawLabel(
        _formatStep(distance),
        Offset(center.dx - dx + 4, center.dy + 4),
      );
    }

    int j = 1;

    for (double dy = mainStepPx; dy < size.height / 2; dy += mainStepPx, j++) {
      final distance = j * mainStep;
      drawLabel(
        _formatStep(distance),
        Offset(center.dx + 4, center.dy + dy + 4),
      );
    }

    j = 1;
    for (double dy = mainStepPx; dy < size.height / 2; dy += mainStepPx, j++) {
      final distance = j * mainStep;
      drawLabel(
        _formatStep(distance),
        Offset(center.dx + 4, center.dy - dy + 4),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _drawGrid(
    Canvas canvas,
    Size size,
    Offset center,
    double stepPx,
    Paint paint,
  ) {
    for (double dx = stepPx; dx < size.width / 2; dx += stepPx) {
      canvas.drawLine(
        Offset(center.dx + dx, 0),
        Offset(center.dx + dx, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx - dx, 0),
        Offset(center.dx - dx, size.height),
        paint,
      );
    }

    for (double dy = stepPx; dy < size.height / 2; dy += stepPx) {
      canvas.drawLine(
        Offset(0, center.dy + dy),
        Offset(size.width, center.dy + dy),
        paint,
      );
      canvas.drawLine(
        Offset(0, center.dy - dy),
        Offset(size.width, center.dy - dy),
        paint,
      );
    }
  }

  String _formatStep(double meters) {
    if (meters < 1) {
      return '${(meters * 100).round()}cm';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).round()}km';
    }
    return '${meters.round()}m';
  }

  @override
  bool shouldRepaint(covariant BlueprintScalePainter oldDelegate) {
    return oldDelegate.zoom != zoom ||
        oldDelegate.pixelsPerMeter != pixelsPerMeter;
  }
}
