/*
 *  Copyright (c) 2013, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

// package com.facebook.rebound;

import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:rebound_dart/BaseSpringSystem.dart';
import 'package:rebound_dart/ControllerSpringLooper.dart';
import 'package:rebound_dart/SpringLooper.dart';
import 'package:rebound_dart/SteppingLooper.dart';
import 'package:rebound_dart/SynchronousLooper.dart';

/**
 * This is a wrapper for BaseSpringSystem that provides the convenience of automatically providing
 * the AndroidSpringLooper dependency in {@link SpringSystem#create}.
 */
class SpringSystem extends BaseSpringSystem {

  /**
   * Create a new SpringSystem providing the appropriate constructor parameters to work properly
   * in an Android environment.
   * @return the SpringSystem
   */
  static SpringSystem create(TickerProvider vsync) {
    return new SpringSystem(AnimationSpringLooper(vsync));
  }

  SpringSystem(SpringLooper springLooper): super(springLooper);

  void dispose() {
    mSpringLooper.dispose();
  }
}