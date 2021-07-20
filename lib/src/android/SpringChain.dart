/*
 *  Copyright (c) 2013, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

// package com.facebook.rebound;

// import java.util.List;
// import java.util.concurrent.CopyOnWriteArrayList;

import 'package:flutter/widgets.dart';

import '../Spring.dart';
import '../SpringConfig.dart';
import '../SpringConfigRegistry.dart';
import '../SpringListener.dart';
import '../SpringSystem.dart';

/**
 * SpringChain is a helper class for creating spring animations with multiple springs in a chain.
 * Chains of springs can be used to create cascading animations that maintain individual physics
 * state for each member of the chain. One spring in the chain is chosen to be the control spring.
 * Springs before and after the control spring in the chain are pulled along by their predecessor.
 * You can change which spring is the control spring at any point by calling
 * {@link SpringChain#setControlSpringIndex(int)}.
 */
class SpringChain implements SpringListener {

  /**
   * Add these spring configs to the registry to support live tuning through the
   * {@link com.facebook.rebound.ui.SpringConfiguratorView}
   */
  static final SpringConfigRegistry registry = SpringConfigRegistry.getInstance();
  static const double _DEFAULT_MAIN_TENSION = 40;
  static const double _DEFAULT_MAIN_FRICTION = 6;
  static const double _DEFAULT_ATTACHMENT_TENSION = 70;
  static const double _DEFAULT_ATTACHMENT_FRICTION = 10;
  static int _id = 0;


  /**
   * Factory method for creating a new SpringChain with default SpringConfig.
   * @return the newly created SpringChain
   */
  /*static SpringChain create() {
    return new SpringChain();
  }*/

  /**
   * Factory method for creating a new SpringChain with the provided SpringConfig.
   * @param mainTension tension for the main spring
   * @param mainFriction friction for the main spring
   * @param attachmentTension tension for the attachment spring
   * @param attachmentFriction friction for the attachment spring
   * @return the newly created SpringChain
   */
  static SpringChain create(TickerProvider vsync,
      {   double mainTension = _DEFAULT_MAIN_TENSION,
          double mainFriction = _DEFAULT_MAIN_FRICTION,
          double attachmentTension = _DEFAULT_ATTACHMENT_TENSION,
          double attachmentFriction = _DEFAULT_ATTACHMENT_FRICTION}) {
    return new SpringChain(vsync, mainTension: mainTension, mainFriction: mainFriction, attachmentTension: attachmentTension, attachmentFriction: attachmentFriction);
  }

  late final SpringSystem _mSpringSystem;
  final List<SpringListener> _mListeners = []; // CopyOnWriteArrayList
  final List<Spring> _mSprings = []; // CopyOnWriteArrayList
  int _mControlSpringIndex = -1;

  // The main spring config defines the tension and friction for the control spring. Keeping these
  // values separate allows the behavior of the trailing springs to be different than that of the
  // control point.
  late final SpringConfig _mMainSpringConfig;

  // The attachment spring config defines the tension and friction for the rest of the springs in
  // the chain.
  late final SpringConfig _mAttachmentSpringConfig;

  /*SpringChain() {
    this(
        DEFAULT_MAIN_TENSION,
        DEFAULT_MAIN_FRICTION,
        DEFAULT_ATTACHMENT_TENSION,
        DEFAULT_ATTACHMENT_FRICTION);
  }*/

  SpringChain(TickerProvider vsync,
  {
      double mainTension = _DEFAULT_MAIN_TENSION,
      double mainFriction = _DEFAULT_MAIN_FRICTION,
      double attachmentTension = _DEFAULT_ATTACHMENT_TENSION,
      double attachmentFriction = _DEFAULT_ATTACHMENT_FRICTION}) {
    _mSpringSystem = SpringSystem.create(vsync);
    _mMainSpringConfig = SpringConfig.fromOrigamiTensionAndFriction(mainTension, mainFriction);
    _mAttachmentSpringConfig =
        SpringConfig.fromOrigamiTensionAndFriction(attachmentTension, attachmentFriction);
    registry.addSpringConfig(_mMainSpringConfig, "main spring ${_id++}");
    registry.addSpringConfig(_mAttachmentSpringConfig, "attachment spring ${_id++}");
  }

  void dispose() {
    _mSprings.forEach((spring) {
      spring.destroy();
    });
    _mSprings.clear();
    _mListeners.clear();
    _mSpringSystem.dispose();
  }

  SpringConfig getMainSpringConfig() {
    return _mMainSpringConfig;
  }

  SpringConfig getAttachmentSpringConfig() {
    return _mAttachmentSpringConfig;
  }

  /**
   * Add a spring to the chain that will callback to the provided listener.
   * @param listener the listener to notify for this Spring in the chain
   * @return this SpringChain for chaining
   */
  SpringChain addSpring(final SpringListener listener) {
    // We listen to each spring added to the SpringChain and dynamically chain the springs together
    // whenever the control spring state is modified.
    Spring spring = _mSpringSystem
        .createSpring()
        .addListener(this)
        .setSpringConfig(_mAttachmentSpringConfig);
    _mSprings.add(spring);
    _mListeners.add(listener);
    return this;
  }

  /**
   * Set the index of the control spring. This spring will drive the positions of all the springs
   * before and after it in the list when moved.
   * @param i the index to use for the control spring
   * @return this SpringChain
   */
  SpringChain setControlSpringIndex(int i) {
    if (i < 0 || i >= _mSprings.length) {
      return this;
    }
    _mControlSpringIndex = i;
    /*Spring controlSpring = mSprings.get(mControlSpringIndex);
    if (controlSpring == null) {
      return null;
    }*/
    for (Spring spring in _mSpringSystem.getAllSprings()) {
      spring.setSpringConfig(_mAttachmentSpringConfig);
    }
    getControlSpring().setSpringConfig(_mMainSpringConfig);
    return this;
  }

  /**
   * Retrieve the control spring so you can manipulate it to drive the positions of the other
   * springs.
   * @return the control spring.
   */
  Spring getControlSpring() {
    return _mSprings[_mControlSpringIndex];
  }

  /**
   * Retrieve the list of springs in the chain.
   * @return the list of springs
   */
  List<Spring> getAllSprings() {
    return _mSprings;
  }

  @override
  void onSpringUpdate(Spring spring) {
    // Get the control spring index and update the endValue of each spring above and below it in the
    // spring collection triggering a cascading effect.
    int idx = _mSprings.indexOf(spring);
    if (idx < 0) return;
    SpringListener listener = _mListeners[idx];
    int above = -1;
    int below = -1;
    if (idx == _mControlSpringIndex) {
      below = idx - 1;
      above = idx + 1;
    } else if (idx < _mControlSpringIndex) {
      below = idx - 1;
    } else if (idx > _mControlSpringIndex) {
      above = idx + 1;
    }
    if (above > -1 && above < _mSprings.length) {
      _mSprings[above].setEndValue(spring.getCurrentValue());
    }
    if (below > -1 && below < _mSprings.length) {
      _mSprings[below].setEndValue(spring.getCurrentValue());
    }
    listener.onSpringUpdate(spring);
  }

  @override
  void onSpringAtRest(Spring spring) {
    int idx = _mSprings.indexOf(spring);
    _mListeners[idx].onSpringAtRest(spring);
  }

  @override
  void onSpringActivate(Spring spring) {
    int idx = _mSprings.indexOf(spring);
    _mListeners[idx].onSpringActivate(spring);
  }

  @override
  void onSpringEndStateChange(Spring spring) {
    int idx = _mSprings.indexOf(spring);
    _mListeners[idx].onSpringEndStateChange(spring);
  }
}
