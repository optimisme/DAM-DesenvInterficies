import 'dart:math' as math;
import 'dart:ui' as ui;

import 'libgdx_compat/asset_manager.dart';
import 'debug_overlay.dart';
import 'game_app.dart';
import 'libgdx_compat/game_framework.dart';
import 'gameplay_controller.dart';
import 'gameplay_controller_top_down.dart';
import 'libgdx_compat/gdx.dart';
import 'libgdx_compat/gdx_collections.dart';
import 'level_data.dart';
import 'level_loader.dart';
import 'level_renderer.dart';
import 'libgdx_compat/math_types.dart';
import 'menu_screen.dart';
import 'runtime_transform.dart';
import 'libgdx_compat/viewport.dart';

class PlayScreen extends ScreenAdapter {
  static const double defaultAnimationFps = 8;
  static const double fixedStepSeconds = 1 / 120;
  static const double maxFrameSeconds = 0.25;
  static const double hudMargin = 14;
  static const String hudBackLabel = 'Back';
  static const double hudButtonHeight = 48;
  static const double hudIconSize = 26;
  static const double hudIconTextGap = 8;
  static const double hudBackLabelScale = 1.45;
  static const double hudCounterScale = 1.45;
  static const double hudGemCounterScale = 1.35;
  static const double hudScoreScale = 1.8;
  static const double hudLifeTextScale = 1.2;
  static const double hudLifeBarWidth = 210;
  static const double hudLifeBarHeight = 14;
  static const double hudLifeBarTopGap = 8;
  static const double hudRowGap = 10;
  static const double hudGemRowHeight = 20;
  static const double hudGemRowGap = 4;
  static const double hudScoreRowHeight = 26;
  static const double hudGemIconSize = 18;
  static const double hudGemTextGap = 4;
  static const double hudGemRightMargin = 4;
  static const double hudGemTopMargin = 4;
  static const int hudGemFrameSize = 15;
  static const int hudGemPurpleFrame = 0;
  static const int hudGemGreenFrame = 5;
  static const int hudGemYellowFrame = 10;
  static const int hudGemBlueFrame = 15;
  static const int spawnPurpleGemsCount = 50;
  static const int spawnYellowGemsCount = 100;
  static const int spawnGreenGemsCount = 250;
  static const int spawnBlueGemsCount = 500;
  static const double endOverlayReturnDelaySeconds = 1;
  static const double endOverlayTitleScale = 2.4;
  static const double endOverlayPromptScale = 1.25;
  static const double endOverlayPromptGap = 44;
  static const double cameraDeadZoneFractionX = 0.22;
  static const double cameraDeadZoneFractionY = 0.18;
  static const double cameraFollowSmoothnessPerSecond = 10;

  static final ui.Color hudTextColor = colorValueOf('FFFFFF');
  static final ui.Color hudGreenColor = colorValueOf('7DFF8A');
  static final ui.Color hudPurpleColor = colorValueOf('D9A4FF');
  static final ui.Color hudYellowColor = colorValueOf('FFE07A');
  static final ui.Color hudBlueColor = colorValueOf('8AC7FF');
  static final ui.Color hudLifeBarBg = colorValueOf('5B0D0D');
  static final ui.Color hudLifeBarFill = colorValueOf('3DE67D');
  static final ui.Color hudLifeBarBorder = colorValueOf('E8FFE8');
  static final ui.Color endOverlayDim = colorValueOf('000000A8');

  final GameApp game;
  final int levelIndex;
  final OrthographicCamera camera = OrthographicCamera();
  late final Viewport viewport;
  final OrthographicCamera hudCamera = OrthographicCamera();
  final Viewport hudViewport = ScreenViewport(OrthographicCamera());
  final LevelRenderer levelRenderer = LevelRenderer();
  final DebugOverlay debugOverlayRenderer = DebugOverlay();
  final Array<SpriteRuntimeState> spriteRuntimeStates =
      Array<SpriteRuntimeState>();
  final Array<RuntimeTransform> layerRuntimeStates = Array<RuntimeTransform>();
  final Array<RuntimeTransform> zoneRuntimeStates = Array<RuntimeTransform>();
  final Array<RuntimeTransform> zonePreviousRuntimeStates =
      Array<RuntimeTransform>();
  final Array<_PathBindingRuntime> _pathBindingRuntimes =
      Array<_PathBindingRuntime>();
  final FloatArray spriteAnimationElapsed = FloatArray();
  final IntArray spriteTotalFrames = IntArray();
  List<String> spriteTotalFramesCacheKey = <String>[];
  List<String?> spriteCurrentAnimationId = <String?>[];

  late final LevelData levelData;
  late final List<bool> layerVisibilityStates;
  late final GameplayController gameplayController;
  final Rectangle backButtonBounds = Rectangle();
  final GlyphLayout hudLayout = GlyphLayout();
  Texture? backIconTexture;

  _DebugOverlayMode _debugOverlayMode = _DebugOverlayMode.none;
  _EndOverlayState _endOverlayState = _EndOverlayState.none;
  double endOverlayElapsedSeconds = 0;
  double fixedStepAccumulator = 0;
  double pathMotionTimeSeconds = 0;

