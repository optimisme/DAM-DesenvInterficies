import 'dart:math' as math;

import 'libgdx_compat/gdx.dart';
import 'libgdx_compat/gdx_collections.dart';
import 'gameplay_controller_base.dart';
import 'level_data.dart';
import 'libgdx_compat/math_types.dart';

class GameplayControllerTopDown extends GameplayControllerBase {
  static const double moveSpeedPerSecond = 95;
  static const double diagonalNormalize = 0.70710677;
  static const double normalAccelerationPerSecond = 900;
  static const double normalDecelerationPerSecond = 1200;
  static const double iceAccelerationPerSecond = 230;
  static const double iceDecelerationPerSecond = 75;
  static const double sandSpeedMultiplier = 0.48;
  static const double movementDirectionThreshold = 2;
  static const double velocityStopThreshold = 0.5;
  static const int maxCollisionSlideIterations = 4;
  static const int collisionSweepIterations = 12;
  static const double collisionTimeBackoff = 0.001;
  static const double collisionProbeSpacing = 1.0;
  static const double movementEpsilon = 0.0001;

  final IntArray blockedZoneIndices = IntArray();
  final IntArray iceZoneIndices = IntArray();
  final IntArray sandZoneIndices = IntArray();
  final IntArray arbreZoneIndices = IntArray();
  final IntArray futureBridgeZoneIndices = IntArray();
  final IntArray _singleZoneCollisionQuery = IntArray();
  final ObjectSet<String> collectibleArbreTileKeys = ObjectSet<String>();
  final ObjectSet<String> collectedArbreTileKeys = ObjectSet<String>();
  final Rectangle tileRectCache = Rectangle();

  late final int decorationsLayerIndex;
  late final int hiddenBridgeLayerIndex;
  bool wasInsideFutureBridgeZone = false;
  _Direction _direction = _Direction.down;
  bool moving = false;
  double velocityX = 0;
  double velocityY = 0;

  GameplayControllerTopDown(
    super.levelData,
    super.spriteRuntimeStates,
    super.layerVisibilityStates,
    super.zoneRuntimeStates,
    super.zonePreviousRuntimeStates,
  ) {
    decorationsLayerIndex = _findLayerIndexByName(<String>[
      'decoracions',
      'decorations',
    ]);
    hiddenBridgeLayerIndex = _findLayerIndexByName(<String>[
      'pont amagat',
      'hidden bridge',
    ]);

    _classifyZones();
    _buildCollectibleArbreTiles();
    _updatePlayerAnimationSelection();
    syncPlayerToSpriteRuntime();
  }

  int getCollectedArbresCount() {
    return collectedArbreTileKeys.size;
  }

  int getTotalArbresCount() {
    return collectibleArbreTileKeys.size;
  }

  bool isWin() {
    return collectibleArbreTileKeys.size > 0 &&
        collectedArbreTileKeys.size >= collectibleArbreTileKeys.size;
  }

  @override
  void handleInput() {
    if (Gdx.input.isKeyJustPressed(Input.keys.r)) {
      resetPlayerToSpawn();
    }
  }

