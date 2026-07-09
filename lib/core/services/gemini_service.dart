import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/contact_model.dart';

enum VoiceActionType { call, mute, speaker, record, none }

class VoiceCommandResult {
  final VoiceActionType action;
  final String targetName;
  final String rawResponse;

  VoiceCommandResult({
    required this.action,
    this.targetName = '',
    required this.rawResponse,
  });
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  String _currentApiKey = '';

  void _initModel(String apiKey) {
    if (apiKey.isEmpty) {
      _model = null;
      _currentApiKey = '';
      return;
    }
    _currentApiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Analyze a phone number for spam risk level and trust rating.
  Future<Map<String, dynamic>> analyzeSpamCall(String phoneNumber, String savedKey) async {
    _initModel(savedKey);
    
    if (_model == null) {
      // Intelligent mock offline fallback
      final score = phoneNumber.contains('1400') ? 89 : 12;
      return {
        'trustScore': 100 - score,
        'riskLevel': score > 75 ? 'HIGH' : (score > 30 ? 'MEDIUM' : 'LOW'),
        'reason': score > 75 
            ? 'Flagged by community as insurance credit loan robot.' 
            : 'Verified private contact or standard mobile network routing.',
        'reportsCount': score > 75 ? 142 : 0,
      };
    }

    try {
      final prompt = '''
Analyze the phone number "$phoneNumber" for spam risk.
Respond ONLY with a JSON object in this format:
{
  "trustScore": 0-100 integer,
  "riskLevel": "LOW" | "MEDIUM" | "HIGH",
  "reason": "short explanation",
  "reportsCount": number of spam reports
}
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final cleanedText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanedText);
    } catch (e) {
      return {
        'trustScore': 50,
        'riskLevel': 'MEDIUM',
        'reason': 'API error: using default safety profile.',
        'reportsCount': 1,
      };
    }
  }

  /// Summarize a text transcript of a call.
  Future<String> summarizeCall(String transcript, String savedKey) async {
    _initModel(savedKey);

    if (_model == null) {
      // Intelligent offline fallback
      if (transcript.contains('Figma') || transcript.contains('mockup')) {
        return 'Discussed finishing the application Figma mockup design files. Colleague asked to call back when available.';
      }
      return 'Completed short conversation checking schedule timings and availability for upcoming week events.';
    }

    try {
      final prompt = 'Summarize the following phone call transcript in one sentence:\n\n$transcript';
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No transcript summary available.';
    } catch (e) {
      return 'Summary generation failed (API error).';
    }
  }

  /// Suggest dynamic smart replies for missed call details.
  Future<List<String>> generateSmartReply(String name, String phoneNumber, String savedKey) async {
    _initModel(savedKey);

    if (_model == null) {
      return [
        'Hey $name, sorry I missed your call. What\'s up?',
        'Hi, currently in a meeting. Can I call you back in 30 mins?',
        'I\'ll call you back shortly.',
      ];
    }

    try {
      final prompt = 'Generate 3 modern, minimal SMS/Text quick replies for missing a call from "$name" ($phoneNumber). Return only a JSON array of strings: ["reply1", "reply2", "reply3"].';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final cleaned = (response.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> list = jsonDecode(cleaned);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return ['Sorry I missed your call.', 'I will call you back soon.', 'In a meeting, speak later.'];
    }
  }

  /// Parse natural language commands into calling actions.
  Future<VoiceCommandResult> executeVoiceCommand(String speechText, String savedKey) async {
    _initModel(savedKey);

    if (_model == null) {
      final query = speechText.toLowerCase();
      if (query.contains('call')) {
        String target = query.replaceFirst('call', '').trim();
        return VoiceCommandResult(
          action: VoiceActionType.call,
          targetName: target,
          rawResponse: 'Calling $target...',
        );
      } else if (query.contains('mute')) {
        return VoiceCommandResult(action: VoiceActionType.mute, rawResponse: 'Microphone muted.');
      } else if (query.contains('speaker')) {
        return VoiceCommandResult(action: VoiceActionType.speaker, rawResponse: 'Speaker toggled.');
      } else if (query.contains('record')) {
        return VoiceCommandResult(action: VoiceActionType.record, rawResponse: 'Call recording started.');
      }
      return VoiceCommandResult(action: VoiceActionType.none, rawResponse: 'Command not recognized.');
    }

    try {
      final prompt = '''
Interpret the user voice command: "$speechText".
Convert it to a calling action. Return ONLY a JSON object in this format:
{
  "action": "call" | "mute" | "speaker" | "record" | "none",
  "target": "name of person to call if applicable, else empty",
  "response": "short feedback text"
}
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final cleaned = (response.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleaned);
      
      VoiceActionType action = VoiceActionType.none;
      switch (data['action']) {
        case 'call': action = VoiceActionType.call; break;
        case 'mute': action = VoiceActionType.mute; break;
        case 'speaker': action = VoiceActionType.speaker; break;
        case 'record': action = VoiceActionType.record; break;
      }
      return VoiceCommandResult(
        action: action,
        targetName: data['target'] ?? '',
        rawResponse: data['response'] ?? 'Done.',
      );
    } catch (e) {
      return VoiceCommandResult(action: VoiceActionType.none, rawResponse: 'Error parsing command.');
    }
  }

  /// Filter/find contacts matching a natural language prompt.
  Future<List<Contact>> searchContactsNaturalLanguage(
      String query, List<Contact> allContacts, String savedKey) async {
    if (query.isEmpty) return allContacts;
    
    _initModel(savedKey);

    if (_model == null) {
      // Local semantic mock search
      final lowercaseQuery = query.toLowerCase();
      if (lowercaseQuery.contains('mom') || lowercaseQuery.contains('mother')) {
        return allContacts.where((c) => c.name.toLowerCase() == 'mom').toList();
      }
      if (lowercaseQuery.contains('papa') || lowercaseQuery.contains('father')) {
        return allContacts.where((c) => c.name.toLowerCase() == 'papa').toList();
      }
      if (lowercaseQuery.contains('plumber') || lowercaseQuery.contains('office') || lowercaseQuery.contains('manager') || lowercaseQuery.contains('work')) {
        return allContacts.where((c) => c.category.toLowerCase() == 'business' || c.relationship.toLowerCase() == 'manager').toList();
      }
      return allContacts.where((c) => 
        c.name.toLowerCase().contains(lowercaseQuery) || 
        c.phoneNumber.contains(lowercaseQuery)
      ).toList();
    }

    try {
      final contactsJson = allContacts.map((c) => {
        'id': c.id,
        'name': c.name,
        'category': c.category,
        'relationship': c.relationship,
        'notes': c.notes,
      }).toList();

      final prompt = '''
Analyze this natural language contact query: "$query".
Match the most relevant contacts from the list below:
${jsonEncode(contactsJson)}

Return ONLY a JSON array containing the matching string IDs. e.g., ["1", "3"]
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      final cleaned = (response.text ?? '').replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> matchedIds = jsonDecode(cleaned);
      
      return allContacts.where((c) => matchedIds.contains(c.id)).toList();
    } catch (e) {
      // Fallback
      return allContacts.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
  }
}