  PlayScreen(this.game, this.levelIndex) {
    levelData = LevelLoader.loadLevel(levelIndex);
    _populateRandomGemsInGemsZone();
    layerVisibilityStates = _buildInitialLayerVisibility(levelData);
    viewport = _createViewport(levelData, camera);
    camera.setPosition(0, 0);
    viewport.update(
      Gdx.graphics.getWidth().toDouble(),
      Gdx.graphics.getHeight().toDouble(),
      false,
    );
    _applyInitialCameraFromLevel();
    _initializeAnimationRuntimeState();
    _initializeTransformRuntimeState();
    _initializePathBindingRuntimes();
    gameplayController = _createGameplayController();
    hudViewport.update(
      Gdx.graphics.getWidth().toDouble(),
      Gdx.graphics.getHeight().toDouble(),
      true,
    );
    _loadHudAssets();
  }

  void _populateRandomGemsInGemsZone() {
    final LevelLayer? gemsZoneLayer = _findGemsZoneLayer();
    if (gemsZoneLayer == null) {
      return;
    }

    final List<_GemSpawnCell> spawnCells = _collectGemSpawnCells(gemsZoneLayer);
    if (spawnCells.isEmpty) {
      return;
    }

    final Map<_GemSpawnType, LevelSprite> templates = _findGemTemplates();
    if (!templates.containsKey(_GemSpawnType.purple) ||
        !templates.containsKey(_GemSpawnType.yellow) ||
        !templates.containsKey(_GemSpawnType.green) ||
        !templates.containsKey(_GemSpawnType.blue)) {
      return;
    }

    final List<LevelSprite> nonGemSprites = <LevelSprite>[];
    for (final LevelSprite sprite in levelData.sprites.iterable()) {
      if (_resolveGemSpawnType(sprite) == null) {
        nonGemSprites.add(sprite);
      }
    }

    levelData.sprites.clear();
    for (final LevelSprite sprite in nonGemSprites) {
      levelData.sprites.add(sprite);
    }

    final math.Random random = math.Random();
    final List<int> shuffledCellIndices = List<int>.generate(
      spawnCells.length,
      (int i) => i,
    )..shuffle(random);
    int nextCellCursor = 0;

    int? nextCellIndex() {
      if (nextCellCursor >= shuffledCellIndices.length) {
        return null;
      }
      final int index = shuffledCellIndices[nextCellCursor++];
      return index;
    }

    void spawnType(_GemSpawnType type, int count) {
      final LevelSprite? template = templates[type];
      if (template == null || count <= 0) {
        return;
      }
      for (int i = 0; i < count; i++) {
        final int? cellIndex = nextCellIndex();
        if (cellIndex == null) {
          break;
        }
        final _GemSpawnCell cell = spawnCells[cellIndex];
        final double x = _randomAnchoredXInCell(template, cell, random);
        final double y = _randomAnchoredYInCell(template, cell, random);
        levelData.sprites.add(_copySpriteAt(template, x, y));
      }
    }

    spawnType(_GemSpawnType.purple, spawnPurpleGemsCount);
    spawnType(_GemSpawnType.yellow, spawnYellowGemsCount);
    spawnType(_GemSpawnType.green, spawnGreenGemsCount);
    spawnType(_GemSpawnType.blue, spawnBlueGemsCount);
  }

  double _randomAnchoredXInCell(
    LevelSprite sprite,
    _GemSpawnCell cell,
    math.Random random,
  ) {
    final double minX = cell.x + sprite.width * sprite.anchorX;
    final double maxX =
        cell.x + cell.width - sprite.width * (1 - sprite.anchorX);
    if (maxX <= minX) {
      return cell.x + cell.width * 0.5;
    }
    return minX + random.nextDouble() * (maxX - minX);
  }

  double _randomAnchoredYInCell(
    LevelSprite sprite,
    _GemSpawnCell cell,
    math.Random random,
  ) {
    final double minY = cell.y + sprite.height * sprite.anchorY;
    final double maxY =
        cell.y + cell.height - sprite.height * (1 - sprite.anchorY);
    if (maxY <= minY) {
      return cell.y + cell.height * 0.5;
    }
    return minY + random.nextDouble() * (maxY - minY);
  }

  LevelLayer? _findGemsZoneLayer() {
    for (int i = 0; i < levelData.layers.size; i++) {
      final LevelLayer layer = levelData.layers.get(i);
      final String layerName = layer.name.trim().toLowerCase();
      if (layerName == 'gems zone') {
        return layer;
      }
    }
    return null;
  }

  List<_GemSpawnCell> _collectGemSpawnCells(LevelLayer layer) {
    final List<_GemSpawnCell> cells = <_GemSpawnCell>[];
    if (layer.tileWidth <= 0 || layer.tileHeight <= 0) {
      return cells;
    }
    for (int tileY = 0; tileY < layer.tileMap.length; tileY++) {
      final List<int> row = layer.tileMap[tileY];
      for (int tileX = 0; tileX < row.length; tileX++) {
        cells.add(
          _GemSpawnCell(
            layer.x + tileX * layer.tileWidth,
            layer.y + tileY * layer.tileHeight,
            layer.tileWidth.toDouble(),
            layer.tileHeight.toDouble(),
          ),
        );
      }
    }
    return cells;
  }

  Map<_GemSpawnType, LevelSprite> _findGemTemplates() {
    final Map<_GemSpawnType, LevelSprite> templates =
        <_GemSpawnType, LevelSprite>{};
    for (final LevelSprite sprite in levelData.sprites.iterable()) {
      final _GemSpawnType? type = _resolveGemSpawnType(sprite);
      if (type == null || templates.containsKey(type)) {
        continue;
      }
      templates[type] = sprite;
    }
    return templates;
  }

