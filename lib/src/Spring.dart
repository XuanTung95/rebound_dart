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

//import java.util.concurrent.CopyOnWriteArraySet;

import 'dart:core';

import 'package:rebound_dart/src/BaseSpringSystem.dart';
import 'package:rebound_dart/src/SpringConfig.dart';

import 'package:rebound_dart/src/SpringListener.dart';

/**
 * Classical spring implementing Hooke's law with configurable friction and tension.
 */
class Spring {

  // unique incrementer id for springs
  static int _ID = 0;

  // maximum amount of time to simulate per physics iteration in seconds (4 frames at 60 FPS)
  static final double _MAX_DELTA_TIME_SEC = 0.064;
  // fixed timestep to use in the physics solver in seconds
  static final double _SOLVER_TIMESTEP_SEC = 0.001;
  late SpringConfig _mSpringConfig;
  bool _mOvershootClampingEnabled = false;

  // storage for the current and prior physics state while integration is occurring

  // unique id for the spring in the system
  late final String _mId;
  // all physics simulation objects are final and reused in each processing pass
  final _PhysicsState _mCurrentState = new _PhysicsState();
  final _PhysicsState _mPreviousState = new _PhysicsState();
  final _PhysicsState _mTempState = new _PhysicsState();
  double _mStartValue = 0;
  double _mEndValue = 0;
  bool _mWasAtRest = true;
  // thresholds for determining when the spring is at rest
  double _mRestSpeedThreshold = 0.005;
  double _mDisplacementFromRestThreshold = 0.005;
  double _mTimeAccumulator = 0;
  /*final CopyOnWriteArraySet<SpringListener> mListeners =
    new CopyOnWriteArraySet<SpringListener>();*/
  final Set<SpringListener> _mListeners = Set();

  late final BaseSpringSystem _mSpringSystem;

  /**
   * create a new spring
   */
  Spring(BaseSpringSystem springSystem) {
    _mSpringSystem = springSystem;
    _mId = "spring:${_ID++}";
    setSpringConfig(SpringConfig.defaultConfig);
  }

  /**
   * Destroys this Spring, meaning that it will be deregistered from its BaseSpringSystem so it won't be
   * iterated anymore and will clear its set of listeners. Do not use the Spring after calling this,
   * doing so may just cause an exception to be thrown.
   */
  void destroy() {
    _mListeners.clear();
    _mSpringSystem.deregisterSpring(this);
  }

  /**
   * get the unique id for this spring
   * @return the unique id
   */
  String getId() {
    return _mId;
  }

  /**
   * set the config class
   * @param springConfig config class for the spring
   * @return this Spring instance for chaining
   */
  Spring setSpringConfig(SpringConfig springConfig) {
    _mSpringConfig = springConfig;
    return this;
  }

  /**
   * retrieve the spring config for this spring
   * @return the SpringConfig applied to this spring
   */
  SpringConfig getSpringConfig() {
    return _mSpringConfig;
  }

  /**
   * Set the displaced value to determine the displacement for the spring from the rest value.
   * This value is retained and used to calculate the displacement ratio.
   * The default signature also sets the Spring at rest to facilitate the common behavior of moving
   * a spring to a new position.
   * @param currentValue the new start and current value for the spring
   * @return the spring for chaining
   */
  /*Spring setCurrentValue(double currentValue) {
    return setCurrentValue(currentValue, setAtRest: true);
  }*/

  /**
   * The full signature for setCurrentValue includes the option of not setting the spring at rest
   * after updating its currentValue. Passing setAtRest false means that if the endValue of the
   * spring is not equal to the currentValue, the physics system will start iterating to resolve
   * the spring to the end value. This is almost never the behavior that you want, so the default
   * setCurrentValue signature passes true.
   * @param currentValue the new start and current value for the spring
   * @param setAtRest optionally set the spring at rest after updating its current value.
   *                  see {@link com.facebook.rebound.Spring#setAtRest()}
   * @return the spring for chaining
   */
  Spring setCurrentValue(double currentValue, {bool setAtRest = true}) {
    _mStartValue = currentValue;
    _mCurrentState.position = currentValue;
    _mSpringSystem.activateSpring(this.getId());
    for (SpringListener listener in _mListeners) {
      listener.onSpringUpdate(this);
    }
    if (setAtRest) {
      this.setAtRest();
    }
    return this;
  }

