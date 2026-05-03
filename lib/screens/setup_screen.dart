// lib/screens/setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/installed_apps_service.dart';
import '../models/instance_model.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 0;
  int _selectedInstanceCount = 4;
  String _selectedApp = '';
  String _selectedAppName = '';

  // Real apps from device
  List<InstalledApp> _allApps = [];
  List<InstalledApp> _filteredApps = [];
  bool _loadingApps = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() => _loadingApps = true);
    final apps = await InstalledAppsService.getInstalledApps();
    setState(() {
      _allApps = apps;
      _filteredApps = apps;
      _loadingApps = false;
    });
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = query.isEmpty
          ? _allApps
          : _allApps
              .where((a) =>
                  a.appName.toLowerCase().contains(query.toLowerCase()) ||
                  a.packageName.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: _step == 0
                  ? _buildWelcomeStep()
                  : _step == 1
                      ? _buildInstanceCountStep()
                      : _buildAppSelectStep(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('MD',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('MultiDroid',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const Text('Multi-Instance App Manager',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFF69F0AE)
                        : active
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF222222),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, color: Colors.black, size: 14)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color: active ? Colors.black : const Color(0xFF555555),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? const Color(0xFF69F0AE) : const Color(0xFF222222),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 0: Welcome ──────────────────────────────────────────────────────

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _featureRow('📱', '6 Virtual Instances', 'Same app, 6 different accounts'),
          const SizedBox(height: 16),
          _featureRow('🌐', 'Per Instance Proxy', 'Different country IP each instance'),
          const SizedBox(height: 16),
          _featureRow('🤖', 'Macro Automation', 'Image detection + auto click'),
          const SizedBox(height: 16),
          _featureRow('👑', 'Master Control', 'Control all instances at once'),
          const SizedBox(height: 16),
          _featureRow('⚡', 'Low End Optimized', 'Works on 2GB RAM devices'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requirements',
                    style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _reqRow('Shizuku app installed'),
                _reqRow('Developer Options enabled'),
                _reqRow('Freeform Windows enabled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Instance Count ───────────────────────────────────────────────

  Widget _buildInstanceCountStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kitne instances chahiye?',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Apne device RAM ke hisaab se choose karo',
              style: TextStyle(color: Color(0xFF666666))),
          const SizedBox(height: 32),
          Row(
            children: [
              _instanceCountCard(2, '1-2GB RAM', '⚡'),
              const SizedBox(width: 12),
              _instanceCountCard(4, '2-3GB RAM', '⚖️'),
              const SizedBox(width: 12),
              _instanceCountCard(6, '3GB+ RAM', '🔥'),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Grid Preview',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildGridPreview(),
        ],
      ),
    );
  }

  // ── Step 2: App Select — REAL DEVICE APPS ───────────────────────────────

  Widget _buildAppSelectStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('App select karo clone karne ke liye',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '$_selectedInstanceCount instances banenge',
                style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterApps,
                  decoration: const InputDecoration(
                    hintText: 'App dhundo...',
                    hintStyle: TextStyle(color: Color(0xFF444444)),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF555555)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _loadingApps
                        ? 'Apps load ho rahi hain...'
                        : _allApps.isEmpty
                            ? 'Apps nahi mili'
                            : '${_filteredApps.length} apps mili',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: _loadApps,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          if (_loadingApps)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF00E5FF)),
                            )
                          else
                            const Icon(Icons.refresh,
                                color: Color(0xFF00E5FF), size: 14),
                          const SizedBox(width: 4),
                          const Text('Refresh',
                              style: TextStyle(
                                  color: Color(0xFF00E5FF), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Apps list
        Expanded(
          child: _loadingApps
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF00E5FF)),
                      SizedBox(height: 16),
                      Text('Device apps load ho rahi hain...',
                          style: TextStyle(color: Color(0xFF666666))),
                    ],
                  ),
                )
              : _allApps.isEmpty
                  ? _buildLoadAppsPrompt()
                  : _filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            '"$_searchQuery" nahi mila',
                            style: const TextStyle(color: Color(0xFF555555)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredApps.length,
                          itemBuilder: (ctx, i) =>
                              _AppListTile(
                                app: _filteredApps[i],
                                isSelected:
                                    _selectedApp == _filteredApps[i].packageName,
                                onTap: () => setState(() {
                                  _selectedApp = _filteredApps[i].packageName;
                                  _selectedAppName = _filteredApps[i].appName;
                                }),
                              ),
                        ),
        ),
      ],
    );
  }

  Widget _buildLoadAppsPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apps, color: Color(0xFF333333), size: 64),
          const SizedBox(height: 16),
          const Text('Device apps load karo',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Shizuku se real apps list milegi\nNahi to common apps list milegi',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF555555), fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadApps,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📱 Apps Load Karo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final canProceed = _step == 0 ||
        (_step == 1 && _selectedInstanceCount > 0) ||
        (_step == 2 && _selectedApp.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: () => setState(() => _step--),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: const Text('Back',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: canProceed
                  ? () {
                      if (_step < 2) {
                        setState(() => _step++);
                        // Auto load apps when reaching step 2
                        if (_step == 2 && _allApps.isEmpty) _loadApps();
                      } else {
                        context.read<AppState>().completeSetup(
                              instanceCount: _selectedInstanceCount,
                              appPackage: _selectedApp,
                              appName: _selectedAppName,
                            );
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: canProceed
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)])
                      : null,
                  color: canProceed ? null : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _step == 2 ? '🚀 MultiDroid Start Karo' : 'Continue →',
                    style: TextStyle(
                        color: canProceed ? Colors.white : const Color(0xFF444444),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _instanceCountCard(int count, String ram, String emoji) {
    final selected = _selectedInstanceCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedInstanceCount = count),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00E5FF).withOpacity(0.1)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? const Color(0xFF00E5FF) : const Color(0xFF2A2A2A),
                width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text('$count',
                  style: TextStyle(
                      color: selected ? const Color(0xFF00E5FF) : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text(ram,
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridPreview() {
    final rows = _selectedInstanceCount == 2 ? 1 : _selectedInstanceCount == 4 ? 2 : 3;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: rows == 1 ? 3 : rows == 2 ? 1.5 : 1,
        ),
        itemCount: _selectedInstanceCount,
        itemBuilder: (ctx, i) {
          final hex = InstanceModel.colorForId(i).replaceAll('#', '');
          final color = Color(int.parse('FF$hex', radix: 16));
          return Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text('${i + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _featureRow(String icon, String title, String subtitle) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _reqRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── App List Tile ─────────────────────────────────────────────────────────────

class _AppListTile extends StatelessWidget {
  final InstalledApp app;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppListTile({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = InstalledAppsService.getAppEmoji(app.packageName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.08)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : const Color(0xFF2A2A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // App icon / emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),

            // App name + package
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: const TextStyle(
                        color: Color(0xFF555555), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selected checkmark
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF00E5FF), size: 22)
            else
              const Icon(Icons.radio_button_unchecked,
                  color: Color(0xFF333333), size: 22),
          ],
        ),
      ),
    );
  }
}
