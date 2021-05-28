//package com.facebook.rebound;

/**
 * Helper math util to convert tension &amp; friction values from the Origami design tool to values
 * that the spring system needs.
 */
class OrigamiValueConverter {

  static double tensionFromOrigamiValue(double oValue) {
    return oValue == 0 ? 0 : (oValue - 30.0) * 3.62 + 194.0;
  }

  static double origamiValueFromTension(double tension) {
    return tension == 0 ? 0 : (tension - 194.0) / 3.62 + 30.0;
  }

  static double frictionFromOrigamiValue(double oValue) {
    return oValue == 0 ? 0 : (oValue - 8.0) * 3.0 + 25.0;
  }

  static double origamiValueFromFriction(double friction) {
    return friction == 0 ? 0 : (friction - 25.0) / 3.0 + 8.0;
  }

}