  _GemSpawnType? _resolveGemSpawnType(LevelSprite sprite) {
    final String merged =
        '${sprite.name.toLowerCase()} ${sprite.type.toLowerCase()}';
    if (!merged.contains('gem')) {
      return null;
    }
    if (merged.contains('purple') ||
        merged.contains('lila') ||
        merged.contains('violet')) {
      return _GemSpawnType.purple;
    }
    if (merged.contains('yellow') ||
        merged.contains('groc') ||
        merged.contains('amarillo')) {
      return _GemSpawnType.yellow;
    }
    if (merged.contains('green') ||
        merged.contains('gren') ||
        merged.contains('verd') ||
        merged.contains('verde')) {
      return _GemSpawnType.green;
    }
    if (merged.contains('blue') ||
        merged.contains('blau') ||
        merged.contains('azul')) {
      return _GemSpawnType.blue;
    }
    return null;
  }

  LevelSprite _copySpriteAt(LevelSprite sprite, double x, double y) {
    return LevelSprite(
      sprite.name,
      sprite.type,
      sprite.depth,
      x,
      y,
      sprite.width,
      sprite.height,
      sprite.anchorX,
      sprite.anchorY,
      sprite.flipX,
      sprite.flipY,
      sprite.frameIndex,
      sprite.texturePath,
      sprite.animationId,
    );
  }

  @override
  void show() {
    Gdx.input.setInputProcessor(null);
  }

  @override
  void render(double delta) {
    if (Gdx.input.isKeyJustPressed(Input.keys.escape)) {
      _returnToMenu();
      return;
    }

    _updateBackButtonBounds();
    if (!_isEndOverlayActive() && _handleHudBackInput()) {
      return;
    }

    if (_isEndOverlayActive()) {
      _updateEndOverlay(delta);
      if (game.getScreen() != this) {
        return;
      }
    } else {
      _handleDebugOverlayInput();
      gameplayController.handleInput();
      _stepSimulation(delta);
      _updateEndOverlayStateIfNeeded();
    }

    viewport.apply();
    _updateCameraForGameplay();
    ScreenUtils.clear(levelData.backgroundColor);

    final SpriteBatch batch = game.getBatch();
    batch.begin();
    levelRenderer.render(
      levelData,
      game.getAssetManager(),
      batch,
      camera,
      spriteRuntimeStates,
      layerVisibilityStates,
      layerRuntimeStates,
      viewport,
    );
    batch.end();

    debugOverlayRenderer.render(
      levelData,
      camera,
      _debugOverlayMode == _DebugOverlayMode.zones ||
          _debugOverlayMode == _DebugOverlayMode.both,
      _debugOverlayMode == _DebugOverlayMode.paths ||
          _debugOverlayMode == _DebugOverlayMode.both,
      zoneRuntimeStates,
      viewport,
    );

    _renderHud();
    _renderEndOverlayIfActive();
  }

  @override
  void resize(int width, int height) {
    viewport.update(width.toDouble(), height.toDouble(), false);
    hudViewport.update(width.toDouble(), height.toDouble(), true);
    _updateBackButtonBounds();
    _updateCameraForGameplay();
  }

  @override
  void dispose() {
    debugOverlayRenderer.dispose();
  }

  void _stepSimulation(double deltaSeconds) {
    final double clampedDelta = math.max(
      0,
      math.min(maxFrameSeconds, deltaSeconds),
    );
    fixedStepAccumulator += clampedDelta;

    while (fixedStepAccumulator >= fixedStepSeconds) {
      _snapshotPreviousZoneTransforms();
      _advancePathBindings(fixedStepSeconds);
      gameplayController.fixedUpdate(fixedStepSeconds);
      _updateAnimations(fixedStepSeconds);
      fixedStepAccumulator -= fixedStepSeconds;
    }
  }

  void _initializeAnimationRuntimeState() {
    spriteRuntimeStates.clear();
    spriteAnimationElapsed.clear();
    spriteTotalFrames.clear();
    spriteAnimationElapsed.setSize(levelData.sprites.size);

    for (int i = 0; i < levelData.sprites.size; i++) {
      final LevelSprite sprite = levelData.sprites.get(i);
      spriteRuntimeStates.add(
        SpriteRuntimeState(
          sprite.frameIndex,
          sprite.anchorX,
          sprite.anchorY,
          sprite.x,
          sprite.y,
          true,
          sprite.flipX,
          sprite.flipY,
          math.max(1, sprite.width.round()),
          math.max(1, sprite.height.round()),
          sprite.texturePath,
          sprite.animationId,
        ),
      );
      spriteTotalFrames.add(0);
      spriteAnimationElapsed.set(i, 0);
    }

    spriteTotalFramesCacheKey = List<String>.filled(levelData.sprites.size, '');
    spriteCurrentAnimationId = List<String?>.filled(
      levelData.sprites.size,
      null,
    );
  }

  void _initializeTransformRuntimeState() {
    layerRuntimeStates.clear();
    zoneRuntimeStates.clear();
    zonePreviousRuntimeStates.clear();

    for (int i = 0; i < levelData.layers.size; i++) {
      final LevelLayer layer = levelData.layers.get(i);
      layerRuntimeStates.add(RuntimeTransform(layer.x, layer.y));
    }

    for (int i = 0; i < levelData.zones.size; i++) {
      final LevelZone zone = levelData.zones.get(i);
      final RuntimeTransform current = RuntimeTransform(zone.x, zone.y);
      zoneRuntimeStates.add(current);
      zonePreviousRuntimeStates.add(RuntimeTransform(zone.x, zone.y));
    }

    pathMotionTimeSeconds = 0;
  }

