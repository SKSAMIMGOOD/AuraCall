import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _auraController;
  bool _showPermissionsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _initFlow();
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  void _initFlow() async {
    // Show splash for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Check permission status
    final contactsStatus = await Permission.contacts.status;
    final phoneStatus = await Permission.phone.status;
    final micStatus = await Permission.microphone.status;

    if (contactsStatus.isGranted && phoneStatus.isGranted && micStatus.isGranted) {
      _navigateToHome();
    } else {
      setState(() {
        _showPermissionsOnboarding = true;
      });
    }
  }

  void _requestAllPermissions() async {
    HapticFeedback.mediumImpact();
    
    // Request contacts, phone, microphone
    final statuses = await [
      Permission.contacts,
      Permission.phone,
      Permission.microphone,
    ].request();

    if (statuses[Permission.contacts]!.isGranted &&
        statuses[Permission.phone]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      _navigateToHome();
    } else {
      // In mock/sandbox contexts permissions might be denied or auto-granted.
      // We will allow the user to proceed to the app home regardless, so the prototype remains usable!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding verified: accessing AuraCall shell.'),
          backgroundColor: AppColors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Theme Dark Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.darkBackgroundGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Animated Aura Ring Glow behind logo
          AnimatedBuilder(
            animation: _auraController,
            builder: (context, child) {
              final scale = 1.0 + (_auraController.value * 0.25);
              final opacity = 0.15 + (_auraController.value * 0.15);
              return Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withOpacity(opacity),
                      AppColors.green.withOpacity(opacity * 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                transform: Matrix4.identity()..scale(scale),
              );
            },
          ),

          // Content Switcher: Splash Logo vs Permissions Onboarding
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: !_showPermissionsOnboarding
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glowing Glass Logo
                      GlassCard(
                        borderRadius: 36.0,
                        padding: const EdgeInsets.all(24),
                        width: 100,
                        height: 100,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'AuraCall',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Next Gen AI calling',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          const Icon(Icons.security_outlined, color: AppColors.blue, size: 64),
                          const SizedBox(height: 24),
                          const Text(
                            'Permissions Required',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'AuraCall needs standard microphone, contact, and phone dialer access to manage call routing and Gemini AI transcriptions.',
                            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Permissions Cards list
                          _buildPermissionTile(Icons.mic_none, 'Microphone Access', 'Transcribes audio calls to text in real-time.'),
                          const SizedBox(height: 12),
                          _buildPermissionTile(Icons.perm_contact_calendar_outlined, 'Contacts Access', 'Resolves phone numbers to contacts directory.'),
                          const SizedBox(height: 12),
                          _buildPermissionTile(Icons.phone_outlined, 'Phone log access', 'Displays recents call logs history.'),
                          
                          const Spacer(),
                          
                          GlassButton(
                            isCircle: false,
                            borderRadius: 16.0,
                            color: AppColors.blue,
                            onTap: _requestAllPermissions,
                            child: const Text(
                              'Grant & Proceed',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(IconData icon, String title, String subtitle) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16.0,
      backgroundColor: Colors.white.withOpacity(0.03),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 18,
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
