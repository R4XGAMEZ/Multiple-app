// lib/services/virtual_engine_service.dart

import 'package:flutter/services.dart';
import 'shizuku_service.dart';

class InstanceLaunchResult {
  final bool success;
  final String message;
  InstanceLaunchResult(this.success, this.message);
}

class VirtualEngineService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // ── Clone app ──────────────────────────────────────────────────────────

  static Future<bool> cloneApp(String packageName, int instanceCount) async {
    try {
      return await _channel.invokeMethod('clone_app', {
            'package': packageName,
            'count': instanceCount,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> resetInstance(int instanceId, String packageName) async {
    try {
      return await _channel.invokeMethod('reset_instance', {
            'instance_id': instanceId,
            'package': packageName,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ── Launch all instances in freeform grid ──────────────────────────────

  static Future<List<InstanceLaunchResult>> launchAllInstances({
    required String packageName,
    required int instanceCount,
    required int screenW,
    required int screenH,
  }) async {
    final results = <InstanceLaunchResult>[];

    // Get main activity
    final activity = await _getMainActivity(packageName);

    for (int i = 0; i < instanceCount; i++) {
      final bounds = _calculateBounds(i, instanceCount, screenW, screenH);

      final success = await ShizukuService.launchFreeform(
        packageName: packageName,
        activityName: activity,
        left: bounds[0],
        top: bounds[1],
        right: bounds[2],
        bottom: bounds[3],
      );

      results.add(InstanceLaunchResult(
        success,
        success ? 'Instance ${i + 1} launched' : 'Instance ${i + 1} failed',
      ));

      // Small delay between launches
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  // Launch single instance
  static Future<InstanceLaunchResult> launchInstance({
    required String packageName,
    required int instanceId,
    required int instanceCount,
    required int screenW,
    required int screenH,
  }) async {
    final activity = await _getMainActivity(packageName);
    final bounds = _calculateBounds(instanceId, instanceCount, screenW, screenH);

    final success = await ShizukuService.launchFreeform(
      packageName: packageName,
      activityName: activity,
      left: bounds[0],
      top: bounds[1],
      right: bounds[2],
      bottom: bounds[3],
    );

    return InstanceLaunchResult(
      success,
      success ? 'Launched!' : 'Launch failed — Shizuku check karo',
    );
  }

  // ── Bounds calculator ──────────────────────────────────────────────────

  static List<int> _calculateBounds(
      int instanceId, int totalInstances, int screenW, int screenH) {
    const cols = 2;
    final rows = totalInstances ~/ cols;
    final col = instanceId % cols;
    final row = instanceId ~/ cols;

    final cellW = screenW ~/ cols;
    final cellH = screenH ~/ rows;

    return [
      col * cellW,        // left
      row * cellH,        // top
      (col + 1) * cellW,  // right
      (row + 1) * cellH,  // bottom
    ];
  }

  static Future<String> _getMainActivity(String packageName) async {
    try {
      return await _channel.invokeMethod('get_main_activity',
              {'package': packageName}) ??
          '$packageName.MainActivity';
    } catch (_) {
      return '$packageName.MainActivity';
    }
  }

  // ── Instance size ──────────────────────────────────────────────────────

  static Future<int> getInstanceSizeMB(int instanceId) async {
    try {
      return await _channel.invokeMethod('instance_size_mb',
              {'instance_id': instanceId}) ??
          0;
    } catch (_) {
      return 0;
    }
  }
}
