import 'package:flutter/material.dart';

class TableData {
  final List<String> headers;
  final List<List<String>> rows;

  TableData({required this.headers, required this.rows});
}

class ParsedTable {
  final String beforeText;
  final TableData? table;
  final String afterText;

  ParsedTable({
    required this.beforeText,
    required this.table,
    required this.afterText,
  });
}

ParsedTable parseMarkdownTable(String text) {
  final lines = text.split('\n');
  int start = -1;
  int separator = -1;

  for (var i = 0; i < lines.length - 1; i++) {
    final line = lines[i];
    final next = lines[i + 1];
    if (line.contains('|') && next.contains('|') && next.contains('-')) {
      start = i;
      separator = i + 1;
      break;
    }
  }

  if (start == -1 || separator == -1) {
    return ParsedTable(beforeText: text.trim(), table: null, afterText: '');
  }

  var end = separator + 1;
  while (end < lines.length && lines[end].contains('|')) {
    end += 1;
  }

  final before = lines.sublist(0, start).join('\n').trim();
  final after = lines.sublist(end).join('\n').trim();
  final tableLines = lines.sublist(start, end);

  if (tableLines.length < 2) {
    return ParsedTable(beforeText: text.trim(), table: null, afterText: '');
  }

  List<String> parseRow(String line) {
    var cleaned = line.trim();
    if (cleaned.startsWith('|')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('|')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned.split('|').map((cell) => cell.trim()).toList();
  }

  final headers = parseRow(tableLines[0]);
  final rows = <List<String>>[];
  for (var i = 2; i < tableLines.length; i++) {
    rows.add(parseRow(tableLines[i]));
  }

  return ParsedTable(
    beforeText: before,
    table: TableData(headers: headers, rows: rows),
    afterText: after,
  );
}

String _normalizeCellText(String text) {
  return text.replaceAll('&quot;', '"');
}

TextSpan _buildStyledSpan(String text, TextStyle baseStyle) {
  final normalized = _normalizeCellText(text);
  final spans = <InlineSpan>[];
  // Supports bold (**text**) and italics (*text*), preferring bold when both markers could apply.
  final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
  var lastIndex = 0;

  for (final match in regex.allMatches(normalized)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: normalized.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }
    final token = match.group(0)!;
    final isBold = token.startsWith('**') && token.endsWith('**');
    final innerText =
        isBold ? token.substring(2, token.length - 2) : token.substring(1, token.length - 1);
    spans.add(TextSpan(
      text: innerText,
      style: baseStyle.merge(
        isBold
            ? const TextStyle(fontWeight: FontWeight.bold)
            : const TextStyle(fontStyle: FontStyle.italic),
      ),
    ));
    lastIndex = match.end;
  }

  if (lastIndex < normalized.length) {
    spans.add(TextSpan(
      text: normalized.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return TextSpan(children: spans, style: baseStyle);
}

class PaintedTable extends StatelessWidget {
  final TableData data;
  final TextStyle headerStyle;
  final TextStyle cellStyle;
  final Color borderColor;
  final Color headerBackground;
  final EdgeInsets cellPadding;

  const PaintedTable({
    super.key,
    required this.data,
    this.headerStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    this.cellStyle = const TextStyle(fontSize: 14, color: Colors.black),
    this.borderColor = const Color(0xFFB7BDC7),
    this.headerBackground = const Color(0xFFE8ECF2),
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    if (data.headers.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _TableLayout.compute(
          data: data,
          maxWidth: constraints.maxWidth,
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          cellPadding: cellPadding,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CustomPaint(
            size: Size(layout.totalWidth, layout.totalHeight),
            painter: TablePainter(
              data: data,
              columnWidths: layout.columnWidths,
              headerHeight: layout.headerHeight,
              rowHeight: layout.rowHeight,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              borderColor: borderColor,
              headerBackground: headerBackground,
              cellPadding: cellPadding,
            ),
          ),
        );
      },
    );
  }
}

class _TableLayout {
  final List<double> columnWidths;
  final double headerHeight;
  final double rowHeight;
  final double totalWidth;
  final double totalHeight;

  _TableLayout({
    required this.columnWidths,
    required this.headerHeight,
    required this.rowHeight,
    required this.totalWidth,
    required this.totalHeight,
  });

  static _TableLayout compute({
    required TableData data,
    required double maxWidth,
    required TextStyle headerStyle,
    required TextStyle cellStyle,
    required EdgeInsets cellPadding,
  }) {
    final columnCount = data.headers.length;
    final widths = List<double>.filled(columnCount, 0);

    for (var i = 0; i < columnCount; i++) {
      widths[i] = _measureStyledTextWidth(data.headers[i], headerStyle) + cellPadding.horizontal;
    }

    for (final row in data.rows) {
      for (var i = 0; i < columnCount; i++) {
        final value = i < row.length ? row[i] : '';
        final width = _measureStyledTextWidth(value, cellStyle) + cellPadding.horizontal;
        if (width > widths[i]) {
          widths[i] = width;
        }
      }
    }

    var totalWidth = widths.fold<double>(0, (sum, w) => sum + w);
    if (maxWidth.isFinite && totalWidth < maxWidth) {
      final extra = (maxWidth - totalWidth) / columnCount;
      for (var i = 0; i < widths.length; i++) {
        widths[i] += extra;
      }
      totalWidth = maxWidth;
    }

    final headerHeight = _measureTextHeight('Hg', headerStyle) + cellPadding.vertical;
    final rowHeight = _measureTextHeight('Hg', cellStyle) + cellPadding.vertical;
    final totalHeight = headerHeight + rowHeight * data.rows.length;

    return _TableLayout(
      columnWidths: widths,
      headerHeight: headerHeight,
      rowHeight: rowHeight,
      totalWidth: totalWidth,
      totalHeight: totalHeight,
    );
  }

  static double _measureStyledTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: _buildStyledSpan(text, style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  static double _measureTextHeight(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.height;
  }
}

class TablePainter extends CustomPainter {
  final TableData data;
  final List<double> columnWidths;
  final double headerHeight;
  final double rowHeight;
  final TextStyle headerStyle;
  final TextStyle cellStyle;
  final Color borderColor;
  final Color headerBackground;
  final EdgeInsets cellPadding;

  TablePainter({
    required this.data,
    required this.columnWidths,
    required this.headerHeight,
    required this.rowHeight,
    required this.headerStyle,
    required this.cellStyle,
    required this.borderColor,
    required this.headerBackground,
    required this.cellPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final headerPaint = Paint()..color = headerBackground;

    final totalWidth = columnWidths.fold<double>(0, (sum, w) => sum + w);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth, headerHeight),
      headerPaint,
    );

    double y = 0;
    double x = 0;

    canvas.drawLine(Offset(0, 0), Offset(totalWidth, 0), borderPaint);
    canvas.drawLine(
        Offset(0, headerHeight), Offset(totalWidth, headerHeight), borderPaint);

    for (var col = 0; col < columnWidths.length; col++) {
      final width = columnWidths[col];
      _paintCellText(
        canvas,
        data.headers[col],
        Rect.fromLTWH(x, 0, width, headerHeight),
        headerStyle,
      );
      x += width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), borderPaint);
    }

    for (var rowIndex = 0; rowIndex < data.rows.length; rowIndex++) {
      final row = data.rows[rowIndex];
      final rowTop = headerHeight + rowHeight * rowIndex;
      canvas.drawLine(
        Offset(0, rowTop + rowHeight),
        Offset(totalWidth, rowTop + rowHeight),
        borderPaint,
      );
      x = 0;
      for (var col = 0; col < columnWidths.length; col++) {
        final text = col < row.length ? row[col] : '';
        _paintCellText(
          canvas,
          text,
          Rect.fromLTWH(x, rowTop, columnWidths[col], rowHeight),
          cellStyle,
        );
        x += columnWidths[col];
      }
    }
  }

  void _paintCellText(
    Canvas canvas,
    String text,
    Rect rect,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: _buildStyledSpan(text, style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - cellPadding.horizontal);

    final offset = Offset(
      rect.left + cellPadding.left,
      rect.top + (rect.height - painter.height) / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TablePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.columnWidths != columnWidths ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.headerBackground != headerBackground;
  }
}
