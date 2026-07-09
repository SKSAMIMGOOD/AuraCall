class Voicemail {
  final String id;
  final String callerName;
  final String phoneNumber;
  final DateTime timestamp;
  final String audioUrl;
  final int durationSeconds;
  final String transcript;
  final String aiSummary;
  final bool isRead;

  Voicemail({
    required this.id,
    required this.callerName,
    required this.phoneNumber,
    required this.timestamp,
    this.audioUrl = '',
    required this.durationSeconds,
    this.transcript = '',
    this.aiSummary = '',
    this.isRead = false,
  });

  Voicemail copyWith({
    String? id,
    String? callerName,
    String? phoneNumber,
    DateTime? timestamp,
    String? audioUrl,
    int? durationSeconds,
    String? transcript,
    String? aiSummary,
    bool? isRead,
  }) {
    return Voicemail(
      id: id ?? this.id,
      callerName: callerName ?? this.callerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timestamp: timestamp ?? this.timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transcript: transcript ?? this.transcript,
      aiSummary: aiSummary ?? this.aiSummary,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerName': callerName,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'transcript': transcript,
      'aiSummary': aiSummary,
      'isRead': isRead ? 1 : 0,
    };
  }

  factory Voicemail.fromMap(Map<dynamic, dynamic> map) {
    return Voicemail(
      id: map['id'] ?? '',
      callerName: map['callerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      audioUrl: map['audioUrl'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      transcript: map['transcript'] ?? '',
      aiSummary: map['aiSummary'] ?? '',
      isRead: (map['isRead'] == 1 || map['isRead'] == true),
    );
  }
}
