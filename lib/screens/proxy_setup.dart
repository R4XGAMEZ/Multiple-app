// lib/screens/proxy_setup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/geonode_service.dart';
import '../models/instance_model.dart';

class ProxySetupScreen extends StatefulWidget {
  final int instanceId;
  const ProxySetupScreen({super.key, required this.instanceId});

  @override
  State<ProxySetupScreen> createState() => _ProxySetupScreenState();
}

class _ProxySetupScreenState extends State<ProxySetupScreen> {
  bool _isFetching = false;
  List<ProxyModel> _proxies = [];
  String _selectedCountry = 'US';

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _selectedCountry =
        state.instances[widget.instanceId].selectedCountryCode;
  }

  Future<void> _fetchProxies() async {
    setState(() {
      _isFetching = true;
      _proxies = [];
    });
    final proxies =
        await GeonodeService.fetchProxies(country: _selectedCountry);
    setState(() {
      _proxies = proxies;
      _isFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final instance = state.instances[widget.instanceId];
    final borderColor = _hexColor(instance.borderColor);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: borderColor, shape: BoxShape.circle),
              child: Center(
                child: Text('${widget.instanceId + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Proxy Setup',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current proxy status
          if (instance.proxy != null) _buildCurrentProxy(instance, borderColor),

          const SizedBox(height: 16),

          // Country selector
          _buildCountrySelector(borderColor),

          const SizedBox(height: 16),

          // Fetch button
          GestureDetector(
            onTap: _isFetching ? null : _fetchProxies,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [borderColor, borderColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isFetching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('🔍 Fetch Proxies from Geonode',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Proxy list
          if (_proxies.isNotEmpty) ...[
            Text('${_proxies.length} proxies found',
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 12)),
            const SizedBox(height: 8),
            ..._proxies.map((p) => _ProxyTile(
                  proxy: p,
                  borderColor: borderColor,
                  onSelect: () {
                    context
                        .read<AppState>()
                        .setInstanceCountry(widget.instanceId, _selectedCountry);
                    Navigator.pop(context);
                  },
                )),
          ],

          if (_proxies.isEmpty && !_isFetching)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.public,
                        color: borderColor.withOpacity(0.3), size: 48),
                    const SizedBox(height: 12),
                    Text('Select country and fetch proxies',
                        style: TextStyle(
                            color: borderColor.withOpacity(0.4),
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentProxy(InstanceModel instance, Color borderColor) {
    final proxy = instance.proxy!;
    Color statusColor;
    String statusText;

    switch (proxy.status) {
      case ProxyStatus.good:
        statusColor = const Color(0xFF69F0AE);
        statusText = '✅ Working';
        break;
      case ProxyStatus.slow:
        statusColor = const Color(0xFFFFD740);
        statusText = '⚠️ Slow';
        break;
      case ProxyStatus.dead:
        statusColor = const Color(0xFFFF5252);
        statusText = '❌ Dead';
        break;
      default:
        statusColor = const Color(0xFF00E5FF);
        statusText = '🔍 Checking';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Proxy',
              style:
                  TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                GeonodeService.getFlagForCode(proxy.countryCode),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proxy.fullAddress,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text('${proxy.protocol.toUpperCase()} • ${proxy.country}',
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor, fontSize: 12)),
                  Text('${proxy.pingMs}ms',
                      style: TextStyle(
                          color: statusColor.withOpacity(0.7),
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector(Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Country',
              style:
                  TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GeonodeService.countries.map((c) {
              final isSelected = _selectedCountry == c['code'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCountry = c['code']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? borderColor.withOpacity(0.15)
                        : const Color(0xFF0D0D0D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? borderColor
                            : const Color(0xFF333333),
                        width: isSelected ? 1.5 : 1),
                  ),
                  child: Text(
                    '${c['flag']} ${c['code']}',
                    style: TextStyle(
                        color: isSelected
                            ? borderColor
                            : const Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _ProxyTile extends StatelessWidget {
  final ProxyModel proxy;
  final Color borderColor;
  final VoidCallback onSelect;
  const _ProxyTile(
      {required this.proxy,
      required this.borderColor,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Text(
            GeonodeService.getFlagForCode(proxy.countryCode),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proxy.fullAddress,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                    '${proxy.protocol.toUpperCase()} • Uptime: ${proxy.uptime.toInt()}%',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: borderColor.withOpacity(0.4)),
              ),
              child: Text('Use',
                  style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
