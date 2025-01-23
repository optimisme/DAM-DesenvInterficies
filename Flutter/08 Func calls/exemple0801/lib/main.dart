import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'drawable.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Ollama Flutter App',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final ScrollController scrollController = ScrollController();
    final TextEditingController textController = TextEditingController();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ollama API Demo'),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: CupertinoColors.systemGrey5,
                child: CustomPaint(
                  painter: MyCustomPainter(
                    drawables: appData.drawables,
                  ),
                  child: Container(),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CupertinoTextField(
                      controller: textController,
                      placeholder: 'Escriu una pregunta...',
                      maxLines: 3,
                      minLines: 1,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.activeBlue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: appData.isLoading
                                ? null
                                : () {
                                    appData.callStream(
                                        question: textController.text);
                                  },
                            child: const Text('Stream'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: appData.isLoading
                                ? null
                                : () {
                                    appData.callComplete(
                                        question: textController.text);
                                  },
                            child: const Text('Cmplt.'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: () {
                              final userPrompt = textController.text;
                              appData.callWithCustomTools(
                                  userPrompt: userPrompt);
                            },
                            child: const Text('Tools'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            onPressed: appData.isLoading
                                ? () => appData.cancelRequests()
                                : null,
                            color: appData.isLoading
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.inactiveGray,
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CupertinoScrollbar(
                        controller: scrollController,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              appData.responseText,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomPainter extends CustomPainter {
  final List<Drawable> drawables;

  MyCustomPainter({required this.drawables});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawable in drawables) {
      drawable.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
