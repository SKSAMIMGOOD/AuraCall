import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/models/call_log_model.dart';
import '../../../core/widgets/glass_widgets.dart';

class AiDashboardScreen extends ConsumerStatefulWidget {
  const AiDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiDashboardScreen> createState() => _AiDashboardScreenState();
}

class _AiDashboardScreenState extends ConsumerState<AiDashboardScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  List<Contact> _matchedContacts = [];
  String _aiExplanation = '';

  void _runAiQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _matchedContacts = [];
      _aiExplanation = '';
    });

    HapticFeedback.mediumImpact();

    final allContacts = ref.read(contactsProvider);
    final settings = ref.read(settingsProvider);
    final gemini = ref.read(geminiServiceProvider);

    // Call semantic search
    final matches = await gemini.searchContactsNaturalLanguage(query, allContacts, settings.geminiApiKey);

    // Dynamic explanation response builder
    String explanation = '';
    if (matches.isEmpty) {
      explanation = 'Gemini didn\'t find any matching contacts in your directory for "$query". Try searching for "Mom" or "Office".';
    } else {
      explanation = 'Gemini found ${matches.length} matching contact(s) matching your request. Tapping call starts call.';
    }

    setState(() {
      _isLoading = false;
      _matchedContacts = matches;
      _aiExplanation = explanation;
    });
  }

  void _runActionSuggestion(String queryText) {
    _queryController.text = queryText;
    _runAiQuery();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final spamBlockedCount = logs.where((l) => l.isSpam).length;

    return Column(
      children: [
        // Header
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
            children: [
              // AI Search query box
              GlassCard(
                borderColor: AppColors.blue.withOpacity(0.3),
                backgroundColor: AppColors.blue.withOpacity(0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Natural Language Contact Search',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ask Gemini in plain English to search or trigger calls.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    
                    // Input row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _queryController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'e.g. "Call the plumber", "Call Mom"',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _runAiQuery(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassButton(
                          onTap: _runAiQuery,
                          size: 48,
                          color: AppColors.blue,
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Suggestion Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Call Mom',
                    'Call office manager',
                    'Call business clients',
                    'Call Amit',
                  ].map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _runActionSuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(
                            suggestion,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Query results display panel
              if (_isLoading || _aiExplanation.isNotEmpty || _matchedContacts.isNotEmpty) ...[
                _buildSectionHeader('Gemini Search Results'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_aiExplanation.isNotEmpty)
                        Text(
                          _aiExplanation,
                          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                        ),
                      if (_matchedContacts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 6),
                        ..._matchedContacts.map((contact) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: contact.avatarUrl.isNotEmpty
                                  ? CircleAvatar(backgroundImage: NetworkImage(contact.avatarUrl))
                                  : const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white54)),
                              title: Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('${contact.category} • ${contact.phoneNumber}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              trailing: GlassButton(
                                onTap: () {
                                  ref.read(callStateProvider.notifier).startOutgoingCall(
                                        contact.name,
                                        contact.phoneNumber,
                                        contact.avatarUrl,
                                      );
                                },
                                size: 40,
                                color: AppColors.green.withOpacity(0.12),
                                child: const Icon(Icons.phone, color: AppColors.green, size: 18),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // AI Spam Metrics Row
              _buildSectionHeader('AI Security Metrics'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.security, color: AppColors.green, size: 24),
                          const SizedBox(height: 12),
                          const Text('Spam Shield', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('$spamBlockedCount Blocked', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.security, color: AppColors.blue, size: 24),
                          const SizedBox(height: 12),
                          const Text('Trust Rating Index', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 4),
                          const Text('98.4% Secure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent AI call summaries history timeline
              _buildSectionHeader('Recent Call Summaries'),
              const SizedBox(height: 8),
              _buildSummariesTimeline(logs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.blue,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSummariesTimeline(List<CallLog> logs) {
    final summaryLogs = logs.where((l) => l.aiSummary.isNotEmpty).toList();

    if (summaryLogs.isEmpty) {
      return const GlassCard(
        child: Center(
          child: Text('No call summaries generated yet.', style: TextStyle(color: Colors.white24, fontSize: 13)),
        ),
      );
    }

    return Column(
      children: List.generate(summaryLogs.length, (index) {
        final log = summaryLogs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Call with ${log.callerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.blue, size: 10),
                        SizedBox(width: 4),
                        Text('AI Summarized', style: TextStyle(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.durationSeconds}s duration',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Text(
                  log.aiSummary,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
