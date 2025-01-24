import 'dart:math';
import 'package:exemple0801/canvas_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Ollama Flutter App',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final ScrollController scrollController = ScrollController();
    final TextEditingController textController = TextEditingController();

    final random = Random();
    final placeholders = [
      'Dibuixa una línia 10, 50 i 100, 25 ...',
      'Dibuixa un cercle amb centre a 150, 200 i radi 50 ...',
      'Fes un rectangle entre x=10, y=20 i x=100, y=200 ...',
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Funcion call demo'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: CupertinoColors.systemGrey5,
                    child: CustomPaint(
                      painter: CanvasPainter(
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
                      ),
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CupertinoTextField(
                            controller: textController,
                            placeholder: placeholders[
                                random.nextInt(placeholders.length)],
                            maxLines: 3,
                            minLines: 1,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: CupertinoColors.activeBlue),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabled:
                                !appData.isLoading, // Desactiva si carregant
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
                                        final userPrompt = textController.text;
                                        appData.callWithCustomTools(
                                            userPrompt: userPrompt);
                                      },
                                child: const Text('Query'),
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
      ),
    );
  }
}
