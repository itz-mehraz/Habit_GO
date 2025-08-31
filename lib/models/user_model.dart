class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isDarkMode;
  final List<String> favoriteQuotes;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.gender,
    this.dateOfBirth,
    this.height,
    required this.createdAt,
    required this.lastUpdated,
    this.isDarkMode = false,
    this.favoriteQuotes = const [],
    this.profilePictureUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      height: map['height']?.toDouble(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.parse(map['lastUpdated']) 
          : DateTime.now(),
      isDarkMode: map['isDarkMode'] ?? false,
      favoriteQuotes: List<String>.from(map['favoriteQuotes'] ?? []),
      profilePictureUrl: map['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'height': height,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDarkMode': isDarkMode,
      'favoriteQuotes': favoriteQuotes,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    bool? isDarkMode,
    List<String>? favoriteQuotes,
    String? profilePictureUrl,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
      isDarkMode: isDarkMode ?? this.isDarkMode,
      favoriteQuotes: favoriteQuotes ?? this.favoriteQuotes,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
