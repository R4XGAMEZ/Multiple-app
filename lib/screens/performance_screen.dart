// lib/screens/performance_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Performance Mode',
            style: TextStyle(color: Colors.white)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // Mode cards
          _ModeCard(
            emoji: '🔋',
            title: 'Battery Saver',
            subtitle: '1-2GB RAM devices ke liye',
            details: [
              '2 instances active max',
              'Scan interval: 5 seconds',
              'Background instances frozen',
              'Master sync disabled',
            ],
            color: const Color(0xFF69F0AE),
            mode: PerformanceMode.batterySaver,
            isSelected: state.performanceMode == PerformanceMode.batterySaver,
            onTap: () => context.read<AppState>().setPerformanceMode(
                PerformanceMode.batterySaver),
          ),

          const SizedBox(height: 12),

          _ModeCard(
            emoji: '⚖️',
            title: 'Balanced',
            subtitle: '2-3GB RAM devices ke liye (Recommended)',
            details: [
              '4 instances active max',
              'Scan interval: 1-2 seconds',
              'Smart freeze/unfreeze',
              'Basic master sync',
            ],
            color: const Color(0xFF00E5FF),
            mode: PerformanceMode.balanced,
            isSelected: state.performanceMode == PerformanceMode.balanced,
            onTap: () => context.read<AppState>().setPerformanceMode(
                PerformanceMode.balanced),
          ),

          const SizedBox(height: 12),

          _ModeCard(
            emoji: '🔥',
            title: 'Performance',
            subtitle: '3GB+ RAM devices ke liye',
            details: [
              'All 6 instances active',
              'Scan interval: 0.5 seconds',
              'No freezing',
              'Full master sync',
            ],
            color: const Color(0xFFFF5252),
            mode: PerformanceMode.performance,
            isSelected: state.performanceMode == PerformanceMode.performance,
            onTap: () => context.read<AppState>().setPerformanceMode(
                PerformanceMode.performance),
          ),

          const SizedBox(height: 24),

          // Current stats
          _buildStatsCard(state),

          const SizedBox(height: 24),

          // Per instance scan interval
          _buildScanIntervalCard(context, state),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Stats',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatTile('RAM', '${state.totalRamUsageMB}MB',
                  const Color(0xFF00E5FF))),
              Expanded(child: _StatTile('CPU', '${state.totalCpuPercent}%',
                  const Color(0xFFFFD740))),
              Expanded(child: _StatTile('Active',
                  '${state.activeInstanceCount}/${state.instanceCount}',
                  const Color(0xFF69F0AE))),
              Expanded(child: _StatTile('Scan',
                  '${state.scanInterval}s',
                  const Color(0xFFFF5252))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanIntervalCard(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Per Instance Scan Interval',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 14),
          ...state.instances.map((inst) {
            final color = Color(int.parse(
                'FF${inst.borderColor.replaceAll('#', '')}', radix: 16));
            final macro = inst.macros.isEmpty ? null : inst.macros.first;
            final interval = macro?.scanInterval ?? state.scanInterval;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${inst.id + 1}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: color,
                        inactiveTrackColor: const Color(0xFF333333),
                        thumbColor: color,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: interval.clamp(0.5, 10.0),
                        min: 0.5, max: 10.0,
                        onChanged: (v) {
                          if (inst.macros.isNotEmpty) {
                            inst.macros.first.scanInterval = v;
                            context.read<AppState>().notifyListeners();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${interval.toStringAsFixed(1)}s',
                          style: TextStyle(color: color, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<String> details;
  final Color color;
  final PerformanceMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji, required this.title, required this.subtitle,
    required this.details, required this.color, required this.mode,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A2A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: isSelected ? color : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('ACTIVE',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 12)),
                  const SizedBox(height: 10),
                  ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(d,
                            style: const TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 12)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
      ],
    );
  }
}
