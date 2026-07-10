import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/voicemail_model.dart';
import '../../../core/widgets/glass_widgets.dart';

class VoicemailScreen extends ConsumerStatefulWidget {
  const VoicemailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoicemailScreen> createState() => _VoicemailScreenState();
}

class _VoicemailScreenState extends ConsumerState<VoicemailScreen> {
  String? _activeVoicemailId;
  bool _isPlaying = false;
  double _playProgress = 0.0; // 0.0 to 1.0
  int _simulatedElapsedSeconds = 0;

  void _togglePlay(Voicemail voicemail) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isPlaying) {
        _isPlaying = false;
      } else {
        _isPlaying = true;
        _runAudioSimulation(voicemail);
      }
    });

    // Mark as read
    if (!voicemail.isRead) {
      ref.read(voicemailsProvider.notifier).markRead(voicemail.id);
    }
  }

  void _runAudioSimulation(Voicemail voicemail) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isPlaying || _activeVoicemailId != voicemail.id) return false;

      setState(() {
        _simulatedElapsedSeconds++;
        _playProgress = _simulatedElapsedSeconds / voicemail.durationSeconds;
        
        if (_playProgress >= 1.0) {
          _playProgress = 0.0;
          _simulatedElapsedSeconds = 0;
          _isPlaying = false;
        }
      });
      return _isPlaying && _playProgress < 1.0;
    });
  }

  void _selectVoicemail(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_activeVoicemailId == id) {
        _activeVoicemailId = null;
        _isPlaying = false;
        _playProgress = 0.0;
        _simulatedElapsedSeconds = 0;
      } else {
        _activeVoicemailId = id;
        _isPlaying = false;
        _playProgress = 0.0;
        _simulatedElapsedSeconds = 0;
      }
    });
  }

  void _deleteVoicemail(String id) {
    HapticFeedback.mediumImpact();
    ref.read(voicemailsProvider.notifier).deleteVoicemail(id);
    setState(() {
      _activeVoicemailId = null;
      _isPlaying = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voicemail deleted.')),
    );
  }

  void _exportVoicemail(Voicemail voicemail) {
    HapticFeedback.lightImpact();
    final text = 'Voicemail from ${voicemail.callerName} (${voicemail.phoneNumber}):\n\n'
        'Transcript: "${voicemail.transcript}"\n\n'
        'AI Summary: "${voicemail.aiSummary}"';
    Share.share(text, subject: 'Voicemail Transcript');
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final voicemails = ref.watch(voicemailsProvider);

    return Column(
      children: [
        // App header
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voicemail',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                Text(
                  '${voicemails.where((v) => !v.isRead).length} Unread',
                  style: const TextStyle(color: Colors.white30, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: voicemails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.voicemail, size: 64, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text(
                        'No voicemail messages',
                        style: TextStyle(color: Colors.white30, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
                  itemCount: voicemails.length,
                  itemBuilder: (context, index) {
                    final voicemail = voicemails[index];
                    final isExpanded = _activeVoicemailId == voicemail.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildVoicemailCard(voicemail, isExpanded),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVoicemailCard(Voicemail voicemail, bool isExpanded) {
    final dateStr = DateFormat('MMM dd, yyyy • h:mm a').format(voicemail.timestamp);

    return GlassCard(
      borderRadius: 24.0,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header info row
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Text(
                    voicemail.callerName.isNotEmpty ? voicemail.callerName[0] : 'U',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                if (!voicemail.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              voicemail.callerName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voicemail.phoneNumber, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
            trailing: Text(
              _formatTime(voicemail.durationSeconds),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () => _selectVoicemail(voicemail.id),
          ),
          
          // Expanded Player Details
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Audio progress slider scrubber
                  Row(
                    children: [
                      Text(_formatTime(_simulatedElapsedSeconds), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: _playProgress,
                          onChanged: (val) {
                            setState(() {
                              _playProgress = val;
                              _simulatedElapsedSeconds = (val * voicemail.durationSeconds).round();
                            });
                          },
                        ),
                      ),
                      Text('-${_formatTime(voicemail.durationSeconds - _simulatedElapsedSeconds)}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Player actions row (Play/Pause, Delete, Share)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white70),
                        onPressed: () => _exportVoicemail(voicemail),
                      ),
                      GlassButton(
                        onTap: () => _togglePlay(voicemail),
                        size: 50.0,
                        color: _isPlaying ? AppColors.blue.withOpacity(0.3) : AppColors.blue,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.red),
                        onPressed: () => _deleteVoicemail(voicemail.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Speech-to-text Transcript Box
                  const Text(
                    'TRANSCRIPT (STT)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      voicemail.transcript,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gemini-powered Summary Box
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.blue, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'GEMINI AI SUMMARY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.blue.withOpacity(0.12)),
                    ),
                    child: Text(
                      voicemail.aiSummary,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
