import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/call_log_model.dart';
import '../../../core/widgets/glass_widgets.dart';

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  String _selectedFilter = 'All'; // All, Missed, Outgoing, Spam
  final Map<String, bool> _expandedSummaries = {};

  void _toggleSummary(String logId) {
    setState(() {
      final current = _expandedSummaries[logId] ?? false;
      _expandedSummaries[logId] = !current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);

    // Apply Filter
    final filteredLogs = logs.where((log) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Missed') return log.callType == 'Missed';
      if (_selectedFilter == 'Outgoing') return log.callType == 'Outgoing';
      if (_selectedFilter == 'Spam') return log.isSpam;
      return true;
    }).toList();

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
                  'Recents',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                if (logs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white60, size: 24),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(logsProvider.notifier).clearAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call history cleared.')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: ['All', 'Missed', 'Outgoing', 'Spam'].map((filter) {
              final isSelected = _selectedFilter == filter;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: AppColors.glassSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: isSelected ? Colors.white : AppColors.glassBorder, width: 1),
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedFilter = filter;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Timeline list
        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      Text(
                        'No call logs matching "$_selectedFilter"',
                        style: const TextStyle(color: Colors.white24, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final isExpanded = _expandedSummaries[log.id] ?? false;
                    final hasSummary = log.aiSummary.isNotEmpty;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildLogItemCard(log, isExpanded, hasSummary),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogItemCard(CallLog log, bool isExpanded, bool hasSummary) {
    final dateStr = DateFormat('hh:mm a').format(log.timestamp);
    final relativeDay = _getRelativeDay(log.timestamp);
    final isIncoming = log.callType == 'Incoming';

    // Decide call status icon color
    Color typeColor = AppColors.blue;
    IconData typeIcon = Icons.call_made;

    if (log.callType == 'Missed') {
      typeColor = AppColors.red;
      typeIcon = Icons.call_missed;
    } else if (log.callType == 'Spam') {
      typeColor = AppColors.red;
      typeIcon = Icons.warning_amber_rounded;
    } else if (isIncoming) {
      typeColor = AppColors.green;
      typeIcon = Icons.call_received;
    }

    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Swipe left-to-right -> Call back immediately
        HapticFeedback.mediumImpact();
        ref.read(callStateProvider.notifier).startOutgoingCall(log.callerName, log.phoneNumber, '');
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: const Icon(Icons.phone, color: AppColors.green, size: 24),
      ),
      child: GlassCard(
        borderRadius: 24.0,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Status icon circle
                CircleAvatar(
                  radius: 18,
                  backgroundColor: typeColor.withOpacity(0.12),
                  child: Icon(typeIcon, color: typeColor, size: 16),
                ),
                const SizedBox(width: 14),
                
                // Caller details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.callerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: log.callType == 'Missed' || log.callType == 'Spam' ? AppColors.red : Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(log.phoneNumber, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          if (log.durationSeconds > 0) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text('${log.durationSeconds}s', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Call Time and expandable AI tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$relativeDay $dateStr',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (log.isSpam)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Spam ${log.spamScore}%',
                              style: const TextStyle(color: AppColors.red, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (hasSummary) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _toggleSummary(log.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.blue, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    isExpanded ? 'Hide' : 'AI Summary',
                                    style: const TextStyle(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            // Expanded AI Summary Details Box
            if (hasSummary && isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.blue, size: 12),
                        SizedBox(width: 6),
                        Text(
                          'GEMINI INTELLIGENCE REPORT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blue, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.aiSummary,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRelativeDay(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (logDate == today) return 'Today';
    if (logDate == yesterday) return 'Yesterday';
    return DateFormat('MMM dd').format(timestamp);
  }
}
