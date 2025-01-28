import 'package:flutter/cupertino.dart';
import 'view3.dart';

class View1 extends StatelessWidget {
  const View1({super.key});

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('View 1'),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: topPadding),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('This is view 1', style: TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: Center(
              child: CupertinoButton(
                child: const Text('Go to View 3'),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const View3()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
