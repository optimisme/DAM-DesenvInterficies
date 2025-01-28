import 'package:flutter/cupertino.dart';
import 'shape_painter.dart';

class ViewWidget extends StatefulWidget {
  const ViewWidget({super.key});

  @override
  ViewWidgetState createState() => ViewWidgetState();
}

class ViewWidgetState extends State<ViewWidget> {
  late Rect greenSquare;
  late Rect blueCircle;
  bool isGreenSquareDragged = false;
  bool isBlueCircleDragged = false;
  bool isCircleOnTop = true;
  Offset offset = const Offset(-1, -1);

  @override
  void initState() {
    super.initState();
    greenSquare = const Rect.fromLTWH(50, 50, 100, 100);
    blueCircle = const Rect.fromLTWH(250, 250, 100, 100);
  }

  void onPanStart(DragStartDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPosition = details.globalPosition;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    // Adjusting the local position based on the height of CupertinoNavigationBar and SafeArea
    final double navigationBarHeight =
        const CupertinoNavigationBar().preferredSize.height;
    final double safeAreaHeight = MediaQuery.of(context).padding.top;
    final Offset adjustedLocalPosition = Offset(localPosition.dx,
        localPosition.dy - navigationBarHeight - safeAreaHeight);

    setState(() {
      if (greenSquare.contains(adjustedLocalPosition)) {
        isGreenSquareDragged = true;
        isCircleOnTop = false;
        offset = adjustedLocalPosition - greenSquare.topLeft;
      } else if (blueCircle.contains(adjustedLocalPosition)) {
        isBlueCircleDragged = true;
        isCircleOnTop = true;
        offset = adjustedLocalPosition - blueCircle.topLeft;
      } else {}
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPosition = details.globalPosition;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    // Adjusting the local position based on the height of CupertinoNavigationBar and SafeArea
    final double navigationBarHeight =
        const CupertinoNavigationBar().preferredSize.height;
    final double safeAreaHeight = MediaQuery.of(context).padding.top;
    final Offset adjustedLocalPosition = Offset(localPosition.dx,
        localPosition.dy - navigationBarHeight - safeAreaHeight);

    setState(() {
      if (isGreenSquareDragged) {
        greenSquare = Rect.fromLTWH(
            adjustedLocalPosition.dx - offset.dx,
            adjustedLocalPosition.dy - offset.dy,
            greenSquare.width,
            greenSquare.height);
      } else if (isBlueCircleDragged) {
        blueCircle = Rect.fromLTWH(
            adjustedLocalPosition.dx - offset.dx,
            adjustedLocalPosition.dy - offset.dy,
            blueCircle.width,
            blueCircle.height);
      }
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      isGreenSquareDragged = false;
      isBlueCircleDragged = false;
      offset = const Offset(-1, -1);
    });
  }

  void adjustShapes(double canvasWidth, double canvasHeight) {
    // Adjust green square position if out of bounds
    if (greenSquare.right > canvasWidth) {
      greenSquare = Rect.fromLTWH(canvasWidth - greenSquare.width,
          greenSquare.top, greenSquare.width, greenSquare.height);
    }
    if (greenSquare.bottom > canvasHeight) {
      greenSquare = Rect.fromLTWH(
          greenSquare.left,
          canvasHeight - greenSquare.height,
          greenSquare.width,
          greenSquare.height);
    }

    // Adjust blue circle position if out of bounds
    if (blueCircle.right > canvasWidth) {
      blueCircle = Rect.fromLTWH(canvasWidth - blueCircle.width, blueCircle.top,
          blueCircle.width, blueCircle.height);
    }
    if (blueCircle.bottom > canvasHeight) {
      blueCircle = Rect.fromLTWH(
          blueCircle.left,
          canvasHeight - blueCircle.height,
          blueCircle.width,
          blueCircle.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          adjustShapes(constraints.maxWidth, constraints.maxHeight);
          setState(() {});
        });

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('CustomPaint App'),
          ),
          child: SafeArea(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: CupertinoColors.lightBackgroundGray,
                child: CustomPaint(
                  painter: ShapePainter(
                    greenSquare: greenSquare,
                    blueCircle: blueCircle,
                    isCircleOnTop: isCircleOnTop,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
