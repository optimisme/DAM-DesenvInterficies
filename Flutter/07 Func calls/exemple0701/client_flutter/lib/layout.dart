import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'table_view.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final String _placeholder;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    final random = Random();
    final placeholders = [
      'Quin planeta té més llunes?',
      'Quina és la gravetat de la Terra?',
      'Mostra els planetes amb més de 1 lluna',
      'Quina és la distància mitjana al Sol de Mart?',
      'Fes una taula amb nom i diàmetre dels planetes',
    ];
    _placeholder = placeholders[random.nextInt(placeholders.length)];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final session = appData.session;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CupertinoScrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: session.isEmpty ? 1 : session.length,
                          itemBuilder: (context, index) {
                            if (session.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Text(
                                  '...',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              );
                            }
                            final entry = session[index];
                            return _SessionEntryView(entry: entry);
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CDKFieldText(
                        maxLines: 5,
                        controller: _textController,
                        placeholder: _placeholder,
                        enabled: !appData.isLoading,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CDKButton(
                            style: CDKButtonStyle.action,
                            onPressed: appData.isLoading
                                ? null
                                : () {
                                    final userPrompt = _textController.text;
                                    appData.callWithCustomTools(
                                        userPrompt: userPrompt);
                                    _textController.clear();
                                  },
                            child: const Text('Query'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CDKButton(
                            onPressed: appData.isLoading
                                ? () => appData.cancelRequests()
                                : null,
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (appData.isLoading)
                Positioned.fill(
                  child: Container(
                    color: CupertinoColors.systemGrey.withOpacity(0.5),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }
}

class _SessionEntryView extends StatelessWidget {
  final SessionEntry entry;

  const _SessionEntryView({required this.entry});

  String _normalizeText(String text) {
    return text.replaceAll('&quot;', '"');
  }

  TextSpan _buildStyledSpan(String text, TextStyle baseStyle) {
    final normalized = _normalizeText(text);
    final spans = <InlineSpan>[];
    // Match bold (**text**) or italic (*text*) segments, preferring bold when both markers appear.
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
      final innerText = isBold
          ? token.substring(2, token.length - 2)
          : token.substring(1, token.length - 1);
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

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == SessionRole.user;
    final isSystem = entry.role == SessionRole.system;
    final alignment = isSystem
        ? Alignment.center
        : (isUser ? Alignment.centerRight : Alignment.centerLeft);
    final backgroundColor = isSystem
        ? CupertinoColors.systemGrey5
        : (isUser
            ? CupertinoColors.activeBlue.withOpacity(0.15)
            : CupertinoColors.systemGrey6);
    final textColor = isUser ? CupertinoColors.black : CupertinoColors.black;

    final content = _normalizeText(entry.content);
    final parsed = parseMarkdownTable(content);
    final parts = <Widget>[];
    if (parsed.beforeText.isNotEmpty) {
      parts.add(RichText(
        text: _buildStyledSpan(
          parsed.beforeText,
          TextStyle(fontSize: 15, color: textColor),
        ),
      ));
    }
    if (parsed.table != null) {
      if (parts.isNotEmpty) {
        parts.add(const SizedBox(height: 8));
      }
      parts.add(PaintedTable(data: parsed.table!));
    }
    if (parsed.afterText.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(const SizedBox(height: 8));
      }
      parts.add(RichText(
        text: _buildStyledSpan(
          parsed.afterText,
          TextStyle(fontSize: 15, color: textColor),
        ),
      ));
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: parts.isEmpty
            ? RichText(
                text: _buildStyledSpan(
                  content,
                  TextStyle(fontSize: 15, color: textColor),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: parts,
              ),
      ),
    );
  }
}
