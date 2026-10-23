class AiCompanionMessage {
  final String id;
  final String sender; // 'user' or 'caremate'
  final String content;
  final DateTime timestamp;
  final String? clinicalDisclaimer;
  final List<String> referenceSources; // e.g. ["Medscape Reference", "FDA Label"]
  final List<String> quickFollowUps;

  AiCompanionMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.clinicalDisclaimer,
    this.referenceSources = const [],
    this.quickFollowUps = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'clinicalDisclaimer': clinicalDisclaimer,
    'referenceSources': referenceSources,
    'quickFollowUps': quickFollowUps,
  };

  factory AiCompanionMessage.fromJson(Map<String, dynamic> json) => AiCompanionMessage(
    id: json['id'] as String,
    sender: json['sender'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    clinicalDisclaimer: json['clinicalDisclaimer'] as String?,
    referenceSources: List<String>.from(json['referenceSources'] as List? ?? []),
    quickFollowUps: List<String>.from(json['quickFollowUps'] as List? ?? []),
  );
}
