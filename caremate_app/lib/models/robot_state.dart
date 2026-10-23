enum RobotConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  connectionError,
}

class RobotState {
  final RobotConnectionStatus connectionStatus;
  final String deviceName;
  final int activeSlot; // 1-6
  final int batteryLevel; // 0-100 %
  final bool isGateOpen;
  final bool isJamDetected;
  final bool isDispensing;
  final int rssi;
  final DateTime? lastHeartbeat;
  final String firmwareVersion;
  final bool isSimulated;
  final String lastLog;

  RobotState({
    this.connectionStatus = RobotConnectionStatus.disconnected,
    this.deviceName = 'CAREMATE-ROBOT-01',
    this.activeSlot = 1,
    this.batteryLevel = 94,
    this.isGateOpen = false,
    this.isJamDetected = false,
    this.isDispensing = false,
    this.rssi = -62,
    this.lastHeartbeat,
    this.firmwareVersion = 'v1.4.2-esp32',
    this.isSimulated = true,
    this.lastLog = 'Ready',
  });

  RobotState copyWith({
    RobotConnectionStatus? connectionStatus,
    String? deviceName,
    int? activeSlot,
    int? batteryLevel,
    bool? isGateOpen,
    bool? isJamDetected,
    bool? isDispensing,
    int? rssi,
    DateTime? lastHeartbeat,
    String? firmwareVersion,
    bool? isSimulated,
    String? lastLog,
  }) {
    return RobotState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      deviceName: deviceName ?? this.deviceName,
      activeSlot: activeSlot ?? this.activeSlot,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isGateOpen: isGateOpen ?? this.isGateOpen,
      isJamDetected: isJamDetected ?? this.isJamDetected,
      isDispensing: isDispensing ?? this.isDispensing,
      rssi: rssi ?? this.rssi,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isSimulated: isSimulated ?? this.isSimulated,
      lastLog: lastLog ?? this.lastLog,
    );
  }
}
