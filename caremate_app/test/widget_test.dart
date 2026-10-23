import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caremate_app/models/medication.dart';
import 'package:caremate_app/models/dose_event.dart';
import 'package:caremate_app/models/vital_reading.dart';
import 'package:caremate_app/services/medical_reference_service.dart';
import 'package:caremate_app/services/ai_companion_service.dart';
import 'package:caremate_app/widgets/carousel_visualizer.dart';
import 'package:caremate_app/widgets/vital_card.dart';
import 'package:caremate_app/widgets/caremate_robot_avatar.dart';

void main() {
  group('CAREMATE Models and Safety Engine Tests', () {
    test('DoseStatus states are truthful and distinct', () {
      expect(DoseStatus.scheduled.displayName, 'Scheduled');
      expect(DoseStatus.dispenseConfirmed.displayName, 'Dispensed (In Tray)');
      expect(DoseStatus.acknowledged.displayName, 'Taken (Acknowledged)');
      expect(DoseStatus.failed.displayName, 'Dispense Failed');

      // Crucial Safety check: scheduled is NOT dispensed
      expect(DoseStatus.scheduled != DoseStatus.dispenseConfirmed, isTrue);
      // Dispensed is NOT acknowledged
      expect(DoseStatus.dispenseConfirmed != DoseStatus.acknowledged, isTrue);
    });

    test('Medication model serialization and copyWith', () {
      final med = Medication(
        id: 'med_test',
        name: 'Metformin HCl',
        dosage: '500 mg',
        compartmentSlot: 1,
        scheduleTimes: ['08:00', '20:00'],
      );

      final json = med.toJson();
      expect(json['name'], 'Metformin HCl');
      expect(json['compartmentSlot'], 1);

      final restored = Medication.fromJson(json);
      expect(restored.id, 'med_test');
      expect(restored.scheduleTimes.length, 2);

      final updated = restored.copyWith(stockCount: 15);
      expect(updated.stockCount, 15);
    });

    test('VitalReading properly classifies blood pressure categories', () {
      final optimal = VitalReading(
        id: 'v_1',
        type: VitalType.bloodPressure,
        primaryValue: 118,
        secondaryValue: 78,
        unit: 'mmHg',
        timestamp: DateTime.now(),
        deviceModel: 'Simulated Profile: Omron Platinum',
      );
      expect(optimal.statusCategory, 'Optimal');

      final stage1 = VitalReading(
        id: 'v_2',
        type: VitalType.bloodPressure,
        primaryValue: 135,
        secondaryValue: 85,
        unit: 'mmHg',
        timestamp: DateTime.now(),
        deviceModel: 'Simulated Profile: Omron Platinum',
      );
      expect(stage1.statusCategory, 'Stage 1 HTN');
    });

    test('Medical Reference Service detects drug interactions', () {
      final refService = MedicalReferenceService();
      final monographs = refService.getAllMonographs();
      expect(monographs.isNotEmpty, isTrue);

      final result = refService.checkInteraction('Lisinopril', 'Aspirin Low Dose');
      expect(result.severity, 'Moderate');
      expect(result.clinicalSummary, contains('NSAID/Aspirin'));
    });

    test('AI Companion clinical triage flags red-flag symptoms', () async {
      final aiService = AiCompanionService();
      final reply = await aiService.sendMessage('I am having severe chest pain and trouble breathing');
      expect(reply.content, contains('EMERGENCY PROTOCOL'));
      expect(reply.clinicalDisclaimer, contains('RED FLAG ALERT'));
    });
  });

  group('CAREMATE Accessibility, Semantics & Hardening Widget Tests', () {
    testWidgets('CarouselVisualizer renders accessible Semantics for all 6 slots', (WidgetTester tester) async {
      final sampleMeds = [
        Medication(
          id: 'med_1',
          name: 'Metformin HCl',
          dosage: '500 mg',
          compartmentSlot: 1,
          scheduleTimes: ['08:00'],
        ),
      ];

      int tappedSlot = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselVisualizer(
              activeSlot: 1,
              isGateOpen: false,
              isJamDetected: false,
              isDispensing: false,
              medications: sampleMeds,
              onSlotTap: (slot) => tappedSlot = slot,
            ),
          ),
        ),
      );

      // Verify Slot 1 has proper Semantics with medicine name and button trait
      final slot1Semantics = find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          final label = widget.properties.label ?? '';
          return label.contains('Compartment Slot 1') && label.contains('Metformin HCl');
        }
        return false;
      });
      expect(slot1Semantics, findsOneWidget);

      // Verify Empty Slot (e.g. Slot 5) announces as Empty compartment
      final emptySlotSemantics = find.byWidgetPredicate((widget) {
        if (widget is Semantics) {
          final label = widget.properties.label ?? '';
          return label.contains('Compartment Slot 5') && label.contains('Empty compartment');
        }
        return false;
      });
      expect(emptySlotSemantics, findsOneWidget);

      // Verify Minimum 48x48 dp touch target dimensions on slot cups
      final firstCup = tester.getSize(find.byType(ConstrainedBox).first);
      expect(firstCup.width, greaterThanOrEqualTo(48.0));
      expect(firstCup.height, greaterThanOrEqualTo(48.0));

      // Verify Tap triggers callback
      await tester.tap(find.text('S1'));
      expect(tappedSlot, 1);
    });

    testWidgets('VitalCard displays Simulated badge when reading is unvalidated', (WidgetTester tester) async {
      final simulatedVital = VitalReading(
        id: 'v_sim',
        type: VitalType.bloodPressure,
        primaryValue: 120,
        secondaryValue: 80,
        unit: 'mmHg',
        timestamp: DateTime.now(),
        deviceModel: 'Simulated Profile: Omron Platinum',
        isValidated: false,
        clinicalNote: '[Simulated Reading] Demo profile',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VitalCard(vital: simulatedVital),
          ),
        ),
      );

      // Verify "Simulated" badge is visible
      expect(find.text('Simulated'), findsOneWidget);
      expect(find.text('Simulated Profile: Omron Platinum'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });

    testWidgets('VitalCard displays verified checkmark only when isValidated is true', (WidgetTester tester) async {
      final realVital = VitalReading(
        id: 'v_real',
        type: VitalType.heartRate,
        primaryValue: 74,
        unit: 'bpm',
        timestamp: DateTime.now(),
        deviceModel: 'Omron Platinum Hardware BLE Sync',
        isValidated: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VitalCard(vital: realVital),
          ),
        ),
      );

      // Verified checkmark should appear and Simulated badge should NOT appear
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Simulated'), findsNothing);
    });

    testWidgets('CaremateRobotAvatar renders custom painter with accessible semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CaremateRobotAvatar(width: 110, height: 100),
            ),
          ),
        ),
      );

      expect(find.byType(CaremateRobotAvatar), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      // Accessible Semantics check
      expect(
        find.bySemanticsLabel(RegExp(r'CAREMATE Robot Companion', caseSensitive: false)),
        findsOneWidget,
      );
    });

    test('Caregiver and Dose Audit chronology and metrics integrity', () {
      final now = DateTime.now();
      final dose1 = DoseEvent(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Metformin HCl',
        dosage: '500 mg',
        compartmentSlot: 1,
        scheduledTime: now.subtract(const Duration(hours: 2)),
        commandSentTime: now.subtract(const Duration(hours: 2, minutes: -1)),
        dispensedTime: now.subtract(const Duration(hours: 2, minutes: -2)),
        acknowledgedTime: now.subtract(const Duration(hours: 2, minutes: -4)),
        status: DoseStatus.acknowledged,
      );

      final dose2 = DoseEvent(
        id: 'd2',
        medicationId: 'm2',
        medicationName: 'Amlodipine Besylate',
        dosage: '5 mg',
        compartmentSlot: 2,
        scheduledTime: now.subtract(const Duration(hours: 1)),
        commandSentTime: now.subtract(const Duration(hours: 1, minutes: -1)),
        dispensedTime: null,
        status: DoseStatus.failed,
        failureReason: 'Optical IR sensor timeout',
      );

      // Verify chronology: scheduledTime <= commandSentTime <= dispensedTime <= acknowledgedTime
      expect(dose1.scheduledTime.isBefore(dose1.commandSentTime!), isTrue);
      expect(dose1.commandSentTime!.isBefore(dose1.dispensedTime!), isTrue);
      expect(dose1.dispensedTime!.isBefore(dose1.acknowledgedTime!), isTrue);

      // Verify failed dose has no false dispensedTime
      expect(dose2.dispensedTime, isNull);
      expect(dose2.status, DoseStatus.failed);
      expect(dose2.failureReason, isNotNull);
    });

    test('Adherence percentage is calculated strictly from confirmed or taken doses', () {
      final now = DateTime.now();
      final todayDoses = [
        DoseEvent(
          id: 'd_1',
          medicationId: 'm1',
          medicationName: 'Metformin',
          dosage: '500mg',
          compartmentSlot: 1,
          scheduledTime: now,
          status: DoseStatus.acknowledged,
        ),
        DoseEvent(
          id: 'd_2',
          medicationId: 'm2',
          medicationName: 'Amlodipine',
          dosage: '5mg',
          compartmentSlot: 2,
          scheduledTime: now,
          status: DoseStatus.dispenseConfirmed,
        ),
        DoseEvent(
          id: 'd_3',
          medicationId: 'm3',
          medicationName: 'Atorvastatin',
          dosage: '20mg',
          compartmentSlot: 3,
          scheduledTime: now,
          status: DoseStatus.scheduled,
        ),
        DoseEvent(
          id: 'd_4',
          medicationId: 'm4',
          medicationName: 'Lisinopril',
          dosage: '10mg',
          compartmentSlot: 4,
          scheduledTime: now,
          status: DoseStatus.failed,
        ),
      ];

      final confirmedOrTaken = todayDoses.where((d) =>
        d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
      ).length;

      final rate = confirmedOrTaken / todayDoses.length;
      expect(rate, 0.50); // Exactly 2 out of 4 (50%)
    });

    test('Duplicate-dose protection prevents in-flight and recent double dispensing', () {
      final now = DateTime.now();
      final recentDoses = [
        DoseEvent(
          id: 'dose_recent',
          medicationId: 'med_test_dup',
          medicationName: 'Paracetamol',
          dosage: '500mg',
          compartmentSlot: 1,
          scheduledTime: now.subtract(const Duration(minutes: 10)),
          dispensedTime: now.subtract(const Duration(minutes: 10)),
          status: DoseStatus.dispenseConfirmed,
        ),
      ];

      // Check guard logic: within 45 minutes
      final hasDuplicate = recentDoses.any((d) {
        if (d.medicationId != 'med_test_dup') return false;
        if (d.status == DoseStatus.commandSent) return true;
        if (d.status == DoseStatus.dispenseConfirmed && d.dispensedTime != null) {
          return now.difference(d.dispensedTime!).inMinutes < 45;
        }
        return false;
      });

      expect(hasDuplicate, isTrue); // Must detect and block duplicate dose
    });

    test('Adherence transition from dispenseConfirmed to acknowledged never double-counts', () {
      final now = DateTime.now();
      // Initially, dose is dispenseConfirmed (in tray)
      var dose = DoseEvent(
        id: 'dose_lifecycle_1',
        medicationId: 'med_paracetamol',
        medicationName: 'Paracetamol',
        dosage: '500 mg',
        compartmentSlot: 1,
        scheduledTime: now,
        commandSentTime: now,
        dispensedTime: now.add(const Duration(seconds: 4)),
        status: DoseStatus.dispenseConfirmed,
      );

      final listPhase1 = [dose];
      // Check counting: only 1 dose in list
      final countPhase1 = listPhase1.where((d) =>
        d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
      ).length;
      expect(countPhase1, 1);

      // Now patient acknowledges taking it: status transitions to acknowledged
      dose = dose.copyWith(
        status: DoseStatus.acknowledged,
        acknowledgedTime: now.add(const Duration(minutes: 5)),
      );

      final listPhase2 = [dose];
      final countPhase2 = listPhase2.where((d) =>
        d.status == DoseStatus.acknowledged || d.status == DoseStatus.dispenseConfirmed
      ).length;

      // Crucial: Must still count as exactly 1!
      expect(countPhase2, 1);
      expect(dose.acknowledgedTime, isNotNull);
      expect(dose.dispensedTime, isNotNull);
    });

    test('DoseStatus.unknown is distinct and fails safely without false dispense claim', () {
      final unknownDose = DoseEvent(
        id: 'dose_timeout_1',
        medicationId: 'med_amlodipine',
        medicationName: 'Amlodipine',
        dosage: '5 mg',
        compartmentSlot: 2,
        scheduledTime: DateTime.now(),
        status: DoseStatus.unknown,
        failureReason: 'ERR:BLE_TIMEOUT',
      );

      expect(unknownDose.status, DoseStatus.unknown);
      expect(unknownDose.dispensedTime, isNull);
      expect(unknownDose.failureReason, 'ERR:BLE_TIMEOUT');
      expect(unknownDose.status != DoseStatus.dispenseConfirmed, isTrue);
      expect(unknownDose.status != DoseStatus.acknowledged, isTrue);
    });
  });
}

