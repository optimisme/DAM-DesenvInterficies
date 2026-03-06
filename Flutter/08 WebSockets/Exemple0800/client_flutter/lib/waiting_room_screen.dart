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
  static const double gemLegendDotRadius = 11;

  static final ui.Color background = colorValueOf('070E08');
  static final ui.Color panelFill = colorValueOf('0F1912DD');
  static final ui.Color panelStroke = colorValueOf('35FF74');
  static final ui.Color titleColor = colorValueOf('FFFFFF');
  static final ui.Color textColor = colorValueOf('C7FFD5');
  static final ui.Color dimTextColor = colorValueOf('6FA07A');
  static final ui.Color highlightColor = colorValueOf('35FF74');
  static final ui.Color localPlayerColor = colorValueOf('FFE07A');
  static final ui.Color blueGemColor = colorValueOf('4CCBFF');
  static final ui.Color greenGemColor = colorValueOf('63FF8F');
  static final ui.Color yellowGemColor = colorValueOf('FFD85E');
  static final ui.Color purpleGemColor = colorValueOf('C08BFF');

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

    final double legendCenterX = (worldWidth - panelWidth) * 0.5;
    final List<_GemLegendEntry> gemLegend = <_GemLegendEntry>[
      _GemLegendEntry('Blue gem', 1, blueGemColor),
      _GemLegendEntry('Green gem', 2, greenGemColor),
      _GemLegendEntry('Yellow gem', 3, yellowGemColor),
      _GemLegendEntry('Purple gem', 5, purpleGemColor),
    ];
    shapes.begin(ShapeType.filled);
    double legendDotY = worldHeight * 0.71;
    for (final _GemLegendEntry entry in gemLegend) {
      shapes.setColor(entry.color);
      shapes.circle(legendCenterX - 132, legendDotY - 8, gemLegendDotRadius);
      legendDotY += 42;
    }
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

    _drawCenteredText(
      batch,
      font,
      'Collect as many gems as you can.',
      worldHeight * 0.62,
      1.3,
      textColor,
    );

    double legendTextY = worldHeight * 0.71;
    for (final _GemLegendEntry entry in gemLegend) {
      _drawCenteredText(
        batch,
        font,
        '${entry.label}  ${entry.points} pt${entry.points == 1 ? '' : 's'}',
        legendTextY,
        1.05,
        entry.color,
      );
      legendTextY += 42;
    }

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

class _GemLegendEntry {
  final String label;
  final int points;
  final ui.Color color;

  const _GemLegendEntry(this.label, this.points, this.color);
}
