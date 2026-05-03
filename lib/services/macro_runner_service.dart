// lib/services/macro_runner_service.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/instance_model.dart';
import 'shizuku_service.dart';

class MacroRunnerService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Active timers per instance
  static final Map<int, Timer> _timers = {};
  static final Map<int, bool> _running = {};

  // Callbacks
  static Function(int instanceId, bool found)? onMatchResult;
  static Function(int instanceId)? onMacroStopped;

  // ── Start macro for one instance ───────────────────────────────────────

  static void startMacro(int instanceId, MacroModel macro,
      Map<String, int> bounds) {
    stopMacro(instanceId); // Clear existing
    _running[instanceId] = true;

    final intervalMs =
        (macro.scanInterval * 1000).toInt();

    _timers[instanceId] = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _runScan(instanceId, macro, bounds),
    );
  }

  static Future<void> _runScan(
      int instanceId, MacroModel macro, Map<String, int> bounds) async {
    if (_running[instanceId] != true) return;

    try {
      // Tell Java side to scan + match
      final result = await _channel.invokeMethod('macro_scan', {
        'instance_id': instanceId,
        'image_path': macro.imagePath,
        'click_x': macro.clickX.toInt(),
        'click_y': macro.clickY.toInt(),
        'bounds_left': bounds['left'] ?? 0,
        'bounds_top': bounds['top'] ?? 0,
        'bounds_right': bounds['right'] ?? 540,
        'bounds_bottom': bounds['bottom'] ?? 800,
        'threshold': 0.82,
      }) as bool? ?? false;

      onMatchResult?.call(instanceId, result);

      if (result) {
        // Random delay after click (anti-bot)
        if (macro.randomDelay) {
          final extraMs = Random().nextInt(800) + 200;
          await Future.delayed(Duration(milliseconds: extraMs));
        } else {
          await Future.delayed(
              Duration(milliseconds: (macro.delayAfterClick * 1000).toInt()));
        }
      }
    } catch (_) {}
  }

  // ── Start ALL instances ────────────────────────────────────────────────

  static void startAll(
    List<InstanceModel> instances,
    List<Map<String, int>> allBounds,
  ) {
    for (final inst in instances) {
      if (inst.macros.isEmpty) continue;
      final bounds = allBounds.length > inst.id
          ? allBounds[inst.id]
          : {'left': 0, 'top': 0, 'right': 540, 'bottom': 800};
      startMacro(inst.id, inst.macros.first, bounds);
    }
  }

  // ── Stop ───────────────────────────────────────────────────────────────

  static void stopMacro(int instanceId) {
    _running[instanceId] = false;
    _timers[instanceId]?.cancel();
    _timers.remove(instanceId);
    onMacroStopped?.call(instanceId);
  }

  static void stopAll() {
    for (final id in List.from(_timers.keys)) {
      stopMacro(id);
    }
  }

  static bool isRunning(int instanceId) =>
      _running[instanceId] == true;
}
