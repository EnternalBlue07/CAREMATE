import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/dose_event.dart';
import '../models/robot_state.dart';
import '../services/storage_service.dart';
import '../services/ble_robot_service.dart';
import '../core/constants/ble_protocol_constants.dart';

class MedicationProvider extends ChangeNotifier {
  final StorageService _storageService;
  final BleRobotService _bleService;

  List<Medication> _medications = [];
  List<DoseEvent> _doseHistory = [];
  bool _isLoading = false;
  String? _lastDispenseMessage;

  List<Medication> get medications => List.unmodifiable(_medications);
  List<DoseEvent> get doseHistory => List.unmodifiable(_doseHistory);
  bool get isLoading => _isLoading;
  String? get lastDispenseMessage => _lastDispenseMessage;

  MedicationProvider(this._storageService, this._bleService) {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _medications = await _storageService.loadMedications();
      final loadedDoses = await _storageService.loadDoseHistory();

      // Deterministic Event Reconciliation:
      // When duplicate IDs are encountered across restarts or syncs,
      // preserve the most trustworthy state according to strict clinical progress rank.
      final Map<String, DoseEvent> reconciledMap = {};
      for (final dose in loadedDoses) {
        if (!reconciledMap.containsKey(dose.id)) {
          reconciledMap[dose.id] = dose;
        } else {
          final existing = reconciledMap[dose.id]!;
          reconciledMap[dose.id] = _reconcileDoseEvents(existing, dose);
        }
      }
      _doseHistory = reconciledMap.values.toList();
      _sortDoses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // State-Ranking: higher rank represents a more advanced / trustworthy confirmed clinical state
  static int _statusRank(DoseStatus status) {
    switch (status) {
      case DoseStatus.acknowledged:
        return 5;
      case DoseStatus.dispenseConfirmed:
        return 4;
      case DoseStatus.failed:
        return 3;
      case DoseStatus.unknown:
        return 2;
      case DoseStatus.commandSent:
        return 1;
      case DoseStatus.scheduled:
        return 0;
    }
  }

  static DoseEvent _reconcileDoseEvents(DoseEvent a, DoseEvent b) {
    final rankA = _statusRank(a.status);
    final rankB = _statusRank(b.status);

    if (rankB > rankA) {
      // b has a more advanced state; preserve b, but retain any earlier timestamps from a if b lacks them
      return b.copyWith(
        commandSentTime: b.commandSentTime ?? a.commandSentTime,
        dispensedTime: b.dispensedTime ?? a.dispensedTime,
        acknowledgedTime: b.acknowledgedTime ?? a.acknowledgedTime,
      );
    } else {
      // a has equal or higher rank; retain a, filling any missing timestamps from b
      return a.copyWith(
        commandSentTime: a.commandSentTime ?? b.commandSentTime,
        dispensedTime: a.dispensedTime ?? b.dispensedTime,
        acknowledgedTime: a.acknowledgedTime ?? b.acknowledgedTime,
      );
    }
  }

  void _sortDoses() {
    _doseHistory.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  // --- Next Scheduled Dose ---
  DoseEvent? get nextScheduledDose {
    final now = DateTime.now();
    final upcoming = _doseHistory.where((d) => 
      d.status == DoseStatus.scheduled && d.scheduledTime.isAfter(now.subtract(const Duration(hours: 2)))
    ).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return upcoming.first;
  }

  // --- Today's Doses ---
  List<DoseEvent> get todayDoses {
    final now = DateTime.now();
    return _doseHistory.where((d) {
      return d.scheduledTime.year == now.year &&
             d.scheduledTime.month == now.month &&
             d.scheduledTime.day == now.day;
    }).toList();
  }

  // --- Adherence Rate Calculation ---
  double get todayAdherenceRate {
    final doses = todayDoses;
    if (doses.isEmpty) return 1.0;
    final confirmedOrTaken = doses.where((d) => 
      d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
    ).length;
    return confirmedOrTaken / doses.length;
  }

  // --- 7-Day Adherence Calculation ---
  double get sevenDayAdherenceRate {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final relevant = _doseHistory.where((d) =>
      d.scheduledTime.isAfter(sevenDaysAgo) && d.scheduledTime.isBefore(now)
    ).toList();
    if (relevant.isEmpty) return todayAdherenceRate;
    final successful = relevant.where((d) =>
      d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
    ).length;
    return successful / relevant.length;
  }

  int get todayTakenCount => todayDoses.where((d) =>
    d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
  ).length;

  int get todayPendingCount => todayDoses.where((d) =>
    d.status == DoseStatus.scheduled || d.status == DoseStatus.commandSent
  ).length;

  int get todayMissedOrFailedCount => todayDoses.where((d) =>
    d.status == DoseStatus.failed || (d.status == DoseStatus.scheduled && d.scheduledTime.isBefore(DateTime.now().subtract(const Duration(hours: 2))))
  ).length;

  List<Medication> get lowStockMedications => _medications.where((m) =>
    m.stockCount <= 5
  ).toList();

  // --- Dispensing State Machine with Truthful Safety Guardrails ---
  Future<bool> dispenseMedication(Medication med, {DoseEvent? existingDose}) async {
    final robotState = _bleService.currentState;

    // Safety Guard 1: Verify Connection
    if (robotState.connectionStatus != RobotConnectionStatus.connected) {
      _lastDispenseMessage = 'Dispense Aborted: CAREMATE Robot is not connected over BLE.';
      notifyListeners();
      return false;
    }

    // Safety Guard 2: Verify Mechanism Not Jammed
    if (robotState.isJamDetected) {
      _lastDispenseMessage = 'Dispense Aborted: Robot reported mechanical jam. Please inspect carousel.';
      notifyListeners();
      return false;
    }

    // Safety Guard 3: Duplicate-Command Protection & Ambiguous Outcome Interlock
    final now = DateTime.now();
    final ambiguousOrRecent = _doseHistory.where((d) {
      if (d.medicationId != med.id) return false;
      if (d.status == DoseStatus.commandSent) return true;
      if (d.status == DoseStatus.dispenseConfirmed && d.dispensedTime != null) {
        // Guard against double dispensing within 45 minutes of a verified drop
        return now.difference(d.dispensedTime!).inMinutes < 45;
      }
      if (d.status == DoseStatus.unknown) {
        // Strict Hardware Safety Invariant:
        // A dispense with an UNKNOWN outcome is NEVER automatically unblocked by time alone!
        // It remains locked indefinitely until caregiver/patient manually verifies the tray
        // and reconciles the dose (via acknowledgeDose or manual clearance).
        return true;
      }
      return false;
    }).toList();

    if (ambiguousOrRecent.isNotEmpty) {
      final hasUnknown = ambiguousOrRecent.any((d) => d.status == DoseStatus.unknown);
      if (hasUnknown) {
        _lastDispenseMessage = 'Safety Interlock: An earlier dispense attempt for ${med.name} had an unknown outcome. You must manually inspect the tray and acknowledge or clear it before another drop can be initiated.';
      } else {
        _lastDispenseMessage = 'Safety Alert: A dose of ${med.name} was already dispensed or is currently in-flight!';
      }
      notifyListeners();
      return false;
    }

    // Create or update dose event to COMMAND_SENT
    DoseEvent activeDose;
    if (existingDose != null) {
      activeDose = existingDose.copyWith(
        status: DoseStatus.commandSent,
        commandSentTime: now,
      );
      final idx = _doseHistory.indexWhere((d) => d.id == existingDose.id);
      if (idx != -1) _doseHistory[idx] = activeDose;
    } else {
      activeDose = DoseEvent(
        id: 'dose_${now.millisecondsSinceEpoch}',
        medicationId: med.id,
        medicationName: med.name,
        dosage: med.dosage,
        compartmentSlot: med.compartmentSlot,
        scheduledTime: now,
        commandSentTime: now,
        status: DoseStatus.commandSent,
      );
      _doseHistory.insert(0, activeDose);
    }
    notifyListeners();
    await _storageService.saveDoseHistory(_doseHistory);

    // Send BLE command to ESP32 with safe exception / timeout handling
    final cmd = BleProtocolConstants.cmdDispenseSlot(med.compartmentSlot);
    String response;
    try {
      response = await _bleService.sendCommand(cmd).timeout(
        const Duration(seconds: 15),
        onTimeout: () => 'ERR:BLE_TIMEOUT',
      );
    } catch (e) {
      response = 'ERR:COMMUNICATION_LOST:$e';
    }

    final eventIdx = _doseHistory.indexWhere((d) => d.id == activeDose.id);
    if (eventIdx == -1) return false;

    // Evaluate Truthful Hardware Response
    if (response.startsWith(BleProtocolConstants.prefixDispenseConfirmed)) {
      // SUCCESS: Tablet optical drop confirmed
      _doseHistory[eventIdx] = _doseHistory[eventIdx].copyWith(
        status: DoseStatus.dispenseConfirmed,
        dispensedTime: DateTime.now(),
        notes: 'Dispense confirmed by IR optical drop sensor.',
      );

      // Decrement stock count
      final medIdx = _medications.indexWhere((m) => m.id == med.id);
      if (medIdx != -1 && _medications[medIdx].stockCount > 0) {
        _medications[medIdx] = _medications[medIdx].copyWith(
          stockCount: _medications[medIdx].stockCount - 1,
        );
        await _storageService.saveMedications(_medications);
      }

      _lastDispenseMessage = 'Success: ${med.name} dispensed into tray. Please take your medicine.';
      await _storageService.saveDoseHistory(_doseHistory);
      notifyListeners();
      return true;
    } else if (response.contains('TIMEOUT') || response.contains('COMMUNICATION_LOST')) {
      // UNCERTAIN STATE: Communication lost mid-cycle. Do NOT retry blindly.
      _doseHistory[eventIdx] = _doseHistory[eventIdx].copyWith(
        status: DoseStatus.unknown,
        failureReason: response,
        notes: 'Communication lost during dispense cycle. Physical chute inspection required. Do not blindly re-dispense.',
      );
      _lastDispenseMessage = 'Safety Alert: Robot disconnected or timed out mid-cycle. Please check the tray manually before re-dispensing.';
      await _storageService.saveDoseHistory(_doseHistory);
      notifyListeners();
      return false;
    } else {
      // FAILURE / JAM / EMPTY
      _doseHistory[eventIdx] = _doseHistory[eventIdx].copyWith(
        status: DoseStatus.failed,
        failureReason: response,
        notes: 'Robot reported error during cycle: $response',
      );
      _lastDispenseMessage = 'Dispense Failed: $response. No dose released.';
      await _storageService.saveDoseHistory(_doseHistory);
      notifyListeners();
      return false;
    }
  }

  // --- Patient or Caregiver Acknowledges Taking the Dose ---
  Future<void> acknowledgeDose(String doseId) async {
    final idx = _doseHistory.indexWhere((d) => d.id == doseId);
    if (idx != -1) {
      _doseHistory[idx] = _doseHistory[idx].copyWith(
        status: DoseStatus.acknowledged,
        acknowledgedTime: DateTime.now(),
        notes: '${_doseHistory[idx].notes ?? ''} [Acknowledged by patient at tray]',
      );
      await _storageService.saveDoseHistory(_doseHistory);
      _lastDispenseMessage = 'Dose acknowledged. Recorded in caregiver timeline.';
      notifyListeners();
    }
  }

  // --- Medication CRUD ---
  Future<void> addMedication(Medication med) async {
    _medications.add(med);
    await _storageService.saveMedications(_medications);

    // Auto-populate today's scheduled dose events for this new medication
    final now = DateTime.now();
    for (final timeStr in med.scheduleTimes) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts[1]) ?? 0;
        final schedDate = DateTime(now.year, now.month, now.day, hour, minute);

        final doseId = 'dose_${med.id}_${now.year}${now.month}${now.day}_$hour$minute';
        final alreadyExists = _doseHistory.any((d) => d.id == doseId || (d.medicationId == med.id && d.scheduledTime == schedDate));
        if (!alreadyExists) {
          _doseHistory.add(DoseEvent(
            id: doseId,
            medicationId: med.id,
            medicationName: med.name,
            dosage: med.dosage,
            compartmentSlot: med.compartmentSlot,
            scheduledTime: schedDate,
            status: DoseStatus.scheduled,
          ));
        }
      }
    }
    _sortDoses();
    await _storageService.saveDoseHistory(_doseHistory);
    notifyListeners();
  }

  Future<void> updateMedication(Medication med) async {
    final idx = _medications.indexWhere((m) => m.id == med.id);
    if (idx != -1) {
      _medications[idx] = med;
      await _storageService.saveMedications(_medications);

      // Strict Safety Rule: Synchronize ONLY future pending scheduled dose events.
      // NEVER silently rewrite in-flight commands (commandSent) or executed states
      // (dispenseConfirmed, acknowledged, failed, unknown) to prevent audit-physical discrepancies.
      for (int i = 0; i < _doseHistory.length; i++) {
        if (_doseHistory[i].medicationId == med.id &&
            _doseHistory[i].status == DoseStatus.scheduled) {
          _doseHistory[i] = _doseHistory[i].copyWith(
            medicationName: med.name,
            dosage: med.dosage,
            compartmentSlot: med.compartmentSlot,
          );
        }
      }
      await _storageService.saveDoseHistory(_doseHistory);
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String medId) async {
    _medications.removeWhere((m) => m.id == medId);
    await _storageService.saveMedications(_medications);

    // Cancel and remove only pending scheduled doses so they don't corrupt adherence metrics;
    // preserve historical completed doses (acknowledged, dispenseConfirmed, failed, unknown) for clinical audit trails
    _doseHistory.removeWhere((d) =>
      d.medicationId == medId && d.status == DoseStatus.scheduled
    );
    await _storageService.saveDoseHistory(_doseHistory);
    notifyListeners();
  }
}
