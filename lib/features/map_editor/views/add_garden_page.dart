import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';
import 'package:hortus_app/features/map_editor/widgets/tilemap_painter.dart';
import '../../gardens/providers/garden_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/firebase_providers.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

enum EditorScreen {
  choice, // aucune image
  image, // image affichée mais pas en édition
  tileEditor, // mode édition actif
}

enum ViewMode { panZoom, rotate }

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

  bool gridVisible = false;

  Matrix4 _transform = Matrix4.identity();

  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _translation = Offset.zero;

  late Offset _lastFocalPoint;
  late double _startScale;
  late double _startRotation;
  late Offset _startTranslation;

  Size _viewportSize = Size.zero;
  Size? _mapWorldSize;

  ViewMode _viewMode = ViewMode.panZoom;

  ui.Image? _backgroundCache;
  Size? _backgroundCacheSize;
  bool _isBuildingCache = false;

  bool _hasInitializedView = false;

  @override
  void initState() {
    super.initState();
    _tilesetFuture = loadTileset();
  }

  Offset _screenToWorld(Offset screenPos) {
    final inv = Matrix4.inverted(_transform);
    return MatrixUtils.transformPoint(inv, screenPos);
  }

  Offset _screenDeltaToWorld(Offset delta) {
    // Enlever le scale
    final scaled = delta / _scale;

    // Enlever la rotation
    final cosR = math.cos(-_rotation);
    final sinR = math.sin(-_rotation);

    return Offset(
      scaled.dx * cosR - scaled.dy * sinR,
      scaled.dx * sinR + scaled.dy * cosR,
    );
  }

  Future<void> _rebuildBackgroundCache(Size size, GardenPainter painter) async {
    if (_isBuildingCache) return;

    _isBuildingCache = true;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Dessin du fond UNIQUEMENT
    for (int y = 0; y < painter.tilesHigh; y++) {
      for (int x = 0; x < painter.tilesWide; x++) {
        final isTop = y == 0;
        final isBottom = y == painter.tilesHigh - 1;
        final isLeft = x == 0;
        final isRight = x == painter.tilesWide - 1;

        int index;
        if (isTop && isLeft)
          index = 5;
        else if (isTop && isRight)
          index = 7;
        else if (isBottom && isLeft)
          index = 25;
        else if (isBottom && isRight)
          index = 27;
        else if (isTop)
          index = 6;
        else if (isBottom)
          index = 26;
        else if (isLeft)
          index = 15;
        else if (isRight)
          index = 17;
        else
          index = 16;

        final srcRect = Rect.fromLTWH(
          (index % 10) * 64,
          (index ~/ 10) * 64,
          64,
          64,
        );

        canvas.drawImageRect(
          painter.soilImage,
          srcRect,
          Rect.fromLTWH(
            x * painter.tileSize,
            y * painter.tileSize,
            painter.tileSize,
            painter.tileSize,
          ),
          Paint(),
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());

    if (!mounted) return;

    setState(() {
      _backgroundCache = image;
      _backgroundCacheSize = size;
      _isBuildingCache = false;
    });
  }

  Rect _computeVisibleWorldRect() {
    final inv = Matrix4.inverted(_transform);

    final topLeft = MatrixUtils.transformPoint(inv, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inv,
      Offset(_viewportSize.width, _viewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
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
      child: Column(
        children: [
          Row(
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
              _toolButton(
                Icons.zoom_in_map,
                Colors.blue,
                !paintMode && _viewMode == ViewMode.panZoom,
                () {
                  setState(() => paintMode = false);
                  setState(() => _viewMode = ViewMode.panZoom);
                },
              ),
              _toolButton(
                Icons.rotate_90_degrees_cw_sharp,
                Colors.blue,
                !paintMode && _viewMode == ViewMode.rotate,
                () {
                  setState(() => paintMode = false);
                  setState(() => _viewMode = ViewMode.rotate);
                },
              ),
              _toolButton(Icons.reset_tv_rounded, Colors.blue, false, () {
                resetView();
              }),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolButton(Icons.undo, Colors.white, false, notifier.undo),
              _toolButton(Icons.redo, Colors.white, false, notifier.redo),
              _toolButton(Icons.grid_4x4, Colors.cyan, gridVisible, () {
                setState(() => gridVisible = !gridVisible);
              }),
              _toolButton(Icons.layers, Colors.cyan, false, () {}),
            ],
          ),
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

  void _updateTransform() {
    // On veut que le zoom se fasse autour du centre du viewport
    final center = Vector3(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
      0,
    );

    _transform = Matrix4.identity()
      ..translateByVector3(center) // on déplace le centre au milieu
      ..scaleByDouble(1.0, 1.0, 1.0, _scale) // on applique le zoom
      ..rotateZ(_rotation) // rotation si besoin
      ..translateByVector3(
        Vector3(-center.x + _translation.dx, -center.y + _translation.dy, 0),
      );
  }

  void resetView() {
    setState(() {
      _scale = 1;
      _rotation = 0;
      _translation = Offset.zero;
      _updateTransform();
      _viewMode = ViewMode.panZoom;
    });
  }

  void resetViewToFit() {
    if (_mapWorldSize != null) {
      final mapWidth = _mapWorldSize!.width;
      final mapHeight = _mapWorldSize!.height;

      final viewWidth = _viewportSize.width;
      final viewHeight = _viewportSize.height;

      // --- 1. Rotation : grand axe vertical
      if (mapWidth > mapHeight) {
        _rotation = math.pi / 2;
      } else {
        _rotation = 0;
      }

      // --- 2. Dimensions après rotation
      final rotatedWidth = _rotation == 0 ? mapWidth : mapHeight;
      final rotatedHeight = _rotation == 0 ? mapHeight : mapWidth;

      // --- 3. Scale pour fitter
      _scale = math.min(viewWidth / rotatedWidth, viewHeight / rotatedHeight);

      // marge de confort
      _scale *= 0.95;

      // --- 4. Centrage
      final centerWorld = Offset(mapWidth / 2, mapHeight / 2);
      final centerScreen = Offset(viewWidth / 2, viewHeight / 2);

      _translation = centerScreen - centerWorld * 1 / _scale;
    }
  }

  Widget tileMapEditor() {
    final gridSize = _computeGridSize();
    final tileSizePx = tileSizeMeters * pixelsPerMeter;

    final mapWorldSize = Size(
      gridSize.width * tileSizePx,
      gridSize.height * tileSizePx,
    );

    // initialisation UNE SEULE FOIS
    _mapWorldSize ??= mapWorldSize;

    final notifier = ref.read(tileEditorProvider(gridSize).notifier);
    final state = ref.watch(tileEditorProvider(gridSize));

    final visibleRect = _computeVisibleWorldRect();

    if (soilImage == null ||
        hardImage == null ||
        soilRects == null ||
        hardRects == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final painter = GardenPainter(
      viewportSize: _viewportSize,
      screenToWorld: _screenToWorld,
      tiles: state.tiles,
      tileSize: tileSizePx,
      soilImage: soilImage!,
      hardImage: hardImage!,
      soilRects: soilRects!,
      hardRects: hardRects!,
      tilesWide: gridSize.width.toInt(),
      tilesHigh: gridSize.height.toInt(),
      visibleRect: visibleRect,
      backgroundCache: _backgroundCache,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
    );

    final canvasSize = Size(
      gridSize.width * tileSizePx,
      gridSize.height * tileSizePx,
    );

    if ((_backgroundCache == null || _backgroundCacheSize != canvasSize) &&
        !_isBuildingCache) {
      _rebuildBackgroundCache(canvasSize, painter);
    }

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
            _viewportSize = constraints.biggest;

            if (!_hasInitializedView &&
                _mapWorldSize != null &&
                _viewportSize.isFinite) {
              _hasInitializedView = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  resetViewToFit();
                  _updateTransform();
                });
              });
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: paintMode
                  ? null
                  : (details) {
                      _lastFocalPoint = details.focalPoint;
                      _startScale = _scale;
                      _startRotation = _rotation;
                      _startTranslation = _translation;
                    },
              onScaleUpdate: paintMode
                  ? null
                  : (details) {
                      setState(() {
                        if (_viewMode == ViewMode.panZoom) {
                          // --- Nouveau scale ---
                          final newScale = (_startScale * (1 / details.scale))
                              .clamp(0.2, 8.0);

                          // --- Coordonnée monde du point focal AVANT zoom ---
                          final focalWorldBefore = _screenToWorld(
                            details.focalPoint,
                          );

                          // --- Appliquer le nouveau scale ---
                          _scale = newScale;

                          // --- Coordonnée monde du point focal APRÈS zoom ---
                          final focalWorldAfter = _screenToWorld(
                            details.focalPoint,
                          );

                          // --- Ajuste la translation pour que le point focal reste fixe ---
                          _translation += (focalWorldBefore - focalWorldAfter);

                          // --- Pan uniforme, en tenant compte du zoom ---
                          final deltaScreen =
                              (details.focalPoint - _lastFocalPoint) *
                              _scale *
                              _scale;
                          final deltaWorld = _screenDeltaToWorld(deltaScreen);

                          _translation += deltaWorld;

                          _lastFocalPoint = details.focalPoint;
                        }

                        if (_viewMode == ViewMode.rotate) {
                          _rotation = _startRotation + details.rotation;
                          final deltaScreen =
                              (details.focalPoint - _lastFocalPoint) *
                              _scale *
                              _scale;
                          final deltaWorld = _screenDeltaToWorld(deltaScreen);

                          _translation += deltaWorld;

                          _lastFocalPoint = details.focalPoint;
                        }
                        _updateTransform();
                      });
                    },
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Transform(
                      transform: _transform,
                      child: CustomPaint(
                        size: Size(
                          gridSize.width * tileSizePx,
                          gridSize.height * tileSizePx,
                        ),
                        painter: painter,
                      ),
                    ),
                    if (paintMode)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,

                          onTapDown: (d) {
                            final worldPos = _screenToWorld(
                              (context.findRenderObject() as RenderBox)
                                  .globalToLocal(d.globalPosition),
                            );

                            final x = (worldPos.dx / tileSizePx).floor();
                            final y = (worldPos.dy / tileSizePx).floor();
                            notifier.paintTile(x, y);
                          },

                          onDoubleTapDown: (d) {
                            isSelecting = true;
                            selectionStart = _screenToWorld(
                              (context.findRenderObject() as RenderBox)
                                  .globalToLocal(d.globalPosition),
                            );
                            selectionEnd = selectionStart;
                            setState(() {});
                          },

                          onPanUpdate: (d) {
                            if (isSelecting) {
                              selectionEnd = _screenToWorld(
                                (context.findRenderObject() as RenderBox)
                                    .globalToLocal(d.globalPosition),
                              );
                              setState(() {});
                              return;
                            }

                            final worldPos = _screenToWorld(
                              (context.findRenderObject() as RenderBox)
                                  .globalToLocal(d.globalPosition),
                            );

                            final x = (worldPos.dx / tileSizePx).floor();
                            final y = (worldPos.dy / tileSizePx).floor();

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
            );
          },
        ),
        gridVisible
            ? Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BlueprintScalePainter(
                      zoom: 1 / _scale,
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
      backgroundColor: EditorScreen.tileEditor == screen
          ? const ui.Color.fromARGB(235, 150, 208, 255)
          : Colors.white.withOpacity(0.9),
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
