import '../models/ai_companion_message.dart';

class AiCompanionService {
  final List<AiCompanionMessage> _history = [];

  List<AiCompanionMessage> get history => List.unmodifiable(_history);

  AiCompanionService() {
    _history.add(AiCompanionMessage(
      id: 'msg_welcome',
      sender: 'caremate',
      content: 'Hello! I am your CAREMATE Health Companion. I can help you understand your medicine schedule, explain how to take your tablets, or check for food warnings. How are you feeling today?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      clinicalDisclaimer: 'CAREMATE is an assistive companion, not a replacement for medical diagnosis. In an emergency, contact emergency medical services immediately.',
      referenceSources: ['CAREMATE Clinical Engine', 'Authorized Medical Reference'],
      quickFollowUps: [
        'How should I take Metformin?',
        'Can I take Amlodipine with food?',
        'Why does Atorvastatin say avoid grapefruit?',
        'Robot me dawa kaise check karein?',
      ],
    ));
  }

  Future<AiCompanionMessage> sendMessage(String userText) async {
    // Add user message to history
    final userMsg = AiCompanionMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      content: userText,
      timestamp: DateTime.now(),
    );
    _history.add(userMsg);

    // Simulate clinical reasoning delay
    await Future.delayed(const Duration(milliseconds: 700));

    final reply = _generateClinicalResponse(userText);
    _history.add(reply);
    return reply;
  }

  AiCompanionMessage _generateClinicalResponse(String input) {
    final text = input.toLowerCase();
    final now = DateTime.now();
    final msgId = 'msg_${now.millisecondsSinceEpoch}_bot';

    // 1. Critical Red-Flag Emergency Triage
    if (text.contains('chest pain') ||
        text.contains('breathing') ||
        text.contains('short of breath') ||
        text.contains('seene me dard') ||
        text.contains('stroke') ||
        text.contains('paralysis') ||
        text.contains('faint')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'EMERGENCY PROTOCOL: You have mentioned symptoms that may indicate an urgent medical event. Please do not wait. Call 112 / 911 or your local emergency number immediately. Inform your emergency caregiver now.',
        timestamp: now,
        clinicalDisclaimer: 'RED FLAG ALERT: Immediate professional medical intervention is required.',
        referenceSources: ['AHA/ACC Emergency Triage Guidelines'],
        quickFollowUps: ['Call Emergency Contact', 'Alert Caregiver', 'View Vitals'],
      );
    }

    // 2. Metformin Guidance
    if (text.contains('metformin')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'Metformin HCl (500mg) is prescribed for blood sugar management. Key advice:\n\n• Always take it WITH or immediately after a meal to prevent stomach upset or nausea.\n• Do not crush extended-release tablets.\n• Stay well hydrated throughout the day.\n• In your CAREMATE robot, this is located in Compartment Slot 1 for 08:00 AM & 08:00 PM.',
        timestamp: now,
        clinicalDisclaimer: 'Consult your prescribing doctor if you experience persistent nausea or muscle aches.',
        referenceSources: ['Medscape Drug Reference: Metformin', 'FDA Package Insert'],
        quickFollowUps: ['What if I miss a Metformin dose?', 'Check Slot 1 Status'],
      );
    }

    // 3. Amlodipine Guidance
    if (text.contains('amlodipine') || text.contains('bp') || text.contains('blood pressure')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'Amlodipine Besylate (5mg) relaxes blood vessels to maintain healthy blood pressure.\n\n• Can be taken with or without food, preferably at the same time each morning.\n• Avoid standing up too quickly if you feel slightly lightheaded.\n• Assigned to Compartment Slot 2 in your CAREMATE robot (09:00 AM daily).',
        timestamp: now,
        clinicalDisclaimer: 'Monitor your blood pressure regularly. Do not abruptly stop taking without doctor guidance.',
        referenceSources: ['Medscape Reference: Amlodipine', 'AHA Guidelines'],
        quickFollowUps: ['View my latest Blood Pressure', 'Dispense Amlodipine (Slot 2)'],
      );
    }

    // 4. Grapefruit / Atorvastatin Interaction
    if (text.contains('grapefruit') || text.contains('atorvastatin') || text.contains('cholesterol')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'Atorvastatin Calcium (20mg) is taken in the evening to optimize cholesterol regulation.\n\n• Grapefruit Interaction: Grapefruit juice inhibits the liver enzyme (CYP3A4) that breaks down atorvastatin. This can cause the medicine level in your bloodstream to rise too high, increasing muscle ache risk. It is best to avoid grapefruit products while on this medicine.\n• Compartment Slot: Slot 3 (21:00 / 9:00 PM).',
        timestamp: now,
        clinicalDisclaimer: 'Notify your physician if you develop unexplained muscle soreness or dark urine.',
        referenceSources: ['FDA Drug Safety Communication: Statins and Grapefruit', 'Medscape Clinical Pharmacology'],
        quickFollowUps: ['What foods are safe with statins?', 'Check Atorvastatin schedule'],
      );
    }

    // 5. Missed Dose Guidance
    if (text.contains('missed') || text.contains('bhool gaya') || text.contains('late')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'General Rule for Missed Medication:\n\n1. If you remember within 1-2 hours of the scheduled time, take it.\n2. If it is already close to your next scheduled dose, SKIP the missed dose and resume your regular schedule.\n3. NEVER take a double dose to make up for a missed pill.\n4. Check the Caregiver Dashboard to ensure your dose timeline is recorded accurately.',
        timestamp: now,
        clinicalDisclaimer: 'Specific medications have individualized missed-dose rules. Refer to your pharmacist or prescribing clinician.',
        referenceSources: ['CDC Medication Adherence Best Practices'],
        quickFollowUps: ['Schedule manual reminder', 'Contact Caregiver'],
      );
    }

    // 6. Robot / Dispensing Guidance (Hindi & English friendly)
    if (text.contains('robot') || text.contains('dispense') || text.contains('dawa kaise') || text.contains('carousel')) {
      return AiCompanionMessage(
        id: msgId,
        sender: 'caremate',
        content: 'CAREMATE Robot Assistance:\n\n• To dispense your scheduled dose, navigate to the Robot Control tab or tap "Take Medicine" on your Home dashboard.\n• The ESP32 controller will rotate the carousel to the exact compartment slot.\n• The trapdoor gate will open, and an optical IR sensor will verify the tablet fell into the tray.\n• Once you take the medicine, tap "Acknowledge" so your family/caregiver knows you took it safely.',
        timestamp: now,
        clinicalDisclaimer: 'Never force the rotating carousel manually while motors are engaged.',
        referenceSources: ['CAREMATE Hardware Safety Protocol v1.4'],
        quickFollowUps: ['Open Robot Control', 'Test Robot Buzzer', 'Calibrate Carousel'],
      );
    }

    // 7. General Friendly Healthcare Companion Reply
    return AiCompanionMessage(
      id: msgId,
      sender: 'caremate',
      content: 'I am here with you. You can ask me about any of your four active medications (Metformin, Amlodipine, Atorvastatin, Aspirin), food interactions, vital tracking, or robot dispensing commands.\n\nEverything is saved offline on your device, and your caregiver receives status updates whenever you take your scheduled doses.',
      timestamp: now,
      clinicalDisclaimer: 'CAREMATE provides educational reference information. Consult healthcare professionals for personal medical decisions.',
      referenceSources: ['CAREMATE Knowledge Base', 'Licensed Clinical References'],
      quickFollowUps: [
        'Check today\'s schedule',
        'Are my medications interacting?',
        'Test Robot Connection',
      ],
    );
  }
}
