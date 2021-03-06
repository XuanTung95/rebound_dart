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

//import java.util.concurrent.CopyOnWriteArraySet;

import 'package:rebound_dart/src/Spring.dart';
import 'package:rebound_dart/src/SpringLooper.dart';
import 'package:rebound_dart/src/SpringSystemListener.dart';

/**
 * BaseSpringSystem maintains the set of springs within an Application context. It is responsible for
 * Running the spring integration loop and maintains a registry of all the Springs it solves for.
 * In addition to listening to physics events on the individual Springs in the system, listeners
 * can be added to the BaseSpringSystem itself to provide pre and post integration setup.
 */
class BaseSpringSystem {

  final Map<String, Spring> _mSpringRegistry = new Map<String, Spring>();
  final Set<Spring> _mActiveSprings = Set(); //new CopyOnWriteArraySet<Spring>();
  late final SpringLooper mSpringLooper;
  final Set<SpringSystemListener> _mListeners = Set(); //new CopyOnWriteArraySet<SpringSystemListener>();
  bool _mIdle = true;

  /**
   * create a new BaseSpringSystem
   * @param springLooper parameterized springLooper to allow testability of the
   *        physics loop
   */
  BaseSpringSystem(SpringLooper springLooper) {
    mSpringLooper = springLooper;
    mSpringLooper.setSpringSystem(this);
  }

  /**
   * check if the system is idle
   * @return is the system idle
   */
  bool getIsIdle() {
    return _mIdle;
  }

  /**
   * create a spring with a random uuid for its name.
   * @return the spring
   */
  Spring createSpring() {
    Spring spring = new Spring(this);
    registerSpring(spring);
    return spring;
  }

  /**
   * get a spring by name
   * @param id id of the spring to retrieve
   * @return Spring with the specified key
   */
  Spring? getSpringById(String id) {
    return _mSpringRegistry[id];
  }

  /**
   * return all the springs in the simulator
   * @return all the springs
   */
  List<Spring> getAllSprings() {
    return _mSpringRegistry.values.toList();
    /*if (collection instanceof List) {
      list = (List<Spring>)collection;
    } else {
      list = new ArrayList<Spring>(collection);
    }
    return Collections.unmodifiableList(list);*/
  }

  /**
   * Registers a Spring to this BaseSpringSystem so it can be iterated if active.
   * @param spring the Spring to register
   */
  void registerSpring(Spring spring) {
    if (_mSpringRegistry.containsKey(spring.getId())) {
      throw new Exception("spring is already registered");
    }
    _mSpringRegistry[spring.getId()] = spring;
  }

  /**
   * Deregisters a Spring from this BaseSpringSystem, so it won't be iterated anymore. The Spring should
   * not be used anymore after doing this.
   *
   * @param spring the Spring to deregister
   */
  void deregisterSpring(Spring spring) {
    _mActiveSprings.remove(spring);
    _mSpringRegistry.remove(spring.getId());
  }

  /**
   * update the springs in the system
   * @param deltaTime delta since last update in millis
   */
  void advance(double deltaTime) {
    /*
    for (Spring spring : mActiveSprings) {
      // advance time in seconds
      if (spring.systemShouldAdvance()) {
        spring.advance(deltaTime / 1000.0);
      } else {
        mActiveSprings.remove(spring);
      }
    }
    */
    if (_mActiveSprings.isEmpty) return;
    var copyList = _mActiveSprings.toList(growable: false);
    for (Spring spring in copyList) {
      if (spring.systemShouldAdvance()) {
        spring.advance(deltaTime / 1000.0);
      } else {
        _mActiveSprings.remove(spring);
      }
    }
  }

  /**
   * loop the system until idle
   * @param elapsedMillis elapsed milliseconds
   */
  void loop(double elapsedMillis) {
    for (SpringSystemListener listener in _mListeners) {
      listener.onBeforeIntegrate(this);
    }
    advance(elapsedMillis);
    if (_mActiveSprings.isEmpty) {
      _mIdle = true;
    }
    for (SpringSystemListener listener in _mListeners) {
      listener.onAfterIntegrate(this);
    }
    if (_mIdle) {
      mSpringLooper.stop();
    }
  }

  /**
   * This is used internally by the {@link Spring}s created by this {@link BaseSpringSystem} to notify
   * it has reached a state where it needs to be iterated. This will add the spring to the list of
   * active springs on this system and start the iteration if the system was idle before this call.
   * @param springId the id of the Spring to be activated
   */
  void activateSpring(String springId) {
    Spring? spring = _mSpringRegistry[springId];
    if (spring == null) {
      throw new Exception("springId " + springId + " does not reference a registered spring");
    }
    _mActiveSprings.add(spring);
    if (getIsIdle()) {
      _mIdle = false;
      mSpringLooper.start();
    }
  }

  /** listeners **/

  /**
   * Add new listener object.
   * @param newListener listener
   */
  void addListener(SpringSystemListener newListener) {
    _mListeners.add(newListener);
  }

  /**
   * Remove listener object.
   * @param listenerToRemove listener
   */
  void removeListener(SpringSystemListener listenerToRemove) {
    _mListeners.remove(listenerToRemove);
  }

  /**
   * Remove all listeners.
   */
  void removeAllListeners() {
    _mListeners.clear();
  }
}


