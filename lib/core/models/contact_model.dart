class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String avatarUrl;
  final bool isFavorite;
  final String category; // Family, Emergency, Business, Frequently Called
  final String whatsappNumber;
  final String telegramUsername;
  final String instagramUsername;
  final String birthday;
  final String relationship;
  final String notes;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email = '',
    this.avatarUrl = '',
    this.isFavorite = false,
    this.category = 'General',
    this.whatsappNumber = '',
    this.telegramUsername = '',
    this.instagramUsername = '',
    this.birthday = '',
    this.relationship = '',
    this.notes = '',
  });

  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    bool? isFavorite,
    String? category,
    String? whatsappNumber,
    String? telegramUsername,
    String? instagramUsername,
    String? birthday,
    String? relationship,
    String? notes,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      birthday: birthday ?? this.birthday,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'avatarUrl': avatarUrl,
      'isFavorite': isFavorite ? 1 : 0,
      'category': category,
      'whatsappNumber': whatsappNumber,
      'telegramUsername': telegramUsername,
      'instagramUsername': instagramUsername,
      'birthday': birthday,
      'relationship': relationship,
      'notes': notes,
    };
  }

  factory Contact.fromMap(Map<dynamic, dynamic> map) {
    return Contact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      category: map['category'] ?? 'General',
      whatsappNumber: map['whatsappNumber'] ?? '',
      telegramUsername: map['telegramUsername'] ?? '',
      instagramUsername: map['instagramUsername'] ?? '',
      birthday: map['birthday'] ?? '',
      relationship: map['relationship'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
