import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/widgets/glass_widgets.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final Contact contact;

  const ContactDetailsScreen({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);
    final contactLogs = logs.where((l) => l.phoneNumber.replaceAll(' ', '') == contact.phoneNumber.replaceAll(' ', '')).toList();

    // Calculate analytics
    final totalCalls = contactLogs.length;
    final totalDuration = contactLogs.fold<int>(0, (sum, item) => sum + item.durationSeconds);
    final avgDuration = totalCalls > 0 ? (totalDuration / totalCalls).round() : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: IconButton(
                    icon: Icon(contact.isFavorite ? Icons.star : Icons.star_border, color: contact.isFavorite ? Colors.amber : Colors.white),
                    onPressed: () {
                      ref.read(contactsProvider.notifier).toggleFavorite(contact.id);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Theme Background Gradient
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

          // Scrollable details content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: kToolbarHeight + 60, bottom: 40, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Name
                Center(
                  child: Column(
                    children: [
                      contact.avatarUrl.isNotEmpty
                          ? CircleAvatar(
                              radius: 70,
                              backgroundImage: NetworkImage(contact.avatarUrl),
                            )
                          : CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white10,
                              child: Text(
                                contact.name.isNotEmpty ? contact.name[0] : 'U',
                                style: const TextStyle(fontSize: 54, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text(
                        contact.name,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phoneNumber,
                        style: const TextStyle(fontSize: 16, color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                      if (contact.relationship.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            contact.relationship,
                            style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Core Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(Icons.phone, 'Call', AppColors.green, () {
                      ref.read(callStateProvider.notifier).startOutgoingCall(contact.name, contact.phoneNumber, contact.avatarUrl);
                    }),
                    _buildQuickAction(Icons.message_rounded, 'Message', AppColors.blue, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message window opened for ${contact.name}')),
                      );
                    }),
                    _buildQuickAction(Icons.videocam, 'Video', Colors.purple, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video call is not supported in this region')),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 28),

                // Contact info card
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email, 'Email', contact.email.isNotEmpty ? contact.email : 'Add email'),
                      _buildDivider(),
                      _buildInfoRow(Icons.chat_bubble_outline, 'WhatsApp', contact.whatsappNumber.isNotEmpty ? contact.whatsappNumber : 'Add number'),
                      _buildDivider(),
                      _buildInfoRow(Icons.telegram, 'Telegram', contact.telegramUsername.isNotEmpty ? '@${contact.telegramUsername}' : 'Add username'),
                      _buildDivider(),
                      _buildInfoRow(Icons.camera_alt_outlined, 'Instagram', contact.instagramUsername.isNotEmpty ? '@${contact.instagramUsername}' : 'Add instagram'),
                      _buildDivider(),
                      _buildInfoRow(Icons.cake, 'Birthday', contact.birthday.isNotEmpty ? contact.birthday : 'Add birthday'),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Call Analytics Card
                _buildSectionHeader('Communication Analytics'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAnalyticStat('Total Calls', totalCalls.toString()),
                          _buildAnalyticStat('Avg Duration', '${avgDuration}s'),
                          _buildAnalyticStat('Total time', '${(totalDuration / 60).toStringAsFixed(1)}m'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Mini Chart rendering call duration logs
                      SizedBox(
                        height: 120,
                        child: totalCalls > 0
                            ? BarChart(
                                BarChartData(
                                  barGroups: List.generate(
                                    contactLogs.take(5).length,
                                    (index) {
                                      final log = contactLogs[index];
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: log.durationSeconds.toDouble().clamp(5.0, 300.0),
                                            color: log.callType == 'Incoming' ? AppColors.green : AppColors.blue,
                                            width: 12,
                                            borderRadius: BorderRadius.circular(4),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(show: false),
                                ),
                              )
                            : const Center(
                                child: Text('No call metrics logs found', style: TextStyle(color: Colors.white24, fontSize: 13)),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Secure Notes Card
                _buildSectionHeader('Secure Notes'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Text(
                    contact.notes.isNotEmpty ? contact.notes : 'No encrypted notes saved for this contact. Tap settings to add notes.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),

                const SizedBox(height: 28),

                // Call History Timeline
                _buildSectionHeader('Recent Timeline'),
                const SizedBox(height: 8),
                if (contactLogs.isEmpty)
                  const GlassCard(
                    child: Center(
                      child: Text('No logs found', style: TextStyle(color: Colors.white24)),
                    ),
                  )
                else
                  Column(
                    children: List.generate(contactLogs.length, (index) {
                      final log = contactLogs[index];
                      final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(log.timestamp);
                      final isIncoming = log.callType == 'Incoming';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: log.callType == 'Missed'
                                    ? AppColors.red.withOpacity(0.15)
                                    : (isIncoming ? AppColors.green.withOpacity(0.15) : AppColors.blue.withOpacity(0.15)),
                                child: Icon(
                                  log.callType == 'Missed'
                                      ? Icons.call_missed
                                      : (isIncoming ? Icons.call_received : Icons.call_made),
                                  color: log.callType == 'Missed'
                                      ? AppColors.red
                                      : (isIncoming ? AppColors.green : AppColors.blue),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.callType,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                log.durationSeconds > 0 ? '${log.durationSeconds}s' : 'Missed',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GlassButton(
          onTap: onTap,
          size: 56,
          color: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white30, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, height: 1);
  }

  Widget _buildAnalyticStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
