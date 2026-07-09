import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

// Call Screens
import '../../call/presentation/incoming_call_screen.dart';
import '../../call/presentation/outgoing_call_screen.dart';
import '../../call/presentation/active_call_screen.dart';

// Navigation Screens
import '../../favorites/presentation/favorites_screen.dart';
import '../../recents/presentation/recents_screen.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../dialpad/presentation/dialpad_screen.dart';
import '../../ai/presentation/ai_dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 2; // Default to Contacts Tab

  final List<Widget> _screens = [
    const FavoritesScreen(),
    const RecentsScreen(),
    const ContactsScreen(),
    const DialPadScreen(),
    const AiDashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);

    // Overlay call screens when states are active
    if (callState.status == CallStatus.incoming) {
      return const IncomingCallScreen();
    } else if (callState.status == CallStatus.ringing) {
      return const OutgoingCallScreen();
    } else if (callState.status == CallStatus.active) {
      return const ActiveCallScreen();
    }

    return Scaffold(
      extendBody: true, // Crucial to render content under floating bottom nav
      body: Stack(
        children: [
          // Dynamic Dark Abstract Gradient Background
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
          
          // Screen content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0.0), // Floating nav takes care of padding
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
          
          // Floating Premium Glass Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: GlassCard(
                borderRadius: 30.0,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                backgroundColor: Colors.black.withOpacity(0.4),
                borderColor: AppColors.glassBorder.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.star_rounded, Icons.star_outline_rounded, 'Favorites'),
                    _buildNavItem(1, Icons.history_rounded, Icons.history_rounded, 'Recents'),
                    _buildNavItem(2, Icons.people_rounded, Icons.people_outline_rounded, 'Contacts'),
                    _buildNavItem(3, Icons.dialpad_rounded, Icons.dialpad_rounded, 'Dial Pad'),
                    _buildNavItem(4, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'AI'),
                    _buildNavItem(5, Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.blue : Colors.white54;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with scale feedback
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Minimal text indicator
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
