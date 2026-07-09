class CallLog {
  final String id;
  final String callerName;
  final String phoneNumber;
  final DateTime timestamp;
  final int durationSeconds;
  final String callType; // Incoming, Outgoing, Missed, Rejected, Spam
  final bool isSpam;
  final int spamScore; // 0 to 100
  final String spamReason;
  final String aiSummary;

  CallLog({
    required this.id,
    required this.callerName,
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.callType,
    this.isSpam = false,
    this.spamScore = 0,
    this.spamReason = '',
    this.aiSummary = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerName': callerName,
      'phoneNumber': phoneNumber,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'callType': callType,
      'isSpam': isSpam ? 1 : 0,
      'spamScore': spamScore,
      'spamReason': spamReason,
      'aiSummary': aiSummary,
    };
  }

  factory CallLog.fromMap(Map<dynamic, dynamic> map) {
    return CallLog(
      id: map['id'] ?? '',
      callerName: map['callerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      durationSeconds: map['durationSeconds'] ?? 0,
      callType: map['callType'] ?? 'Incoming',
      isSpam: (map['isSpam'] == 1 || map['isSpam'] == true),
      spamScore: map['spamScore'] ?? 0,
      spamReason: map['spamReason'] ?? '',
      aiSummary: map['aiSummary'] ?? '',
    );
  }
}
