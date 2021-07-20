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
  // static final SpringConfigRegistry registry = SpringConfigRegistry.getInstance();
  static const double DEFAULT_MAIN_TENSION = 40;
  static const double DEFAULT_MAIN_FRICTION = 6;
  static const double DEFAULT_ATTACHMENT_TENSION = 70;
  static const double DEFAULT_ATTACHMENT_FRICTION = 10;
  static int id = 0;


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
      {   double mainTension = DEFAULT_MAIN_TENSION,
          double mainFriction = DEFAULT_MAIN_FRICTION,
          double attachmentTension = DEFAULT_ATTACHMENT_TENSION,
          double attachmentFriction = DEFAULT_ATTACHMENT_FRICTION}) {
    return new SpringChain(vsync, mainTension: mainTension, mainFriction: mainFriction, attachmentTension: attachmentTension, attachmentFriction: attachmentFriction);
  }

  late final SpringSystem mSpringSystem;
  final List<SpringListener> mListeners = []; // CopyOnWriteArrayList
  final List<Spring> mSprings = []; // CopyOnWriteArrayList
  int mControlSpringIndex = -1;

  // The main spring config defines the tension and friction for the control spring. Keeping these
  // values separate allows the behavior of the trailing springs to be different than that of the
  // control point.
  late final SpringConfig mMainSpringConfig;

  // The attachment spring config defines the tension and friction for the rest of the springs in
  // the chain.
  late final SpringConfig mAttachmentSpringConfig;

  /*SpringChain() {
    this(
        DEFAULT_MAIN_TENSION,
        DEFAULT_MAIN_FRICTION,
        DEFAULT_ATTACHMENT_TENSION,
        DEFAULT_ATTACHMENT_FRICTION);
  }*/

  SpringChain(TickerProvider vsync,
  {
      double mainTension = DEFAULT_MAIN_TENSION,
      double mainFriction = DEFAULT_MAIN_FRICTION,
      double attachmentTension = DEFAULT_ATTACHMENT_TENSION,
      double attachmentFriction = DEFAULT_ATTACHMENT_FRICTION}) {
    mSpringSystem = SpringSystem.create(vsync);
    mMainSpringConfig = SpringConfig.fromOrigamiTensionAndFriction(mainTension, mainFriction);
    mAttachmentSpringConfig =
        SpringConfig.fromOrigamiTensionAndFriction(attachmentTension, attachmentFriction);
    // registry.addSpringConfig(mMainSpringConfig, "main spring ${id++}");
    // registry.addSpringConfig(mAttachmentSpringConfig, "attachment spring ${id++}");
  }

  void dispose() {
    mSprings.forEach((spring) {
      spring.destroy();
    });
    mSprings.clear();
    mListeners.clear();
    mSpringSystem.dispose();
  }

  SpringConfig getMainSpringConfig() {
    return mMainSpringConfig;
  }

  SpringConfig getAttachmentSpringConfig() {
    return mAttachmentSpringConfig;
  }

  /**
   * Add a spring to the chain that will callback to the provided listener.
   * @param listener the listener to notify for this Spring in the chain
   * @return this SpringChain for chaining
   */
  SpringChain addSpring(final SpringListener listener) {
    // We listen to each spring added to the SpringChain and dynamically chain the springs together
    // whenever the control spring state is modified.
    Spring spring = mSpringSystem
        .createSpring()
        .addListener(this)
        .setSpringConfig(mAttachmentSpringConfig);
    mSprings.add(spring);
    mListeners.add(listener);
    return this;
  }

  /**
   * Set the index of the control spring. This spring will drive the positions of all the springs
   * before and after it in the list when moved.
   * @param i the index to use for the control spring
   * @return this SpringChain
   */
  SpringChain setControlSpringIndex(int i) {
    mControlSpringIndex = i;
    /*Spring controlSpring = mSprings.get(mControlSpringIndex);
    if (controlSpring == null) {
      return null;
    }*/
    for (Spring spring in mSpringSystem.getAllSprings()) {
      spring.setSpringConfig(mAttachmentSpringConfig);
    }
    getControlSpring().setSpringConfig(mMainSpringConfig);
    return this;
  }

  /**
   * Retrieve the control spring so you can manipulate it to drive the positions of the other
   * springs.
   * @return the control spring.
   */
  Spring getControlSpring() {
    return mSprings[mControlSpringIndex];
  }

  /**
   * Retrieve the list of springs in the chain.
   * @return the list of springs
   */
  List<Spring> getAllSprings() {
    return mSprings;
  }

  @override
  void onSpringUpdate(Spring spring) {
    // Get the control spring index and update the endValue of each spring above and below it in the
    // spring collection triggering a cascading effect.
    int idx = mSprings.indexOf(spring);
    if (idx < 0) return;
    SpringListener listener = mListeners[idx];
    int above = -1;
    int below = -1;
    if (idx == mControlSpringIndex) {
      below = idx - 1;
      above = idx + 1;
    } else if (idx < mControlSpringIndex) {
      below = idx - 1;
    } else if (idx > mControlSpringIndex) {
      above = idx + 1;
    }
    if (above > -1 && above < mSprings.length) {
      mSprings[above].setEndValue(spring.getCurrentValue());
    }
    if (below > -1 && below < mSprings.length) {
      mSprings[below].setEndValue(spring.getCurrentValue());
    }
    listener.onSpringUpdate(spring);
  }

  @override
  void onSpringAtRest(Spring spring) {
    int idx = mSprings.indexOf(spring);
    mListeners[idx].onSpringAtRest(spring);
  }

  @override
  void onSpringActivate(Spring spring) {
    int idx = mSprings.indexOf(spring);
    mListeners[idx].onSpringActivate(spring);
  }

  @override
  void onSpringEndStateChange(Spring spring) {
    int idx = mSprings.indexOf(spring);
    mListeners[idx].onSpringEndStateChange(spring);
  }
}
