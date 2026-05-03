// lib/widgets/master_sync_overlay.dart
// Phase 4 — Master Sync floating overlay widget

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/bridge_service.dart';
import '../models/instance_model.dart';

/// Floating overlay shown at the top of HomeGrid when Master Sync is active.
/// Shows: sync status, event log, master instance selector.
class MasterSyncOverlay extends StatefulWidget {
  const MasterSyncOverlay({super.key});

  @override
  State<MasterSyncOverlay> createState() => _MasterSyncOverlayState();
}

class _MasterSyncOverlayState extends State<MasterSyncOverlay>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  final List<String> _eventLog = [];
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Listen to bridge events for live log
    _eventSub = BridgeService.events.listen((event) {
      if (!mounted) return;
      setState(() {
        String line;
        switch (event.type) {
          case 'master_click':
            final x = event.data['x'];
            final y = event.data['y'];
            line = '👆 Click → ($x, $y)';
            break;
          case 'master_text':
            line = '⌨️ Text → "${event.data['text']}"';
            break;
          case 'master_scroll':
            line = '↕️ Scroll → (${event.data['scroll_x']}, ${event.data['scroll_y']})';
            break;
          case 'macro_started':
            line = '▶ Macro started #${event.data['instance_id']}';
            break;
          case 'macro_stopped':
            line = '⏹ Macro stopped #${event.data['instance_id']}';
            break;
          default:
            line = '• ${event.type}';
        }
        _eventLog.insert(0, line);
        if (_eventLog.length > 6) _eventLog.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.masterModeEnabled) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFFFFD700),
                const Color(0xFFFF8F00),
                _pulseCtrl.value,
              )!.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 6),
              const Text(
                'MASTER SYNC ACTIVE',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Master instance selector
              _MasterInstanceSelector(
                instanceCount: state.instanceCount,
                currentMaster: state.masterInstanceId,
                onChanged: (id) => context.read<AppState>().setMasterInstance(id),
              ),
              const SizedBox(width: 8),
              // Stop sync button
              GestureDetector(
                onTap: () => context.read<AppState>().toggleMasterMode(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
                  ),
                  child: const Text(
                    'STOP',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Event log
          if (_eventLog.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ListView.builder(
                itemCount: _eventLog.length,
                itemBuilder: (ctx, i) => Text(
                  _eventLog[i],
                  style: TextStyle(
                    color: const Color(0xFF888888).withOpacity(1 - i * 0.15),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MasterInstanceSelector extends StatelessWidget {
  final int instanceCount;
  final int currentMaster;
  final ValueChanged<int> onChanged;

  const _MasterInstanceSelector({
    required this.instanceCount,
    required this.currentMaster,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Master:',
          style: TextStyle(color: Color(0xFF888888), fontSize: 10),
        ),
        const SizedBox(width: 4),
        ...List.generate(instanceCount, (i) {
          final isSelected = i == currentMaster;
          final color = Color(int.parse(
            'FF${InstanceModel.colorForId(i).replaceAll('#', '')}',
            radix: 16,
          ));
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : color.withOpacity(0.2),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : color.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
