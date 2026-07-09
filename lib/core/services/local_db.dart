import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact_model.dart';
import '../models/call_log_model.dart';
import '../models/voicemail_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  late Box _contactsBox;
  late Box _logsBox;
  late Box _voicemailsBox;
  late Box _settingsBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    
    _contactsBox = await Hive.openBox('contacts');
    _logsBox = await Hive.openBox('call_logs');
    _voicemailsBox = await Hive.openBox('voicemails');
    _settingsBox = await Hive.openBox('settings');

    _isInitialized = true;
    
    if (_contactsBox.isEmpty && _logsBox.isEmpty) {
      await _seedMockData();
    }
  }

  // Settings helpers
  bool get isBiometricsEnabled => _settingsBox.get('biometrics_enabled', defaultValue: false);
  Future<void> setBiometricsEnabled(bool value) async => await _settingsBox.put('biometrics_enabled', value);

  String get geminiApiKey => _settingsBox.get('gemini_api_key', defaultValue: '');
  Future<void> setGeminiApiKey(String value) async => await _settingsBox.put('gemini_api_key', value);

  bool get isDarkMode => _settingsBox.get('dark_mode', defaultValue: true);
  Future<void> setDarkMode(bool value) async => await _settingsBox.put('dark_mode', value);

  String get activeAccentColor => _settingsBox.get('accent_color', defaultValue: 'blue');
  Future<void> setActiveAccentColor(String color) async => await _settingsBox.put('accent_color', color);

  // Contacts operations
  List<Contact> getContacts() {
    return _contactsBox.values.map((e) => Contact.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveContact(Contact contact) async {
    await _contactsBox.put(contact.id, contact.toMap());
  }

  Future<void> deleteContact(String id) async {
    await _contactsBox.delete(id);
  }

  // Call Logs operations
  List<CallLog> getCallLogs() {
    final logs = _logsBox.values.map((e) => CallLog.fromMap(Map<String, dynamic>.from(e))).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<void> saveCallLog(CallLog log) async {
    await _logsBox.put(log.id, log.toMap());
  }

  Future<void> clearCallLogs() async {
    await _logsBox.clear();
  }

  // Voicemail operations
  List<Voicemail> getVoicemails() {
    final voicemails = _voicemailsBox.values.map((e) => Voicemail.fromMap(Map<String, dynamic>.from(e))).toList();
    voicemails.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return voicemails;
  }

  Future<void> saveVoicemail(Voicemail voicemail) async {
    await _voicemailsBox.put(voicemail.id, voicemail.toMap());
  }

  Future<void> deleteVoicemail(String id) async {
    await _voicemailsBox.delete(id);
  }

  // Mock Seeding
  Future<void> _seedMockData() async {
    final mockContacts = [
      Contact(
        id: '1',
        name: 'Mom',
        phoneNumber: '+91 99887 66555',
        email: 'mom@family.com',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        isFavorite: true,
        category: 'Family',
        relationship: 'Mother',
        whatsappNumber: '+91 99887 66555',
        notes: 'Call Mom on Sunday morning!',
      ),
      Contact(
        id: '2',
        name: 'Papa',
        phoneNumber: '+91 99887 55444',
        email: 'papa@family.com',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        isFavorite: true,
        category: 'Family',
        relationship: 'Father',
        whatsappNumber: '+91 99887 55444',
        notes: 'Prefers audio calls over video.',
      ),
      Contact(
        id: '3',
        name: 'Arjun Singh',
        phoneNumber: '+91 91234 56789',
        email: 'arjun.singh@office.com',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        isFavorite: true,
        category: 'Business',
        relationship: 'Manager',
        telegramUsername: 'arjunsingh_manager',
        notes: 'Office project details discussions.',
      ),
      Contact(
        id: '4',
        name: 'Riya Sharma',
        phoneNumber: '+91 91234 56700',
        email: 'riya@friends.com',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        isFavorite: false,
        category: 'Family', // Or Friend
        relationship: 'Sister',
        instagramUsername: 'riya_sharma_ig',
      ),
      Contact(
        id: '5',
        name: 'Amit Kumar',
        phoneNumber: '+91 76799 06467',
        email: 'amit.kumar@tech.com',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        isFavorite: false,
        category: 'Frequently Called',
        relationship: 'Colleague',
        whatsappNumber: '+91 76799 06467',
      ),
      Contact(
        id: '6',
        name: 'Bhavna Joshi',
        phoneNumber: '+91 88990 12345',
        email: 'bhavna.j@consulting.com',
        avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        isFavorite: false,
        category: 'Business',
        relationship: 'Client',
      ),
    ];

    for (var contact in mockContacts) {
      await saveContact(contact);
    }

    final mockLogs = [
      CallLog(
        id: 'l1',
        callerName: 'Mom',
        phoneNumber: '+91 99887 66555',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        durationSeconds: 145,
        callType: 'Incoming',
        aiSummary: 'Discussed family dinner plans for Sunday and confirmed returning home early.',
      ),
      CallLog(
        id: 'l2',
        callerName: 'Amit Kumar',
        phoneNumber: '+91 76799 06467',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        durationSeconds: 0,
        callType: 'Missed',
      ),
      CallLog(
        id: 'l3',
        callerName: 'Spam Telemarketer',
        phoneNumber: '+91 14009 87654',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        durationSeconds: 0,
        callType: 'Spam',
        isSpam: true,
        spamScore: 89,
        spamReason: 'Reported by 142 users as robotized financial service loans offer.',
      ),
      CallLog(
        id: 'l4',
        callerName: 'Papa',
        phoneNumber: '+91 99887 55444',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 320,
        callType: 'Outgoing',
        aiSummary: 'Updated father about the health checkup reports and medicines delivery.',
      ),
      CallLog(
        id: 'l5',
        callerName: 'Arjun Singh',
        phoneNumber: '+91 91234 56789',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        durationSeconds: 412,
        callType: 'Incoming',
        aiSummary: 'Reviewed the UI sprint designs. Scheduled a follow-up review for Monday morning.',
      ),
    ];

    for (var log in mockLogs) {
      await saveCallLog(log);
    }

    final mockVoicemails = [
      Voicemail(
        id: 'v1',
        callerName: 'Amit Kumar',
        phoneNumber: '+91 76799 06467',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        durationSeconds: 45,
        transcript: 'Hey! I tried calling you. I wanted to check if you finalized the Figma mockup for the new app. Let me know when you are free, or just text me. Thanks!',
        aiSummary: 'Amit is asking about the finalization of the Figma app design mockup and requests a call back or text response.',
        isRead: false,
      ),
      Voicemail(
        id: 'v2',
        callerName: 'Bhavna Joshi',
        phoneNumber: '+91 88990 12345',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        durationSeconds: 22,
        transcript: 'Hello, Bhavna here. Our meeting timing needs to be pushed to 5:30 PM due to client traffic. See you then.',
        aiSummary: 'Bhavna requested to reschedule the meeting time to 5:30 PM due to traffic delays.',
        isRead: true,
      ),
    ];

    for (var voicemail in mockVoicemails) {
      await saveVoicemail(voicemail);
    }
  }
}
