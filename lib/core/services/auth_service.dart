import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class UserCredentials {
  final String email;
  final String passwordHash;
  final String name;

  UserCredentials({
    required this.email,
    required this.passwordHash,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
    };
  }

  factory UserCredentials.fromJson(Map<String, dynamic> json) {
    return UserCredentials(
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      name: json['name'] as String,
    );
  }
}

class AuthService {
  static const String _usersKey = 'registered_users';

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> emailExists(String email) async {
    try {
      final users = await _getAllUsers();
      return users.any((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final users = await _getAllUsers();
      
      // Check if email already exists
      if (users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
        return false; // Email already registered
      }

      // Create new user
      final passwordHash = _hashPassword(password);
      final newUser = UserCredentials(
        email: email,
        passwordHash: passwordHash,
        name: name,
      );

      users.add(newUser);
      await _saveAllUsers(users);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final users = await _getAllUsers();
      final emailLower = email.toLowerCase();
      
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == emailLower,
        orElse: () => throw Exception('User not found'),
      );

      final passwordHash = _hashPassword(password);
      if (user.passwordHash == passwordHash) {
        // Update current user profile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode({
          'name': user.name,
          'email': user.email,
          'profilePicturePath': null,
        }));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserCredentials?> getUserByEmail(String email) async {
    try {
      final users = await _getAllUsers();
      final emailLower = email.toLowerCase();
      return users.firstWhere(
        (u) => u.email.toLowerCase() == emailLower,
        orElse: () => throw Exception('User not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<UserCredentials>> _getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        return usersList.map((json) => UserCredentials.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveAllUsers(List<UserCredentials> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = json.encode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, usersJson);
    } catch (e) {
      // Handle error silently
    }
  }
}