  void _initializePathBindingRuntimes() {
    _pathBindingRuntimes.clear();
    if (levelData.pathBindings.size <= 0 || levelData.paths.size <= 0) {
      return;
    }

    final ObjectMap<String, _PathRuntime> pathById =
        ObjectMap<String, _PathRuntime>();
    for (int i = 0; i < levelData.paths.size; i++) {
      final LevelPath path = levelData.paths.get(i);
      if (path.id.isEmpty || path.points.size < 2) {
        continue;
      }
      final _PathRuntime? runtime = _PathRuntime.from(path);
      if (runtime != null) {
        pathById.put(path.id, runtime);
      }
    }

    for (int i = 0; i < levelData.pathBindings.size; i++) {
      final LevelPathBinding binding = levelData.pathBindings.get(i);
      if (!binding.enabled) {
        continue;
      }
      final _PathRuntime? path = pathById.get(binding.pathId);
      if (path == null) {
        continue;
      }

      double initialX;
      double initialY;
      if (binding.targetType == 'layer') {
        if (binding.targetIndex < 0 ||
            binding.targetIndex >= layerRuntimeStates.size) {
          continue;
        }
        final RuntimeTransform target = layerRuntimeStates.get(
          binding.targetIndex,
        );
        initialX = target.x;
        initialY = target.y;
        _pathBindingRuntimes.add(
          _PathBindingRuntime(path, binding, initialX, initialY),
        );
      } else if (binding.targetType == 'zone') {
        if (binding.targetIndex < 0 ||
            binding.targetIndex >= zoneRuntimeStates.size) {
          continue;
        }
        final RuntimeTransform target = zoneRuntimeStates.get(
          binding.targetIndex,
        );
        initialX = target.x;
        initialY = target.y;
        _pathBindingRuntimes.add(
          _PathBindingRuntime(path, binding, initialX, initialY),
        );
      } else if (binding.targetType == 'sprite') {
        if (binding.targetIndex < 0 ||
            binding.targetIndex >= spriteRuntimeStates.size) {
          continue;
        }
        final SpriteRuntimeState target = spriteRuntimeStates.get(
          binding.targetIndex,
        );
        initialX = target.worldX;
        initialY = target.worldY;
        _pathBindingRuntimes.add(
          _PathBindingRuntime(path, binding, initialX, initialY),
        );
      }
    }
  }

  void _snapshotPreviousZoneTransforms() {
    for (
      int i = 0;
      i < zoneRuntimeStates.size && i < zonePreviousRuntimeStates.size;
      i++
    ) {
      final RuntimeTransform current = zoneRuntimeStates.get(i);
      final RuntimeTransform previous = zonePreviousRuntimeStates.get(i);
      previous.x = current.x;
      previous.y = current.y;
    }
  }

  void _advancePathBindings(double delta) {
    if (_pathBindingRuntimes.size <= 0) {
      return;
    }

    pathMotionTimeSeconds += delta;
    for (final _PathBindingRuntime runtime in _pathBindingRuntimes.iterable()) {
      if (!runtime.binding.enabled) {
        continue;
      }
      final double progress = _pathProgressAtTime(
        runtime.binding.behavior,
        runtime.binding.durationSeconds,
        pathMotionTimeSeconds,
      );
      final _PathSample sample = runtime.path.sampleAtProgress(progress);

      final double targetX = runtime.binding.relativeToInitialPosition
          ? runtime.initialX + (sample.x - runtime.path.firstPointX)
          : sample.x;
      final double targetY = runtime.binding.relativeToInitialPosition
          ? runtime.initialY + (sample.y - runtime.path.firstPointY)
          : sample.y;
      _applyPathTarget(
        runtime.binding.targetType,
        runtime.binding.targetIndex,
        targetX,
        targetY,
      );
    }
  }

  void _applyPathTarget(
    String targetType,
    int targetIndex,
    double x,
    double y,
  ) {
    if (targetType == 'layer') {
      if (targetIndex >= 0 && targetIndex < layerRuntimeStates.size) {
        final RuntimeTransform target = layerRuntimeStates.get(targetIndex);
        target.x = x;
        target.y = y;
      }
      return;
    }
    if (targetType == 'zone') {
      if (targetIndex >= 0 && targetIndex < zoneRuntimeStates.size) {
        final RuntimeTransform target = zoneRuntimeStates.get(targetIndex);
        target.x = x;
        target.y = y;
      }
      return;
    }
    if (targetType == 'sprite') {
      if (targetIndex >= 0 && targetIndex < spriteRuntimeStates.size) {
        final SpriteRuntimeState target = spriteRuntimeStates.get(targetIndex);
        target.worldX = x;
        target.worldY = y;
      }
    }
  }

