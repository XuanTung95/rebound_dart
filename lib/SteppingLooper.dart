/**
 *  Copyright (c) 2013, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

// package com.facebook.rebound;

import 'package:rebound_dart/SpringLooper.dart';

class SteppingLooper extends SpringLooper {

  bool mStarted = false;
  int mLastTime = 0;

  // @Override
  void start() {
    mStarted = true;
    mLastTime = 0;
  }

  bool step(int interval) {
    if (mSpringSystem == null || !mStarted) {
      return false;
    }
    int currentTime = mLastTime + interval;
    mSpringSystem!.loop(currentTime.toDouble());
    mLastTime = currentTime;
    return mSpringSystem!.getIsIdle();
  }

  // @Override
  void stop() {
    mStarted = false;
  }

  void dispose(){

  }
}

