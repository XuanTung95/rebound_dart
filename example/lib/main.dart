import 'package:flutter/material.dart';
import 'package:rebound_dart/rebound_dart.dart';
import 'dart:math';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class SpringChainData {
  double x = 200.0; // Position Left of widget
  double y = 200.0; // Position Top of widget
  double savedX = 0.0; // saved x
  double savedY = 0.0; // saved y
  double savedGlobalX = 0.0;
  double savedGlobalY = 0.0;
  double widgetSize = 70;

  Size outSize = Size(300, 500);
  Rect inRect = Rect.zero;
  EdgeInsets padding = EdgeInsets.zero;
  Spring? springX;
  Spring? springY;
  bool touching = false;

  SpringChainData({required this.outSize, required this.padding}) {
    _initPosition();
  }

  void updateSize(Size outSize, EdgeInsets padding) {
    if (this.outSize == outSize && this.padding == padding) return;
    this.outSize = outSize;
    this.padding = padding;
    _initPosition();
  }

  void _initPosition() {
    inRect = Rect.fromLTRB(
        padding.left,
        padding.top,
        outSize.width - padding.right - widgetSize,
        outSize.height - padding.bottom - widgetSize);
    x = inRect.right;
    y = inRect.bottom / 2;
  }

  void onPanStart(DragStartDetails details) {}

  void onPanDown(DragDownDetails details) {
    touching = true;
    savedX = x;
    savedY = y;
    savedGlobalX = details.globalPosition.dx;
    savedGlobalY = details.globalPosition.dy;
  }

  void onPanEnd(DragEndDetails details) {
    touching = false;
    var endX = x;
    var endY = y;
    var vx = details.velocity.pixelsPerSecond.dx;
    var vy = details.velocity.pixelsPerSecond.dy;
    double tx = 0;
    if (vx > 0) {
      tx = ((inRect.right - x) / vx).abs();
    } else if (vx < 0) {
      tx = (x / vx).abs();
    }

    double ty = 0;
    if (vy > 0) {
      ty = ((inRect.bottom - y) / vy).abs();
    } else if (vy < 0) {
      ty = (y / vy).abs();
    }

    tx = min(tx, ty);
    endX += vx * tx;
    endY += vy * tx;

    if (endX < inRect.left) {
      endX = inRect.left;
    }
    if (endX > inRect.right) {
      endX = inRect.right;
    }
    if (endY < inRect.top) {
      endY = inRect.top;
    }
    if (endY > inRect.bottom) {
      endY = inRect.bottom;
    }
    springX?.setVelocity(vx);
    springY?.setVelocity(vy);
    springX?.setEndValue(endX);
    springY?.setEndValue(endY);
  }

  void onPanUpdate(DragUpdateDetails details) {
    // move with finger
    springX?.setCurrentValue(savedX + details.globalPosition.dx - savedGlobalX);
    springY?.setCurrentValue(savedY + details.globalPosition.dy - savedGlobalY);
  }
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late SpringSystem springSystem;
  late Spring springX;
  late Spring springY;
  late SpringChainData springData;

  // Demo SpringChain
  late SpringChain springChainX;
  late SpringChain springChainY;
  List<SpringChainData> chainData = [];
  final screenPadding = EdgeInsets.only(top: 30, bottom: 10, left: -5, right: -5);
  final image1 =
      'https://upanh123.com/wp-content/uploads/2021/03/anh-dai-dien-ngau7.jpg';
  final image2 =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQUnGzz2rKplOGt40YoxJpetEVfVK7elg5KvcSiDOrVkcoEF-T-usOSDq5Ti6MtPoWfavQ&usqp=CAU';

  void initState() {
    super.initState();
    springSystem = SpringSystem.create(this);
    springX = springSystem.createSpring();
    springY = springSystem.createSpring();
    springX.setSpringConfig(SpringConfigs.NOT_DRAGGING);
    springY.setSpringConfig(SpringConfigs.NOT_DRAGGING);
    Size size = window.physicalSize / window.devicePixelRatio;
    springData = SpringChainData(
        outSize: size,
        padding: screenPadding);

    springX.addListener(SimpleSpringListener(
      updateCallback: (spring) {
        setState(() {
          springData.x = spring.getCurrentValue();
        });
      },
    ));
    springY.addListener(SimpleSpringListener(
      updateCallback: (spring) {
        setState(() {
          springData.y = spring.getCurrentValue();
        });
      },
    ));
    springData.springX = springX;
    springData.springY = springY;

    // demo Spring chain
    springChainX = SpringChain.create(this);
    springChainY = SpringChain.create(this);
    int maxItem = 5;
    for (int i = maxItem; i >= 0; i--) {
      SpringChainData newData = SpringChainData(
          outSize: size,
          padding: screenPadding);
      chainData.add(newData);
      springChainX.addSpring(SimpleSpringListener(updateCallback: (spring) {
        setState(() {
          newData.x = spring.getCurrentValue();
        });
      }));
      springChainY.addSpring(SimpleSpringListener(updateCallback: (spring) {
        setState(() {
          newData.y = spring.getCurrentValue();
        });
      }));
      if (i == 0) {
        springChainX.setControlSpringIndex(maxItem);
        springChainY.setControlSpringIndex(maxItem);
        newData.springX = springChainX.getControlSpring();
        newData.springY = springChainY.getControlSpring();
      }
    }
  }

  @override
  void dispose() {
    springSystem.dispose();
    springChainX.dispose();
    springChainY.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    if (size != springData.outSize) {
      springData.updateSize(size, screenPadding);
      for (var data in chainData) {
        data.updateSize(size, screenPadding);
      }
    }
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          Positioned(
              left: springData.x,
              top: springData.y,
              child: GestureDetector(
                  onPanStart: springData.onPanStart,
                  onPanEnd: springData.onPanEnd,
                  onPanDown: springData.onPanDown,
                  onPanUpdate: springData.onPanUpdate,
                  child: CircleAvatar(
                    child: ClipOval(
                        child: Image.network(
                      image1,
                      fit: BoxFit.cover,
                    )),
                    radius: springData.widgetSize / 2,
                  ))),
          if (chainData.isNotEmpty) ...buildChain(),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> buildChain() {
    List<Widget> ret = [];
    for (int i = 0; i < chainData.length; i++) {
      var data = chainData[i];
      Widget widget = CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
            child: Image.network(
          i >= 3 ? image2 : image1,
          fit: BoxFit.cover,
        )),
        radius: data.widgetSize / 2,
      );
      ret.add(Positioned(
          left: data.x,
          top: data.y,
          child: i < (chainData.length - 1)
              ? widget
              : GestureDetector(
                  onPanStart: data.onPanStart,
                  onPanEnd: data.onPanEnd,
                  onPanDown: data.onPanDown,
                  onPanUpdate: data.onPanUpdate,
                  child: widget)));
    }
    return ret;
  }
}

class SpringConfigs {
  static final SpringConfig NOT_DRAGGING =
      SpringConfig.fromOrigamiTensionAndFriction(40.0, 4.5); // (60.0, 7.5)
  static final SpringConfig CAPTURING =
      SpringConfig.fromBouncinessAndSpeed(8.0, 40.0);
  static final SpringConfig CLOSE_SCALE =
      SpringConfig.fromBouncinessAndSpeed(7.0, 25.0);
  static final SpringConfig CLOSE_Y =
      SpringConfig.fromBouncinessAndSpeed(3.0, 3.0);
  static final SpringConfig DRAGGING =
      SpringConfig.fromOrigamiTensionAndFriction(0.0, 5.0);
  static final SpringConfig CONTENT_SCALE =
      SpringConfig.fromBouncinessAndSpeed(5.0, 40.0);
}
