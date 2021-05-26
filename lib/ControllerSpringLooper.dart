



import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:rebound_dart/SpringLooper.dart';

class AnimationSpringLooper extends SpringLooper {
  late final AnimationController controller;
  bool mStarted = false;
  int mLastTime = 0;

  AnimationSpringLooper(TickerProvider vsync) {
    controller = AnimationController(vsync: vsync, duration: Duration(seconds: 1));
    controller.addListener(() {
      print("controller Callback");
      if (!mStarted || mSpringSystem == null) {
        return;
      }
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      mSpringSystem!.loop((currentTime - mLastTime).toDouble());
      mLastTime = currentTime;
    });
  }

  void start() {
    if (mStarted) {
      return;
    }
    mStarted = true;
    mLastTime = DateTime.now().millisecondsSinceEpoch;
    controller.repeat();
  }

  void stop() {
    mStarted = false;
    controller.stop();
  }

  void dispose() {
    controller.stop();
    controller.dispose();
  }
}