  /**
   * Get the displacement value from the last time setCurrentValue was called.
   * @return displacement value
   */
  double getStartValue() {
    return _mStartValue;
  }

  /**
   * Get the current
   * @return current value
   */
  double getCurrentValue() {
    return _mCurrentState.position;
  }

  /**
   * get the displacement of the springs current value from its rest value.
   * @return the distance displaced by
   */
  double getCurrentDisplacementDistance() {
    return getDisplacementDistanceForState(_mCurrentState);
  }

  /**
   * get the displacement from rest for a given physics state
   * @param state the state to measure from
   * @return the distance displaced by
   */
  double getDisplacementDistanceForState(_PhysicsState state) {
    return (_mEndValue - state.position).abs();
  }

  /**
   * set the rest value to determine the displacement for the spring
   * @param endValue the endValue for the spring
   * @return the spring for chaining
   */
  Spring setEndValue(double endValue) {
    if (_mEndValue == endValue && isAtRest()) {
      return this;
    }
    _mStartValue = getCurrentValue();
    _mEndValue = endValue;
    _mSpringSystem.activateSpring(this.getId());
    for (SpringListener listener in _mListeners) {
      listener.onSpringEndStateChange(this);
    }
    return this;
  }

  /**
   * get the rest value used for determining the displacement of the spring
   * @return the rest value for the spring
   */
  double getEndValue() {
    return _mEndValue;
  }

  /**
   * set the velocity on the spring in pixels per second
   * @param velocity velocity value
   * @return the spring for chaining
   */
  Spring setVelocity(double velocity) {
    if (velocity == _mCurrentState.velocity) {
      return this;
    }
    _mCurrentState.velocity = velocity;
    _mSpringSystem.activateSpring(this.getId());
    return this;
  }

  /**
   * get the velocity of the spring
   * @return the current velocity
   */
  double getVelocity() {
    return _mCurrentState.velocity;
  }

  /**
   * Sets the speed at which the spring should be considered at rest.
   * @param restSpeedThreshold speed pixels per second
   * @return the spring for chaining
   */
  Spring setRestSpeedThreshold(double restSpeedThreshold) {
    _mRestSpeedThreshold = restSpeedThreshold;
    return this;
  }

  /**
   * Returns the speed at which the spring should be considered at rest in pixels per second
   * @return speed in pixels per second
   */
  double getRestSpeedThreshold() {
    return _mRestSpeedThreshold;
  }

  /**
   * set the threshold of displacement from rest below which the spring should be considered at rest
   * @param displacementFromRestThreshold displacement to consider resting below
   * @return the spring for chaining
   */
  Spring setRestDisplacementThreshold(double displacementFromRestThreshold) {
    _mDisplacementFromRestThreshold = displacementFromRestThreshold;
    return this;
  }

  /**
   * get the threshold of displacement from rest below which the spring should be considered at rest
   * @return displacement to consider resting below
   */
  double getRestDisplacementThreshold() {
    return _mDisplacementFromRestThreshold;
  }

  /**
   * Force the spring to clamp at its end value to avoid overshooting the target value.
   * @param overshootClampingEnabled whether or not to enable overshoot clamping
   * @return the spring for chaining
   */
  Spring setOvershootClampingEnabled(bool overshootClampingEnabled) {
    _mOvershootClampingEnabled = overshootClampingEnabled;
    return this;
  }

  /**
   * Check if overshoot clamping is enabled.
   * @return is overshoot clamping enabled
   */
  bool isOvershootClampingEnabled() {
    return _mOvershootClampingEnabled;
  }

  /**
   * Check if the spring is overshooting beyond its target.
   * @return true if the spring is overshooting its target
   */
  bool isOvershooting() {
    return _mSpringConfig.tension > 0 &&
           ((_mStartValue < _mEndValue && getCurrentValue() > _mEndValue) ||
           (_mStartValue > _mEndValue && getCurrentValue() < _mEndValue));
  }

