import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/widgets/glass_widgets.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final favorites = contacts.where((c) => c.isFavorite).toList();

    // Group favorites by category
    final Map<String, List<Contact>> categorizedFavorites = {
      'Family': favorites.where((c) => c.category == 'Family').toList(),
      'Business': favorites.where((c) => c.category == 'Business').toList(),
      'Emergency': favorites.where((c) => c.category == 'Emergency').toList(),
      'Others': favorites.where((c) => c.category != 'Family' && c.category != 'Business' && c.category != 'Emergency').toList(),
    };

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
                  'Favorites',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                Text(
                  '${favorites.length} Pinned',
                  style: const TextStyle(color: Colors.white30, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline_rounded, size: 64, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text(
                        'No favorites pinned yet.',
                        style: TextStyle(color: Colors.white30, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Long press contacts to add them here.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
                  children: [
                    if (categorizedFavorites['Emergency']!.isNotEmpty)
                      _buildFavoriteSection(context, ref, 'Emergency Pinned', categorizedFavorites['Emergency']!, isEmergency: true),
                    if (categorizedFavorites['Family']!.isNotEmpty)
                      _buildFavoriteSection(context, ref, 'Family Connections', categorizedFavorites['Family']!),
                    if (categorizedFavorites['Business']!.isNotEmpty)
                      _buildFavoriteSection(context, ref, 'Business Contacts', categorizedFavorites['Business']!),
                    if (categorizedFavorites['Others']!.isNotEmpty)
                      _buildFavoriteSection(context, ref, 'Frequently Called', categorizedFavorites['Others']!),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFavoriteSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Contact> items, {
    bool isEmergency = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 14, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isEmergency ? AppColors.red : AppColors.blue,
              letterSpacing: 1.5,
            ),
          ),
        ),
        
        // Grid View inside Section
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final contact = items[index];
            
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(callStateProvider.notifier).startOutgoingCall(
                  contact.name,
                  contact.phoneNumber,
                  contact.avatarUrl,
                );
              },
              child: GlassCard(
                borderColor: isEmergency ? AppColors.red.withOpacity(0.4) : AppColors.glassBorder,
                backgroundColor: isEmergency ? AppColors.red.withOpacity(0.06) : AppColors.glassSurface,
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        contact.avatarUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(contact.avatarUrl),
                              )
                            : CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white10,
                                child: Text(contact.name[0], style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                        Icon(
                          isEmergency ? Icons.emergency : Icons.phone,
                          color: isEmergency ? AppColors.red : AppColors.green,
                          size: 16,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.relationship.isNotEmpty ? contact.relationship : 'Favorite',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
