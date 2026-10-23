import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../models/dose_event.dart';
import '../models/vital_reading.dart';
import '../models/caregiver_alert.dart';

class StorageService {
  static const String _keyMeds = 'caremate_medications';
  static const String _keyDoses = 'caremate_dose_history';
  static const String _keyVitals = 'caremate_vitals';
  static const String _keyAlerts = 'caremate_alerts';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfEmpty();
    return service;
  }

  // --- Seed Initial Realistic Data for Demonstration ---
  Future<void> _seedInitialDataIfEmpty() async {
    if (!_prefs.containsKey(_keyMeds)) {
      final initialMeds = [
        Medication(
          id: 'med_1',
          name: 'Metformin HCl',
          genericName: 'Metformin',
          dosage: '500 mg',
          unit: 'tablet',
          compartmentSlot: 1,
          scheduleTimes: ['08:00', '20:00'],
          instructions: 'Take with or right after meal to avoid stomach upset',
          stockCount: 28,
          rxVerified: true,
          purpose: 'Type 2 Diabetes Blood Sugar Control',
          active: true,
        ),
        Medication(
          id: 'med_2',
          name: 'Amlodipine Besylate',
          genericName: 'Amlodipine',
          dosage: '5 mg',
          unit: 'tablet',
          compartmentSlot: 2,
          scheduleTimes: ['09:00'],
          instructions: 'Take at the same time each morning. May take with or without food.',
          stockCount: 14,
          rxVerified: true,
          purpose: 'Hypertension (Blood Pressure)',
          active: true,
        ),
        Medication(
          id: 'med_3',
          name: 'Atorvastatin Calcium',
          genericName: 'Atorvastatin',
          dosage: '20 mg',
          unit: 'tablet',
          compartmentSlot: 3,
          scheduleTimes: ['21:00'],
          instructions: 'Take at night. Avoid grapefruit or grapefruit juice.',
          stockCount: 22,
          rxVerified: true,
          purpose: 'Hyperlipidemia / Cholesterol',
          active: true,
        ),
        Medication(
          id: 'med_4',
          name: 'Aspirin Low Dose',
          genericName: 'Acetylsalicylic Acid',
          dosage: '81 mg',
          unit: 'tablet',
          compartmentSlot: 4,
          scheduleTimes: ['08:30'],
          instructions: 'Take with a full glass of water with morning breakfast.',
          stockCount: 45,
          rxVerified: true,
          purpose: 'Cardiovascular Protection',
          active: true,
        ),
      ];
      await saveMedications(initialMeds);

      // Seed realistic initial dose events for today
      final now = DateTime.now();
      final today8am = DateTime(now.year, now.month, now.day, 8, 0);
      final today830am = DateTime(now.year, now.month, now.day, 8, 30);
      final today9am = DateTime(now.year, now.month, now.day, 9, 0);
      final today8pm = DateTime(now.year, now.month, now.day, 20, 0);
      final today9pm = DateTime(now.year, now.month, now.day, 21, 0);

      final initialDoses = [
        DoseEvent(
          id: 'dose_1',
          medicationId: 'med_1',
          medicationName: 'Metformin HCl',
          dosage: '500 mg',
          compartmentSlot: 1,
          scheduledTime: today8am,
          commandSentTime: today8am.add(const Duration(minutes: 1)),
          dispensedTime: today8am.add(const Duration(minutes: 1, seconds: 4)),
          acknowledgedTime: today8am.add(const Duration(minutes: 6)),
          status: DoseStatus.acknowledged,
          notes: 'Dispensed smoothly. Patient confirmed with breakfast.',
        ),
        DoseEvent(
          id: 'dose_2',
          medicationId: 'med_4',
          medicationName: 'Aspirin Low Dose',
          dosage: '81 mg',
          compartmentSlot: 4,
          scheduledTime: today830am,
          commandSentTime: today830am.add(const Duration(seconds: 30)),
          dispensedTime: today830am.add(const Duration(seconds: 34)),
          acknowledgedTime: today830am.add(const Duration(minutes: 4)),
          status: DoseStatus.acknowledged,
          notes: 'Dose taken on schedule.',
        ),
        DoseEvent(
          id: 'dose_3',
          medicationId: 'med_2',
          medicationName: 'Amlodipine Besylate',
          dosage: '5 mg',
          compartmentSlot: 2,
          scheduledTime: today9am,
          commandSentTime: today9am,
          dispensedTime: today9am.add(const Duration(seconds: 6)),
          status: DoseStatus.dispenseConfirmed,
          notes: 'Pill released in tray. Optical drop confirmed. Awaiting patient acknowledgment.',
        ),
        DoseEvent(
          id: 'dose_4',
          medicationId: 'med_1',
          medicationName: 'Metformin HCl',
          dosage: '500 mg',
          compartmentSlot: 1,
          scheduledTime: today8pm,
          status: DoseStatus.scheduled,
        ),
        DoseEvent(
          id: 'dose_5',
          medicationId: 'med_3',
          medicationName: 'Atorvastatin Calcium',
          dosage: '20 mg',
          compartmentSlot: 3,
          scheduledTime: today9pm,
          status: DoseStatus.scheduled,
        ),
      ];
      await saveDoseHistory(initialDoses);

      // Seed initial sample vitals (Clearly marked as simulated demo profiles)
      final initialVitals = [
        VitalReading(
          id: 'v_1',
          type: VitalType.bloodPressure,
          primaryValue: 124,
          secondaryValue: 82,
          unit: 'mmHg',
          timestamp: now.subtract(const Duration(hours: 3)),
          deviceModel: 'Simulated Profile: Omron Platinum',
          isValidated: false,
          clinicalNote: '[Simulated Reading] Sitting position, 5 min rest. Physical BLE GATT hardware sync pending bench validation.',
        ),
        VitalReading(
          id: 'v_2',
          type: VitalType.heartRate,
          primaryValue: 72,
          unit: 'bpm',
          timestamp: now.subtract(const Duration(hours: 3)),
          deviceModel: 'Simulated Profile: Omron Platinum',
          isValidated: false,
          clinicalNote: '[Simulated Reading] Resting pulse profile.',
        ),
        VitalReading(
          id: 'v_3',
          type: VitalType.oxygenSaturation,
          primaryValue: 98,
          unit: '%',
          timestamp: now.subtract(const Duration(hours: 1)),
          deviceModel: 'Simulated Profile: Masimo MightySat',
          isValidated: false,
          clinicalNote: '[Simulated Reading] Ambient room air pulse oximetry.',
        ),
        VitalReading(
          id: 'v_4',
          type: VitalType.bloodGlucose,
          primaryValue: 118,
          unit: 'mg/dL',
          timestamp: today8am.subtract(const Duration(minutes: 15)),
          deviceModel: 'Simulated Profile: Contour Next Gen',
          isValidated: false,
          clinicalNote: '[Simulated Reading] Fasting morning glucose profile prior to Metformin dose.',
        ),
      ];
      await saveVitals(initialVitals);

      // Seed initial alerts
      final initialAlerts = [
        CaregiverAlert(
          id: 'alt_1',
          severity: AlertSeverity.info,
          title: 'Morning Dose Acknowledged',
          message: 'Metformin HCl 500mg taken and confirmed by patient at 08:06 AM.',
          timestamp: today8am.add(const Duration(minutes: 6)),
          isAcknowledged: true,
          relatedMedication: 'Metformin HCl',
        ),
        CaregiverAlert(
          id: 'alt_2',
          severity: AlertSeverity.warning,
          title: 'Pending Pill In Tray',
          message: 'Amlodipine Besylate 5mg was dispensed at 09:00 AM. Patient has not yet removed it from tray.',
          timestamp: today9am.add(const Duration(minutes: 25)),
          isAcknowledged: false,
          relatedMedication: 'Amlodipine Besylate',
          actionNeeded: 'Check with patient or robot tray to ensure dose consumption.',
        ),
      ];
      await saveAlerts(initialAlerts);
    }
  }

  // --- Medications ---
  Future<List<Medication>> loadMedications() async {
    final str = _prefs.getString(_keyMeds);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => Medication.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMedications(List<Medication> meds) async {
    final jsonList = meds.map((m) => m.toJson()).toList();
    await _prefs.setString(_keyMeds, jsonEncode(jsonList));
  }

  // --- Dose History ---
  Future<List<DoseEvent>> loadDoseHistory() async {
    final str = _prefs.getString(_keyDoses);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => DoseEvent.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDoseHistory(List<DoseEvent> doses) async {
    final jsonList = doses.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyDoses, jsonEncode(jsonList));
  }

  // --- Vitals ---
  Future<List<VitalReading>> loadVitals() async {
    final str = _prefs.getString(_keyVitals);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => VitalReading.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveVitals(List<VitalReading> vitals) async {
    final jsonList = vitals.map((v) => v.toJson()).toList();
    await _prefs.setString(_keyVitals, jsonEncode(jsonList));
  }

  // --- Caregiver Alerts ---
  Future<List<CaregiverAlert>> loadAlerts() async {
    final str = _prefs.getString(_keyAlerts);
    if (str == null) return [];
    try {
      final List list = jsonDecode(str);
      return list.map((item) => CaregiverAlert.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAlerts(List<CaregiverAlert> alerts) async {
    final jsonList = alerts.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyAlerts, jsonEncode(jsonList));
  }
}
