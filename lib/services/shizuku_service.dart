// lib/services/shizuku_service.dart

import 'package:flutter/services.dart';

class ShizukuService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // ── Shizuku status ─────────────────────────────────────────────────────

  static Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod('shizuku_available') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod('shizuku_has_permission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod('shizuku_request_permission') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Freeform ───────────────────────────────────────────────────────────

  static Future<bool> isFreeformSupported() async {
    try {
      return await _channel.invokeMethod('freeform_supported') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> enableFreeform() async {
    try {
      await _channel.invokeMethod('enable_freeform');
    } catch (_) {}
  }

  static Future<List<int>> getScreenSize() async {
    try {
      final List result = await _channel.invokeMethod('get_screen_size') ?? [1080, 2400];
      return [result[0] as int, result[1] as int];
    } catch (_) {
      return [1080, 2400];
    }
  }

  // Launch app in freeform window at specific bounds
  static Future<bool> launchFreeform({
    required String packageName,
    required String activityName,
    required int left,
    required int top,
    required int right,
    required int bottom,
  }) async {
    try {
      return await _channel.invokeMethod('launch_freeform', {
            'package': packageName,
            'activity': activityName,
            'left': left,
            'top': top,
            'right': right,
            'bottom': bottom,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // Force stop an app
  static Future<void> forceStop(String packageName) async {
    try {
      await _channel.invokeMethod('force_stop', {'package': packageName});
    } catch (_) {}
  }

  // Execute raw ADB command
  static Future<String> execCommand(String command) async {
    try {
      return await _channel.invokeMethod('exec_command', {'command': command}) ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Accessibility ──────────────────────────────────────────────────────

  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('accessibility_enabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('open_accessibility_settings');
    } catch (_) {}
  }

  static Future<bool> performClick(int x, int y) async {
    try {
      return await _channel.invokeMethod('perform_click', {'x': x, 'y': y}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> performSwipe(int x1, int y1, int x2, int y2) async {
    try {
      return await _channel.invokeMethod('perform_swipe',
              {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
