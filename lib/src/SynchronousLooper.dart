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

class SynchronousLooper extends SpringLooper {

  static final double SIXTY_FPS = 16.6667;
  double _mTimeStep = SIXTY_FPS;
  bool _mRunning = false;

  SynchronousLooper();

  double getTimeStep() {
    return _mTimeStep;
  }

  void setTimeStep(double timeStep) {
    _mTimeStep = timeStep;
  }

  @override
  void start() {
    _mRunning = true;
    while (!mSpringSystem!.getIsIdle()) {
      if (_mRunning == false) {
        break;
      }
      mSpringSystem!.loop(_mTimeStep);
    }
  }

  @override
  void stop() {
    _mRunning = false;
  }

  void dispose(){
  }
}

