import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_model.dart';
import '../models/call_log_model.dart';
import '../models/voicemail_model.dart';
import '../services/local_db.dart';
import '../services/gemini_service.dart';

// Service providers
final localDbProvider = Provider<LocalDbService>((ref) => LocalDbService());
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

// Settings state
class AppSettings {
  final bool darkTheme;
  final String accentColor;
  final bool biometricsEnabled;
  final String geminiApiKey;

  AppSettings({
    required this.darkTheme,
    required this.accentColor,
    required this.biometricsEnabled,
    required this.geminiApiKey,
  });

  AppSettings copyWith({
    bool? darkTheme,
    String? accentColor,
    bool? biometricsEnabled,
    String? geminiApiKey,
  }) {
    return AppSettings(
      darkTheme: darkTheme ?? this.darkTheme,
      accentColor: accentColor ?? this.accentColor,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalDbService _db;
  SettingsNotifier(this._db) : super(AppSettings(
    darkTheme: _db.isDarkMode,
    accentColor: _db.activeAccentColor,
    biometricsEnabled: _db.isBiometricsEnabled,
    geminiApiKey: _db.geminiApiKey,
  ));

  Future<void> toggleTheme() async {
    final next = !state.darkTheme;
    await _db.setDarkMode(next);
    state = state.copyWith(darkTheme: next);
  }

  Future<void> updateAccentColor(String color) async {
    await _db.setActiveAccentColor(color);
    state = state.copyWith(accentColor: color);
  }

  Future<void> toggleBiometrics() async {
    final next = !state.biometricsEnabled;
    await _db.setBiometricsEnabled(next);
    state = state.copyWith(biometricsEnabled: next);
  }

  Future<void> saveGeminiKey(String key) async {
    await _db.setGeminiApiKey(key);
    state = state.copyWith(geminiApiKey: key);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(localDbProvider));
});

// Contacts Provider
class ContactsNotifier extends StateNotifier<List<Contact>> {
  final LocalDbService _db;
  ContactsNotifier(this._db) : super(_db.getContacts());

  Future<void> addContact(Contact contact) async {
    await _db.saveContact(contact);
    state = _db.getContacts();
  }

  Future<void> toggleFavorite(String id) async {
    final list = state.map((c) {
      if (c.id == id) {
        final updated = c.copyWith(isFavorite: !c.isFavorite);
        _db.saveContact(updated);
        return updated;
      }
      return c;
    }).toList();
    state = list;
  }

  Future<void> deleteContact(String id) async {
    await _db.deleteContact(id);
    state = _db.getContacts();
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contact>>((ref) {
  return ContactsNotifier(ref.read(localDbProvider));
});

// Logs Provider
class LogsNotifier extends StateNotifier<List<CallLog>> {
  final LocalDbService _db;
  LogsNotifier(this._db) : super(_db.getCallLogs());

  Future<void> addLog(CallLog log) async {
    await _db.saveCallLog(log);
    state = _db.getCallLogs();
  }

  Future<void> clearAll() async {
    await _db.clearCallLogs();
    state = [];
  }
}

final logsProvider = StateNotifierProvider<LogsNotifier, List<CallLog>>((ref) {
  return LogsNotifier(ref.read(localDbProvider));
});

// Voicemail Provider
class VoicemailNotifier extends StateNotifier<List<Voicemail>> {
  final LocalDbService _db;
  VoicemailNotifier(this._db) : super(_db.getVoicemails());

  Future<void> addVoicemail(Voicemail voicemail) async {
    await _db.saveVoicemail(voicemail);
    state = _db.getVoicemails();
  }

  Future<void> markRead(String id) async {
    final list = state.map((v) {
      if (v.id == id) {
        final updated = v.copyWith(isRead: true);
        _db.saveVoicemail(updated);
        return updated;
      }
      return v;
    }).toList();
    state = list;
  }

  Future<void> deleteVoicemail(String id) async {
    await _db.deleteVoicemail(id);
    state = _db.getVoicemails();
  }
}

final voicemailsProvider = StateNotifierProvider<VoicemailNotifier, List<Voicemail>>((ref) {
  return VoicemailNotifier(ref.read(localDbProvider));
});

// Calling Simulation State
enum CallStatus { idle, incoming, ringing, active, disconnected }

class CallState {
  final CallStatus status;
  final String name;
  final String number;
  final String avatarUrl;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeaker;
  final bool isRecording;
  final bool isHold;
  final int spamScore;
  final String spamReason;
  final List<String> transcript;
  final List<String> translation;

  CallState({
    this.status = CallStatus.idle,
    this.name = '',
    this.number = '',
    this.avatarUrl = '',
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeaker = false,
    this.isRecording = false,
    this.isHold = false,
    this.spamScore = 0,
    this.spamReason = '',
    this.transcript = const [],
    this.translation = const [],
  });

  CallState copyWith({
    CallStatus? status,
    String? name,
    String? number,
    String? avatarUrl,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeaker,
    bool? isRecording,
    bool? isHold,
    int? spamScore,
    String? spamReason,
    List<String>? transcript,
    List<String>? translation,
  }) {
    return CallState(
      status: status ?? this.status,
      name: name ?? this.name,
      number: number ?? this.number,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
      isRecording: isRecording ?? this.isRecording,
      isHold: isHold ?? this.isHold,
      spamScore: spamScore ?? this.spamScore,
      spamReason: spamReason ?? this.spamReason,
      transcript: transcript ?? this.transcript,
      translation: translation ?? this.translation,
    );
  }
}

class CallController extends StateNotifier<CallState> {
  final Ref _ref;
  Timer? _callTimer;
  Timer? _simulationTimer;

  CallController(this._ref) : super(CallState());

  /// Triggers a simulated incoming call. Performs spam checks automatically.
  Future<void> receiveIncomingCall(String number) async {
    final contacts = _ref.read(contactsProvider);
    final contact = contacts.firstWhere(
      (c) => c.phoneNumber.replaceAll(' ', '') == number.replaceAll(' ', ''),
      orElse: () => Contact(id: '', name: 'Unknown Caller', phoneNumber: number),
    );

    // Spam Check
    final settings = _ref.read(settingsProvider);
    final spamResult = await _ref.read(geminiServiceProvider).analyzeSpamCall(number, settings.geminiApiKey);

    state = CallState(
      status: CallStatus.incoming,
      name: contact.id.isEmpty ? 'Unknown' : contact.name,
      number: number,
      avatarUrl: contact.avatarUrl,
      spamScore: spamResult['trustScore'] != null ? (100 - (spamResult['trustScore'] as int)) : 0,
      spamReason: spamResult['reason'] ?? '',
    );
  }

  /// Triggers a simulated outgoing call. Ringing turns active after 3 seconds.
  void startOutgoingCall(String name, String number, String avatarUrl) {
    state = CallState(
      status: CallStatus.ringing,
      name: name,
      number: number,
      avatarUrl: avatarUrl,
    );

    // Simulate connecting after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (state.status == CallStatus.ringing) {
        answerCall();
      }
    });
  }

