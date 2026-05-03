// lib/services/app_state.dart — Phase 4 (full replacement)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/instance_model.dart';
import 'geonode_service.dart';
import 'shizuku_service.dart';
import 'virtual_engine_service.dart';
import 'bridge_service.dart';

enum PerformanceMode { batterySaver, balanced, performance }

class AppState extends ChangeNotifier {
  // ── Instance count ─────────────────────────────────────────────────────
  int _instanceCount = 6;
  int get instanceCount => _instanceCount;

  List<InstanceModel> _instances = [];
  List<InstanceModel> get instances => _instances;

  // ── App selection ──────────────────────────────────────────────────────
  String _selectedAppPackage = '';
  String _selectedAppName = '';
  String get selectedAppPackage => _selectedAppPackage;
  String get selectedAppName => _selectedAppName;

  // ── Master control ─────────────────────────────────────────────────────
  bool _masterModeEnabled = false;
  int _masterInstanceId = 0;
  bool get masterModeEnabled => _masterModeEnabled;
  int get masterInstanceId => _masterInstanceId;

  // ── Performance ────────────────────────────────────────────────────────
  PerformanceMode _performanceMode = PerformanceMode.balanced;
  PerformanceMode get performanceMode => _performanceMode;

  // ── Volume ─────────────────────────────────────────────────────────────
  double _masterVolume = 1.0;
  double get masterVolume => _masterVolume;

  // ── Setup ──────────────────────────────────────────────────────────────
  bool _isSetupDone = false;
  bool get isSetupDone => _isSetupDone;

  bool _shizukuAvailable = false;
  bool get shizukuAvailable => _shizukuAvailable;

  bool _freeformAvailable = false;
  bool get freeformAvailable => _freeformAvailable;

  int _screenW = 1080;
  int _screenH = 2400;
  int get screenW => _screenW;
  int get screenH => _screenH;

  // ── Phase 4: EventChannel subscription ────────────────────────────────
  StreamSubscription? _bridgeEventSub;

  // ── Init ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSetupDone = prefs.getBool('setup_done') ?? false;
    _instanceCount = prefs.getInt('instance_count') ?? 6;
    _selectedAppPackage = prefs.getString('selected_app') ?? '';
    _selectedAppName = prefs.getString('selected_app_name') ?? '';
    _performanceMode = PerformanceMode.values[prefs.getInt('performance_mode') ?? 1];

    _initInstances();
    _loadInstanceData(prefs);

    // Shizuku + Freeform
    _shizukuAvailable = await ShizukuService.isAvailable();
    if (_shizukuAvailable) {
      _freeformAvailable = await ShizukuService.isFreeformSupported();
      if (!_freeformAvailable) await ShizukuService.enableFreeform();
      _freeformAvailable = await ShizukuService.isFreeformSupported();
    }
    final screenSize = await ShizukuService.getScreenSize();
    _screenW = screenSize[0];
    _screenH = screenSize[1];

    // Phase 4: Listen to Java EventChannel events
    _subscribeBridgeEvents();

