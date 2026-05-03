// lib/services/master_sync_service.dart

import 'package:flutter/services.dart';
import 'shizuku_service.dart';

enum SyncAction { click, text, scroll, swipe }

class MasterSyncService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Slave instance IDs to sync to
  static List<int> _slaveIds = [];
  static bool _enabled = false;
  static int _masterId = 0;

  // Instance bounds — for coordinate remapping
  static List<Map<String, int>> _instanceBounds = [];

  static void configure({
    required int masterId,
    required List<int> slaveIds,
    required List<Map<String, int>> instanceBounds,
    required bool enabled,
  }) {
    _masterId = masterId;
    _slaveIds = slaveIds;
    _instanceBounds = instanceBounds;
    _enabled = enabled;
    _channel.invokeMethod('set_master_sync', {
      'enabled': enabled,
      'master_id': masterId,
    });
  }

  static void disable() {
    _enabled = false;
    _channel.invokeMethod('set_master_sync', {
      'enabled': false,
      'master_id': _masterId,
    });
  }

  // Broadcast click from master to all slaves
  // Remaps coordinates relative to each slave's bounds
  static Future<void> broadcastClick(int absX, int absY) async {
    if (!_enabled || _instanceBounds.isEmpty) return;

    final masterBounds = _instanceBounds[_masterId];
    // Relative position within master instance (0.0 - 1.0)
    final relX = (absX - masterBounds['left']!) /
        (masterBounds['right']! - masterBounds['left']!);
    final relY = (absY - masterBounds['top']!) /
        (masterBounds['bottom']! - masterBounds['top']!);

    for (final slaveId in _slaveIds) {
      if (slaveId >= _instanceBounds.length) continue;
      final slaveBounds = _instanceBounds[slaveId];

      // Remap to slave's coordinate space
      final slaveX = (slaveBounds['left']! +
              relX * (slaveBounds['right']! - slaveBounds['left']!))
          .toInt();
      final slaveY = (slaveBounds['top']! +
              relY * (slaveBounds['bottom']! - slaveBounds['top']!))
          .toInt();

      await ShizukuService.performClick(slaveX, slaveY);
    }
  }

  // Broadcast text to all slaves
  static Future<void> broadcastText(String text) async {
    if (!_enabled) return;
    for (final _ in _slaveIds) {
      await _channel.invokeMethod('perform_type', {'text': text});
    }
  }

  // Broadcast scroll to all slaves
  static Future<void> broadcastScroll(
      int instanceId, int dx, int dy) async {
    if (!_enabled) return;
    if (_instanceBounds.isEmpty) return;

    final masterBounds = _instanceBounds[_masterId];
    final cx = ((masterBounds['left']! + masterBounds['right']!) / 2).toInt();
    final cy = ((masterBounds['top']! + masterBounds['bottom']!) / 2).toInt();

    for (final slaveId in _slaveIds) {
      if (slaveId >= _instanceBounds.length) continue;
      final slaveBounds = _instanceBounds[slaveId];
      final scx = ((slaveBounds['left']! + slaveBounds['right']!) / 2).toInt();
      final scy = ((slaveBounds['top']! + slaveBounds['bottom']!) / 2).toInt();

      await ShizukuService.performSwipe(scx, scy, scx + dx, scy + dy);
    }
  }
}
