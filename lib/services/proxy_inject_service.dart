// lib/services/proxy_inject_service.dart

import 'package:flutter/services.dart';
import '../models/instance_model.dart';
import 'shizuku_service.dart';

class ProxyInjectService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Inject proxy for a specific instance app
  // Uses iptables-based routing per UID via Shizuku
  static Future<bool> injectProxy({
    required String appPackage,
    required int instanceId,
    required ProxyModel proxy,
  }) async {
    try {
      // Get app UID
      final uid = await _getAppUid(appPackage);
      if (uid < 0) return false;

      // Route traffic for this UID through proxy
      // Using iptables OUTPUT chain per UID
      final proxyHost = proxy.ip;
      final proxyPort = int.parse(proxy.port);

      // Redirect app traffic to proxy
      await ShizukuService.execCommand(
        'iptables -t nat -A OUTPUT -p tcp '
        '-m owner --uid-owner $uid '
        '-j DNAT --to-destination $proxyHost:$proxyPort',
      );

      // Also set system-level proxy as fallback
      await ShizukuService.execCommand(
        'settings put global http_proxy $proxyHost:$proxyPort',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear proxy for specific instance
  static Future<void> clearProxy({
    required String appPackage,
    required int instanceId,
  }) async {
    try {
      final uid = await _getAppUid(appPackage);
      if (uid < 0) return;

      await ShizukuService.execCommand(
        'iptables -t nat -D OUTPUT -p tcp '
        '-m owner --uid-owner $uid '
        '-j DNAT 2>/dev/null || true',
      );
    } catch (_) {}
  }

  // Inject proxies for all instances simultaneously
  static Future<void> injectAllProxies({
    required String appPackage,
    required List<ProxyModel?> proxies,
  }) async {
    for (int i = 0; i < proxies.length; i++) {
      final proxy = proxies[i];
      if (proxy != null) {
        await injectProxy(
          appPackage: appPackage,
          instanceId: i,
          proxy: proxy,
        );
      }
    }
  }

  // Clear all proxy rules
  static Future<void> clearAllProxies() async {
    await ShizukuService.execCommand('iptables -t nat -F OUTPUT 2>/dev/null || true');
    await ShizukuService.execCommand('settings delete global http_proxy');
  }

  static Future<int> _getAppUid(String packageName) async {
    try {
      final result = await ShizukuService.execCommand(
        'dumpsys package $packageName | grep userId=',
      );
      // Parse "    userId=10234"
      final match = RegExp(r'userId=(\d+)').firstMatch(result);
      if (match != null) return int.parse(match.group(1)!);
      return -1;
    } catch (_) {
      return -1;
    }
  }
}
