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

class SynchronousLooper extends SpringLooper {

  static final double SIXTY_FPS = 16.6667;
  double mTimeStep = SIXTY_FPS;
  bool mRunning = false;

  SynchronousLooper();

  double getTimeStep() {
    return mTimeStep;
  }

  void setTimeStep(double timeStep) {
    mTimeStep = timeStep;
  }

  //@Override
  void start() {
    mRunning = true;
    while (!mSpringSystem!.getIsIdle()) {
      if (mRunning == false) {
        break;
      }
      mSpringSystem!.loop(mTimeStep);
    }
  }

  //@Override
  void stop() {
    mRunning = false;
  }

  void dispose(){
  }
}

