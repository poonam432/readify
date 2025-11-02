import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_profile_service.dart';
import '../di/injection.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserProfileService _profileService = getIt<UserProfileService>();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Load existing profile first to preserve name if Firebase doesn't have displayName
        final existingProfile = await _profileService.getProfile();
        final userName = userCredential.user!.displayName ?? 
                         existingProfile.name ??
                         userCredential.user!.email?.split('@')[0] ?? 
                         'User';
        
        // Save profile ensuring name is preserved
        await _profileService.saveProfile(
          UserProfile(
            name: userName,
            email: userCredential.user!.email,
            profilePicturePath: userCredential.user!.photoURL ?? existingProfile.profilePicturePath,
          ),
        );
        await _profileService.setLoggedIn(true);
        return AuthResult(success: true);
      }

      return AuthResult(
        success: false,
        message: 'Sign in failed',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name in Firebase
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
        
        // Save profile with the provided name (not waiting for Firebase to sync)
        await _profileService.saveProfile(
          UserProfile(
            name: name,
            email: userCredential.user!.email,
            profilePicturePath: userCredential.user!.photoURL,
          ),
        );
        await _profileService.setLoggedIn(true);
        return AuthResult(success: true);
      }

      return AuthResult(
        success: false,
        message: 'Registration failed',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult(
          success: false,
          message: 'Sign-in was canceled',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Get name from Google account or Firebase user
        final userName = googleUser.displayName ?? 
                         userCredential.user!.displayName ??
                         userCredential.user!.email?.split('@')[0] ?? 
                         'User';
        
        // Save profile with Google account name
        await _profileService.saveProfile(
          UserProfile(
            name: userName,
            email: userCredential.user!.email ?? googleUser.email,
            profilePicturePath: userCredential.user!.photoURL ?? googleUser.photoUrl,
          ),
        );
        await _profileService.setLoggedIn(true);
        return AuthResult(success: true);
      }

      return AuthResult(
        success: false,
        message: 'Google Sign-In failed',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Google Sign-In failed: ${e.toString()}',
      );
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _profileService.setLoggedIn(false);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveUserProfile(User user) async {
    // Load existing profile to preserve name if Firebase doesn't have displayName
    final existingProfile = await _profileService.getProfile();
    final userName = user.displayName ?? 
                     existingProfile.name ??
                     user.email?.split('@')[0] ?? 
                     'User';
    
    await _profileService.saveProfile(
      UserProfile(
        name: userName,
        email: user.email,
        profilePicturePath: user.photoURL ?? existingProfile.profilePicturePath,
      ),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An authentication error occurred.';
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;

  AuthResult({
    required this.success,
    this.message,
  });
}

