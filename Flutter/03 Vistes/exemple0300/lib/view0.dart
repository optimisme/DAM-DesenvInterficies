import 'package:flutter/cupertino.dart';
import 'view1.dart';
import 'view2.dart';

class View0 extends StatelessWidget {
  const View0({super.key});

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('View 0'),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: topPadding),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('This is view 0', style: TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CupertinoButton(
                    child: const Text('Go to View 1'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const View1()),
                      );
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Go to View 2'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const View2()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
