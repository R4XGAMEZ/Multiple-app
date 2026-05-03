// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'performance_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // App info card
          _buildAppCard(state),
          const SizedBox(height: 16),

          // Performance
          _SectionTitle('Performance'),
          _SettingsTile(
            icon: Icons.speed,
            iconColor: const Color(0xFF00E5FF),
            title: 'Performance Mode',
            subtitle: _modeLabel(state.performanceMode),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerformanceScreen())),
            trailing: _modeBadge(state.performanceMode),
          ),

          // Instances
          _SectionTitle('Instances'),
          _SettingsTile(
            icon: Icons.apps,
            iconColor: const Color(0xFF7C4DFF),
            title: 'Instance Count',
            subtitle: '${state.instanceCount} instances active',
            onTap: () => _showInstanceCountDialog(context, state),
          ),
          _SettingsTile(
            icon: Icons.refresh,
            iconColor: const Color(0xFFFFD740),
            title: 'Reset All Instances',
            subtitle: 'Sab instances ka data clear karo',
            onTap: () => _showResetDialog(context, state),
          ),

          // Proxy
          _SectionTitle('Proxy'),
          _SettingsTile(
            icon: Icons.public,
            iconColor: const Color(0xFF69F0AE),
            title: 'Clear All Proxies',
            subtitle: 'Sab instances se proxy hatao',
            onTap: () => state.clearAllProxies(),
          ),
          _SettingsTile(
            icon: Icons.refresh,
            iconColor: const Color(0xFF69F0AE),
            title: 'Refresh All Proxies',
            subtitle: 'Geonode se naye proxies fetch karo',
            onTap: () => state.checkAllProxies(),
          ),

          // Macro
          _SectionTitle('Macro'),
          _SettingsTile(
            icon: Icons.stop_circle,
            iconColor: const Color(0xFFFF5252),
            title: 'Stop All Macros',
            subtitle: 'Sab running macros band karo',
            onTap: () => state.stopAllMacros(),
          ),

          // About
          _SectionTitle('About'),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF888888),
            title: 'MultiDroid',
            subtitle: 'Version 1.0.0 • Phase 5 Complete',
            onTap: () {},
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAppCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('MD',
                  style: TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MultiDroid',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  '${state.instanceCount} instances • ${state.selectedAppName}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBadge(PerformanceMode mode) {
    final labels = {
      PerformanceMode.batterySaver: ('🔋', const Color(0xFF69F0AE)),
      PerformanceMode.balanced: ('⚖️', const Color(0xFF00E5FF)),
      PerformanceMode.performance: ('🔥', const Color(0xFFFF5252)),
    };
    final data = labels[mode]!;
    return Text(data.$1, style: const TextStyle(fontSize: 20));
  }

  String _modeLabel(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.batterySaver: return 'Battery Saver';
      case PerformanceMode.balanced: return 'Balanced (Recommended)';
      case PerformanceMode.performance: return 'Performance';
    }
  }

  void _showInstanceCountDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Instance Count',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [2, 4, 6].map((count) {
            final selected = state.instanceCount == count;
            return ListTile(
              title: Text('$count Instances',
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF00E5FF)
                          : Colors.white)),
              trailing: selected
                  ? const Icon(Icons.check, color: Color(0xFF00E5FF))
                  : null,
              onTap: () {
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Reset Instances?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Sab instances ka data delete ho jaayega. Account logins bhi hat jaayenge.',
            style: TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All instances reset!'),
                    backgroundColor: Color(0xFF222222)),
              );
            },
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Text(title,
          style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: Color(0xFF444444), size: 20),
          ],
        ),
      ),
    );
  }
}