  double _pathProgressAtTime(
    String behavior,
    double durationSeconds,
    double timeSeconds,
  ) {
    if (!durationSeconds.isFinite || durationSeconds <= 0) {
      return 0;
    }

    final double t = math.max(0, timeSeconds);
    final String normalizedBehavior = behavior.trim().toLowerCase();
    if (normalizedBehavior == 'ping_pong' || normalizedBehavior == 'pingpong') {
      final double cycle = durationSeconds * 2;
      if (cycle <= 0) {
        return 0;
      }
      final double cycleTime = t % cycle;
      if (cycleTime <= durationSeconds) {
        return cycleTime / durationSeconds;
      }
      final double backwardsTime = cycleTime - durationSeconds;
      return 1 - (backwardsTime / durationSeconds);
    }
    if (normalizedBehavior == 'once') {
      return clampDouble(t / durationSeconds, 0, 1);
    }
    return (t % durationSeconds) / durationSeconds;
  }

  void _updateAnimations(double delta) {
    final double safeDelta = math.max(0, delta);
    for (int i = 0; i < spriteRuntimeStates.size; i++) {
      final SpriteRuntimeState runtime = spriteRuntimeStates.get(i);
      final LevelSprite sprite = levelData.sprites.get(i);
      final String? overrideAnimationId = gameplayController
          .animationOverrideForSprite(i);
      String? animationId = overrideAnimationId;
      if (animationId == null || animationId.isEmpty) {
        animationId = sprite.animationId;
      }

      final String? previousAnimationId = spriteCurrentAnimationId[i];
      if ((previousAnimationId == null && animationId != null) ||
          (previousAnimationId != null && previousAnimationId != animationId)) {
        spriteAnimationElapsed.set(i, 0);
      }
      spriteCurrentAnimationId[i] = animationId;

      if (animationId == null || animationId.isEmpty) {
        runtime.animationId = null;
        runtime.texturePath = sprite.texturePath;
        runtime.frameWidth = math.max(1, sprite.width.round());
        runtime.frameHeight = math.max(1, sprite.height.round());
        runtime.frameIndex = math.max(0, sprite.frameIndex);
        runtime.anchorX = sprite.anchorX;
        runtime.anchorY = sprite.anchorY;
        continue;
      }

      final AnimationClip? clip = levelData.animationClips.get(animationId);
      if (clip == null) {
        runtime.animationId = null;
        runtime.texturePath = sprite.texturePath;
        runtime.frameWidth = math.max(1, sprite.width.round());
        runtime.frameHeight = math.max(1, sprite.height.round());
        runtime.frameIndex = math.max(0, sprite.frameIndex);
        runtime.anchorX = sprite.anchorX;
        runtime.anchorY = sprite.anchorY;
        continue;
      }

      runtime.texturePath = clip.texturePath ?? sprite.texturePath;
      runtime.frameWidth = clip.frameWidth > 0
          ? clip.frameWidth
          : math.max(1, sprite.width.round());
      runtime.frameHeight = clip.frameHeight > 0
          ? clip.frameHeight
          : math.max(1, sprite.height.round());
      runtime.animationId = animationId;

      double elapsed = spriteAnimationElapsed.get(i) + safeDelta;
      spriteAnimationElapsed.set(i, elapsed);

      final int start = math.max(0, clip.startFrame);
      final int end = math.max(start, clip.endFrame);
      final int span = math.max(1, end - start + 1);
      final double fps = clip.fps.isFinite && clip.fps > 0
          ? clip.fps
          : defaultAnimationFps;
      final int ticks = (elapsed * fps).floor();
      final int offset = clip.loop
          ? _positiveMod(ticks, span)
          : math.min(ticks, span - 1);
      runtime.frameIndex = start + offset;

      final FrameRig? frameRig = clip.frameRigs.get(runtime.frameIndex);
      runtime.anchorX = frameRig?.anchorX ?? clip.anchorX;
      runtime.anchorY = frameRig?.anchorY ?? clip.anchorY;
    }
  }

  int _positiveMod(int value, int divisor) {
    if (divisor <= 0) {
      return 0;
    }
    final int mod = value % divisor;
    return mod < 0 ? mod + divisor : mod;
  }

  void _renderHud() {
    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    final double hudWidth = Gdx.graphics.getWidth().toDouble();

    batch.begin();
    font.getData().setScale(hudBackLabelScale);
    font.setColor(hudTextColor);
    double backTextX = hudMargin;
    if (backIconTexture != null) {
      final ui.Rect iconSrc = ui.Rect.fromLTWH(
        0,
        0,
        backIconTexture!.width.toDouble(),
        backIconTexture!.height.toDouble(),
      );
      final ui.Rect iconDst = ui.Rect.fromLTWH(
        hudMargin,
        hudMargin + (hudButtonHeight - hudIconSize) * 0.5,
        hudIconSize,
        hudIconSize,
      );
      batch.drawRegion(backIconTexture!, iconSrc, iconDst);
      backTextX = hudMargin + hudIconSize + hudIconTextGap;
    }
    font.drawText(hudBackLabel, backTextX, hudMargin + hudButtonHeight * 0.72);
    font.getData().setScale(1);

    final GameplayControllerTopDown gc =
        gameplayController as GameplayControllerTopDown;
    final AssetManager assets = game.getAssetManager();
    const String gemTexturePath = 'levels/media/gem.png';
    final double rightEdgeX = hudWidth - hudGemRightMargin;
    final double row0Top = hudGemTopMargin;

    _drawGemHudRow(
      batch,
      font,
      assets,
      gemTexturePath,
      hudGemGreenFrame,
      gc.getCollectedGreenGemsCount(),
      rightEdgeX,
      row0Top,
      hudGemRowHeight,
      hudGreenColor,
    );
    _drawGemHudRow(
      batch,
      font,
      assets,
      gemTexturePath,
      hudGemPurpleFrame,
      gc.getCollectedPurpleGemsCount(),
      rightEdgeX,
      row0Top + hudGemRowHeight + hudGemRowGap,
      hudGemRowHeight,
      hudPurpleColor,
    );
    _drawGemHudRow(
      batch,
      font,
      assets,
      gemTexturePath,
      hudGemYellowFrame,
      gc.getCollectedYellowGemsCount(),
      rightEdgeX,
      row0Top + (hudGemRowHeight + hudGemRowGap) * 2,
      hudGemRowHeight,
      hudYellowColor,
    );
    _drawGemHudRow(
      batch,
      font,
      assets,
      gemTexturePath,
      hudGemBlueFrame,
      gc.getCollectedBlueGemsCount(),
      rightEdgeX,
      row0Top + (hudGemRowHeight + hudGemRowGap) * 3,
      hudGemRowHeight,
      hudBlueColor,
    );

    final String scoreText = '${gc.getGemScore()}';
    final double scoreRowTop = row0Top + (hudGemRowHeight + hudGemRowGap) * 4;
    font.setColor(hudTextColor);
    font.getData().setScale(hudScoreScale);
    hudLayout.setText(font, scoreText);
    final double scoreX = rightEdgeX - hudLayout.width;
    final double scoreY =
        scoreRowTop + (hudScoreRowHeight + hudLayout.height) * 0.5;
    font.drawText(scoreText, scoreX, scoreY);
    font.getData().setScale(1);

    batch.end();
  }

