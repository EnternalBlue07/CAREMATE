enum DoseStatus {
  scheduled,           // Dose is planned for a specific time
  commandSent,         // App has transmitted DISPENSE_SLOT command to robot over BLE
  dispenseConfirmed,   // ESP32 IR drop sensor physically confirmed tablet released to tray
  acknowledged,        // Patient or caregiver confirmed taking the tablet from tray
  failed,              // Dispense jammed, empty slot, or BLE disconnect during cycle
  unknown,             // State uncertain (e.g. communication lost mid-cycle)
}

extension DoseStatusExtension on DoseStatus {
  String get displayName {
    switch (this) {
      case DoseStatus.scheduled:
        return 'Scheduled';
      case DoseStatus.commandSent:
        return 'Command Sent';
      case DoseStatus.dispenseConfirmed:
        return 'Dispensed (In Tray)';
      case DoseStatus.acknowledged:
        return 'Taken (Acknowledged)';
      case DoseStatus.failed:
        return 'Dispense Failed';
      case DoseStatus.unknown:
        return 'Status Unknown';
    }
  }

  String get description {
    switch (this) {
      case DoseStatus.scheduled:
        return 'Pending scheduled time';
      case DoseStatus.commandSent:
        return 'Robot command transmitted via BLE';
      case DoseStatus.dispenseConfirmed:
        return 'Tablet drop detected by optical sensor. Waiting for patient to consume.';
      case DoseStatus.acknowledged:
        return 'Patient confirmed medicine taken.';
      case DoseStatus.failed:
        return 'Hardware reported jam or sensor timeout. Dose not confirmed.';
      case DoseStatus.unknown:
        return 'Connection lost during cycle. Physical check required.';
    }
  }
}

class DoseEvent {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final int compartmentSlot;
  final DateTime scheduledTime;
  final DateTime? commandSentTime;
  final DateTime? dispensedTime;
  final DateTime? acknowledgedTime;
  final DoseStatus status;
  final String? failureReason;
  final String? notes;

  DoseEvent({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.compartmentSlot,
    required this.scheduledTime,
    this.commandSentTime,
    this.dispensedTime,
    this.acknowledgedTime,
    this.status = DoseStatus.scheduled,
    this.failureReason,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'medicationName': medicationName,
    'dosage': dosage,
    'compartmentSlot': compartmentSlot,
    'scheduledTime': scheduledTime.toIso8601String(),
    'commandSentTime': commandSentTime?.toIso8601String(),
    'dispensedTime': dispensedTime?.toIso8601String(),
    'acknowledgedTime': acknowledgedTime?.toIso8601String(),
    'status': status.name,
    'failureReason': failureReason,
    'notes': notes,
  };

  factory DoseEvent.fromJson(Map<String, dynamic> json) => DoseEvent(
    id: json['id'] as String,
    medicationId: json['medicationId'] as String,
    medicationName: json['medicationName'] as String,
    dosage: json['dosage'] as String,
    compartmentSlot: json['compartmentSlot'] as int,
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
    commandSentTime: json['commandSentTime'] != null ? DateTime.parse(json['commandSentTime'] as String) : null,
    dispensedTime: json['dispensedTime'] != null ? DateTime.parse(json['dispensedTime'] as String) : null,
    acknowledgedTime: json['acknowledgedTime'] != null ? DateTime.parse(json['acknowledgedTime'] as String) : null,
    status: DoseStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => DoseStatus.unknown),
    failureReason: json['failureReason'] as String?,
    notes: json['notes'] as String?,
  );

  DoseEvent copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? dosage,
    int? compartmentSlot,
    DateTime? scheduledTime,
    DateTime? commandSentTime,
    DateTime? dispensedTime,
    DateTime? acknowledgedTime,
    DoseStatus? status,
    String? failureReason,
    String? notes,
  }) {
    return DoseEvent(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      compartmentSlot: compartmentSlot ?? this.compartmentSlot,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      commandSentTime: commandSentTime ?? this.commandSentTime,
      dispensedTime: dispensedTime ?? this.dispensedTime,
      acknowledgedTime: acknowledgedTime ?? this.acknowledgedTime,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      notes: notes ?? this.notes,
    );
  }
}
