import 'package:flutter/material.dart';
import 'package:rebound_dart/SimpleSpringListener.dart';
import 'package:rebound_dart/Spring.dart';
import 'package:rebound_dart/SpringConfig.dart';
import 'package:rebound_dart/SpringSystem.dart';
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
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
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SpringConfigs {
  static SpringConfig NOT_DRAGGING =
      SpringConfig.fromOrigamiTensionAndFriction(40.0, 5.5); // (60.0, 7.5)
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
