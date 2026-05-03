// lib/screens/macro_setup.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/instance_model.dart';

class MacroSetupScreen extends StatefulWidget {
  final int instanceId;
  const MacroSetupScreen({super.key, required this.instanceId});

  @override
  State<MacroSetupScreen> createState() => _MacroSetupScreenState();
}

class _MacroSetupScreenState extends State<MacroSetupScreen> {
  double _scanInterval = 1.0;
  bool _isLoop = true;
  bool _randomDelay = true;
  double _delayAfterClick = 0.5;
  String _macroName = '';

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
                child: Text(
                  '${widget.instanceId + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Macro Setup',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Existing macros
          if (instance.macros.isNotEmpty) ...[
            _sectionTitle('Active Macros'),
            ...instance.macros.map((m) => _MacroTile(
                  macro: m,
                  instanceId: widget.instanceId,
                  borderColor: borderColor,
                )),
            const SizedBox(height: 20),
          ],

          // Add new macro
          _sectionTitle('Add New Macro'),
          const SizedBox(height: 12),

          // Macro name
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Macro Name',
                    style: TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Like Button',
                    hintStyle:
                        const TextStyle(color: Color(0xFF444444)),
                    filled: true,
                    fillColor: const Color(0xFF0D0D0D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: borderColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: borderColor.withOpacity(0.3)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _macroName = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Image trigger
          _buildCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: borderColor.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(Icons.add_photo_alternate,
                      color: borderColor.withOpacity(0.5), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image Trigger',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                          'Screenshot the button to detect',
                          style: TextStyle(
                              color: Color(0xFF666666), fontSize: 12)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Image picker
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: borderColor.withOpacity(0.4)),
                          ),
                          child: Text('📸 Select Image',
                              style: TextStyle(
                                  color: borderColor, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Click position
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app, color: borderColor, size: 20),
                    const SizedBox(width: 8),
                    const Text('Click Position',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap on screen to set click position',
                  style: TextStyle(
                      color: Color(0xFF666666), fontSize: 12),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: borderColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text('👆 Set Click Position',
                          style: TextStyle(color: borderColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scan interval
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: borderColor, size: 20),
                        const SizedBox(width: 8),
                        const Text('Scan Interval',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_scanInterval.toStringAsFixed(1)}s',
                        style: TextStyle(
                            color: borderColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: borderColor,
                    inactiveTrackColor: const Color(0xFF333333),
                    thumbColor: borderColor,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _scanInterval,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    onChanged: (v) =>
                        setState(() => _scanInterval = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _intervalChip('⚡ 0.5s', 0.5, borderColor),
                    _intervalChip('🔄 1s', 1.0, borderColor),
                    _intervalChip('🐢 3s', 3.0, borderColor),
                    _intervalChip('💤 5s', 5.0, borderColor),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Options
          _buildCard(
            child: Column(
              children: [
                _buildToggle('🔁 Loop Macro', _isLoop, borderColor,
                    (v) => setState(() => _isLoop = v)),
                const Divider(color: Color(0xFF222222)),
                _buildToggle(
                    '⏱ Random Delay (anti-bot)',
                    _randomDelay,
                    borderColor,
                    (v) => setState(() => _randomDelay = v)),
                if (_randomDelay) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delay after click',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 12)),
                      Text(
                          '${_delayAfterClick.toStringAsFixed(1)}s',
                          style: TextStyle(
                              color: borderColor, fontSize: 12)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: borderColor,
                      inactiveTrackColor: const Color(0xFF333333),
                      thumbColor: borderColor,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _delayAfterClick,
                      min: 0.1,
                      max: 5.0,
                      onChanged: (v) =>
                          setState(() => _delayAfterClick = v),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save button
          GestureDetector(
            onTap: () {
              final macro = MacroModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _macroName.isEmpty ? 'Macro' : _macroName,
                imagePath: '',
                clickX: 0,
                clickY: 0,
                scanInterval: _scanInterval,
                isLoop: _isLoop,
                delayAfterClick: _delayAfterClick,
                randomDelay: _randomDelay,
              );
              context.read<AppState>().addMacro(widget.instanceId, macro);
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [borderColor, borderColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('💾 Save Macro',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _intervalChip(String label, double value, Color color) {
    final selected = (_scanInterval - value).abs() < 0.05;
    return GestureDetector(
      onTap: () => setState(() => _scanInterval = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? color : const Color(0xFF333333)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : const Color(0xFF666666),
                fontSize: 11)),
      ),
    );
  }

  Widget _buildToggle(
      String label, bool value, Color color, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1));
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _MacroTile extends StatelessWidget {
  final MacroModel macro;
  final int instanceId;
  final Color borderColor;
  const _MacroTile(
      {required this.macro,
      required this.instanceId,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: macro.isActive
                ? borderColor.withOpacity(0.5)
                : const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy,
              color: macro.isActive ? borderColor : const Color(0xFF555555),
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(macro.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text(
                    '${macro.scanInterval}s scan • ${macro.isLoop ? "Loop" : "Once"}',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFFF5252), size: 20),
            onPressed: () => context
                .read<AppState>()
                .removeMacro(instanceId, macro.id),
          ),
        ],
      ),
    );
  }
}
