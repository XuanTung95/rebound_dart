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

/*import java.util.Collections;
import java.util.HashMap;
import java.util.Map;*/

import 'dart:core';

import 'package:rebound_dart/src/SpringConfig.dart';

/**
 * class for maintaining a registry of all spring configs
 */
class SpringConfigRegistry {

  static final SpringConfigRegistry _INSTANCE = new SpringConfigRegistry(true);

  static SpringConfigRegistry getInstance() {
    return _INSTANCE;
  }

  final Map<SpringConfig, String> _mSpringConfigMap = new Map<SpringConfig, String>();

  /**
   * constructor for the SpringConfigRegistry
   */
  SpringConfigRegistry(bool includeDefaultEntry) {
    if (includeDefaultEntry) {
      addSpringConfig(SpringConfig.defaultConfig, "default config");
    }
  }

  /**
   * add a SpringConfig to the registry
   *
   * @param springConfig SpringConfig to add to the registry
   * @param configName name to give the SpringConfig in the registry
   * @return true if the SpringConfig was added, false if a config with that name is already
   *    present.
   */
  bool addSpringConfig(SpringConfig springConfig, String configName) {
    if (_mSpringConfigMap.containsKey(springConfig)) {
      return false;
    }
    _mSpringConfigMap[springConfig] = configName;
    return true;
  }

  /**
   * remove a specific SpringConfig from the registry
   * @param springConfig the of the SpringConfig to remove
   * @return true if the SpringConfig was removed, false if it was not present.
   */
  bool removeSpringConfig(SpringConfig springConfig) {
    return _mSpringConfigMap.remove(springConfig) != null;
  }

  /**
   * retrieve all SpringConfig in the registry
   * @return a list of all SpringConfig
   */
  Map<SpringConfig, String> getAllSpringConfig() {
    // return Collections.unmodifiableMap(mSpringConfigMap);
    return _mSpringConfigMap;
  }

  /**
   * clear all SpringConfig in the registry
   */
  void removeAllSpringConfig() {
    _mSpringConfigMap.clear();
  }
}

