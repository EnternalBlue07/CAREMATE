import 'package:flutter/material.dart';
import '../models/caregiver_alert.dart';
import '../models/vital_reading.dart';
import '../services/storage_service.dart';

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.isPrimary = false,
  });
}

class CaregiverProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<CaregiverAlert> _alerts = [];
  List<VitalReading> _vitals = [];
  bool _isLoading = false;

  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      name: 'Dr. Sarah Verma, MD',
      relationship: 'Primary Care Physician',
      phone: '+1 (555) 349-8821',
      isPrimary: false,
    ),
    EmergencyContact(
      name: 'Priya Sharma (Daughter)',
      relationship: 'Primary Family Caregiver',
      phone: '+1 (555) 782-9904',
      isPrimary: true,
    ),
    EmergencyContact(
      name: 'Local Emergency EMS',
      relationship: 'Urgent Care & Paramedics',
      phone: '911 / 112',
      isPrimary: false,
    ),
  ];

  List<CaregiverAlert> get alerts => List.unmodifiable(_alerts);
  List<VitalReading> get vitals => List.unmodifiable(_vitals);
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);
  bool get isLoading => _isLoading;

  int get unacknowledgedAlertsCount => _alerts.where((a) => !a.isAcknowledged).length;

  CaregiverProvider(this._storageService) {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _alerts = await _storageService.loadAlerts();
      _vitals = await _storageService.loadVitals();
      _sortData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortData() {
    _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _vitals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(isAcknowledged: true);
      await _storageService.saveAlerts(_alerts);
      notifyListeners();
    }
  }

  Future<void> addAlert(CaregiverAlert alert) async {
    _alerts.insert(0, alert);
    await _storageService.saveAlerts(_alerts);
    notifyListeners();
  }

  Future<void> addVital(VitalReading vital) async {
    _vitals.insert(0, vital);
    await _storageService.saveVitals(_vitals);
    notifyListeners();
  }

  // --- Summary Metrics for Caregiver Dashboard ---
  VitalReading? get latestBloodPressure {
    try {
      return _vitals.firstWhere((v) => v.type == VitalType.bloodPressure);
    } catch (_) {
      return null;
    }
  }

  VitalReading? get latestHeartRate {
    try {
      return _vitals.firstWhere((v) => v.type == VitalType.heartRate);
    } catch (_) {
      return null;
    }
  }

  VitalReading? get latestGlucose {
    try {
      return _vitals.firstWhere((v) => v.type == VitalType.bloodGlucose);
    } catch (_) {
      return null;
    }
  }

  VitalReading? get latestSpO2 {
    try {
      return _vitals.firstWhere((v) => v.type == VitalType.oxygenSaturation);
    } catch (_) {
      return null;
    }
  }

  // --- Severity and Category Filters for Caregiver Dashboard ---
  List<CaregiverAlert> get unacknowledgedAlerts =>
      _alerts.where((a) => !a.isAcknowledged).toList();

  List<CaregiverAlert> get criticalAlerts => _alerts
      .where((a) =>
          a.severity == AlertSeverity.emergency ||
          a.severity == AlertSeverity.hardwareError ||
          a.severity == AlertSeverity.missedDose)
      .toList();

  List<CaregiverAlert> get missedDoseAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.missedDose).toList();

  List<CaregiverAlert> get hardwareAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.hardwareError).toList();
}
