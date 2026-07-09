import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../contacts/presentation/contact_details_screen.dart';

class DialPadScreen extends ConsumerStatefulWidget {
  const DialPadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends ConsumerState<DialPadScreen> {
  String _inputDigits = '';
  List<dynamic> _t9Matches = [];

  // T9 Key Mapping
  final Map<String, String> _t9Map = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  void _onKeyPress(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _inputDigits += digit;
      _updateT9Matches();
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_inputDigits.isNotEmpty) {
      setState(() {
        _inputDigits = _inputDigits.substring(0, _inputDigits.length - 1);
        _updateT9Matches();
      });
    }
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _inputDigits = '';
      _t9Matches = [];
    });
  }

  void _updateT9Matches() {
    if (_inputDigits.isEmpty) {
      _t9Matches = [];
      return;
    }

    final contacts = ref.read(contactsProvider);
    
    // T9 Matching Logic
    final matched = contacts.where((contact) {
      // 1. Matches digits directly in phone number
      final cleanPhone = contact.phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.contains(_inputDigits)) return true;

      // 2. Matches letters using T9 keys
      return _nameMatchesT9(contact.name.toLowerCase(), _inputDigits);
    }).toList();

    setState(() {
      _t9Matches = matched;
    });
  }

  bool _nameMatchesT9(String name, String typedDigits) {
    final words = name.split(RegExp(r'\s+'));
    
    // Check if any word starts with or matches the T9 digits
    for (var word in words) {
      if (word.length < typedDigits.length) continue;
      
      bool wordMatches = true;
      for (int i = 0; i < typedDigits.length; i++) {
        final digit = typedDigits[i];
        final letters = _t9Map[digit];
        
        if (letters == null) {
          wordMatches = false;
          break;
        }

        final charAtWord = word[i];
        if (!letters.toLowerCase().contains(charAtWord)) {
          wordMatches = false;
          break;
        }
      }
      if (wordMatches) return true;
    }
    return false;
  }

  void _initiateCall() {
    if (_inputDigits.isEmpty) return;
    HapticFeedback.mediumImpact();

    // Find contact if matches
    final contacts = ref.read(contactsProvider);
    final matchedContact = contacts.firstWhere(
      (c) => c.phoneNumber.replaceAll(' ', '') == _inputDigits.replaceAll(' ', ''),
      orElse: () => Contact(id: '', name: 'Unknown', phoneNumber: _inputDigits),
    );

    ref.read(callStateProvider.notifier).startOutgoingCall(
      matchedContact.name,
      _inputDigits,
      matchedContact.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: kToolbarHeight),
        // Predicted contacts results above pad
        Expanded(
          child: _t9Matches.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _t9Matches.length,
                  itemBuilder: (context, index) {
                    final contact = _t9Matches[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: contact.avatarUrl.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(contact.avatarUrl))
                            : const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white70)),
                        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(contact.phoneNumber, style: const TextStyle(color: Colors.white54)),
                        trailing: GlassButton(
                          onTap: () {
                            ref.read(callStateProvider.notifier).startOutgoingCall(
                              contact.name,
                              contact.phoneNumber,
                              contact.avatarUrl,
                            );
                          },
                          size: 40,
                          color: AppColors.green.withOpacity(0.2),
                          child: const Icon(Icons.phone, color: AppColors.green, size: 18),
                        ),
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
                  },
                )
              : Center(
                  child: Text(
                    _inputDigits.isEmpty ? 'AuraCall Smart T9 Dialer' : 'No predicted matches',
                    style: const TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
        ),

        // Display input box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          height: 60,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _inputDigits,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Numeric Keypad Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialButton('1', ''),
                  _buildDialButton('2', 'ABC'),
                  _buildDialButton('3', 'DEF'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialButton('4', 'GHI'),
                  _buildDialButton('5', 'JKL'),
                  _buildDialButton('6', 'MNO'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialButton('7', 'PQRS'),
                  _buildDialButton('8', 'TUV'),
                  _buildDialButton('9', 'WXYZ'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialButton('*', ''),
                  _buildDialButton('0', '+'),
                  _buildDialButton('#', ''),
                ],
              ),
              const SizedBox(height: 20),
              
              // Bottom Action Row (Call, Backspace)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Spacer to align call in center
                  const SizedBox(width: 64),
                  
                  // Central Green Call Button
                  GlassButton(
                    onTap: _inputDigits.isNotEmpty ? _initiateCall : null,
                    size: 72,
                    color: _inputDigits.isNotEmpty ? AppColors.green : Colors.white10,
                    child: const Icon(Icons.phone, color: Colors.white, size: 32),
                  ),

                  // Backspace/Delete Button
                  SizedBox(
                    width: 64,
                    child: _inputDigits.isNotEmpty
                        ? GestureDetector(
                            onTap: _onBackspace,
                            onLongPress: _onClear,
                            child: const CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.backspace_outlined, color: Colors.white70, size: 24),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 110), // Padding to avoid overlap with bottom navigation bar
      ],
    );
  }

  Widget _buildDialButton(String digit, String letters) {
    return GestureDetector(
      onTap: () => _onKeyPress(digit),
      onLongPress: digit == '0' ? () => _onKeyPress('+') : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder.withOpacity(0.5), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: Colors.white),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
