import 'dart:async';
import '../models/robot_state.dart';
import '../core/constants/ble_protocol_constants.dart';

class BleRobotService {
  final _stateController = StreamController<RobotState>.broadcast();
  final _rawLogController = StreamController<String>.broadcast();

  RobotState _state = RobotState();
  Timer? _heartbeatTimer;
  bool _forceNextDispenseFailure = false;

  Stream<RobotState> get stateStream => _stateController.stream;
  Stream<String> get logStream => _rawLogController.stream;
  RobotState get currentState => _state;

  BleRobotService() {
    _emitState(_state);
  }

  void _emitState(RobotState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _log(String line) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $line';
    _rawLogController.add(logMessage);
    _emitState(_state.copyWith(lastLog: line));
  }

  // --- Connection Management ---
  Future<void> connect({bool simulate = true}) async {
    _emitState(_state.copyWith(
      connectionStatus: RobotConnectionStatus.scanning,
      isSimulated: simulate,
    ));
    _log('BLE: Scanning for peripheral with UUID ${BleProtocolConstants.serviceUuid}...');

    await Future.delayed(const Duration(milliseconds: 900));
    _emitState(_state.copyWith(connectionStatus: RobotConnectionStatus.connecting));
    _log('BLE: Found "${BleProtocolConstants.deviceNamePrefix}-01". Establishing GATT connection...');

    await Future.delayed(const Duration(milliseconds: 800));
    _emitState(_state.copyWith(
      connectionStatus: RobotConnectionStatus.connected,
      lastHeartbeat: DateTime.now(),
      batteryLevel: 94,
    ));
    _log('BLE: Connected & Subscribed to TX Characteristic (${BleProtocolConstants.txCharacteristicUuid}).');

    // Request initial status
    await sendCommand(BleProtocolConstants.cmdStatus);
    _startHeartbeat();
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _emitState(_state.copyWith(
      connectionStatus: RobotConnectionStatus.disconnected,
      isDispensing: false,
      isGateOpen: false,
    ));
    _log('BLE: Disconnected from robot.');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_state.connectionStatus == RobotConnectionStatus.connected) {
        sendCommand(BleProtocolConstants.cmdStatus);
      }
    });
  }

  // --- Command Execution & Protocol Handling ---
  Future<String> sendCommand(String command) async {
    if (_state.connectionStatus != RobotConnectionStatus.connected) {
      _log('BLE ERR: Cannot send "$command" - Robot disconnected.');
      return 'ERR:NOT_CONNECTED';
    }

    _log('BLE TX >> $command');

    // Handle command via simulator engine
    return await _processCommand(command);
  }

  Future<String> _processCommand(String cmd) async {
    if (cmd == BleProtocolConstants.cmdStatus) {
      final response = 'STATUS:OK|SLOT:${_state.activeSlot}|BAT:${_state.batteryLevel}|JAM:${_state.isJamDetected ? 1 : 0}|GATE:${_state.isGateOpen ? 1 : 0}';
      _log('BLE RX << $response');
      _emitState(_state.copyWith(lastHeartbeat: DateTime.now()));
      return response;
    }

    if (cmd == BleProtocolConstants.cmdTestBuzzer) {
      _log('BLE RX << STATE:BUZZER_ACTIVE');
      await Future.delayed(const Duration(milliseconds: 600));
      _log('BLE RX << ACK:TEST_BUZZER_DONE');
      return 'ACK:TEST_BUZZER_DONE';
    }

    if (cmd == BleProtocolConstants.cmdCalibrate) {
      _log('BLE RX << STATE:HOMING_CAROUSEL');
      await Future.delayed(const Duration(milliseconds: 1000));
      _emitState(_state.copyWith(
        activeSlot: 1,
        isGateOpen: false,
        isJamDetected: false,
      ));
      _log('BLE RX << ACK:CALIBRATION_COMPLETE');
      return 'ACK:CALIBRATION_COMPLETE';
    }

    if (cmd == BleProtocolConstants.cmdSimulateJam) {
      _emitState(_state.copyWith(isJamDetected: true));
      _log('BLE RX << WARN:SIMULATED_JAM_ACTIVE');
      return 'WARN:SIMULATED_JAM_ACTIVE';
    }

    if (cmd == BleProtocolConstants.cmdClearJam) {
      _emitState(_state.copyWith(isJamDetected: false));
      _log('BLE RX << ACK:JAM_CLEARED');
      return 'ACK:JAM_CLEARED';
    }

    if (cmd == BleProtocolConstants.cmdEmergencyStop) {
      _emitState(_state.copyWith(
        isDispensing: false,
        isGateOpen: false,
      ));
      _log('BLE RX << ACK:EMERGENCY_STOP_EXECUTED');
      return 'ACK:EMERGENCY_STOP_EXECUTED';
    }

    if (cmd.startsWith('DISPENSE_SLOT:') || cmd == BleProtocolConstants.cmdDispenseTest) {
      int targetSlot = _state.activeSlot;
      if (cmd.startsWith('DISPENSE_SLOT:')) {
        targetSlot = int.tryParse(cmd.substring(14)) ?? _state.activeSlot;
      }
      return await _executeDispenseCycle(targetSlot);
    }

    _log('BLE RX << ERR:UNKNOWN_COMMAND');
    return 'ERR:UNKNOWN_COMMAND';
  }

  Future<String> _executeDispenseCycle(int slot) async {
    if (_state.isJamDetected) {
      _log('BLE RX << ERR:JAM_DETECTED:Slot $slot locked. Mechanism jammed.');
      return 'ERR:JAM_DETECTED';
    }

    _emitState(_state.copyWith(isDispensing: true));

    // Phase 1: Rotate carousel to target slot
    _log('BLE RX << STATE:ROTATING_SLOT:$slot (Angle: ${(slot - 1) * 60}°)');
    await Future.delayed(const Duration(milliseconds: 800));
    _emitState(_state.copyWith(activeSlot: slot));

    // Phase 2: Buzzer alert before dropping
    _log('BLE RX << STATE:AUDIO_CHIME_PLAYING');
    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 3: Open Dispense Gate
    _log('BLE RX << STATE:OPENING_GATE');
    _emitState(_state.copyWith(isGateOpen: true));
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 4: Optical IR drop sensor check
    if (_forceNextDispenseFailure) {
      _forceNextDispenseFailure = false;
      _emitState(_state.copyWith(
        isGateOpen: false,
        isDispensing: false,
      ));
      _log('BLE RX << ERR:NO_DROP_DETECTED:SLOT:$slot (Tray beam intact / empty slot)');
      return 'ERR:NO_DROP_DETECTED';
    }

    // Phase 5: Successful drop detected
    _emitState(_state.copyWith(isGateOpen: false, isDispensing: false));
    _log('BLE RX << DISPENSE_CONFIRMED:SLOT:$slot (Optical drop sensor triggered)');
    return 'DISPENSE_CONFIRMED:SLOT:$slot';
  }

  // Developer / Judge Testing Knobs
  void triggerNextDispenseFailure() {
    _forceNextDispenseFailure = true;
    _log('SIMULATOR: Scheduled intentional drop failure for next dispense command.');
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _stateController.close();
    _rawLogController.close();
  }
}
