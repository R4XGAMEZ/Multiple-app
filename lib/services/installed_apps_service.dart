// lib/services/installed_apps_service.dart

import 'package:flutter/services.dart';

class InstalledApp {
  final String packageName;
  final String appName;

  InstalledApp({required this.packageName, required this.appName});

  factory InstalledApp.fromMap(Map map) {
    return InstalledApp(
      packageName: map['package'] ?? '',
      appName: map['name'] ?? map['package'] ?? '',
    );
  }
}

class InstalledAppsService {
  static const _channel = MethodChannel('com.multidroid/bridge');

  // Fetch real installed user apps from device
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List result =
          await _channel.invokeMethod('get_installed_apps') ?? [];
      return result.map((e) => InstalledApp.fromMap(e)).toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
    } catch (e) {
      // Fallback if Shizuku not available
      return _fallbackApps();
    }
  }

  // Common apps as fallback
  static List<InstalledApp> _fallbackApps() {
    return [
      InstalledApp(packageName: 'com.instagram.android', appName: 'Instagram'),
      InstalledApp(packageName: 'com.whatsapp', appName: 'WhatsApp'),
      InstalledApp(packageName: 'com.facebook.katana', appName: 'Facebook'),
      InstalledApp(packageName: 'com.twitter.android', appName: 'Twitter/X'),
      InstalledApp(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
      InstalledApp(packageName: 'com.snapchat.android', appName: 'Snapchat'),
      InstalledApp(packageName: 'com.telegram.messenger', appName: 'Telegram'),
      InstalledApp(packageName: 'com.google.android.youtube', appName: 'YouTube'),
    ];
  }

  // Get emoji icon for known apps
  static String getAppEmoji(String packageName) {
    const icons = {
      'com.instagram.android': '📸',
      'com.whatsapp': '💬',
      'com.whatsapp.w4b': '💼',
      'com.facebook.katana': '👤',
      'com.facebook.lite': '👤',
      'com.twitter.android': '🐦',
      'com.zhiliaoapp.musically': '🎵',
      'com.tiktok.android': '🎵',
      'com.snapchat.android': '👻',
      'com.telegram.messenger': '✈️',
      'org.telegram.messenger': '✈️',
      'com.google.android.youtube': '▶️',
      'com.linkedin.android': '💼',
      'com.pinterest': '📌',
      'com.reddit.frontpage': '🤖',
      'com.discord': '🎮',
      'com.spotify.music': '🎧',
      'com.netflix.mediaclient': '🎬',
      'com.amazon.mShop.android.shopping': '🛒',
      'com.shopee.ph': '🛍️',
      'com.lazada.android': '🛍️',
    };
    return icons[packageName] ?? '📱';
  }
}