  void _drawGemHudRow(
    SpriteBatch batch,
    BitmapFont font,
    AssetManager assets,
    String gemTexturePath,
    int gemFrameIndex,
    int value,
    double rightEdgeX,
    double rowTop,
    double rowHeight,
    ui.Color valueColor,
  ) {
    final String text = '$value';
    font.setColor(valueColor);
    font.getData().setScale(hudGemCounterScale);
    hudLayout.setText(font, text);
    final double iconX = rightEdgeX - hudGemIconSize;
    final double iconY = rowTop + (rowHeight - hudGemIconSize) * 0.5;
    final double textRightEdge = iconX - hudGemTextGap;
    final double textX = textRightEdge - hudLayout.width;
    final double textY = rowTop + (rowHeight + hudLayout.height) * 0.5;
    _drawGemIcon(
      batch,
      assets,
      gemTexturePath,
      gemFrameIndex,
      iconX,
      iconY,
      hudGemIconSize,
    );
    font.drawText(text, textX, textY);
    font.getData().setScale(1);
  }

  void _drawGemIcon(
    SpriteBatch batch,
    AssetManager assets,
    String texturePath,
    int frameIndex,
    double x,
    double y,
    double size,
  ) {
    if (!assets.isLoaded(texturePath, Texture)) {
      return;
    }
    final Texture texture = assets.get(texturePath, Texture);
    final int cols = texture.width ~/ hudGemFrameSize;
    final int rows = texture.height ~/ hudGemFrameSize;
    if (cols <= 0 || rows <= 0) {
      return;
    }
    final int total = cols * rows;
    final int frame = clampInt(frameIndex, 0, total - 1);
    final int srcCol = frame % cols;
    final int srcRow = frame ~/ cols;
    final ui.Rect src = ui.Rect.fromLTWH(
      (srcCol * hudGemFrameSize).toDouble(),
      (srcRow * hudGemFrameSize).toDouble(),
      hudGemFrameSize.toDouble(),
      hudGemFrameSize.toDouble(),
    );
    final ui.Rect dst = ui.Rect.fromLTWH(x, y, size, size);
    batch.drawRegion(texture, src, dst);
  }

  void _loadHudAssets() {
    if (game.getAssetManager().isLoaded('other/enrrere.png', Texture)) {
      backIconTexture = game.getAssetManager().get(
        'other/enrrere.png',
        Texture,
      );
    }
  }

  void _renderEndOverlayIfActive() {
    if (!_isEndOverlayActive()) {
      return;
    }

    final ShapeRenderer shapes = game.getShapeRenderer();
    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();

    shapes.begin(ShapeType.filled);
    shapes.setColor(endOverlayDim);
    shapes.rect(
      0,
      0,
      Gdx.graphics.getWidth().toDouble(),
      Gdx.graphics.getHeight().toDouble(),
    );
    shapes.end();

    batch.begin();
    _drawCenteredText(
      batch,
      font,
      _endOverlayTitle(),
      Gdx.graphics.getHeight() * 0.45,
      endOverlayTitleScale,
      hudTextColor,
    );
    if (endOverlayElapsedSeconds >= endOverlayReturnDelaySeconds) {
      _drawCenteredText(
        batch,
        font,
        _endOverlayPrompt(),
        Gdx.graphics.getHeight() * 0.45 + endOverlayPromptGap,
        endOverlayPromptScale,
        hudTextColor,
      );
    }
    batch.end();
  }