  /// Answers the call, transitions state to active, and starts transcription simulations.
  void answerCall() {
    state = state.copyWith(status: CallStatus.active, durationSeconds: 0);
    _startTimer();
    _startTranscriptionSimulation();
  }

  /// Toggles hold, mute, speaker, and recording.
  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);
  void toggleSpeaker() => state = state.copyWith(isSpeaker: !state.isSpeaker);
  void toggleHold() => state = state.copyWith(isHold: !state.isHold);
  
  void toggleRecording() {
    final next = !state.isRecording;
    state = state.copyWith(isRecording: next);
    if (next) {
      state = state.copyWith(transcript: [...state.transcript, '[Call recording started]']);
    } else {
      state = state.copyWith(transcript: [...state.transcript, '[Call recording stopped]']);
    }
  }

  /// Hangs up, adds a record to the call logs, and resets calling states.
  void hangUp({String type = 'Incoming'}) {
    _callTimer?.cancel();
    _simulationTimer?.cancel();

    final finalDuration = state.durationSeconds;
    final logId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Save to Log History
    String callType = type;
    if (state.status == CallStatus.incoming) {
      callType = 'Rejected';
    } else if (state.status == CallStatus.active) {
      callType = type == 'Outgoing' ? 'Outgoing' : 'Incoming';
    } else if (state.status == CallStatus.ringing) {
      callType = 'Cancelled';
    }

    // Mock AI summary generator
    String aiSummary = '';
    if (finalDuration > 10) {
      aiSummary = 'AI Call Summary: Call with ${state.name} lasted ${finalDuration}s. Discussed weekend plans and work timelines.';
    }

    final newLog = CallLog(
      id: logId,
      callerName: state.name,
      phoneNumber: state.number,
      timestamp: DateTime.now(),
      durationSeconds: finalDuration,
      callType: state.spamScore > 70 ? 'Spam' : callType,
      isSpam: state.spamScore > 70,
      spamScore: state.spamScore,
      spamReason: state.spamReason,
      aiSummary: aiSummary,
    );

    _ref.read(logsProvider.notifier).addLog(newLog);

    state = state.copyWith(status: CallStatus.disconnected);
    Future.delayed(const Duration(milliseconds: 800), () {
      state = CallState(status: CallStatus.idle);
    });
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  // Simulates live speech-to-text and AI translation during the active call
  void _startTranscriptionSimulation() {
    _simulationTimer?.cancel();
    final mockLines = [
      "Hello! How are you doing today?",
      "I am doing great! Did you check out the new design designs?",
      "Yes, they look fantastic! We should deploy them tomorrow.",
      "Awesome, let's schedule a meeting with Arjun at 11 AM.",
      "Sounds like a plan. Talk to you soon!",
    ];

    final translations = [
      "नमस्ते! आप आज कैसे हैं?",
      "मैं बहुत अच्छा कर रहा हूँ! क्या आपने नए डिज़ाइन देखे?",
      "हाँ, वे बहुत बढ़िया लग रहे हैं! हमें उन्हें कल तैनात करना चाहिए।",
      "बहुत बढ़िया, आइए सुबह 11 बजे अर्जुन के साथ एक बैठक तय करें।",
      "ठीक लग रहा है। जल्द ही आपसे बात होगी!",
    ];

    int index = 0;
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (index >= mockLines.length) {
        _simulationTimer?.cancel();
        return;
      }
      if (state.status == CallStatus.active && !state.isHold) {
        state = state.copyWith(
          transcript: [...state.transcript, '${state.name}: ${mockLines[index]}'],
          translation: [...state.translation, translations[index]],
        );
        index++;
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}

final callStateProvider = StateNotifierProvider<CallController, CallState>((ref) {
  return CallController(ref);
});
