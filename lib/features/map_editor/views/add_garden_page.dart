import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';
import 'package:hortus_app/features/map_editor/widgets/tilemap_painter.dart';
import 'package:image_picker/image_picker.dart';
import '../../gardens/providers/garden_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/firebase_providers.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

enum EditorScreen {
  choice, // aucune image
  image, // image affichée mais pas en édition
  tileEditor, // mode édition actif
}

enum _OverlayGestureMode { unknown, pinch, rotate }

enum _MapGestureMode { unknown, pinch, rotate }

const List<String> decoImages = [
  'assets/images/deco/01.png',
  'assets/images/deco/02.png',
  'assets/images/deco/03.png',
  'assets/images/deco/04.png',
  'assets/images/deco/05.png',
  'assets/images/deco/06.png',
  'assets/images/deco/07.png',
  'assets/images/deco/08.png',
  'assets/images/deco/09.png',
  'assets/images/deco/10.png',
  'assets/images/deco/11.png',
  'assets/images/deco/12.png',
  'assets/images/deco/13.png',
  'assets/images/deco/14.png',
  'assets/images/deco/15.png',
  'assets/images/deco/16.png',
  'assets/images/deco/17.png',
  'assets/images/deco/18.png',
];

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

  ui.Image? _backgroundCache;
  Size? _backgroundCacheSize;
  bool _isBuildingCache = false;

  Size? _lastInitViewport;

  // Overlay image (calque)
  ui.Image? _overlayImage;
  bool _overlayVisible = false;
  bool _overlayLocked = true;
  Offset _overlayWorldOffset = Offset.zero;
  double _overlayWorldScale = 1.0;
  double _overlayOpacity = 0.4;
  double _overlayWorldRotation = 0.0;

  // --- pour gérer le gesture ---
  late Offset _overlayLastFocalPoint;
  late Offset _overlayStartOffset;
  late double _overlayStartScale;
  late double _overlayStartRotation;

  _OverlayGestureMode _overlayGestureMode = _OverlayGestureMode.unknown;
  _MapGestureMode _mapGestureMode = _MapGestureMode.unknown;

  final double _zoomThreshold = 0.02;
  final double _rotationThreshold = 0.02;

  bool _overlayOpacityVisible = false;
  bool overlaySliderExpanded = false;

  bool _decoPanelVisible = false;
  String? _selectedDecoImage;

  late final Size _editorGridSize;
  late TileEditorNotifier _editorNotifier;

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

  Future<void> _pickOverlayImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _overlayImage = frame.image;
      _overlayVisible = true;
    });
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

  Future<void> _saveGarden() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(currentUserProvider);
    if (uid == null) return;

    final userDoc = await ref
        .read(firestoreProvider)
        .collection('users')
        .doc(uid)
        .get();

    final username = userDoc.data()?['username'] ?? "inconnu";

    final tilesToSave = _editorNotifier.state.tiles;

    // 🔹 Sauvegarde
    await ref
        .read(gardenRepoProvider)
        .createGarden(
          name: nameCtrl.text,
          width: double.parse(widthCtrl.text),
          length: double.parse(lengthCtrl.text),
          ownerUsername: username,
          isPublic: false,
          isEditable: false,
          tiles: tilesToSave, // tiles correctes
        );

    // 🔹 Réinitialiser la tilemap
    _editorNotifier.reset(
      _editorGridSize.width.toInt(),
      _editorGridSize.height.toInt(),
    );

    if (mounted) Navigator.pop(context);
  }

  Size _computeGridSize() {
    final width = double.tryParse(widthCtrl.text) ?? 1;
    final length = double.tryParse(lengthCtrl.text) ?? 1;

    final tilesX = (width / tileSizeMeters).ceil();
    final tilesY = (length / tileSizeMeters).ceil();

    return Size(tilesX.toDouble(), tilesY.toDouble());
  }

  Widget _toolButton(
    IconData icon,
    Color color,
    bool active,
    VoidCallback onTap,
    VoidCallback? onLongPress,
  ) {
    return GestureDetector(
      onLongPress: onLongPress,
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
                null,
              ),
              _toolButton(
                Icons.square,
                Colors.grey,
                state.currentBrush == TileType.hard && paintMode,
                () {
                  notifier.setBrush(TileType.hard);
                  setState(() => paintMode = true);
                },
                null,
              ),
              _toolButton(
                Icons.delete,
                Colors.red,
                state.currentBrush == TileType.empty && paintMode,
                () {
                  notifier.setBrush(TileType.empty);
                  setState(() => paintMode = true);
                },
                null,
              ),
              _toolButton(Icons.zoom_in_map, Colors.blue, !paintMode, () {
                setState(() => paintMode = false);
              }, null),
              _toolButton(Icons.reset_tv_rounded, Colors.blue, false, () {
                setState(() {
                  resetViewToFit(_mapWorldSize!);
                });
              }, null),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolButton(Icons.undo, Colors.white, false, notifier.undo, null),
              _toolButton(Icons.redo, Colors.white, false, notifier.redo, null),
              _toolButton(Icons.grid_4x4, Colors.cyan, gridVisible, () {
                setState(() => gridVisible = !gridVisible);
              }, null),
              _toolButton(Icons.layers, Colors.cyan, _overlayVisible, () {
                setState(() {
                  _overlayVisible = !_overlayVisible;
                  _overlayLocked = true;
                  _overlayOpacityVisible = !_overlayOpacityVisible;
                });
              }, _pickOverlayImage),

              _toolButton(
                Icons.emoji_nature,
                Colors.lightGreen,
                _decoPanelVisible,
                () {
                  setState(() {
                    // ✅ Récupérer le gridSize utilisé pour l'édition
                    final gridSize = _computeGridSize();

                    // ✅ Lire l'état actuel du tile editor
                    final notifier = ref.read(
                      tileEditorProvider(gridSize).notifier,
                    );

                    print('state.tiles= ${notifier.state.tiles}');
                    _decoPanelVisible = !_decoPanelVisible;
                  });
                },
                null,
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _decoPanel() {
    if (!_decoPanelVisible) return const SizedBox();

    return Positioned(
      right: 12,
      top: 140,

      child: Container(
        width: 80,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: decoImages.length,
          itemBuilder: (context, index) {
            final path = decoImages[index];
            final isSelected = path == _selectedDecoImage;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDecoImage = path;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.lightGreen.withOpacity(0.25)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.lightGreen
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Image.asset(path, fit: BoxFit.contain, height: 48),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _overlayOpacityPanel() {
    if (!_overlayVisible || !_overlayOpacityVisible) {
      return const SizedBox();
    }

    return Positioned(
      top: 120,
      right: 15,
      child: Container(
        width: 56,
        height: overlaySliderExpanded ? 340 : null,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const ui.Color.fromARGB(160, 0, 0, 0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: ui.Color.fromARGB(70, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  overlaySliderExpanded = !overlaySliderExpanded;
                });
              },
              icon: Icon(Icons.layers, color: Colors.white70, size: 25),
            ),

            overlaySliderExpanded
                ? Expanded(
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Slider(
                        value: _overlayOpacity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) {
                          setState(() {
                            _overlayOpacity = v;
                          });
                        },
                      ),
                    ),
                  )
                : SizedBox(),

            const SizedBox(height: 6),

            IconButton(
              onPressed: () {
                setState(() {
                  _overlayLocked ? _unlockOverlay() : _lockOverlay();
                });
              },
              icon: Icon(
                _overlayLocked ? Icons.lock : Icons.lock_open,
                color: Colors.orange,
              ),
            ),
          ],
        ),
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
                  _editorGridSize = _computeGridSize();
                  _editorNotifier = ref.read(
                    tileEditorProvider(_editorGridSize).notifier,
                  );
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

  void resetViewToFit(Size mapWorldSize) {
    final mapW = mapWorldSize.width;
    final mapH = mapWorldSize.height;

    final viewW = _viewportSize.width;
    final viewH = _viewportSize.height;

    // 0️⃣ Reset propre
    _scale = 1.0;
    _rotation = 0.0;
    _translation = Offset.zero;

    // 1️⃣ Rotation (grand axe vertical)
    if (mapW > mapH) {
      _rotation = math.pi / 2;
    }

    // 2️⃣ Dimensions apparentes après rotation
    final fittedW = _rotation == 0 ? mapW : mapH;
    final fittedH = _rotation == 0 ? mapH : mapW;

    // 3️⃣ Scale FIT
    _scale = (math.max(fittedW / viewW, fittedH / viewH)) * 1.05;

    // 4️⃣ Centrage monde → viewport
    final worldCenter = Offset(mapW / 2, mapH / 2);
    final viewportCenter = Offset(viewW / 2, viewH / 2);

    _translation = viewportCenter - worldCenter;

    _updateTransform();
  }

  bool _wouldMapRemainVisible(Offset candidateTranslation, Size mapWorldSize) {
    final testTransform = Matrix4.identity()
      ..translateByVector3(
        Vector3(_viewportSize.width / 2, _viewportSize.height / 2, 0),
      )
      ..scaleByDouble(1, 1, 1, _scale)
      ..rotateZ(_rotation)
      ..translateByVector3(
        Vector3(
          -_viewportSize.width / 2 + candidateTranslation.dx,
          -_viewportSize.height / 2 + candidateTranslation.dy,
          0,
        ),
      );

    final topLeft = MatrixUtils.transformPoint(testTransform, Offset(0, 0));

    final bottomRight = MatrixUtils.transformPoint(
      testTransform,
      Offset(mapWorldSize.width, mapWorldSize.height),
    );

    final mapRect = Rect.fromPoints(topLeft, bottomRight);

    const margin = 20.0;

    final viewport = Rect.fromLTWH(
      0,
      0,
      _viewportSize.width,
      _viewportSize.height,
    );

    return mapRect.overlaps(viewport.deflate(margin));
  }

  void _lockOverlay() {
    setState(() => _overlayLocked = true);
  }

  void _unlockOverlay() {
    setState(() => _overlayLocked = false);
  }

  Widget _overlayGestureDetector() {
    if (!_overlayVisible || _overlayLocked || _overlayImage == null) {
      return const SizedBox();
    }

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: (details) {
          _overlayLastFocalPoint = details.focalPoint;
          _overlayStartScale = _overlayWorldScale;
          _overlayStartRotation = _overlayWorldRotation;
          _overlayStartOffset = _overlayWorldOffset;
          _overlayGestureMode = _OverlayGestureMode.unknown;
        },
        onScaleUpdate: (details) {
          setState(() {
            final scaleDelta = (details.scale - 1.0).abs();
            final rotationDelta = details.rotation.abs();

            if (_overlayGestureMode == _OverlayGestureMode.unknown) {
              // Déterminer le geste dominant
              if (scaleDelta > _zoomThreshold) {
                _overlayGestureMode = _OverlayGestureMode.pinch;
              } else if (rotationDelta > _rotationThreshold &&
                  details.pointerCount >= 2) {
                _overlayGestureMode = _OverlayGestureMode.rotate;
              }
            }

            // Translation toujours appliquée
            final deltaScreen =
                (details.focalPoint - _overlayLastFocalPoint) * _scale * _scale;
            final deltaWorld = _screenDeltaToWorld(deltaScreen);
            _overlayWorldOffset = _overlayStartOffset + deltaWorld;

            // Appliquer scale seulement si geste dominant est pinch ou rotate
            if (_overlayGestureMode == _OverlayGestureMode.pinch ||
                _overlayGestureMode == _OverlayGestureMode.rotate) {
              _overlayWorldScale = _overlayStartScale * details.scale;
            }

            // Appliquer rotation seulement si geste dominant est rotate
            if (_overlayGestureMode == _OverlayGestureMode.rotate) {
              _overlayWorldRotation = _overlayStartRotation + details.rotation;
            }
          });
        },
        onScaleEnd: (details) {
          _overlayGestureMode = _OverlayGestureMode.unknown;
        },
      ),
    );
  }

  Widget tileMapEditor() {
    final gridSize = _editorGridSize; // utilise la taille fixée
    final notifier = _editorNotifier;
    final state = ref.watch(tileEditorProvider(_editorGridSize));
    final tileSizePx = tileSizeMeters * pixelsPerMeter;

    final mapWorldSize = Size(
      gridSize.width * tileSizePx,
      gridSize.height * tileSizePx,
    );

    // initialisation UNE SEULE FOIS
    _mapWorldSize ??= mapWorldSize;

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

            if (_mapWorldSize != null &&
                _viewportSize.isFinite &&
                _viewportSize != Size.zero &&
                _lastInitViewport != _viewportSize) {
              _lastInitViewport = _viewportSize;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  resetViewToFit(_mapWorldSize!);
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
                      _mapGestureMode = _MapGestureMode.unknown;
                    },
              onScaleUpdate: paintMode
                  ? null
                  : (details) {
                      setState(() {
                        final scaleDelta = (details.scale - 1.0).abs();
                        final rotationDelta = details.rotation.abs();

                        // Déterminer le geste dominant si inconnu
                        if (_mapGestureMode == _MapGestureMode.unknown) {
                          if (scaleDelta > _zoomThreshold) {
                            _mapGestureMode = _MapGestureMode.pinch;
                          } else if (rotationDelta > _rotationThreshold &&
                              details.pointerCount >= 2) {
                            _mapGestureMode = _MapGestureMode.rotate;
                          }
                        }

                        // --- Coordonnée monde du point focal AVANT zoom ---
                        final focalWorldBefore = _screenToWorld(
                          details.focalPoint,
                        );

                        // --- Appliquer scale si mode pinch ou rotate ---
                        if (_mapGestureMode == _MapGestureMode.pinch ||
                            _mapGestureMode == _MapGestureMode.rotate) {
                          _scale = (_startScale / details.scale).clamp(
                            0.2,
                            8.0,
                          );
                        }

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

                        final candidateTranslation = _translation + deltaWorld;

                        if (_wouldMapRemainVisible(
                          candidateTranslation,
                          _mapWorldSize!,
                        )) {
                          _translation = candidateTranslation;
                        }

                        _lastFocalPoint = details.focalPoint;

                        // --- Appliquer rotation seulement si mode rotate ---
                        if (_mapGestureMode == _MapGestureMode.rotate) {
                          _rotation = _startRotation + details.rotation;
                        }

                        _updateTransform();
                      });
                    },
              onScaleEnd: paintMode
                  ? null
                  : (details) {
                      // Reset du mode dominant
                      _mapGestureMode = _MapGestureMode.unknown;
                    },

              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Transform(
                      transform: _transform,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(
                              gridSize.width * tileSizePx,
                              gridSize.height * tileSizePx,
                            ),
                            painter: painter,
                          ),
                          if (_overlayVisible && _overlayImage != null)
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(
                                  _overlayWorldOffset.dx,
                                  _overlayWorldOffset.dy,
                                )
                                ..scale(_overlayWorldScale)
                                ..rotateZ(_overlayWorldRotation),
                              child: Opacity(
                                opacity: _overlayOpacity,
                                child: RawImage(image: _overlayImage),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Gesture overlay
                    _overlayGestureDetector(),

                    if (paintMode)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,

                          onTapDown: (d) {
                            notifier.beginPaint();
                            final worldPos = _screenToWorld(
                              (context.findRenderObject() as RenderBox)
                                  .globalToLocal(d.globalPosition),
                            );

                            final x = (worldPos.dx / tileSizePx).floor();
                            final y = (worldPos.dy / tileSizePx).floor();
                            notifier.paintTile(x, y);

                            print('_editorGridSize = $_editorGridSize');
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
                            notifier.beginPaint();
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
        // panneau déco
        _decoPanel(),

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
              onPressed: () => _saveGarden(),
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

  Widget _floatingEditorBar() {
    final gridSize = _computeGridSize();
    final state = ref.watch(tileEditorProvider(gridSize));

    return Positioned(
      top: 40,
      left: 40,
      right: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: ui.Color.fromARGB(60, 0, 0, 0),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ⬅️ Retour
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  screen = EditorScreen.choice;
                });
              },
            ),

            const SizedBox(width: 8),

            // 📝 Nom du jardin
            Expanded(
              child: Center(
                child: Text(
                  nameCtrl.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 💾 Save
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () => _saveGarden(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: screen == EditorScreen.choice ? _buildAppBar() : null,
      body: Stack(
        children: [
          Form(key: _formKey, child: _buildBody()),

          if (screen == EditorScreen.tileEditor) _floatingEditorBar(),
          _overlayOpacityPanel(),
        ],
      ),
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
