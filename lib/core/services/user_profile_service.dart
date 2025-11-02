import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String? email;
  final String? profilePicturePath;

  UserProfile({
    required this.name,
    this.email,
    this.profilePicturePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'profilePicturePath': profilePicturePath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String?,
      profilePicturePath: json['profilePicturePath'] as String?,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? profilePicturePath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }
}

class UserProfileService {
  static const String _profileKey = 'user_profile';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<UserProfile> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        final Map<String, dynamic> profile = json.decode(profileJson);
        return UserProfile.fromJson(profile);
      }
      
      // Return default profile (will be updated when user logs in)
      return UserProfile(
        name: 'User',
        email: null,
      );
    } catch (e) {
      return UserProfile(
        name: 'User',
        email: null,
      );
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, json.encode(profile.toJson()));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> updateName(String name) async {
    final profile = await getProfile();
    await saveProfile(profile.copyWith(name: name));
  }

  Future<void> updateEmail(String email) async {
    final profile = await getProfile();
    await saveProfile(profile.copyWith(email: email));
  }

  Future<void> updateProfilePicture(String? path) async {
    final profile = await getProfile();
    await saveProfile(profile.copyWith(profilePicturePath: path));
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? true; // Default to logged in
    } catch (e) {
      return true;
    }
  }

  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, isLoggedIn);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> logout() async {
    await setLoggedIn(false);
    // Optionally clear profile data or keep it for next login
  }
}


