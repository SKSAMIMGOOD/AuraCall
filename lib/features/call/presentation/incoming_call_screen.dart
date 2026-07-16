import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> with SingleTickerProviderStateMixin {
  double _dragX = 0.0;
  double _dragY = 0.0;
  bool _isDragging = false;
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _springAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _isDragging = true;
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDragWidth) {
    final xLimit = maxDragWidth * 0.3;
    final yLimit = 120.0;

    if (_dragX > xLimit) {
      // Swipe Right -> Accept Call
      ref.read(callStateProvider.notifier).answerCall();
    } else if (_dragX < -xLimit) {
      // Swipe Left -> Reject Call
      ref.read(callStateProvider.notifier).hangUp(type: 'Rejected');
    } else if (_dragY < -yLimit) {
      // Swipe Up -> Quick Message Sheet
      _showQuickMessageSheet();
      _resetDrag();
    } else if (_dragY > yLimit) {
      // Swipe Down -> Remind Later
      _triggerRemindLater();
      _resetDrag();
    } else {
      _resetDrag();
    }
  }

  void _resetDrag() {
    final startX = _dragX;
    final startY = _dragY;
    
    _springAnimation = Tween<Offset>(
      begin: Offset(startX, startY),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );

    _springController.reset();
    _springController.forward().then((_) {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
    });
  }

  void _showQuickMessageSheet() {
    final callState = ref.read(callStateProvider);
    final settings = ref.read(settingsProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassCard(
          borderRadius: 36.0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Quick Message to ${callState.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...[
                'Sorry, can\'t talk right now. What\'s up?',
                'In a meeting, I will call you back.',
                'On my way, speak to you soon.',
                'Can I call you back later?',
              ].map((msg) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: GlassButton(
                  isCircle: false,
                  size: 50.0,
                  borderRadius: 16.0,
                  onTap: () {
                    Navigator.pop(context);
                    // Reject call & record message trigger
                    ref.read(callStateProvider.notifier).hangUp(type: 'Rejected');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message sent: "$msg"'),
                        backgroundColor: AppColors.blue.withOpacity(0.9),
                      ),
                    );
                  },
                  child: Text(msg, style: const TextStyle(color: Colors.white70)),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _triggerRemindLater() {
    final callState = ref.read(callStateProvider);
    ref.read(callStateProvider.notifier).hangUp(type: 'Missed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set: Call back ${callState.name} in 1 hour.'),
        backgroundColor: Colors.orange.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);
    final size = MediaQuery.of(context).size;
    final isSpam = callState.spamScore > 70;

    // Liquid expansion colors based on drag
    Color liquidColor = Colors.transparent;
    double currentDrag = 0.0;
    if (_isDragging) {
      if (_dragX.abs() > _dragY.abs()) {
        currentDrag = (_dragX / (size.width * 0.3)).clamp(-1.0, 1.0);
        liquidColor = _dragX > 0 
            ? AppColors.green.withOpacity(currentDrag.abs() * 0.25)
            : AppColors.red.withOpacity(currentDrag.abs() * 0.25);
      } else {
        currentDrag = (_dragY / 120.0).clamp(-1.0, 1.0);
        liquidColor = _dragY < 0 
            ? AppColors.blue.withOpacity(currentDrag.abs() * 0.25)
            : Colors.orange.withOpacity(currentDrag.abs() * 0.25);
      }
    }

    final double xOffset = _springController.isAnimating ? _springAnimation.value.dx : _dragX;
    final double yOffset = _springController.isAnimating ? _springAnimation.value.dy : _dragY;

    return Scaffold(
      body: Stack(
        children: [
          // Background photo (blurred)
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

          // Blurry backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: liquidColor.withOpacity(_isDragging ? liquidColor.opacity : 0.65),
              ),
            ),
          ),

          // Caller Info
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                if (callState.avatarUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: NetworkImage(callState.avatarUrl),
                  )
                else
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white12,
                    child: Text(
                      callState.name.isNotEmpty ? callState.name[0] : 'U',
                      style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  callState.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  callState.number,
                  style: const TextStyle(fontSize: 18, color: Colors.white70, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isSpam ? 'POTENTIAL SPAM' : 'INCOMING AUDIO CALL',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    color: isSpam ? AppColors.red : AppColors.blue,
                  ),
                ),
                
                const Spacer(),

                // Spam Details Warning Card
                if (isSpam)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GlassCard(
                      borderColor: AppColors.red.withOpacity(0.5),
                      backgroundColor: AppColors.red.withOpacity(0.12),
                      borderRadius: 20.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Risk Score: ${callState.spamScore}%',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            callState.spamReason,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const Spacer(),

                // Gesture Control Area
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Guidelines and indicators
                      if (_isDragging) ...[
                        Positioned(
                          right: 40,
                          child: Opacity(
                            opacity: (_dragX > 0 ? (_dragX / 100).clamp(0.0, 1.0) : 0.0),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.call, color: AppColors.green, size: 36),
                                SizedBox(height: 4),
                                Text('Accept', style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 40,
                          child: Opacity(
                            opacity: (_dragX < 0 ? (-_dragX / 100).clamp(0.0, 1.0) : 0.0),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.call_end, color: AppColors.red, size: 36),
                                SizedBox(height: 4),
                                Text('Decline', style: TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          child: Opacity(
                            opacity: (_dragY < 0 ? (-_dragY / 80).clamp(0.0, 1.0) : 0.0),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message_outlined, color: AppColors.blue, size: 36),
                                SizedBox(height: 4),
                                Text('Message', style: TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          child: Opacity(
                            opacity: (_dragY > 0 ? (_dragY / 80).clamp(0.0, 1.0) : 0.0),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm, color: Colors.orange, size: 36),
                                SizedBox(height: 4),
                                Text('Remind Later', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Dynamic floating ring hints
                        const Positioned(
                          child: IgnorePointer(
                            child: Text(
                              'Swipe Left to Decline   •   Swipe Right to Accept',
                              style: TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],

                      // Central interactive liquid gesture button
                      Transform.translate(
                        offset: Offset(xOffset, yOffset),
                        child: GestureDetector(
                          onPanUpdate: (details) => _onDragUpdate(details, size.width),
                          onPanEnd: (details) => _onDragEnd(details, size.width),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.glassSurface,
                              border: Border.all(color: AppColors.glassBorder, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      color: Colors.black,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