  @override
  void fixedUpdate(double dtSeconds) {
    if (playerSpriteIndex < 0) {
      return;
    }

    double inputX = 0;
    double inputY = 0;
    final bool left =
        Gdx.input.isKeyPressed(Input.keys.left) ||
        Gdx.input.isKeyPressed(Input.keys.a);
    final bool right =
        Gdx.input.isKeyPressed(Input.keys.right) ||
        Gdx.input.isKeyPressed(Input.keys.d);
    final bool up =
        Gdx.input.isKeyPressed(Input.keys.up) ||
        Gdx.input.isKeyPressed(Input.keys.w);
    final bool down =
        Gdx.input.isKeyPressed(Input.keys.down) ||
        Gdx.input.isKeyPressed(Input.keys.s);

    if (left) {
      inputX -= 1;
    }
    if (right) {
      inputX += 1;
    }
    if (up) {
      inputY -= 1;
    }
    if (down) {
      inputY += 1;
    }

    if (inputX != 0 && inputY != 0) {
      inputX *= diagonalNormalize;
      inputY *= diagonalNormalize;
    }

    final bool onIce = _isPlayerOnIce();
    final bool onSand = _isPlayerOnSand();
    final double speedMultiplier = onSand ? sandSpeedMultiplier : 1;
    final double targetVelocityX =
        inputX * moveSpeedPerSecond * speedMultiplier;
    final double targetVelocityY =
        inputY * moveSpeedPerSecond * speedMultiplier;
    final bool hasInput = inputX != 0 || inputY != 0;
    final double acceleration = onIce
        ? iceAccelerationPerSecond
        : normalAccelerationPerSecond;
    final double deceleration = onIce
        ? iceDecelerationPerSecond
        : normalDecelerationPerSecond;
    final double maxVelocityDelta =
        (hasInput ? acceleration : deceleration) * dtSeconds;
    velocityX = _approach(velocityX, targetVelocityX, maxVelocityDelta);
    velocityY = _approach(velocityY, targetVelocityY, maxVelocityDelta);
    if (velocityX.abs() < velocityStopThreshold) {
      velocityX = 0;
    }
    if (velocityY.abs() < velocityStopThreshold) {
      velocityY = 0;
    }

    final bool movingLeft = velocityX < -movementDirectionThreshold;
    final bool movingRight = velocityX > movementDirectionThreshold;
    final bool movingUp = velocityY < -movementDirectionThreshold;
    final bool movingDown = velocityY > movementDirectionThreshold;
    _updateDirection(movingUp, movingDown, movingLeft, movingRight);

    final double dx = velocityX * dtSeconds;
    final double dy = velocityY * dtSeconds;

    final double previousX = playerX;
    final double previousY = playerY;
    _movePlayerWithWallCollisions(previousX, previousY, dx, dy);

    moving =
        velocityX.abs() > movementDirectionThreshold ||
        velocityY.abs() > movementDirectionThreshold;
    _updatePlayerAnimationSelection();

    _revealHiddenBridgeIfNeeded();
    _collectArbreTileIfNeeded();
    syncPlayerToSpriteRuntime();
  }

  @override
  void resetPlayerToSpawn() {
    super.resetPlayerToSpawn();
    wasInsideFutureBridgeZone = false;
    _direction = _Direction.down;
    moving = false;
    velocityX = 0;
    velocityY = 0;
    setPlayerFlip(false, false);
    _updatePlayerAnimationSelection();
  }

  void _classifyZones() {
    blockedZoneIndices.clear();
    iceZoneIndices.clear();
    sandZoneIndices.clear();
    arbreZoneIndices.clear();
    futureBridgeZoneIndices.clear();

    for (int i = 0; i < levelData.zones.size; i++) {
      final LevelZone zone = levelData.zones.get(i);
      final String type = normalize(zone.type);
      final String name = normalize(zone.name);
      final String gameplayData = normalize(zone.gameplayData);
      final bool isWall =
          containsAny(type, <String>['mur', 'wall']) ||
          containsAny(name, <String>['mur', 'wall']);
      final bool isIce =
          containsAny(type, <String>['ice', 'gel', 'hielo']) ||
          containsAny(name, <String>['ice', 'gel', 'hielo']);
      final bool isSand =
          containsAny(type, <String>['sand', 'sorra', 'arena']) ||
          containsAny(name, <String>['sand', 'sorra', 'arena']);

      if (isWall) {
        blockedZoneIndices.add(i);
      }
      if (isIce) {
        iceZoneIndices.add(i);
      }
      if (isSand) {
        sandZoneIndices.add(i);
      }
      if (containsAny(type, <String>['arbre']) ||
          containsAny(name, <String>['arbre', 'tree'])) {
        arbreZoneIndices.add(i);
      }
      if (gameplayData == 'futur pont' || gameplayData == 'future bridge') {
        futureBridgeZoneIndices.add(i);
      }
    }
  }

