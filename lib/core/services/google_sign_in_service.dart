import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../di/injection.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final AuthService _authService = getIt<AuthService>();
  final UserProfileService _profileService = getIt<UserProfileService>();

  Future<GoogleSignInResult> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return GoogleSignInResult(
          success: false,
          message: 'Sign-in was canceled',
        );
      }

      // Get user details
      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'User';
      final photoUrl = googleUser.photoUrl;

      if (email == null || email.isEmpty) {
        return GoogleSignInResult(
          success: false,
          message: 'Unable to get email from Google account',
        );
      }

      // Check if user already exists
      final emailExists = await _authService.emailExists(email);
      
      if (!emailExists) {
        // New user - register them with a dummy password (Google auth users don't need password)
        // Using a random secure token as password since we won't use it for Google auth
        final dummyPassword = 'google_auth_${DateTime.now().millisecondsSinceEpoch}';
        final registered = await _authService.registerUser(
          email: email,
          password: dummyPassword,
          name: displayName,
        );

        if (!registered) {
          return GoogleSignInResult(
            success: false,
            message: 'Failed to register user',
          );
        }
      }

      // Save profile data
      await _profileService.saveProfile(
        UserProfile(
          name: displayName,
          email: email,
          profilePicturePath: photoUrl,
        ),
      );

      // Set logged in status
      await _profileService.setLoggedIn(true);

      return GoogleSignInResult(
        success: true,
        email: email,
        name: displayName,
        photoUrl: photoUrl,
      );
    } catch (e) {
      return GoogleSignInResult(
        success: false,
        message: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }
}

class GoogleSignInResult {
  final bool success;
  final String? message;
  final String? email;
  final String? name;
  final String? photoUrl;

  GoogleSignInResult({
    required this.success,
    this.message,
    this.email,
    this.name,
    this.photoUrl,
  });
}

