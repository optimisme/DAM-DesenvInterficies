import 'dart:math' as math;
import 'dart:ui' as ui;

import 'app_data.dart';
import 'game_app.dart';
import 'libgdx_compat/game_framework.dart';
import 'libgdx_compat/math_types.dart';
import 'libgdx_compat/viewport.dart';
import 'play_screen.dart';

class WaitingRoomScreen extends ScreenAdapter {
  static const double worldWidth = 1280;
  static const double worldHeight = 720;
  static const double panelWidth = 340;
  static const double panelPadding = 22;
  static const double rowHeight = 24;
  static const double rowStartTop = 96;

  static final ui.Color background = colorValueOf('070E08');
  static final ui.Color panelFill = colorValueOf('0F1912DD');
  static final ui.Color panelStroke = colorValueOf('35FF74');
  static final ui.Color titleColor = colorValueOf('FFFFFF');
  static final ui.Color textColor = colorValueOf('C7FFD5');
  static final ui.Color dimTextColor = colorValueOf('6FA07A');
  static final ui.Color highlightColor = colorValueOf('35FF74');
  static final ui.Color localPlayerColor = colorValueOf('FFE07A');

  final GameApp game;
  final int levelIndex;
  final Viewport viewport = FitViewport(
    worldWidth,
    worldHeight,
    OrthographicCamera(),
  );
  final GlyphLayout layout = GlyphLayout();

  WaitingRoomScreen(this.game, this.levelIndex);

  @override
  void render(double delta) {
    final AppData appData = game.getAppData();
    if (appData.phase == MatchPhase.playing ||
        appData.phase == MatchPhase.finished) {
      game.setScreen(PlayScreen(game, levelIndex));
      return;
    }

    ScreenUtils.clear(background);
    viewport.apply();

    final ShapeRenderer shapes = game.getShapeRenderer();
    shapes.begin(ShapeType.filled);
    shapes.setColor(panelFill);
    shapes.rect(worldWidth - panelWidth, 0, panelWidth, worldHeight);
    shapes.end();

    shapes.begin(ShapeType.line);
    shapes.setColor(panelStroke);
    shapes.rect(worldWidth - panelWidth, 0, panelWidth, worldHeight);
    shapes.end();

    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    batch.begin();

    _drawCenteredText(
      batch,
      font,
      'Waiting Room',
      worldHeight * 0.18,
      2.8,
      titleColor,
    );
    _drawCenteredText(
      batch,
      font,
      'Match starts in',
      worldHeight * 0.32,
      1.6,
      dimTextColor,
    );
    _drawCenteredText(
      batch,
      font,
      '${math.max(0, appData.countdownSeconds)}',
      worldHeight * 0.48,
      5.5,
      highlightColor,
    );

    final String statusText = appData.isConnected
        ? '${appData.players.length} player(s) connected'
        : 'Connecting to ${game.getSelectedServerLabel()}';
    _drawCenteredText(
      batch,
      font,
      statusText,
      worldHeight * 0.62,
      1.3,
      textColor,
    );
    _drawCenteredText(
      batch,
      font,
      'Gameplay appears automatically when the counter reaches zero.',
      worldHeight * 0.69,
      1.0,
      dimTextColor,
    );

    _drawLeftAlignedText(
      batch,
      font,
      'Players',
      worldWidth - panelWidth + panelPadding,
      52,
      1.6,
      titleColor,
    );

    double rowTop = rowStartTop;
    int rank = 1;
    for (final MultiplayerPlayer player in appData.sortedPlayers) {
      final bool isLocalPlayer = player.id == appData.playerId;
      final ui.Color rowColor = isLocalPlayer ? localPlayerColor : textColor;
      final String label = '$rank. ${_truncatePlayerName(player.name, 18)}';
      _drawLeftAlignedText(
        batch,
        font,
        label,
        worldWidth - panelWidth + panelPadding,
        rowTop + rowHeight * 0.72,
        0.82,
        rowColor,
      );
      _drawRightAlignedText(
        batch,
        font,
        '${player.score}',
        worldWidth - panelPadding,
        rowTop + rowHeight * 0.72,
        0.82,
        rowColor,
      );
      rowTop += rowHeight;
      rank++;
    }

    if (appData.sortedPlayers.isEmpty) {
      _drawLeftAlignedText(
        batch,
        font,
        'No players yet',
        worldWidth - panelWidth + panelPadding,
        rowStartTop,
        1.1,
        dimTextColor,
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
    layout.setText(font, text);
    final double x = (worldWidth - panelWidth - layout.width) * 0.5;
    font.draw(batch, layout, x, y);
    font.getData().setScale(1);
  }

  void _drawLeftAlignedText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double x,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    font.drawText(text, x, y);
    font.getData().setScale(1);
  }

  void _drawRightAlignedText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double right,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    layout.setText(font, text);
    font.draw(batch, layout, right - layout.width, y);
    font.getData().setScale(1);
  }

  String _truncatePlayerName(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, math.max(0, maxChars - 3))}...';
  }

  @override
  void resize(int width, int height) {
    viewport.update(width.toDouble(), height.toDouble(), true);
  }
}
