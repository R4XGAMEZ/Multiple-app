// lib/services/volume_service.dart

import 'package:flutter/services.dart';
import 'shizuku_service.dart';

class VolumeService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Set volume for specific app instance via media session
  // Uses AudioManager + app UID targeting via Shizuku
  static Future<void> setInstanceVolume({
    required String appPackage,
    required int instanceId,
    required double volume, // 0.0 to 1.0
  }) async {
    try {
      // Convert 0.0-1.0 to Android volume scale (0-15)
      final androidVol = (volume * 15).round();

      // Mute/unmute app via Shizuku
      if (volume == 0) {
        await ShizukuService.execCommand(
          'media volume --stream 3 --set 0',
        );
      } else {
        await ShizukuService.execCommand(
          'media volume --stream 3 --set $androidVol',
        );
      }

      await _channel.invokeMethod('set_instance_volume', {
        'package': appPackage,
        'instance_id': instanceId,
        'volume': volume,
      });
    } catch (_) {}
  }

  // Mute specific instance
  static Future<void> muteInstance({
    required String appPackage,
    required int instanceId,
  }) async {
    await setInstanceVolume(
      appPackage: appPackage,
      instanceId: instanceId,
      volume: 0,
    );
  }

  // Set master volume — all instances
  static Future<void> setMasterVolume(double volume) async {
    final androidVol = (volume * 15).round();
    await ShizukuService.execCommand(
      'media volume --stream 3 --set $androidVol',
    );
  }

  // Mute all instances
  static Future<void> muteAll() async {
    await ShizukuService.execCommand('media volume --stream 3 --set 0');
  }

  // Unmute all
  static Future<void> unmuteAll(double volume) async {
    final androidVol = (volume * 15).round();
    await ShizukuService.execCommand(
      'media volume --stream 3 --set $androidVol',
    );
  }

  // Solo mode — mute all except one
  static Future<void> soloInstance({
    required String appPackage,
    required int soloInstanceId,
    required int totalInstances,
    required double volume,
  }) async {
    await muteAll();
    await Future.delayed(const Duration(milliseconds: 100));
    await setInstanceVolume(
      appPackage: appPackage,
      instanceId: soloInstanceId,
      volume: volume,
    );
  }
}
