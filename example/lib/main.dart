import 'package:flutter/material.dart';
import 'package:rebound_dart/rebound_dart.dart';
import 'dart:math';

void main() {
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
  Widget child = SizedBox();
  double x = 100.0;
  double y = 100.0;
  double initialX = 0.0;
  double initialY = 0.0;
  double initialTouchX = 0.0;
  double initialTouchY = 0.0;
  double scaleX = 1;
  double scaleY = 1;
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late SpringSystem springSystem;
  late Spring springX;
  late Spring springY;
  double x = 0.0;
  double y = 0.0;
  double initialX = 0.0;
  double initialY = 0.0;
  double initialTouchX = 0.0;
  double initialTouchY = 0.0;
  double scaleX = 1;
  double scaleY = 1;
  double HEAD_SIZE = 60;

  // Demo SpringChain
  late SpringChain springChainX;
  late SpringChain springChainY;
  List<SpringChainData> chainData = [];

  void initState() {
    super.initState();
    springSystem = SpringSystem.create(this);
    springX = springSystem.createSpring();
    springY = springSystem.createSpring();
    springX.setSpringConfig(SpringConfigs.NOT_DRAGGING);
    springY.setSpringConfig(SpringConfigs.NOT_DRAGGING);
    springX.addListener(SimpleSpringListener(
      updateCallback: (spring) {
        setState(() {
          x = spring.getCurrentValue();
        });
      },
    ));
    springY.addListener(SimpleSpringListener(
      updateCallback: (spring) {
        setState(() {
          y = spring.getCurrentValue();
        });
      },
    ));
    // demo Spring chain
    springChainX = SpringChain.create(this);
    springChainY = SpringChain.create(this);
    int maxItem = 5;
    for(int i=maxItem; i>=0; i--) {
      Widget child = FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.amber[900],
        child: Icon(
          Icons.wifi_tethering,
        ),
      );
      SpringChainData newData = SpringChainData();
      chainData.add(newData);
      springChainX.addSpring(SimpleSpringListener(
        updateCallback: (spring) {
          newData.x = spring.getCurrentValue();
          setState(() {});
        }
      ));
      springChainY.addSpring(SimpleSpringListener(
        updateCallback: (spring) {
          newData.y = spring.getCurrentValue();
          setState(() {});
        }
      ));
      if (i==0) {
        child = GestureDetector(
          onPanStart: (details) {},
          onPanDown: (details) {
            newData.initialX = newData.x;
            newData.initialY = newData.y;
            newData.initialTouchX = details.globalPosition.dx;
            newData.initialTouchY = details.globalPosition.dy;
            newData.scaleX = 0.9;
            newData.scaleY = 0.9;
          },
          onPanEnd: (details) {
            var size = MediaQuery.of(context).size;
            var endX = newData.x;
            var endY = newData.y;
            var vx = details.velocity.pixelsPerSecond.dx;
            var vy = details.velocity.pixelsPerSecond.dy;
            if (vx == 0 && vy == 0) {
              endX = newData.x;
              endY = newData.y;
            } else if (vx == 0) {
              endX = newData.x;
              endY = (vy > 0) ? size.height - HEAD_SIZE : 0;
            } else if (vy == 0) {
              endY = newData.y;
              endX = (vx > 0) ? size.width - HEAD_SIZE : 0;
            } else {
              double tx =
              (((vx > 0) ? (size.width - HEAD_SIZE - newData.x) : newData.x) / vx)
                  .abs();
              double ty =
              (((vy > 0) ? (size.height - HEAD_SIZE - newData.y) : newData.y) / vy)
                  .abs();
              if (tx > ty) {
                endY = ((vy > 0) ? (size.height - HEAD_SIZE) : 0);
                endX = newData.x + vx * ty;
              } else if (ty > tx) {
                endX = (vx > 0) ? (size.width - HEAD_SIZE) : 0;
                endY = newData.y + vy * tx;
              } else {
                endX = (vx > 0) ? (size.width - HEAD_SIZE) : 0;
                endY = ((vy > 0) ? (size.height - HEAD_SIZE) : 0);
              }
            }
            springChainX.getControlSpring().setEndValue(endX);
            springChainY.getControlSpring().setEndValue(endY);
            newData.scaleX = 1;
            newData.scaleY = 1;
          },
          onPanUpdate: (details) {
            setState(() {
              springChainX.getControlSpring().setCurrentValue(
                  newData.initialX + details.globalPosition.dx - newData.initialTouchX);
              springChainY.getControlSpring().setCurrentValue(
                  newData.initialY + details.globalPosition.dy - newData.initialTouchY);
            });
          },
          child: child,
        );
        springChainX.setControlSpringIndex(maxItem);
        springChainY.setControlSpringIndex(maxItem);
      }
      newData.child = child;
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onPanStart: (details) {},
                onPanDown: (details) {
                  initialX = x;
                  initialY = y;
                  initialTouchX = details.globalPosition.dx;
                  initialTouchY = details.globalPosition.dy;
                  scaleX = 0.9;
                  scaleY = 0.9;
                },
                onPanEnd: (details) {
                  var size = MediaQuery.of(context).size;
                  var endX = x;
                  var endY = y;
                  var vx = details.velocity.pixelsPerSecond.dx;
                  var vy = details.velocity.pixelsPerSecond.dy;
                  if (vx == 0 && vy == 0) {
                    endX = x;
                    endY = y;
                  } else if (vx == 0) {
                    endX = x;
                    endY = (vy > 0) ? size.height - HEAD_SIZE : 0;
                  } else if (vy == 0) {
                    endY = y;
                    endX = (vx > 0) ? size.width - HEAD_SIZE : 0;
                  } else {
                    double tx =
                        (((vx > 0) ? (size.width - HEAD_SIZE - x) : x) / vx)
                            .abs();
                    double ty =
                        (((vy > 0) ? (size.height - HEAD_SIZE - y) : y) / vy)
                            .abs();
                    if (tx > ty) {
                      endY = ((vy > 0) ? (size.height - HEAD_SIZE) : 0);
                      endX = x + vx * ty;
                    } else if (ty > tx) {
                      endX = (vx > 0) ? (size.width - HEAD_SIZE) : 0;
                      endY = y + vy * tx;
                    } else {
                      endX = (vx > 0) ? (size.width - HEAD_SIZE) : 0;
                      endY = ((vy > 0) ? (size.height - HEAD_SIZE) : 0);
                    }
                  }
                  springX.setEndValue(endX);
                  springY.setEndValue(endY);
                  scaleX = 1;
                  scaleY = 1;
                },
                onPanUpdate: (details) {
                  setState(() {
                    springX.setCurrentValue(
                        initialX + details.globalPosition.dx - initialTouchX);
                    springY.setCurrentValue(
                        initialY + details.globalPosition.dy - initialTouchY);
                  });
                },
                child: SizedBox(
                  width: scaleY * HEAD_SIZE,
                  height: scaleY * HEAD_SIZE,
                  child: FloatingActionButton(
                    onPressed: null,
                    child: Icon(
                      Icons.home,
                    ),
                  ),
                ),
              )),
          if (chainData.isNotEmpty) ...buildChain(),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> buildChain() {
    List<Widget> ret = [];
    chainData.forEach((data) {
      ret.add(Positioned(
          left: data.x,
          top: data.y,
          child: SizedBox(
              width: data.scaleY * HEAD_SIZE,
              height: data.scaleY * HEAD_SIZE,
              child: data.child)));
    });
    return ret;
  }
}

class SpringConfigs {
  static SpringConfig NOT_DRAGGING =
      SpringConfig.fromOrigamiTensionAndFriction(40.0, 4.5); // (60.0, 7.5)
  static SpringConfig CAPTURING =
      SpringConfig.fromBouncinessAndSpeed(8.0, 40.0);
  static SpringConfig CLOSE_SCALE =
      SpringConfig.fromBouncinessAndSpeed(7.0, 25.0);
  static SpringConfig CLOSE_Y = SpringConfig.fromBouncinessAndSpeed(3.0, 3.0);
  static SpringConfig DRAGGING =
      SpringConfig.fromOrigamiTensionAndFriction(0.0, 5.0);
  static SpringConfig CONTENT_SCALE =
      SpringConfig.fromBouncinessAndSpeed(5.0, 40.0);
}
