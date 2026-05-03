// lib/widgets/ram_monitor_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/bridge_service.dart';

class RamMonitorWidget extends StatefulWidget {
  const RamMonitorWidget({super.key});

  @override
  State<RamMonitorWidget> createState() => _RamMonitorWidgetState();
}

class _RamMonitorWidgetState extends State<RamMonitorWidget> {
  Timer? _timer;
  int _totalRam = 0;
  int _usedRam = 0;
  double _cpuPercent = 0;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStats());
  }

  Future<void> _fetchStats() async {
    try {
      // Get RAM info via Shizuku
      final ramResult = await BridgeService.execCommand(
          'cat /proc/meminfo | grep -E "MemTotal|MemAvailable"');
      final cpuResult = await BridgeService.execCommand(
          'top -bn1 | grep "Cpu(s)" | awk \'{print \$2}\'');

      if (!mounted) return;

      // Parse RAM
      final totalMatch = RegExp(r'MemTotal:\s+(\d+)').firstMatch(ramResult);
      final availMatch = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(ramResult);
      if (totalMatch != null && availMatch != null) {
        final total = int.parse(totalMatch.group(1)!) ~/ 1024;
        final avail = int.parse(availMatch.group(1)!) ~/ 1024;
        setState(() {
          _totalRam = total;
          _usedRam = total - avail;
        });
      }

      // Parse CPU
      final cpuMatch = RegExp(r'[\d.]+').firstMatch(cpuResult);
      if (cpuMatch != null) {
        setState(() => _cpuPercent = double.tryParse(cpuMatch.group(0)!) ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ramPercent = _totalRam > 0 ? _usedRam / _totalRam : 0.0;
    final ramColor = ramPercent > 0.85
        ? const Color(0xFFFF5252)
        : ramPercent > 0.65
            ? const Color(0xFFFFD740)
            : const Color(0xFF69F0AE);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          // RAM bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.memory, color: ramColor, size: 13),
                      const SizedBox(width: 4),
                      Text('RAM',
                          style: TextStyle(color: ramColor, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ]),
                    Text('${_usedRam}MB / ${_totalRam}MB',
                        style: const TextStyle(
                            color: Color(0xFF666666), fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ramPercent.toDouble(),
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation<Color>(ramColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // CPU
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.developer_board,
                    color: Color(0xFFFFD740), size: 13),
                const SizedBox(width: 4),
                Text('CPU',
                    style: const TextStyle(color: Color(0xFFFFD740),
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 2),
              Text('${_cpuPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
