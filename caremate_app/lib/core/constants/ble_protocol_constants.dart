/// Protocol constants for BLE communication with CAREMATE ESP32 Companion Robot.
class BleProtocolConstants {
  static const String deviceNamePrefix = "CAREMATE-ROBOT";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String rxCharacteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String txCharacteristicUuid = "beb5483f-36e1-4688-b7f5-ea07361b26a8";

  // Commands Sent to ESP32
  static const String cmdStatus = "STATUS";
  static const String cmdDispenseTest = "DISPENSE_TEST";
  static String cmdDispenseSlot(int slot) => "DISPENSE_SLOT:$slot";
  static const String cmdTestBuzzer = "TEST_BUZZER";
  static const String cmdCalibrate = "CALIBRATE";
  static const String cmdSimulateJam = "SIMULATE_JAM";
  static const String cmdClearJam = "CLEAR_JAM";
  static const String cmdEmergencyStop = "EMERGENCY_STOP";

  // Responses received from ESP32
  static const String prefixStatus = "STATUS:";
  static const String prefixState = "STATE:";
  static const String prefixDispenseConfirmed = "DISPENSE_CONFIRMED:SLOT:";
  static const String prefixErr = "ERR:";
  static const String prefixAck = "ACK:";
  static const String prefixWarn = "WARN:";
}