  void _drawCenteredText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    hudLayout.setText(font, text);
    final double x = (Gdx.graphics.getWidth() - hudLayout.width) * 0.5;
    font.draw(batch, hudLayout, x, y);
    font.getData().setScale(1);
  }

  bool _handleHudBackInput() {
    if (!Gdx.input.justTouched()) {
      return false;
    }
    final double x = Gdx.input.getX().toDouble();
    final double y = Gdx.input.getY().toDouble();
    if (backButtonBounds.contains(x, y)) {
      _returnToMenu();
      return true;
    }
    return false;
  }

  void _updateBackButtonBounds() {
    final BitmapFont font = game.getFont();
    font.getData().setScale(hudBackLabelScale);
    hudLayout.setText(font, hudBackLabel);
    font.getData().setScale(1);
    final double iconWidth = backIconTexture != null
        ? hudIconSize + hudIconTextGap
        : 0;
    backButtonBounds.set(
      hudMargin,
      hudMargin,
      iconWidth + hudLayout.width + 16,
      hudButtonHeight,
    );
  }

  void _updateEndOverlayStateIfNeeded() {
    if (_isEndOverlayActive()) {
      return;
    }

    final GameplayControllerTopDown gc =
        gameplayController as GameplayControllerTopDown;
    if (gc.isWin()) {
      _endOverlayState = _EndOverlayState.level0Win;
    }

    if (_isEndOverlayActive()) {
      endOverlayElapsedSeconds = 0;
    }
  }

  bool _isEndOverlayActive() {
    return _endOverlayState != _EndOverlayState.none;
  }

  void _updateEndOverlay(double delta) {
    endOverlayElapsedSeconds += math.max(0, delta);
    if (endOverlayElapsedSeconds < endOverlayReturnDelaySeconds) {
      return;
    }

    if (Gdx.input.justTouched() || _isAnyKeyJustPressed()) {
      _returnToMenu();
    }
  }

  bool _isAnyKeyJustPressed() {
    final List<int> keys = <int>[
      Input.keys.enter,
      Input.keys.space,
      Input.keys.escape,
      Input.keys.up,
      Input.keys.down,
      Input.keys.left,
      Input.keys.right,
      Input.keys.w,
      Input.keys.a,
      Input.keys.s,
      Input.keys.d,
    ];
    for (final int key in keys) {
      if (Gdx.input.isKeyJustPressed(key)) {
        return true;
      }
    }
    return false;
  }

  String _endOverlayTitle() {
    switch (_endOverlayState) {
      case _EndOverlayState.level0Win:
        return 'Has Guanyat';
      case _EndOverlayState.level1Lose:
        return 'You Lose';
      case _EndOverlayState.level1Win:
        return 'You Win';
      case _EndOverlayState.none:
        return '';
    }
  }

  String _endOverlayPrompt() {
    if (_endOverlayState == _EndOverlayState.level0Win) {
      return 'Apreta qualsevol tecla per tornar';
    }
    return 'Press any key to return to main menu';
  }

  void _handleDebugOverlayInput() {
    if (!Gdx.input.isKeyJustPressed(Input.keys.f3)) {
      return;
    }

    final bool shiftPressed =
        Gdx.input.isKeyPressed(Input.keys.shiftLeft) ||
        Gdx.input.isKeyPressed(Input.keys.shiftRight);
    if (shiftPressed) {
      _debugOverlayMode = _nextDebugOverlayMode(_debugOverlayMode);
    } else {
      _debugOverlayMode = _debugOverlayMode == _DebugOverlayMode.none
          ? _DebugOverlayMode.both
          : _DebugOverlayMode.none;
    }

    Gdx.app.log(
      'PlayScreen',
      'Debug overlay: ${_debugOverlayMode.name.toLowerCase()}',
    );
  }

  void _applyInitialCameraFromLevel() {
    final double centerX = levelData.viewportX + levelData.viewportWidth * 0.5;
    final double centerY = levelData.viewportY + levelData.viewportHeight * 0.5;
    camera.setPosition(centerX, centerY);
    camera.update();
  }

  void _updateCameraForGameplay() {
    if (!gameplayController.hasCameraTarget()) {
      camera.update();
      return;
    }

    final double worldW = math.max(1, levelData.worldWidth);
    final double worldH = math.max(1, levelData.worldHeight);
    final double viewW = math.max(1, viewport.worldWidth);
    final double viewH = math.max(1, viewport.worldHeight);
    final double halfW = viewW * 0.5;
    final double halfH = viewH * 0.5;

    final double minX = math.min(halfW, worldW - halfW);
    final double maxX = math.max(halfW, worldW - halfW);
    final double minY = math.min(halfH, worldH - halfH);
    final double maxY = math.max(halfH, worldH - halfH);

    final double playerX = gameplayController.getCameraTargetX();
    final double playerY = gameplayController.getCameraTargetY();
    final double currentCenterX = camera.x;
    final double currentCenterY = camera.y;

    final double deadZoneHalfW = viewW * cameraDeadZoneFractionX * 0.5;
    final double deadZoneHalfH = viewH * cameraDeadZoneFractionY * 0.5;

    double targetCenterX = currentCenterX;
    if (playerX < currentCenterX - deadZoneHalfW) {
      targetCenterX = playerX + deadZoneHalfW;
    } else if (playerX > currentCenterX + deadZoneHalfW) {
      targetCenterX = playerX - deadZoneHalfW;
    }

    double targetCenterY = currentCenterY;
    if (playerY < currentCenterY - deadZoneHalfH) {
      targetCenterY = playerY + deadZoneHalfH;
    } else if (playerY > currentCenterY + deadZoneHalfH) {
      targetCenterY = playerY - deadZoneHalfH;
    }

    targetCenterX = clampDouble(targetCenterX, minX, maxX);
    targetCenterY = clampDouble(targetCenterY, minY, maxY);

    final double dt = clampDouble(
      Gdx.graphics.getDeltaTime(),
      0,
      maxFrameSeconds,
    );
    final double followAlpha =
        1 - math.exp(-cameraFollowSmoothnessPerSecond * dt);

    double centerX = MathUtils.lerp(currentCenterX, targetCenterX, followAlpha);
    double centerY = MathUtils.lerp(currentCenterY, targetCenterY, followAlpha);

    centerX = clampDouble(centerX, minX, maxX);
    centerY = clampDouble(centerY, minY, maxY);

    camera.setPosition(centerX, centerY);
    camera.update();
  }

  GameplayController _createGameplayController() {
    Gdx.app.log('PlayScreen', 'Gameplay mode: topdown');
    return GameplayControllerTopDown(
      levelData,
      spriteRuntimeStates,
      layerVisibilityStates,
      zoneRuntimeStates,
      zonePreviousRuntimeStates,
    );
  }

  Viewport _createViewport(LevelData levelData, OrthographicCamera camera) {
    switch (levelData.viewportAdaptation) {
      case 'expand':
        return ExtendViewport(
          levelData.viewportWidth,
          levelData.viewportHeight,
          camera,
        );
      case 'stretch':
        return StretchViewport(
          levelData.viewportWidth,
          levelData.viewportHeight,
          camera,
        );
      case 'letterbox':
      default:
        return FitViewport(
          levelData.viewportWidth,
          levelData.viewportHeight,
          camera,
        );
    }
  }

  List<bool> _buildInitialLayerVisibility(LevelData levelData) {
    final List<bool> states = List<bool>.filled(levelData.layers.size, true);
    for (int i = 0; i < levelData.layers.size; i++) {
      states[i] = levelData.layers.get(i).visible;
    }
    return states;
  }

  _DebugOverlayMode _nextDebugOverlayMode(_DebugOverlayMode mode) {
    switch (mode) {
      case _DebugOverlayMode.none:
        return _DebugOverlayMode.zones;
      case _DebugOverlayMode.zones:
        return _DebugOverlayMode.paths;
      case _DebugOverlayMode.paths:
        return _DebugOverlayMode.both;
      case _DebugOverlayMode.both:
        return _DebugOverlayMode.none;
    }
  }

  void _returnToMenu() {
    game.unloadReferencedAssetsForLevel(levelIndex);
    game.setScreen(MenuScreen(game));
  }
}

