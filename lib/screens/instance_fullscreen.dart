// lib/screens/instance_fullscreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/instance_model.dart';
import '../services/geonode_service.dart';
import 'macro_setup.dart';
import 'proxy_setup.dart';

class InstanceFullscreenScreen extends StatefulWidget {
  final int instanceId;
  const InstanceFullscreenScreen({super.key, required this.instanceId});

  @override
  State<InstanceFullscreenScreen> createState() =>
      _InstanceFullscreenScreenState();
}

class _InstanceFullscreenScreenState
    extends State<InstanceFullscreenScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.instanceId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: PageView.builder(
        controller: _pageController,
        itemCount: state.instanceCount,
        itemBuilder: (ctx, i) => _InstancePage(instanceId: i),
      ),
    );
  }
}

class _InstancePage extends StatelessWidget {
  final int instanceId;
  const _InstancePage({required this.instanceId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final instance = state.instances[instanceId];
    final flag =
        GeonodeService.getFlagForCode(instance.selectedCountryCode);
    final borderColor = _hexColor(instance.borderColor);

    return Stack(
      children: [
        // App running area (placeholder)
        Container(
          color: const Color(0xFF0D0D0D),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_android,
                    color: borderColor.withOpacity(0.2), size: 80),
                const SizedBox(height: 16),
                Text(
                  'Instance ${instanceId + 1}',
                  style: TextStyle(
                    color: borderColor.withOpacity(0.4),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  state.selectedAppName.isEmpty
                      ? 'No app selected'
                      : state.selectedAppName,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(context, instance, flag, borderColor, state),
        ),

        // Bottom floating controls
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _buildBottomControls(context, instance, borderColor, state),
        ),

        // Swipe hint
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '← Swipe to switch instance →',
              style: TextStyle(
                color: Colors.white.withOpacity(0.15),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, InstanceModel instance,
      String flag, Color borderColor, AppState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 12,
        right: 12,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grid_view,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Instance info
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: borderColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${instanceId + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$flag ${instance.selectedCountryCode}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),

          const Spacer(),

          // Proxy status
          _buildProxyChip(instance),
          const SizedBox(width: 8),

          // Master badge
          if (state.masterModeEnabled &&
              state.masterInstanceId == instanceId)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.military_tech,
                      color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 3),
                  Text('MASTER',
                      style: TextStyle(
                          color: Color(0xFFFFD700), fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProxyChip(InstanceModel instance) {
    if (instance.proxy == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('No Proxy',
            style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
      );
    }

    Color color;
    switch (instance.proxy!.status) {
      case ProxyStatus.good:
        color = const Color(0xFF69F0AE);
        break;
      case ProxyStatus.slow:
        color = const Color(0xFFFFD740);
        break;
      case ProxyStatus.dead:
        color = const Color(0xFFFF5252);
        break;
      default:
        color = const Color(0xFF00E5FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '${instance.proxy!.pingMs}ms',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, InstanceModel instance,
      Color borderColor, AppState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Volume row
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    context.read<AppState>().toggleMute(instance.id),
                child: Icon(
                  instance.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: instance.isMuted
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF888888),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: borderColor,
                    inactiveTrackColor: const Color(0xFF333333),
                    thumbColor: borderColor,
                  ),
                  child: Slider(
                    value: instance.isMuted ? 0 : instance.volume,
                    onChanged: (v) => context
                        .read<AppState>()
                        .setInstanceVolume(instance.id, v),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action buttons row
          Row(
            children: [
              // Macro button
              Expanded(
                child: _ActionBtn(
                  icon: instance.isMacroRunning
                      ? Icons.stop_circle
                      : Icons.smart_toy,
                  label: instance.isMacroRunning ? 'Stop' : 'Macro',
                  color: instance.isMacroRunning
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF69F0AE),
                  onTap: () {
                    if (instance.isMacroRunning) {
                      state.stopMacro(instance.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MacroSetupScreen(instanceId: instance.id),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Proxy button
              Expanded(
                child: _ActionBtn(
                  icon: Icons.public,
                  label: 'Proxy',
                  color: const Color(0xFF00E5FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProxySetupScreen(instanceId: instance.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Screenshot button
              Expanded(
                child: _ActionBtn(
                  icon: Icons.photo_camera,
                  label: 'Screenshot',
                  color: const Color(0xFFFFD740),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Screenshot saved!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF222222),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Master toggle
              Expanded(
                child: _ActionBtn(
                  icon: Icons.military_tech,
                  label: 'Master',
                  color: state.masterModeEnabled &&
                          state.masterInstanceId == instanceId
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF555555),
                  onTap: () {
                    state.setMasterInstance(instanceId);
                    if (!state.masterModeEnabled) {
                      state.toggleMasterMode();
                    }
                  },
                ),
              ),
            ],
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
