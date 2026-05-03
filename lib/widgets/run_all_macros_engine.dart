// lib/widgets/run_all_macros_engine.dart
// Phase 4 — Run All Macros progress engine widget

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/bridge_service.dart';
import '../models/instance_model.dart';

/// Bottom sheet shown when "Run All Macros" is tapped.
/// Shows per-instance macro status with live progress.
class RunAllMacrosSheet extends StatefulWidget {
  const RunAllMacrosSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const RunAllMacrosSheet(),
    );
  }

  @override
  State<RunAllMacrosSheet> createState() => _RunAllMacrosSheetState();
}

class _RunAllMacrosSheetState extends State<RunAllMacrosSheet> {
  bool _launching = false;

  // Per-instance launch result
  final Map<int, _LaunchStatus> _statuses = {};
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = BridgeService.events.listen((event) {
      if (!mounted) return;
      if (event.type == 'macro_started') {
        final id = event.data['instance_id'] as int?;
        if (id != null) {
          setState(() {
            _statuses[id] = _LaunchStatus.running;
          });
        }
      } else if (event.type == 'macro_stopped') {
        final id = event.data['instance_id'] as int?;
        if (id != null) {
          setState(() {
            _statuses[id] = _LaunchStatus.stopped;
          });
        }
      } else if (event.type == 'all_macros_stopped') {
        setState(() {
          for (final k in _statuses.keys) {
            _statuses[k] = _LaunchStatus.stopped;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _runAll() async {
    final state = context.read<AppState>();
    setState(() {
      _launching = true;
      for (final inst in state.instances) {
        if (inst.macros.isNotEmpty) {
          _statuses[inst.id] = _LaunchStatus.launching;
        }
      }
    });

    await state.runAllMacros();

    setState(() => _launching = false);
  }

  Future<void> _stopAll() async {
    await context.read<AppState>().stopAllMacros();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final anyRunning = state.instances.any((i) => i.macroStatus == MacroStatus.running);
    final hasAnyMacros = state.instances.any((i) => i.macros.isNotEmpty);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Color(0xFF00E5FF), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Macro Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: anyRunning
                        ? const Color(0xFF00E5FF).withOpacity(0.15)
                        : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: anyRunning
                          ? const Color(0xFF00E5FF).withOpacity(0.4)
                          : const Color(0xFF444444),
                    ),
                  ),
                  child: Text(
                    anyRunning
                        ? '${state.instances.where((i) => i.isMacroRunning).length} RUNNING'
                        : 'IDLE',
                    style: TextStyle(
                      color: anyRunning
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF666666),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instance list
          ...state.instances.map((inst) {
            final hasM = inst.macros.isNotEmpty;
            final status = _statuses[inst.id] ?? _LaunchStatus.idle;
            final isRunning = inst.macroStatus == MacroStatus.running;
            final borderColor = Color(int.parse(
              'FF${inst.borderColor.replaceAll('#', '')}',
              radix: 16,
            ));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRunning
                      ? borderColor.withOpacity(0.5)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: Row(
                children: [
                  // Instance badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(isRunning ? 1.0 : 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${inst.id + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasM
                              ? '${inst.macros.length} macro${inst.macros.length > 1 ? 's' : ''}'
                              : 'No macros',
                          style: TextStyle(
                            color: hasM ? Colors.white : const Color(0xFF555555),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (hasM)
                          Text(
                            inst.macros.first.name,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  _StatusIndicator(
                    status: status,
                    isRunning: isRunning,
                    hasM: hasM,
                    color: borderColor,
                    onToggle: hasM
                        ? () {
                            if (isRunning) {
                              state.stopMacro(inst.id);
                            } else {
                              state.startMacro(inst.id);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF222222), height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Row(
              children: [
                // Run/Stop All
                Expanded(
                  child: GestureDetector(
                    onTap: _launching
                        ? null
                        : (anyRunning ? _stopAll : (hasAnyMacros ? _runAll : null)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: anyRunning
                              ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                              : hasAnyMacros
                                  ? [
                                      const Color(0xFF00E5FF),
                                      const Color(0xFF7C4DFF),
                                    ]
                                  : [const Color(0xFF333333), const Color(0xFF333333)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_launching) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Launching...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              anyRunning ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              anyRunning
                                  ? 'Stop All Macros'
                                  : hasAnyMacros
                                      ? '▶ Run All Macros'
                                      : 'No Macros Set',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF888888), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LaunchStatus { idle, launching, running, stopped }

class _StatusIndicator extends StatelessWidget {
  final _LaunchStatus status;
  final bool isRunning;
  final bool hasM;
  final Color color;
  final VoidCallback? onToggle;

  const _StatusIndicator({
    required this.status,
    required this.isRunning,
    required this.hasM,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasM) {
      return const Icon(Icons.remove, color: Color(0xFF444444), size: 16);
    }

    if (status == _LaunchStatus.launching) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isRunning
              ? const Color(0xFFFF5252).withOpacity(0.15)
              : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isRunning
                ? const Color(0xFFFF5252).withOpacity(0.4)
                : color.withOpacity(0.4),
          ),
        ),
        child: Text(
          isRunning ? 'STOP' : 'RUN',
          style: TextStyle(
            color: isRunning ? const Color(0xFFFF5252) : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
