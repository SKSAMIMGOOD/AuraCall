import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/widgets/glass_widgets.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    for (var char in _alphabet) {
      _keys[char] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String char) {
    HapticFeedback.lightImpact();
    final key = _keys[char];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddContactSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: GlassCard(
            borderRadius: 36.0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            backgroundColor: Colors.black.withOpacity(0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Contact',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildTextField(nameController, 'Name', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(emailController, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _buildTextField(categoryController, 'Category (Family, Business, General)', Icons.category),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        isCircle: false,
                        borderRadius: 16.0,
                        onTap: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        isCircle: false,
                        color: AppColors.blue,
                        borderRadius: 16.0,
                        onTap: () {
                          if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                            final newContact = Contact(
                              id: const Uuid().v4(),
                              name: nameController.text,
                              phoneNumber: phoneController.text,
                              email: emailController.text,
                              category: categoryController.text,
                            );
                            ref.read(contactsProvider.notifier).addContact(newContact);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact added successfully')),
                            );
                          }
                        },
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.glassBorder.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _showQuickActionsSheet(Contact contact) {
    HapticFeedback.vibrate();
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
              Text(
                contact.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.green),
                title: const Text('Call', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(callStateProvider.notifier).startOutgoingCall(contact.name, contact.phoneNumber, contact.avatarUrl);
                },
              ),
              ListTile(
                leading: Icon(contact.isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
                title: Text(contact.isFavorite ? 'Remove Favorite' : 'Mark Favorite', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  ref.read(contactsProvider.notifier).toggleFavorite(contact.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Delete Contact', style: TextStyle(color: AppColors.red)),
                onTap: () {
                  ref.read(contactsProvider.notifier).deleteContact(contact.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    
    final filteredContacts = contacts.where((c) {
      final nameMatches = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = c.phoneNumber.contains(_searchQuery);
      return nameMatches || phoneMatches;
    }).toList();

    // Sort contacts alphabetically
    filteredContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Group contacts by starting letter
    final Map<String, List<Contact>> groupedContacts = {};
    for (var contact in filteredContacts) {
      final firstLetter = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '#';
      final key = RegExp(r'[A-Z]').hasMatch(firstLetter) ? firstLetter : '#';
      if (!groupedContacts.containsKey(key)) {
        groupedContacts[key] = [];
      }
      groupedContacts[key]!.add(contact);
    }

    final sortedGroups = groupedContacts.keys.toList()..sort();

    return Column(
      children: [
        // App bar
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contacts',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                GlassButton(
                  onTap: _showAddContactSheet,
                  size: 40,
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search by name or number...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Main List & Alphabetical Scroller
        Expanded(
          child: Stack(
            children: [
              // Contact List
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(left: 20, right: 40, top: 8, bottom: 120),
                itemCount: sortedGroups.length,
                itemBuilder: (context, groupIndex) {
                  final char = sortedGroups[groupIndex];
                  final groupContacts = groupedContacts[char]!;

                  return Column(
                    key: _keys.containsKey(char) ? _keys[char] : null,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alphabet Header
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 18, bottom: 8),
                        child: Text(
                          char,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.blue),
                        ),
                      ),
                      
                      // Contacts Card
                      GlassCard(
                        borderRadius: 24.0,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: List.generate(groupContacts.length, (contactIndex) {
                            final contact = groupContacts[contactIndex];
                            
                            return _buildDismissibleContactItem(contact);
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Side Alphabet Indexer
              Positioned(
                right: 8,
                top: 20,
                bottom: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _alphabet.map((char) {
                        final hasContacts = groupedContacts.containsKey(char);
                        return GestureDetector(
                          onTap: () => _scrollToSection(char),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4),
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: hasContacts ? AppColors.blue : Colors.white24,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDismissibleContactItem(Contact contact) {
    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe Left -> Call
          HapticFeedback.mediumImpact();
          ref.read(callStateProvider.notifier).startOutgoingCall(contact.name, contact.phoneNumber, contact.avatarUrl);
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Send Message (mock snackbar)
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message to ${contact.name}: "Hey!"'),
              backgroundColor: AppColors.blue.withOpacity(0.9),
            ),
          );
        }
        return false; // Prevents actual item deletion from list visual structure
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        color: AppColors.blue.withOpacity(0.3),
        child: const Icon(Icons.message_outlined, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        color: AppColors.green.withOpacity(0.3),
        child: const Icon(Icons.phone, color: Colors.white, size: 24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: contact.avatarUrl.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(contact.avatarUrl))
            : CircleAvatar(
                backgroundColor: Colors.white10,
                child: Text(contact.name.isNotEmpty ? contact.name[0] : 'U', style: const TextStyle(color: Colors.white70)),
              ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Text(
          contact.phoneNumber,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        trailing: contact.isFavorite
            ? const Icon(Icons.star_rounded, color: Colors.amber, size: 18)
            : null,
        onLongPress: () => _showQuickActionsSheet(contact),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailsScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }
}
