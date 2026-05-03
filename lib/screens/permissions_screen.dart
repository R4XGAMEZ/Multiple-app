// lib/screens/permissions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/shizuku_service.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onAllGranted;
  const PermissionsScreen({super.key, required this.onAllGranted});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _shizukuAvailable = false;
  bool _shizukuGranted = false;
  bool _freeformEnabled = false;
  bool _accessibilityEnabled = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _checking = true);
    final shizAvail = await ShizukuService.isAvailable();
    final shizPerm = await ShizukuService.hasPermission();
    final freeform = await ShizukuService.isFreeformSupported();
    final access = await ShizukuService.isAccessibilityEnabled();
    setState(() {
      _shizukuAvailable = shizAvail;
      _shizukuGranted = shizPerm;
      _freeformEnabled = freeform;
      _accessibilityEnabled = access;
      _checking = false;
    });

    if (shizPerm && freeform && access) widget.onAllGranted();
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _shizukuGranted && _freeformEnabled && _accessibilityEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Permissions Setup',
            style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildPermTile(
              icon: '🔧',
              title: 'Shizuku Permission',
              subtitle: _shizukuAvailable
                  ? 'Shizuku available hai'
                  : 'Shizuku app install karo pehle',
              status: _shizukuGranted,
              canGrant: _shizukuAvailable && !_shizukuGranted,
              onGrant: () async {
                await ShizukuService.requestPermission();
                await Future.delayed(const Duration(seconds: 2));
                _checkAll();
              },
              helpText: 'Shizuku app → Start → ADB mode',
            ),
            const SizedBox(height: 12),
            _buildPermTile(
              icon: '📱',
              title: 'Freeform Windows',
              subtitle: 'Developer Options mein enable karo',
              status: _freeformEnabled,
              canGrant: _shizukuGranted && !_freeformEnabled,
              onGrant: () async {
                await ShizukuService.enableFreeform();
                await Future.delayed(const Duration(milliseconds: 500));
                _checkAll();
              },
              helpText: 'Settings → Developer Options → Freeform Windows → ON',
            ),
            const SizedBox(height: 12),
            _buildPermTile(
              icon: '♿',
              title: 'Accessibility Service',
              subtitle: 'Auto click aur master sync ke liye',
              status: _accessibilityEnabled,
              canGrant: !_accessibilityEnabled,
              onGrant: () async {
                await ShizukuService.openAccessibilitySettings();
                await Future.delayed(const Duration(seconds: 3));
                _checkAll();
              },
              helpText: 'Settings → Accessibility → MultiDroid → Enable',
            ),
            const Spacer(),

            // Refresh button
            GestureDetector(
              onTap: _checkAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _checking
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF00E5FF)))
                        : const Icon(Icons.refresh,
                            color: Color(0xFF888888), size: 18),
                    const SizedBox(width: 8),
                    const Text('Status Check Karo',
                        style: TextStyle(color: Color(0xFF888888))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Continue button
            GestureDetector(
              onTap: allDone ? widget.onAllGranted : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: allDone
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)])
                      : null,
                  color: allDone ? null : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    allDone ? '✅ Sab ready! Continue karo' : 'Permissions pending hain...',
                    style: TextStyle(
                        color: allDone ? Colors.white : const Color(0xFF444444),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool status,
    required bool canGrant,
    required VoidCallback onGrant,
    required String helpText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status
              ? const Color(0xFF69F0AE).withOpacity(0.4)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 12)),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status
                      ? const Color(0xFF69F0AE).withOpacity(0.1)
                      : const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status ? '✅ Done' : '❌ Pending',
                  style: TextStyle(
                      color: status
                          ? const Color(0xFF69F0AE)
                          : const Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (!status) ...[
            const SizedBox(height: 10),
            Text(helpText,
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 11)),
            const SizedBox(height: 8),
            if (canGrant)
              GestureDetector(
                onTap: onGrant,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.4)),
                  ),
                  child: const Text('Grant karo →',
                      style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
