// lib/services/freeze_service.dart

import 'package:flutter/services.dart';
import 'shizuku_service.dart';

class FreezeService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Frozen instances track karo
  static final Set<int> _frozenInstances = {};

  // Freeze instance — suspend process to save RAM/CPU
  static Future<bool> freezeInstance(int instanceId, String appPackage) async {
    if (_frozenInstances.contains(instanceId)) return true;
    try {
      // SIGSTOP — process suspend karo (RAM mein rehta hai but CPU use nahi karta)
      final result = await ShizukuService.execCommand(
        'am freeze $appPackage 2>/dev/null || '
        'kill -STOP \$(pidof $appPackage) 2>/dev/null || true',
      );
      _frozenInstances.add(instanceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Unfreeze instance — resume process
  static Future<bool> unfreezeInstance(int instanceId, String appPackage) async {
    if (!_frozenInstances.contains(instanceId)) return true;
    try {
      await ShizukuService.execCommand(
        'am unfreeze $appPackage 2>/dev/null || '
        'kill -CONT \$(pidof $appPackage) 2>/dev/null || true',
      );
      _frozenInstances.remove(instanceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Smart freeze — freeze all except active one
  static Future<void> smartFreeze({
    required int activeInstanceId,
    required int totalInstances,
    required String appPackage,
  }) async {
    for (int i = 0; i < totalInstances; i++) {
      if (i == activeInstanceId) {
        await unfreezeInstance(i, appPackage);
      } else {
        await freezeInstance(i, appPackage);
      }
    }
  }

  // Unfreeze all instances
  static Future<void> unfreezeAll(int total, String appPackage) async {
    for (int i = 0; i < total; i++) {
      await unfreezeInstance(i, appPackage);
    }
  }

  static bool isFrozen(int instanceId) => _frozenInstances.contains(instanceId);
  static Set<int> get frozenInstances => _frozenInstances;
}