    notifyListeners();
  }

  @override
  void dispose() {
    _bridgeEventSub?.cancel();
    super.dispose();
  }

  // ── Phase 4: Bridge Event Listener ─────────────────────────────────────

  void _subscribeBridgeEvents() {
    _bridgeEventSub = BridgeService.events.listen((event) {
      switch (event.type) {
        case 'service_connected':
          // Accessibility service came online — re-apply master sync if enabled
          if (_masterModeEnabled) {
            _applyMasterSync(_masterModeEnabled);
          }
          break;

        case 'macro_started':
          final id = event.data['instance_id'] as int?;
          if (id != null && id < _instances.length) {
            _instances[id].macroStatus = MacroStatus.running;
            notifyListeners();
          }
          break;

        case 'macro_stopped':
          final id = event.data['instance_id'] as int?;
          if (id != null && id < _instances.length) {
            _instances[id].macroStatus = MacroStatus.idle;
            notifyListeners();
          }
          break;

        case 'all_macros_stopped':
          for (final inst in _instances) {
            inst.macroStatus = MacroStatus.idle;
          }
          notifyListeners();
          break;

        case 'master_click':
        case 'master_text':
        case 'master_scroll':
          // Already handled on Java side — just for UI feedback if needed
          break;
      }
    }, onError: (e) {
      debugPrint('BridgeService event error: $e');
    });
  }

  // ── Instance init ──────────────────────────────────────────────────────

  void _initInstances() {
    _instances = List.generate(_instanceCount, (i) {
      return InstanceModel(
        id: i,
        borderColor: InstanceModel.colorForId(i),
        selectedCountryCode: _defaultCountries[i % _defaultCountries.length],
      );
    });
  }

  static const List<String> _defaultCountries = ['US', 'GB', 'IN', 'JP', 'DE', 'BR'];

  void _loadInstanceData(SharedPreferences prefs) {
    for (final instance in _instances) {
      final key = 'instance_${instance.id}';
      final data = prefs.getString(key);
      if (data != null) {
        final json = jsonDecode(data);
        instance.selectedCountryCode = json['country'] ?? 'US';
        instance.volume = (json['volume'] ?? 1.0).toDouble();
        instance.isMuted = json['muted'] ?? false;
        instance.instanceNote = json['note'];
        final macroData = json['macros'] as List? ?? [];
        instance.macros = macroData.map((m) => MacroModel.fromJson(m)).toList();
      }
    }
  }

  Future<void> _saveInstance(InstanceModel instance) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'instance_${instance.id}';
    final data = jsonEncode({
      'country': instance.selectedCountryCode,
      'volume': instance.volume,
      'muted': instance.isMuted,
      'note': instance.instanceNote,
      'macros': instance.macros.map((m) => m.toJson()).toList(),
    });
    await prefs.setString(key, data);
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  Future<void> completeSetup({
    required int instanceCount,
    required String appPackage,
    required String appName,
  }) async {
    _instanceCount = instanceCount;
    _selectedAppPackage = appPackage;
    _selectedAppName = appName;
    _isSetupDone = true;
    _initInstances();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('instance_count', instanceCount);
    await prefs.setString('selected_app', appPackage);
    await prefs.setString('selected_app_name', appName);
    await prefs.setBool('setup_done', true);
    notifyListeners();
  }

  // ── Instance controls ──────────────────────────────────────────────────

  Future<void> setInstanceCountry(int instanceId, String countryCode) async {
    final instance = _instances[instanceId];
    instance.selectedCountryCode = countryCode;
    instance.proxy = null;
    instance.status = InstanceStatus.loading;
    notifyListeners();

    final proxy = await GeonodeService.getBestProxy(countryCode);
    instance.proxy = proxy;
    instance.status = InstanceStatus.idle;

    // Phase 4: Actually inject proxy to Android system
    if (proxy != null) {
      await BridgeService.setInstanceProxy(
        instanceId: instanceId,
        host: proxy.ip,
        port: proxy.port,
      );
    }

    await _saveInstance(instance);
    notifyListeners();
  }

  // ── Phase 4: Actual Volume Control ─────────────────────────────────────

  Future<void> setInstanceVolume(int instanceId, double volume) async {
    _instances[instanceId].volume = volume;
    _instances[instanceId].isMuted = volume == 0;
    _saveInstance(_instances[instanceId]);

    // ACTUAL AudioManager call via Java bridge
    await BridgeService.setInstanceVolume(
      instanceId: instanceId,
      volume: volume,
      muted: volume == 0,
    );

    notifyListeners();
  }

  Future<void> toggleMute(int instanceId) async {
    final inst = _instances[instanceId];
    inst.isMuted = !inst.isMuted;
    _saveInstance(inst);

    await BridgeService.setInstanceVolume(
      instanceId: instanceId,
      volume: inst.volume,
      muted: inst.isMuted,
    );

    notifyListeners();
  }

  Future<void> muteAll() async {
    for (final inst in _instances) {
      inst.isMuted = true;
    }
    // Single ADB call to mute system audio
    await BridgeService.muteAll(_instanceCount);
    notifyListeners();
  }

  Future<void> unmuteAll() async {
    for (final inst in _instances) {
      inst.isMuted = false;
    }
    await BridgeService.unmuteAll(_instanceCount);
    notifyListeners();
  }

  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume;
    for (final inst in _instances) {
      inst.volume = volume;
    }
    // Actual system volume change
    await BridgeService.setMasterVolume(volume);
    notifyListeners();
  }

  // ── Phase 4: Macro Engine (real) ───────────────────────────────────────

  Future<void> startMacro(int instanceId) async {
    final inst = _instances[instanceId];
    if (inst.macros.isEmpty) return;

    inst.macroStatus = MacroStatus.running;
    notifyListeners();

    // Calculate bounds
    final bounds = getFreeformBounds(instanceId, _screenW, _screenH);
    final macro = inst.macros.first; // Use first active macro

    // Dispatch to MacroEngine via Java bridge
    final ok = await BridgeService.startMacro(
      instanceId: instanceId,
      scanInterval: macro.scanInterval,
      randomDelay: macro.randomDelay,
      delayAfterMs: (macro.delayAfterClick * 1000).toInt(),
      boundsLeft: bounds['left']!,
      boundsTop: bounds['top']!,
      boundsRight: bounds['right']!,
      boundsBottom: bounds['bottom']!,
      clickX: inst.macros.first.clickX / (_screenW / 2), // normalize
      clickY: inst.macros.first.clickY / (_screenH / _gridRows),
    );

    if (!ok) {
      // Accessibility not available — keep UI state but warn
      debugPrint('Macro: accessibility service not running for instance $instanceId');
    }
  }

  Future<void> stopMacro(int instanceId) async {
    _instances[instanceId].macroStatus = MacroStatus.idle;
    notifyListeners();
    await BridgeService.stopMacro(instanceId);
  }

  /// Run All Macros — fires macro engine for every instance that has macros
  Future<void> runAllMacros() async {
    for (final inst in _instances) {
      if (inst.macros.isNotEmpty) {
        await startMacro(inst.id);
        // Small stagger so instances don't all fire simultaneously
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    notifyListeners();
  }

  Future<void> stopAllMacros() async {
    for (final inst in _instances) {
      inst.macroStatus = MacroStatus.idle;
    }
    await BridgeService.stopAllMacros();
    notifyListeners();
  }

  void addMacro(int instanceId, MacroModel macro) {
    _instances[instanceId].macros.add(macro);
    _saveInstance(_instances[instanceId]);
    notifyListeners();
  }

  void removeMacro(int instanceId, String macroId) {
    _instances[instanceId].macros.removeWhere((m) => m.id == macroId);
    _saveInstance(_instances[instanceId]);
    notifyListeners();
  }

  // ── Phase 4: Master Touch Sync ─────────────────────────────────────────

  Future<void> toggleMasterMode() async {
    _masterModeEnabled = !_masterModeEnabled;
    await _applyMasterSync(_masterModeEnabled);
    notifyListeners();
  }

  Future<void> setMasterInstance(int instanceId) async {
    _masterInstanceId = instanceId;
    if (_masterModeEnabled) {
      await _applyMasterSync(true);
    }
    notifyListeners();
  }

  Future<void> _applyMasterSync(bool enabled) async {
    await BridgeService.setMasterSync(
      enabled: enabled,
      masterId: _masterInstanceId,
    );

    if (enabled) {
      // Register freeform bounds for each instance so Java can translate coords
      for (final inst in _instances) {
        final b = getFreeformBounds(inst.id, _screenW, _screenH);
        await BridgeService.setInstanceBounds(
          instanceId: inst.id,
          left: b['left']!,
          top: b['top']!,
          right: b['right']!,
          bottom: b['bottom']!,
        );
      }
    }
  }

  // ── Phase 4: Proxy management ──────────────────────────────────────────

  Future<void> refreshInstanceProxy(int instanceId) async {
    final inst = _instances[instanceId];
    inst.status = InstanceStatus.loading;
    notifyListeners();

    final proxy = await GeonodeService.getBestProxy(inst.selectedCountryCode);
    inst.proxy = proxy;
    inst.status = InstanceStatus.idle;

    if (proxy != null) {
      await BridgeService.setInstanceProxy(
        instanceId: instanceId,
        host: proxy.ip,
        port: proxy.port,
      );
    }

    await _saveInstance(inst);
    notifyListeners();
  }

  Future<void> checkAllProxies() async {
    for (final inst in _instances) {
      if (inst.proxy != null) {
        final ping = await GeonodeService.testProxy(inst.proxy!);
        if (ping < 0) {
          inst.proxy!.status = ProxyStatus.dead;
          final newProxy = await GeonodeService.getBestProxy(inst.selectedCountryCode);
          inst.proxy = newProxy;
          if (newProxy != null) {
            await BridgeService.setInstanceProxy(
              instanceId: inst.id,
              host: newProxy.ip,
              port: newProxy.port,
            );
          }
        } else if (ping > 2000) {
          inst.proxy!.status = ProxyStatus.slow;
          inst.proxy!.pingMs = ping;
        } else {
          inst.proxy!.status = ProxyStatus.good;
          inst.proxy!.pingMs = ping;
        }
        notifyListeners();
      }
    }
  }

  // ── Performance ────────────────────────────────────────────────────────

  void setPerformanceMode(PerformanceMode mode) {
    _performanceMode = mode;
    notifyListeners();
  }

  double get scanInterval {
    switch (_performanceMode) {
      case PerformanceMode.batterySaver: return 3.0;
      case PerformanceMode.balanced: return 1.0;
      case PerformanceMode.performance: return 0.5;
    }
  }

  // ── Grid layout ────────────────────────────────────────────────────────

  int get _gridRows {
    switch (_instanceCount) {
      case 2: return 1;
      case 4: return 2;
      case 6: return 3;
      default: return 3;
    }
  }

  int get gridRows => _gridRows;
  int get gridCols => 2;

  Map<String, int> getFreeformBounds(int instanceId, int screenW, int screenH) {
    final col = instanceId % gridCols;
    final row = instanceId ~/ gridCols;
    final cellW = screenW ~/ gridCols;
    final cellH = screenH ~/ gridRows;
    return {
      'left': col * cellW,
      'top': row * cellH,
      'right': (col + 1) * cellW,
      'bottom': (row + 1) * cellH,
    };
  }

  // ── Phase 5: Stats getters ─────────────────────────────────────────────

  int get totalRamUsageMB =>
      _instances.fold(0, (sum, i) => sum + i.ramUsageMB.toInt());

  double get totalCpuPercent =>
      _instances.fold(0.0, (sum, i) => sum + i.cpuUsagePercent);

  int get activeInstanceCount =>
      _instances.where((i) => i.status == InstanceStatus.running).length;

  // ── Phase 5: Performance mode auto-apply ──────────────────────────────

  void applyPerformanceMode() {
    for (final inst in _instances) {
      for (final macro in inst.macros) {
        switch (_performanceMode) {
          case PerformanceMode.batterySaver:
            macro.scanInterval = 5.0;
            break;
          case PerformanceMode.balanced:
            macro.scanInterval = 1.5;
            break;
          case PerformanceMode.performance:
            macro.scanInterval = 0.5;
            break;
        }
      }
    }
    notifyListeners();
  }

  // Override setPerformanceMode to auto-apply
  void setPerformanceModeAndApply(PerformanceMode mode) {
    _performanceMode = mode;
    applyPerformanceMode();
    SharedPreferences.getInstance().then(
        (p) => p.setInt('performance_mode', mode.index));
  }
}
