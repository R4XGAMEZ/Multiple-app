// lib/services/geonode_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/instance_model.dart';

class GeonodeService {
  static const String _baseUrl = 'https://proxylist.geonode.com/api/proxy-list';

  // Fetch proxies by country
  static Future<List<ProxyModel>> fetchProxies({
    String country = 'US',
    String protocol = 'http',
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?limit=$limit&page=1&sort_by=uptime&sort_type=desc'
        '&filterByCountry=$country'
        '&filterByProtocols=$protocol'
        '&filterBySpeed=fast',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List proxies = data['data'] ?? [];
        return proxies.map((p) => ProxyModel.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Test proxy ping
  static Future<int> testProxy(ProxyModel proxy) async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = http.Client();

      await client
          .get(Uri.parse('http://httpbin.org/ip'))
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return -1; // Dead
    }
  }

  // Get best proxy for country
  static Future<ProxyModel?> getBestProxy(String countryCode) async {
    final proxies = await fetchProxies(country: countryCode);
    if (proxies.isEmpty) return null;

    // Test all proxies and pick fastest
    ProxyModel? best;
    int bestPing = 99999;

    for (final proxy in proxies.take(5)) {
      final ping = await testProxy(proxy);
      if (ping > 0 && ping < bestPing) {
        bestPing = ping;
        best = proxy;
        best.pingMs = ping;
        best.status = ping < 500
            ? ProxyStatus.good
            : ping < 2000
                ? ProxyStatus.slow
                : ProxyStatus.dead;
      }
    }

    return best;
  }

  // Auto replace dead proxy
  static Future<ProxyModel?> replaceDeadProxy(
      ProxyModel deadProxy, String countryCode) async {
    return await getBestProxy(countryCode);
  }

  // Available countries list
  static const List<Map<String, String>> countries = [
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
    {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
    {'code': 'RU', 'name': 'Russia', 'flag': '🇷🇺'},
    {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
    {'code': 'ID', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'TH', 'name': 'Thailand', 'flag': '🇹🇭'},
  ];

  static String getFlagForCode(String code) {
    final country = countries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'flag': '🌐'},
    );
    return country['flag'] ?? '🌐';
  }
}
