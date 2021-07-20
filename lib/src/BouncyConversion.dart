/*
 *  Copyright (c) 2013, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

//package com.facebook.rebound;
import 'dart:math';

/**
 * This class converts values from the Quartz Composer Bouncy patch into Bouncy QC tension and
 * friction values.
 */
class BouncyConversion {

  late final double _mBouncyTension;
  late final double _mBouncyFriction;
  late final double _mSpeed;
  late final double _mBounciness;


  BouncyConversion(double speed, double bounciness) {
    _mSpeed = speed;
    _mBounciness = bounciness;
    double b = _normalize(bounciness / 1.7, 0, 20.0);
    b = _project_normal(b, 0.0, 0.8);
    double s = _normalize(speed / 1.7, 0, 20.0);
    _mBouncyTension = _project_normal(s, 0.5, 200);
    _mBouncyFriction = _quadratic_out_interpolation(b, _b3_nobounce(_mBouncyTension), 0.01);
  }

  double getSpeed() {
    return _mSpeed;
  }

  double getBounciness() {
    return _mBounciness;
  }

  double getBouncyTension() {
    return _mBouncyTension;
  }

  double getBouncyFriction() {
    return _mBouncyFriction;
  }

  double _normalize(double value, double startValue, double endValue) {
    return (value - startValue) / (endValue - startValue);
  }

  double _project_normal(double n, double start, double end) {
    return start + (n * (end - start));
  }

  double _linear_interpolation(double t, double start, double end) {
    return t * end + (1.0 - t) * start;
  }

  double _quadratic_out_interpolation(double t, double start, double end) {
    return _linear_interpolation(2*t - t*t, start, end);
  }

  double _b3_friction1(double x) {
    return (0.0007 * pow(x, 3)) - (0.031 * pow(x, 2)) + 0.64 * x + 1.28;
  }

  double _b3_friction2(double x) {
    return (0.000044 * pow(x, 3)) - (0.006 * pow(x, 2)) + 0.36 * x + 2.0;
  }

  double _b3_friction3(double x) {
    return (0.00000045 * pow(x, 3)) - (0.000332 * pow(x, 2)) + 0.1078 * x + 5.84;
  }

  double _b3_nobounce(double tension) {
    double friction = 0;
    if (tension <= 18) {
      friction = _b3_friction1(tension);
    } else if (tension > 18 && tension <= 44) {
      friction = _b3_friction2(tension);
    } else if (tension > 44) {
      friction = _b3_friction3(tension);
    } else {
      assert(false);
    }
    return friction;
  }

}
