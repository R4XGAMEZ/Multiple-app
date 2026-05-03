// lib/models/instance_model.dart

enum InstanceStatus { idle, running, frozen, loading }
enum MacroStatus { idle, running, paused }
enum ProxyStatus { good, slow, dead, checking }

class ProxyModel {
  final String ip;
  final String port;
  final String country;
  final String countryCode;
  final String protocol;
  final int speed;
  final double uptime;
  ProxyStatus status;
  int pingMs;

  ProxyModel({
    required this.ip,
    required this.port,
    required this.country,
    required this.countryCode,
    required this.protocol,
    required this.speed,
    required this.uptime,
    this.status = ProxyStatus.checking,
    this.pingMs = 0,
  });

  factory ProxyModel.fromJson(Map<String, dynamic> json) {
    return ProxyModel(
      ip: json['ip'] ?? '',
      port: json['port']?.toString() ?? '',
      country: json['country'] ?? '',
      countryCode: json['country'] ?? '',
      protocol: (json['protocols'] as List?)?.first ?? 'http',
      speed: json['speed'] ?? 0,
      uptime: (json['uptime'] ?? 0).toDouble(),
    );
  }

  String get fullAddress => '$ip:$port';
}

class MacroModel {
  String id;
  String name;
  String imagePath;
  double clickX;
  double clickY;
  double scanInterval; // seconds
  bool isLoop;
  double delayAfterClick;
  bool randomDelay;
  bool isActive;

  MacroModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.clickX,
    required this.clickY,
    this.scanInterval = 1.0,
    this.isLoop = true,
    this.delayAfterClick = 0.5,
    this.randomDelay = true,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'clickX': clickX,
    'clickY': clickY,
    'scanInterval': scanInterval,
    'isLoop': isLoop,
    'delayAfterClick': delayAfterClick,
    'randomDelay': randomDelay,
    'isActive': isActive,
  };

  factory MacroModel.fromJson(Map<String, dynamic> json) => MacroModel(
    id: json['id'],
    name: json['name'],
    imagePath: json['imagePath'],
    clickX: json['clickX'],
    clickY: json['clickY'],
    scanInterval: json['scanInterval'] ?? 1.0,
    isLoop: json['isLoop'] ?? true,
    delayAfterClick: json['delayAfterClick'] ?? 0.5,
    randomDelay: json['randomDelay'] ?? true,
    isActive: json['isActive'] ?? false,
  );
}

class InstanceModel {
  final int id;
  String appPackage;
  String appName;
  String appIconPath;

  // Proxy
  ProxyModel? proxy;
  String selectedCountry;
  String selectedCountryCode;

  // Status
  InstanceStatus status;
  MacroStatus macroStatus;

  // Volume
  double volume; // 0.0 to 1.0
  bool isMuted;

  // Macro
  List<MacroModel> macros;

  // Display
  String? screenshotPath;
  String? instanceNote;
  String borderColor;

  // Performance
  double ramUsageMB;
  double cpuUsagePercent;
  double dataUsageMB;

  // Freeform bounds
  int boundsLeft;
  int boundsTop;
  int boundsRight;
  int boundsBottom;

  InstanceModel({
    required this.id,
    this.appPackage = '',
    this.appName = '',
    this.appIconPath = '',
    this.proxy,
    this.selectedCountry = 'United States',
    this.selectedCountryCode = 'US',
    this.status = InstanceStatus.idle,
    this.macroStatus = MacroStatus.idle,
    this.volume = 1.0,
    this.isMuted = false,
    List<MacroModel>? macros,
    this.screenshotPath,
    this.instanceNote,
    this.borderColor = '#2196F3',
    this.ramUsageMB = 0,
    this.cpuUsagePercent = 0,
    this.dataUsageMB = 0,
    this.boundsLeft = 0,
    this.boundsTop = 0,
    this.boundsRight = 540,
    this.boundsBottom = 800,
  }) : macros = macros ?? [];

  // Border colors for each instance
  static const List<String> instanceColors = [
    '#FF5252', // Red
    '#448AFF', // Blue
    '#69F0AE', // Green
    '#FFD740', // Yellow
    '#FF6D00', // Orange
    '#EA80FC', // Purple
  ];

  static String colorForId(int id) {
    return instanceColors[id % instanceColors.length];
  }

  bool get isMacroRunning => macroStatus == MacroStatus.running;
  bool get isActive => status == InstanceStatus.running;
}