class _PathBindingRuntime {
  final _PathRuntime path;
  final LevelPathBinding binding;
  final double initialX;
  final double initialY;

  _PathBindingRuntime(this.path, this.binding, this.initialX, this.initialY);
}

class _PathRuntime {
  final List<Vector2> points;
  final List<double> cumulativeDistances;
  final double totalDistance;
  final double firstPointX;
  final double firstPointY;

  _PathRuntime(
    this.points,
    this.cumulativeDistances,
    this.totalDistance,
    this.firstPointX,
    this.firstPointY,
  );

  static _PathRuntime? from(LevelPath path) {
    if (path.points.size < 2) {
      return null;
    }

    final List<Vector2> points = path.points.toList();
    final List<double> cumulativeDistances = <double>[0];
    double totalDistance = 0;
    for (int i = 1; i < points.length; i++) {
      final Vector2 prev = points[i - 1];
      final Vector2 curr = points[i];
      final double dx = curr.x - prev.x;
      final double dy = curr.y - prev.y;
      totalDistance += math.sqrt(dx * dx + dy * dy);
      cumulativeDistances.add(totalDistance);
    }
    final Vector2 first = points.first;
    return _PathRuntime(
      points,
      cumulativeDistances,
      totalDistance,
      first.x,
      first.y,
    );
  }

  _PathSample sampleAtProgress(double progress) {
    if (points.isEmpty) {
      return _PathSample(0, 0);
    }
    if (points.length < 2 || totalDistance <= 0) {
      final Vector2 first = points.first;
      return _PathSample(first.x, first.y);
    }

    final double clampedProgress = clampDouble(progress, 0, 1);
    final double targetDistance = totalDistance * clampedProgress;
    for (int i = 1; i < points.length; i++) {
      final double segmentStart = cumulativeDistances[i - 1];
      final double segmentEnd = cumulativeDistances[i];
      if (targetDistance > segmentEnd && i < points.length - 1) {
        continue;
      }
      final double segmentDistance = segmentEnd - segmentStart;
      if (segmentDistance <= 0) {
        final Vector2 point = points[i];
        return _PathSample(point.x, point.y);
      }
      final double localT = clampDouble(
        (targetDistance - segmentStart) / segmentDistance,
        0,
        1,
      );
      final Vector2 a = points[i - 1];
      final Vector2 b = points[i];
      return _PathSample(
        a.x + (b.x - a.x) * localT,
        a.y + (b.y - a.y) * localT,
      );
    }

    final Vector2 last = points.last;
    return _PathSample(last.x, last.y);
  }
}

class _PathSample {
  final double x;
  final double y;

  _PathSample(this.x, this.y);
}

class _GemSpawnCell {
  final double x;
  final double y;
  final double width;
  final double height;

  _GemSpawnCell(this.x, this.y, this.width, this.height);
}

enum _GemSpawnType { purple, yellow, green, blue }

enum _DebugOverlayMode { none, zones, paths, both }

enum _EndOverlayState { none, level0Win, level1Lose, level1Win }
