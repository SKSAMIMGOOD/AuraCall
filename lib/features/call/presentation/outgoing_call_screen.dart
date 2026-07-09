import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';

class OutgoingCallScreen extends ConsumerWidget {
  const OutgoingCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image
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
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black80),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Text(
                  'CALLING...',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  callState.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  callState.number,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                
                const Spacer(),

                // Pulsating avatar ripple
                RippleEffect(
                  color: AppColors.blue,
                  child: callState.avatarUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(callState.avatarUrl),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white10,
                          child: Text(
                            callState.name.isNotEmpty ? callState.name[0] : 'U',
                            style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),

                const Spacer(),

                // Cancel Button
                GlassButton(
                  onTap: () {
                    ref.read(callStateProvider.notifier).hangUp(type: 'Outgoing');
                  },
                  size: 80.0,
                  color: AppColors.red,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
