enum AlertSeverity {
  info,
  warning,
  missedDose,
  hardwareError,
  emergency,
}

class CaregiverAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isAcknowledged;
  final String? relatedMedication;
  final String? actionNeeded;

  CaregiverAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isAcknowledged = false,
    this.relatedMedication,
    this.actionNeeded,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'severity': severity.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isAcknowledged': isAcknowledged,
    'relatedMedication': relatedMedication,
    'actionNeeded': actionNeeded,
  };

  factory CaregiverAlert.fromJson(Map<String, dynamic> json) => CaregiverAlert(
    id: json['id'] as String,
    severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
    title: json['title'] as String,
    message: json['message'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isAcknowledged: json['isAcknowledged'] as bool? ?? false,
    relatedMedication: json['relatedMedication'] as String?,
    actionNeeded: json['actionNeeded'] as String?,
  );

  CaregiverAlert copyWith({
    String? id,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isAcknowledged,
    String? relatedMedication,
    String? actionNeeded,
  }) {
    return CaregiverAlert(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      relatedMedication: relatedMedication ?? this.relatedMedication,
      actionNeeded: actionNeeded ?? this.actionNeeded,
    );
  }
}
