class Medication {
  final String id;
  final String name;
  final String genericName;
  final String dosage; // e.g. "500 mg"
  final String unit; // "tablet", "capsule", "drop"
  final int compartmentSlot; // 1 to 6
  final List<String> scheduleTimes; // ["08:00", "20:00"]
  final String instructions; // "Take with food", "Empty stomach"
  final int stockCount;
  final bool rxVerified;
  final String purpose;
  final bool active;

  Medication({
    required this.id,
    required this.name,
    this.genericName = '',
    required this.dosage,
    this.unit = 'tablet',
    required this.compartmentSlot,
    required this.scheduleTimes,
    this.instructions = 'Take with water',
    this.stockCount = 30,
    this.rxVerified = true,
    this.purpose = 'Maintenance therapy',
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genericName': genericName,
    'dosage': dosage,
    'unit': unit,
    'compartmentSlot': compartmentSlot,
    'scheduleTimes': scheduleTimes,
    'instructions': instructions,
    'stockCount': stockCount,
    'rxVerified': rxVerified,
    'purpose': purpose,
    'active': active,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    genericName: json['genericName'] as String? ?? '',
    dosage: json['dosage'] as String,
    unit: json['unit'] as String? ?? 'tablet',
    compartmentSlot: json['compartmentSlot'] as int,
    scheduleTimes: List<String>.from(json['scheduleTimes'] as List),
    instructions: json['instructions'] as String? ?? 'Take with water',
    stockCount: json['stockCount'] as int? ?? 0,
    rxVerified: json['rxVerified'] as bool? ?? false,
    purpose: json['purpose'] as String? ?? '',
    active: json['active'] as bool? ?? true,
  );

  Medication copyWith({
    String? id,
    String? name,
    String? genericName,
    String? dosage,
    String? unit,
    int? compartmentSlot,
    List<String>? scheduleTimes,
    String? instructions,
    int? stockCount,
    bool? rxVerified,
    String? purpose,
    bool? active,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      compartmentSlot: compartmentSlot ?? this.compartmentSlot,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      instructions: instructions ?? this.instructions,
      stockCount: stockCount ?? this.stockCount,
      rxVerified: rxVerified ?? this.rxVerified,
      purpose: purpose ?? this.purpose,
      active: active ?? this.active,
    );
  }
}