  bool _wouldCollideBlocked(double nextX, double nextY) {
    return spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      nextX,
      nextY,
      blockedZoneIndices,
    );
  }

  bool _isPlayerOnIce() {
    if (iceZoneIndices.size <= 0) {
      return false;
    }
    return spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      playerX,
      playerY,
      iceZoneIndices,
    );
  }

  bool _isPlayerOnSand() {
    if (sandZoneIndices.size <= 0) {
      return false;
    }
    return spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      playerX,
      playerY,
      sandZoneIndices,
    );
  }

  void _movePlayerWithWallCollisions(
    double previousX,
    double previousY,
    double deltaX,
    double deltaY,
  ) {
    double currentX = previousX;
    double currentY = previousY;
    double remainingX = deltaX;
    double remainingY = deltaY;

    for (int i = 0; i < maxCollisionSlideIterations; i++) {
      if (remainingX.abs() <= movementEpsilon &&
          remainingY.abs() <= movementEpsilon) {
        break;
      }

      final double targetX = currentX + remainingX;
      final double targetY = currentY + remainingY;
      if (!_wouldCollideBlocked(targetX, targetY)) {
        currentX = targetX;
        currentY = targetY;
        break;
      }

      final double hitT = _findCollisionTimeOnSegment(
        currentX,
        currentY,
        remainingX,
        remainingY,
      );
      final double safeT = clampDouble(hitT - collisionTimeBackoff, 0, 1);
      final double probeT = clampDouble(hitT + collisionTimeBackoff, 0, 1);

      final double segmentStartX = currentX;
      final double segmentStartY = currentY;
      currentX = segmentStartX + remainingX * safeT;
      currentY = segmentStartY + remainingY * safeT;

      final double probeX = segmentStartX + remainingX * probeT;
      final double probeY = segmentStartY + remainingY * probeT;
      final _CollisionNormal normal = _estimateCollisionNormalAt(
        probeX,
        probeY,
        remainingX,
        remainingY,
      );

      final double remainingScale = math.max(0, 1 - safeT);
      double slideX = remainingX * remainingScale;
      double slideY = remainingY * remainingScale;
      final double intoWall = slideX * normal.x + slideY * normal.y;
      if (intoWall < 0) {
        slideX -= intoWall * normal.x;
        slideY -= intoWall * normal.y;
      }

      remainingX = slideX;
      remainingY = slideY;
    }

    playerX = currentX;
    playerY = currentY;
    if (_wouldCollideBlocked(playerX, playerY)) {
      playerX = previousX;
      playerY = previousY;
      _resolveWallPenetration();
    }
  }

  void _resolveWallPenetration() {
    if (!_wouldCollideBlocked(playerX, playerY)) {
      return;
    }

    for (final int zoneIndex in blockedZoneIndices.iterable()) {
      if (!_collidesWithZoneAt(zoneIndex, playerX, playerY)) {
        continue;
      }

      final Rectangle zoneRect = zoneRectAtIndex(zoneIndex, rectCacheB);
      final double zoneLeft = zoneRect.x;
      final double zoneTop = zoneRect.y;
      final double zoneRight = zoneLeft + zoneRect.width;
      final double zoneBottom = zoneTop + zoneRect.height;

      final Rectangle pb = playerRectAt(playerX, playerY, rectCacheA);
      final double playerLeft = pb.x;
      final double playerTop = pb.y;
      final double playerRight = playerLeft + pb.width;
      final double playerBottom = playerTop + pb.height;

      final double penLeft = playerRight - zoneLeft;
      final double penRight = zoneRight - playerLeft;
      final double penTop = playerBottom - zoneTop;
      final double penBottom = zoneBottom - playerTop;

      double minPen = penLeft;
      double pushX = -penLeft;
      double pushY = 0;

      if (penRight < minPen) {
        minPen = penRight;
        pushX = penRight;
        pushY = 0;
      }
      if (penTop < minPen) {
        minPen = penTop;
        pushX = 0;
        pushY = -penTop;
      }
      if (penBottom < minPen) {
        minPen = penBottom;
        pushX = 0;
        pushY = penBottom;
      }

      playerX += pushX;
      playerY += pushY;

      if (!_wouldCollideBlocked(playerX, playerY)) {
        return;
      }
    }
  }

  double _findCollisionTimeOnSegment(
    double startX,
    double startY,
    double deltaX,
    double deltaY,
  ) {
    if (_wouldCollideBlocked(startX, startY)) {
      return 0;
    }
    final double distance = math.sqrt(deltaX * deltaX + deltaY * deltaY);
    if (distance <= movementEpsilon) {
      return 1;
    }

    final int probeCount = math.max(
      1,
      (distance / collisionProbeSpacing).ceil(),
    );
    double low = 0;
    double high = 1;
    bool hasCollision = false;
    for (int i = 1; i <= probeCount; i++) {
      final double t = i / probeCount;
      final double sampleX = startX + deltaX * t;
      final double sampleY = startY + deltaY * t;
      if (_wouldCollideBlocked(sampleX, sampleY)) {
        high = t;
        hasCollision = true;
        break;
      }
      low = t;
    }

    if (!hasCollision) {
      return 1;
    }

    for (int i = 0; i < collisionSweepIterations; i++) {
      final double mid = (low + high) * 0.5;
      final double midX = startX + deltaX * mid;
      final double midY = startY + deltaY * mid;
      if (_wouldCollideBlocked(midX, midY)) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }

  _CollisionNormal _estimateCollisionNormalAt(
    double x,
    double y,
    double movementX,
    double movementY,
  ) {
    final Rectangle playerBounds = playerRectAt(x, y, rectCacheA);
    final double playerLeft = playerBounds.x;
    final double playerTop = playerBounds.y;
    final double playerRight = playerBounds.x + playerBounds.width;
    final double playerBottom = playerBounds.y + playerBounds.height;

    double bestScore = double.infinity;
    double bestNormalX = 0;
    double bestNormalY = 0;
    for (final int zoneIndex in blockedZoneIndices.iterable()) {
      if (!_collidesWithZoneAt(zoneIndex, x, y)) {
        continue;
      }

      final Rectangle zoneRect = zoneRectAtIndex(zoneIndex, rectCacheB);
      final double zoneLeft = zoneRect.x;
      final double zoneTop = zoneRect.y;
      final double zoneRight = zoneLeft + zoneRect.width;
      final double zoneBottom = zoneTop + zoneRect.height;

      final double relativeX = movementX - _zoneDeltaX(zoneIndex);
      final double relativeY = movementY - _zoneDeltaY(zoneIndex);
      final double relativeSpeedSq =
          relativeX * relativeX + relativeY * relativeY;
      final bool hasRelativeMotion =
          relativeSpeedSq > movementEpsilon * movementEpsilon;

      void consider(double penetration, double normalX, double normalY) {
        if (!penetration.isFinite || penetration <= movementEpsilon) {
          return;
        }
        double score = penetration;
        if (hasRelativeMotion) {
          final double relativeDot = relativeX * normalX + relativeY * normalY;
          if (relativeDot >= 0) {
            score += 1000000;
          }
        }
        if (score < bestScore) {
          bestScore = score;
          bestNormalX = normalX;
          bestNormalY = normalY;
        }
      }

      consider(playerRight - zoneLeft, -1, 0);
      consider(zoneRight - playerLeft, 1, 0);
      consider(playerBottom - zoneTop, 0, -1);
      consider(zoneBottom - playerTop, 0, 1);
    }

    if (bestScore.isFinite) {
      return _CollisionNormal(bestNormalX, bestNormalY);
    }

    final double moveLen = math.sqrt(
      movementX * movementX + movementY * movementY,
    );
    if (moveLen > movementEpsilon) {
      return _CollisionNormal(-movementX / moveLen, -movementY / moveLen);
    }
    return const _CollisionNormal(0, -1);
  }

  bool _collidesWithZoneAt(int zoneIndex, double x, double y) {
    _singleZoneCollisionQuery.clear();
    _singleZoneCollisionQuery.add(zoneIndex);
    return spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      x,
      y,
      _singleZoneCollisionQuery,
    );
  }

  double _zoneDeltaX(int zoneIndex) {
    if (zoneIndex < 0 ||
        zoneIndex >= zoneRuntimeStates.size ||
        zoneIndex >= zonePreviousRuntimeStates.size) {
      return 0;
    }
    return zoneRuntimeStates.get(zoneIndex).x -
        zonePreviousRuntimeStates.get(zoneIndex).x;
  }

  double _zoneDeltaY(int zoneIndex) {
    if (zoneIndex < 0 ||
        zoneIndex >= zoneRuntimeStates.size ||
        zoneIndex >= zonePreviousRuntimeStates.size) {
      return 0;
    }
    return zoneRuntimeStates.get(zoneIndex).y -
        zonePreviousRuntimeStates.get(zoneIndex).y;
  }

  double _approach(double current, double target, double maxDelta) {
    if (current < target) {
      return math.min(current + maxDelta, target);
    }
    if (current > target) {
      return math.max(current - maxDelta, target);
    }
    return target;
  }

  int _findLayerIndexByName(List<String> tokens) {
    for (int i = 0; i < levelData.layers.size; i++) {
      final String layerName = normalize(levelData.layers.get(i).name);
      if (containsAny(layerName, tokens)) {
        return i;
      }
    }
    return -1;
  }

  void _revealHiddenBridgeIfNeeded() {
    if (hiddenBridgeLayerIndex < 0 ||
        hiddenBridgeLayerIndex >= layerVisibilityStates.length ||
        futureBridgeZoneIndices.size <= 0) {
      return;
    }

    final bool insideFutureBridge = spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      playerX,
      playerY,
      futureBridgeZoneIndices,
    );
    if (insideFutureBridge && !wasInsideFutureBridgeZone) {
      layerVisibilityStates[hiddenBridgeLayerIndex] = true;
    }
    wasInsideFutureBridgeZone = insideFutureBridge;
  }

  void _buildCollectibleArbreTiles() {
    collectibleArbreTileKeys.clear();
    if (decorationsLayerIndex < 0 ||
        decorationsLayerIndex >= levelData.layers.size ||
        arbreZoneIndices.size <= 0) {
      return;
    }

    final LevelLayer layer = levelData.layers.get(decorationsLayerIndex);
    if (layer.tileMap.isEmpty ||
        layer.tileWidth <= 0 ||
        layer.tileHeight <= 0) {
      return;
    }

    for (int tileY = 0; tileY < layer.tileMap.length; tileY++) {
      final List<int> row = layer.tileMap[tileY];
      for (int tileX = 0; tileX < row.length; tileX++) {
        if (row[tileX] < 0) {
          continue;
        }
        tileRectCache.set(
          layer.x + tileX * layer.tileWidth,
          layer.y + tileY * layer.tileHeight,
          layer.tileWidth.toDouble(),
          layer.tileHeight.toDouble(),
        );
        if (overlapsAnyZone(tileRectCache, arbreZoneIndices)) {
          collectibleArbreTileKeys.add(_tileKey(tileX, tileY));
        }
      }
    }
  }

  void _collectArbreTileIfNeeded() {
    if (decorationsLayerIndex < 0 ||
        decorationsLayerIndex >= levelData.layers.size ||
        arbreZoneIndices.size <= 0) {
      return;
    }
    if (!spriteOverlapsAnyZoneByHitBoxes(
      playerSpriteIndex,
      playerX,
      playerY,
      arbreZoneIndices,
    )) {
      return;
    }

    final LevelLayer layer = levelData.layers.get(decorationsLayerIndex);
    if (layer.tileMap.isEmpty ||
        layer.tileWidth <= 0 ||
        layer.tileHeight <= 0) {
      return;
    }

    final int tileX = floorToInt((playerX - layer.x) / layer.tileWidth);
    final int tileY = floorToInt((playerY - layer.y) / layer.tileHeight);
    if (tileY < 0 || tileY >= layer.tileMap.length) {
      return;
    }

    final List<int> row = layer.tileMap[tileY];
    if (tileX < 0 || tileX >= row.length) {
      return;
    }
    if (row[tileX] < 0) {
      return;
    }

    final String key = _tileKey(tileX, tileY);
    if (!collectibleArbreTileKeys.contains(key) ||
        collectedArbreTileKeys.contains(key)) {
      return;
    }

    row[tileX] = -1;
    collectedArbreTileKeys.add(key);
  }

  String _tileKey(int x, int y) {
    return '$x:$y';
  }

  void _updateDirection(bool up, bool down, bool left, bool right) {
    if (up && left) {
      _direction = _Direction.upLeft;
    } else if (up && right) {
      _direction = _Direction.upRight;
    } else if (down && left) {
      _direction = _Direction.downLeft;
    } else if (down && right) {
      _direction = _Direction.downRight;
    } else if (up) {
      _direction = _Direction.up;
    } else if (down) {
      _direction = _Direction.down;
    } else if (left) {
      _direction = _Direction.left;
    } else if (right) {
      _direction = _Direction.right;
    }
  }

  void _updatePlayerAnimationSelection() {
    if (playerSpriteIndex < 0) {
      return;
    }

    final List<String> prefixes = moving
        ? <String>['Character  Walk ', 'Character Walk ']
        : <String>['Character Idle '];
    String suffix;
    bool flipX;
    switch (_direction) {
      case _Direction.upLeft:
        suffix = 'Up-Right';
        flipX = true;
        break;
      case _Direction.up:
        suffix = 'Up';
        flipX = false;
        break;
      case _Direction.upRight:
        suffix = 'Up-Right';
        flipX = false;
        break;
      case _Direction.left:
        suffix = 'Right';
        flipX = true;
        break;
      case _Direction.right:
        suffix = 'Right';
        flipX = false;
        break;
      case _Direction.downLeft:
        suffix = 'Down-Right';
        flipX = true;
        break;
      case _Direction.downRight:
        suffix = 'Down-Right';
        flipX = false;
        break;
      case _Direction.down:
        suffix = 'Down';
        flipX = false;
        break;
    }

    setPlayerFlip(flipX, false);
    _setPlayerAnimationFromCandidates(
      prefixes.map((String prefix) => '$prefix$suffix').toList(),
    );
  }

  void _setPlayerAnimationFromCandidates(List<String> animationNames) {
    for (final String animationName in animationNames) {
      if (findAnimationIdByName(animationName) != null) {
        setPlayerAnimationOverrideByName(animationName);
        return;
      }
    }
    setPlayerAnimationOverrideByName(null);
  }
}

class _CollisionNormal {
  final double x;
  final double y;

  const _CollisionNormal(this.x, this.y);
}

enum _Direction { upLeft, up, upRight, left, right, downLeft, down, downRight }