  /**
   * advance the physics simulation in SOLVER_TIMESTEP_SEC sized chunks to fulfill the required
   * realTimeDelta.
   * The math is inlined inside the loop since it made a huge performance impact when there are
   * several springs being advanced.
   * @param realDeltaTime clock drift
   */
  void advance(double realDeltaTime) {

    bool isAtRest = this.isAtRest();

    if (isAtRest && _mWasAtRest) {
      /* begin debug
      Log.d(TAG, "bailing out because we are at rest:" + getName());
      end debug */
      return;
    }

    // clamp the amount of realTime to simulate to avoid stuttering in the UI. We should be able
    // to catch up in a subsequent advance if necessary.
    double adjustedDeltaTime = realDeltaTime;
    if (realDeltaTime > _MAX_DELTA_TIME_SEC) {
      adjustedDeltaTime = _MAX_DELTA_TIME_SEC;
    }

    /* begin debug
    long startTime = System.currentTimeMillis();
    int iterations = 0;
    end debug */

    _mTimeAccumulator += adjustedDeltaTime;

    double tension = _mSpringConfig.tension;
    double friction = _mSpringConfig.friction;

    double position = _mCurrentState.position;
    double velocity = _mCurrentState.velocity;
    double tempPosition = _mTempState.position;
    double tempVelocity = _mTempState.velocity;

    double aVelocity, aAcceleration;
    double bVelocity, bAcceleration;
    double cVelocity, cAcceleration;
    double dVelocity, dAcceleration;

    double dxdt, dvdt;

    // iterate over the true time
    while (_mTimeAccumulator >= _SOLVER_TIMESTEP_SEC) {
      /* begin debug
      iterations++;
      end debug */
      _mTimeAccumulator -= _SOLVER_TIMESTEP_SEC;

      if (_mTimeAccumulator < _SOLVER_TIMESTEP_SEC) {
        // This will be the last iteration. Remember the previous state in case we need to
        // interpolate
        _mPreviousState.position = position;
        _mPreviousState.velocity = velocity;
      }

      // Perform an RK4 integration to provide better detection of the acceleration curve via
      // sampling of Euler integrations at 4 intervals feeding each derivative into the calculation
      // of the next and taking a weighted sum of the 4 derivatives as the final output.

      // This math was inlined since it made for big performance improvements when advancing several
      // springs in one pass of the BaseSpringSystem.

      // The initial derivative is based on the current velocity and the calculated acceleration
      aVelocity = velocity;
      aAcceleration = (tension * (_mEndValue - tempPosition)) - friction * velocity;

      // Calculate the next derivatives starting with the last derivative and integrating over the
      // timestep
      tempPosition = position + aVelocity * _SOLVER_TIMESTEP_SEC * 0.5;
      tempVelocity = velocity + aAcceleration * _SOLVER_TIMESTEP_SEC * 0.5;
      bVelocity = tempVelocity;
      bAcceleration = (tension * (_mEndValue - tempPosition)) - friction * tempVelocity;

      tempPosition = position + bVelocity * _SOLVER_TIMESTEP_SEC * 0.5;
      tempVelocity = velocity + bAcceleration * _SOLVER_TIMESTEP_SEC * 0.5;
      cVelocity = tempVelocity;
      cAcceleration = (tension * (_mEndValue - tempPosition)) - friction * tempVelocity;

      tempPosition = position + cVelocity * _SOLVER_TIMESTEP_SEC;
      tempVelocity = velocity + cAcceleration * _SOLVER_TIMESTEP_SEC;
      dVelocity = tempVelocity;
      dAcceleration = (tension * (_mEndValue - tempPosition)) - friction * tempVelocity;

      // Take the weighted sum of the 4 derivatives as the final output.
      dxdt = 1.0/6.0 * (aVelocity + 2.0 * (bVelocity + cVelocity) + dVelocity);
      dvdt = 1.0/6.0 * (aAcceleration + 2.0 * (bAcceleration + cAcceleration) + dAcceleration);

      position += dxdt * _SOLVER_TIMESTEP_SEC;
      velocity += dvdt * _SOLVER_TIMESTEP_SEC;
    }

    _mTempState.position = tempPosition;
    _mTempState.velocity = tempVelocity;

    _mCurrentState.position = position;
    _mCurrentState.velocity = velocity;

    if (_mTimeAccumulator > 0) {
      interpolate(_mTimeAccumulator / _SOLVER_TIMESTEP_SEC);
    }

    // End the spring immediately if it is overshooting and overshoot clamping is enabled.
    // Also make sure that if the spring was considered within a resting threshold that it's now
    // snapped to its end value.
    if (this.isAtRest() || (_mOvershootClampingEnabled && isOvershooting())) {
      // Don't call setCurrentValue because that forces a call to onSpringUpdate
      if (tension > 0) {
        _mStartValue = _mEndValue;
        _mCurrentState.position = _mEndValue;
      } else {
        _mEndValue = _mCurrentState.position;
        _mStartValue = _mEndValue;
      }
      setVelocity(0);
      isAtRest = true;
    }

    /* begin debug
    long endTime = System.currentTimeMillis();
    long elapsedMillis = endTime - startTime;
    Log.d(TAG,
        "iterations:" + iterations +
            " iterationTime:" + elapsedMillis +
            " position:" + mCurrentState.position +
            " velocity:" + mCurrentState.velocity +
            " realDeltaTime:" + realDeltaTime +
            " adjustedDeltaTime:" + adjustedDeltaTime +
            " isAtRest:" + isAtRest +
            " wasAtRest:" + mWasAtRest);
    end debug */

    // NB: do these checks outside the loop so all listeners are properly notified of the state
    //     transition
    bool notifyActivate = false;
    if (_mWasAtRest) {
      _mWasAtRest = false;
      notifyActivate = true;
    }
    bool notifyAtRest = false;
    if (isAtRest) {
      _mWasAtRest = true;
      notifyAtRest = true;
    }
    for (SpringListener listener in _mListeners) {
      // starting to move
      if (notifyActivate) {
        listener.onSpringActivate(this);
      }

      // updated
      listener.onSpringUpdate(this);

      // coming to rest
      if (notifyAtRest) {
        listener.onSpringAtRest(this);
      }
    }
  }

