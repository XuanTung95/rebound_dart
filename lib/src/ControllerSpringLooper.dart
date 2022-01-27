


import 'package:flutter/scheduler.dart';
import 'package:rebound_dart/src/SpringLooper.dart';

class AnimationSpringLooper extends SpringLooper {
  late final Ticker _ticker;
  bool _mStarted = false;
  int _mLastTime = 0;

  AnimationSpringLooper(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    if (!_mStarted || mSpringSystem == null) {
      return;
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    mSpringSystem!.loop((now - _mLastTime).toDouble());
    _mLastTime = now;
  }
  void start() {
    if (_mStarted) {
      return;
    }
    _mStarted = true;
    _mLastTime = DateTime.now().millisecondsSinceEpoch;
    _ticker.start();
  }

  void stop() {
    _mStarted = false;
    _ticker.stop();
  }

  void dispose() {
    _ticker.stop();
    _ticker.dispose();
  }
}