import 'dart:async';
import 'package:flutter/material.dart';
import '../models/robot_state.dart';
import '../services/ble_robot_service.dart';
import '../core/constants/ble_protocol_constants.dart';

class RobotProvider extends ChangeNotifier {
  final BleRobotService _bleService;
  StreamSubscription? _stateSub;
  StreamSubscription? _logSub;

  final List<String> _terminalLogs = [];
  bool _isBusy = false;

  RobotState get state => _bleService.currentState;
  List<String> get terminalLogs => List.unmodifiable(_terminalLogs);
  bool get isBusy => _isBusy;
  BleRobotService get bleService => _bleService;

  RobotProvider(this._bleService) {
    _stateSub = _bleService.stateStream.listen((newState) {
      notifyListeners();
    });

    _logSub = _bleService.logStream.listen((log) {
      _terminalLogs.add(log);
      if (_terminalLogs.length > 120) {
        _terminalLogs.removeAt(0);
      }
      notifyListeners();
    });

    // Auto-connect simulator on startup for seamless immediate experience
    connect(simulate: true);
  }

  Future<void> connect({bool simulate = true}) async {
    _isBusy = true;
    notifyListeners();
    try {
      await _bleService.connect(simulate: simulate);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    notifyListeners();
  }

  Future<String> sendCustomCommand(String cmd) async {
    _isBusy = true;
    notifyListeners();
    try {
      return await _bleService.sendCommand(cmd);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> testBuzzer() async {
    await sendCustomCommand(BleProtocolConstants.cmdTestBuzzer);
  }

  Future<void> calibrate() async {
    await sendCustomCommand(BleProtocolConstants.cmdCalibrate);
  }

  Future<void> toggleSimulatedJam() async {
    if (state.isJamDetected) {
      await sendCustomCommand(BleProtocolConstants.cmdClearJam);
    } else {
      await sendCustomCommand(BleProtocolConstants.cmdSimulateJam);
    }
  }

  Future<void> emergencyStop() async {
    await sendCustomCommand(BleProtocolConstants.cmdEmergencyStop);
  }

  void triggerNextDispenseFailure() {
    _bleService.triggerNextDispenseFailure();
    notifyListeners();
  }

  void clearLogs() {
    _terminalLogs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }
}
