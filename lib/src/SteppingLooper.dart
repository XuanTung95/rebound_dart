/**
 *  Copyright (c) 2013, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

// package com.facebook.rebound;

import 'package:rebound_dart/src/SpringLooper.dart';

class SteppingLooper extends SpringLooper {

  bool _mStarted = false;
  int _mLastTime = 0;

  @override
  void start() {
    _mStarted = true;
    _mLastTime = 0;
  }

  bool step(int interval) {
    if (mSpringSystem == null || !_mStarted) {
      return false;
    }
    int currentTime = _mLastTime + interval;
    mSpringSystem!.loop(currentTime.toDouble());
    _mLastTime = currentTime;
    return mSpringSystem!.getIsIdle();
  }

  @override
  void stop() {
    _mStarted = false;
  }

  void dispose(){
  }
}

