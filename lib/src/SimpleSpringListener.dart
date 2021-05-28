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

import 'package:rebound_dart/src/Spring.dart';
import 'package:rebound_dart/src/SpringListener.dart';

class SimpleSpringListener implements SpringListener {
  final Function(Spring spring)? updateCallback;
  final Function(Spring spring)? atRestCallback;
  final Function(Spring spring)? activateCallback;
  final Function(Spring spring)? endStateChangeCallback;

  SimpleSpringListener({this.updateCallback, this.atRestCallback, this.activateCallback, this.endStateChangeCallback});


  // @Override
  void onSpringUpdate(Spring spring) {
    updateCallback?.call(spring);
  }

  //@Override
  void onSpringAtRest(Spring spring) {
    atRestCallback?.call(spring);
  }

  //@Override
  void onSpringActivate(Spring spring) {
    activateCallback?.call(spring);
  }

  //@Override
  void onSpringEndStateChange(Spring spring) {
    endStateChangeCallback?.call(spring);
  }
}