  /**
   * Check if this spring should be advanced by the system.  * The rule is if the spring is
   * currently at rest and it was at rest in the previous advance, the system can skip this spring
   * @return should the system process this spring
   */
  bool systemShouldAdvance() {
    return !isAtRest() || !wasAtRest();
  }

  /**
   * Check if the spring was at rest in the prior iteration. This is used for ensuring the ending
   * callbacks are fired as the spring comes to a rest.
   * @return true if the spring was at rest in the prior iteration
   */
  bool wasAtRest() {
    return _mWasAtRest;
  }

  /**
   * check if the current state is at rest
   * @return is the spring at rest
   */
  bool isAtRest() {
    return (_mCurrentState.velocity).abs() <= _mRestSpeedThreshold &&
        (getDisplacementDistanceForState(_mCurrentState) <= _mDisplacementFromRestThreshold ||
         _mSpringConfig.tension == 0);
  }

  /**
   * Set the spring to be at rest by making its end value equal to its current value and setting
   * velocity to 0.
   * @return this object
   */
  Spring setAtRest() {
    _mEndValue = _mCurrentState.position;
    _mTempState.position = _mCurrentState.position;
    _mCurrentState.velocity = 0;
    return this;
  }

  /**
   * linear interpolation between the previous and current physics state based on the amount of
   * timestep remaining after processing the rendering delta time in timestep sized chunks.
   * @param alpha from 0 to 1, where 0 is the previous state, 1 is the current state
   */
  void interpolate(double alpha) {
    _mCurrentState.position = _mCurrentState.position * alpha + _mPreviousState.position *(1-alpha);
    _mCurrentState.velocity = _mCurrentState.velocity * alpha + _mPreviousState.velocity *(1-alpha);
  }

  /** listeners **/

  /**
   * add a listener
   * @param newListener to add
   * @return the spring for chaining
   */
  Spring addListener(SpringListener newListener) {
    _mListeners.add(newListener);
    return this;
  }

  /**
   * remove a listener
   * @param listenerToRemove to remove
   * @return the spring for chaining
   */
  Spring removeListener(SpringListener listenerToRemove) {
    _mListeners.remove(listenerToRemove);
    return this;
  }

  /**
   * remove all of the listeners
   * @return the spring for chaining
   */
  Spring removeAllListeners() {
    _mListeners.clear();
    return this;
  }

  /**
   * This method checks to see that the current spring displacement value is equal to the input,
   * accounting for the spring's rest displacement threshold.
   * @param value The value to compare the spring value to
   * @return Whether the displacement value from the spring is within the bounds of the compare
   * value, accounting for threshold
   */
  bool currentValueIsApproximately(double value) {
    return (getCurrentValue() - value).abs() <= getRestDisplacementThreshold();
  }

}

class _PhysicsState {
  double position = 0;
  double velocity = 0;
}