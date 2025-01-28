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

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ollama API Demo'),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed:
                          appData.isLoading ? null : () => appData.callStream(),
                      child: const Text('Stream'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: appData.isLoading
                          ? null
                          : () => appData.callComplete(),
                      child: const Text('Complete'),
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
            ),
          ],
        ),
      ),
    );
  }
}
