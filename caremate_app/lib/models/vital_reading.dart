enum VitalType {
  bloodPressure,
  heartRate,
  oxygenSaturation,
  bloodGlucose,
}

class VitalReading {
  final String id;
  final VitalType type;
  final double primaryValue; // systolic for BP, bpm for HR, % for SpO2, mg/dL for glucose
  final double? secondaryValue; // diastolic for BP
  final String unit;
  final DateTime timestamp;
  final String deviceModel;
  final bool isValidated;
  final String? clinicalNote;

  VitalReading({
    required this.id,
    required this.type,
    required this.primaryValue,
    this.secondaryValue,
    required this.unit,
    required this.timestamp,
    required this.deviceModel,
    this.isValidated = true,
    this.clinicalNote,
  });

  String get formattedValue {
    switch (type) {
      case VitalType.bloodPressure:
        return '${primaryValue.toInt()}/${secondaryValue?.toInt() ?? 0} $unit';
      case VitalType.heartRate:
        return '${primaryValue.toInt()} $unit';
      case VitalType.oxygenSaturation:
        return '${primaryValue.toInt()} $unit';
      case VitalType.bloodGlucose:
        return '${primaryValue.toInt()} $unit';
    }
  }

  String get statusCategory {
    switch (type) {
      case VitalType.bloodPressure:
        if (primaryValue < 120 && (secondaryValue ?? 80) < 80) return 'Optimal';
        if (primaryValue <= 129 && (secondaryValue ?? 80) < 80) return 'Elevated';
        if (primaryValue <= 139 || (secondaryValue ?? 80) <= 89) return 'Stage 1 HTN';
        return 'Stage 2 HTN';
      case VitalType.heartRate:
        if (primaryValue < 60) return 'Bradycardia';
        if (primaryValue <= 100) return 'Normal';
        return 'Tachycardia';
      case VitalType.oxygenSaturation:
        if (primaryValue >= 95) return 'Normal';
        return 'Low SpO2';
      case VitalType.bloodGlucose:
        if (primaryValue < 70) return 'Low';
        if (primaryValue <= 140) return 'Normal Fasting';
        return 'Elevated';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'primaryValue': primaryValue,
    'secondaryValue': secondaryValue,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'deviceModel': deviceModel,
    'isValidated': isValidated,
    'clinicalNote': clinicalNote,
  };

  factory VitalReading.fromJson(Map<String, dynamic> json) => VitalReading(
    id: json['id'] as String,
    type: VitalType.values.firstWhere((e) => e.name == json['type']),
    primaryValue: (json['primaryValue'] as num).toDouble(),
    secondaryValue: (json['secondaryValue'] as num?)?.toDouble(),
    unit: json['unit'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    deviceModel: json['deviceModel'] as String,
    isValidated: json['isValidated'] as bool? ?? true,
    clinicalNote: json['clinicalNote'] as String?,
  );
}
