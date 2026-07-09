import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  bool _showAiDrawer = false;
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _transcriptScrollController = ScrollController();

  @override
  void dispose() {
    _notesController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_transcriptScrollController.hasClients) {
      _transcriptScrollController.animateTo(
        _transcriptScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final size = MediaQuery.of(context).size;

    // Trigger auto-scroll on new transcript lines
    ref.listen<CallState>(callStateProvider, (previous, next) {
      if (previous?.transcript.length != next.transcript.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background
          if (callState.avatarUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                callState.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            )
          else
            Positioned.fill(child: Container(color: Colors.black)),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.75)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Caller name & timer
                  Text(
                    callState.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(callState.durationSeconds),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (callState.isHold)
                    const Text(
                      'CALL ON HOLD',
                      style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                    )
                  else
                    const Text(
                      'ACTIVE CALL',
                      style: TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Audio Waveform Visualizer
                  WaveformWidget(isAnimated: !callState.isHold),

                  const Spacer(),

                  // Matrix of Controls
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCallOptionButton(
                              icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                              label: 'Mute',
                              isActive: callState.isMuted,
                              onTap: () => ref.read(callStateProvider.notifier).toggleMute(),
                            ),
                            _buildCallOptionButton(
                              icon: Icons.grid_on_outlined,
                              label: 'Keypad',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Dialer keypad opened')),
                                );
                              },
                            ),
                            _buildCallOptionButton(
                              icon: callState.isSpeaker ? Icons.volume_up : Icons.volume_down,
                              label: 'Speaker',
                              isActive: callState.isSpeaker,
                              onTap: () => ref.read(callStateProvider.notifier).toggleSpeaker(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCallOptionButton(
                              icon: Icons.pause_circle_outline,
                              label: 'Hold',
                              isActive: callState.isHold,
                              onTap: () => ref.read(callStateProvider.notifier).toggleHold(),
                            ),
                            _buildCallOptionButton(
                              icon: callState.isRecording ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
                              label: callState.isRecording ? 'Recording' : 'Record',
                              isActive: callState.isRecording,
                              activeColor: AppColors.red,
                              onTap: () => ref.read(callStateProvider.notifier).toggleRecording(),
                            ),
                            _buildCallOptionButton(
                              icon: Icons.blur_on,
                              label: 'AI assistant',
                              isActive: _showAiDrawer,
                              activeColor: AppColors.blue,
                              onTap: () {
                                setState(() {
                                  _showAiDrawer = !_showAiDrawer;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // End Call Button
                  GlassButton(
                    onTap: () {
                      ref.read(callStateProvider.notifier).hangUp(type: 'Active');
                    },
                    size: 80.0,
                    color: AppColors.red,
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Sliding Glassmorphic AI Assistant Drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            left: 0,
            right: 0,
            bottom: _showAiDrawer ? 0 : -size.height * 0.55,
            height: size.height * 0.55,
            child: GlassCard(
              borderRadius: 36.0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              backgroundColor: Colors.black.withOpacity(0.85),
              borderColor: AppColors.blue.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gemini Call Intelligence',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                        onPressed: () {
                          setState(() {
                            _showAiDrawer = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  
                  // Live transcription & translation lists
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Transcript Panel
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text('LIVE TRANSCRIPT', style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: Colors.white30, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: _transcriptScrollController,
                                  itemCount: callState.transcript.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        callState.transcript[index],
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(color: Colors.white10, width: 24),
                        
                        // Live Translation Panel
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text('LIVE TRANSLATION (HI)', style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppColors.blue, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: callState.translation.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        callState.translation[index],
                                        style: const TextStyle(color: AppColors.blue, fontSize: 13, fontStyle: FontStyle.italic),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),

                  // Call notes
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Take secure notes during call...',
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.green),
                        onPressed: () {
                          if (_notesController.text.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notes encrypted and saved to contact.')),
                            );
                            _notesController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = AppColors.green,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassButton(
          onTap: onTap,
          size: 64,
          color: isActive ? activeColor.withOpacity(0.3) : null,
          child: Icon(
            icon,
            color: isActive ? activeColor : Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? activeColor : Colors.white70,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
