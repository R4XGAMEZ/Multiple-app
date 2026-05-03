import 'dart:async';
import 'package:flutter/services.dart';

class BridgeEvent {
  final String type;
  final Map<String, dynamic> data;
  BridgeEvent(this.type, this.data);

  factory BridgeEvent.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? 'unknown';
    final data = Map<String, dynamic>.from(map)..remove('type');
    return BridgeEvent(type, data);
  }
}

class BridgeService {
  static const _method = MethodChannel('com.multidroid/bridge');
  static const _event  = EventChannel('com.multidroid/events');

  static Stream<BridgeEvent>? _eventStream;

  static Stream<BridgeEvent> get events {
    _eventStream ??= _event
        .receiveBroadcastStream()
        .map((e) => BridgeEvent.fromMap(e as Map))
        .asBroadcastStream();
    return _eventStream!;
  }

  static Future<void> setMasterSync({required bool enabled, required int masterId}) async {
    try { await _method.invokeMethod('set_master_sync', {'enabled': enabled, 'master_id': masterId}); } catch (_) {}
  }

  static Future<void> setInstanceBounds({required int instanceId, required int left, required int top, required int right, required int bottom}) async {
    try { await _method.invokeMethod('set_instance_bounds', {'instance_id': instanceId, 'left': left, 'top': top, 'right': right, 'bottom': bottom}); } catch (_) {}
  }

  static Future<bool> setInstanceProxy({required int instanceId, required String host, required String port}) async {
    try { return await _method.invokeMethod('set_instance_proxy', {'instance_id': instanceId, 'host': host, 'port': port}) ?? false; } catch (_) { return false; }
  }

  static Future<bool> clearInstanceProxy(int instanceId) async {
    try { return await _method.invokeMethod('clear_instance_proxy', {'instance_id': instanceId}) ?? false; } catch (_) { return false; }
  }

  static Future<bool> setGlobalProxy(String host, String port) async {
    try { return await _method.invokeMethod('set_global_proxy', {'host': host, 'port': port}) ?? false; } catch (_) { return false; }
  }

  static Future<void> clearAllProxies() async {
    try { await _method.invokeMethod('clear_all_proxies'); } catch (_) {}
  }

  static Future<bool> setInstanceVolume({required int instanceId, required double volume, required bool muted}) async {
    try { return await _method.invokeMethod('set_instance_volume', {'instance_id': instanceId, 'volume': volume, 'muted': muted}) ?? false; } catch (_) { return false; }
  }

  static Future<bool> setMasterVolume(double volume) async {
    try { return await _method.invokeMethod('set_master_volume', {'volume': volume}) ?? false; } catch (_) { return false; }
  }

  static Future<void> muteAll(int count) async {
    try { await _method.invokeMethod('mute_all', {'count': count}); } catch (_) {}
  }

  static Future<void> unmuteAll(int count) async {
    try { await _method.invokeMethod('unmute_all', {'count': count}); } catch (_) {}
  }

  static Future<bool> startMacro({required int instanceId, required double scanInterval, required bool randomDelay, required int delayAfterMs, required int boundsLeft, required int boundsTop, required int boundsRight, required int boundsBottom, required double clickX, required double clickY}) async {
    try {
      return await _method.invokeMethod('start_macro', {
        'instance_id': instanceId, 'scan_interval': scanInterval, 'random_delay': randomDelay,
        'delay_after_ms': delayAfterMs, 'bounds_left': boundsLeft, 'bounds_top': boundsTop,
        'bounds_right': boundsRight, 'bounds_bottom': boundsBottom, 'click_x': clickX, 'click_y': clickY,
      }) ?? false;
    } catch (_) { return false; }
  }

  static Future<void> stopMacro(int instanceId) async {
    try { await _method.invokeMethod('stop_macro', {'instance_id': instanceId}); } catch (_) {}
  }

  static Future<void> stopAllMacros() async {
    try { await _method.invokeMethod('stop_all_macros'); } catch (_) {}
  }

  static Future<bool> performClick(int x, int y) async {
    try { return await _method.invokeMethod('perform_click', {'x': x, 'y': y}) ?? false; } catch (_) { return false; }
  }

  static Future<bool> performSwipe(int x1, int y1, int x2, int y2) async {
    try { return await _method.invokeMethod('perform_swipe', {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2}) ?? false; } catch (_) { return false; }
  }

  static Future<bool> performType(String text) async {
    try { return await _method.invokeMethod('perform_type', {'text': text}) ?? false; } catch (_) { return false; }
  }

  static Future<String> execCommand(String command) async {
    try { return await _method.invokeMethod('exec_command', {'command': command}) ?? ''; } catch (_) { return ''; }
  }

  static Future<List<int>> getRamInfo() async {
    try {
      final List result = await _method.invokeMethod('get_ram_info') ?? [0, 0];
      return [result[0] as int, result[1] as int];
    } catch (_) { return [0, 0]; }
  }
}
