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

  late final double mBouncyTension;
  late final double mBouncyFriction;
  late final double mSpeed;
  late final double mBounciness;


  BouncyConversion(double speed, double bounciness) {
    mSpeed = speed;
    mBounciness = bounciness;
    double b = normalize(bounciness / 1.7, 0, 20.0);
    b = project_normal(b, 0.0, 0.8);
    double s = normalize(speed / 1.7, 0, 20.0);
    mBouncyTension = project_normal(s, 0.5, 200);
    mBouncyFriction = quadratic_out_interpolation(b, b3_nobounce(mBouncyTension), 0.01);
  }

  double getSpeed() {
    return mSpeed;
  }

  double getBounciness() {
    return mBounciness;
  }

  double getBouncyTension() {
    return mBouncyTension;
  }

  double getBouncyFriction() {
    return mBouncyFriction;
  }

  double normalize(double value, double startValue, double endValue) {
    return (value - startValue) / (endValue - startValue);
  }

  double project_normal(double n, double start, double end) {
    return start + (n * (end - start));
  }

  double linear_interpolation(double t, double start, double end) {
    return t * end + (1.0 - t) * start;
  }

  double quadratic_out_interpolation(double t, double start, double end) {
    return linear_interpolation(2*t - t*t, start, end);
  }

  double b3_friction1(double x) {
    return (0.0007 * pow(x, 3)) - (0.031 * pow(x, 2)) + 0.64 * x + 1.28;
  }

  double b3_friction2(double x) {
    return (0.000044 * pow(x, 3)) - (0.006 * pow(x, 2)) + 0.36 * x + 2.0;
  }

  double b3_friction3(double x) {
    return (0.00000045 * pow(x, 3)) - (0.000332 * pow(x, 2)) + 0.1078 * x + 5.84;
  }

  double b3_nobounce(double tension) {
    double friction = 0;
    if (tension <= 18) {
      friction = b3_friction1(tension);
    } else if (tension > 18 && tension <= 44) {
      friction = b3_friction2(tension);
    } else if (tension > 44) {
      friction = b3_friction3(tension);
    } else {
      assert(false);
    }
    return friction;
  }

}
