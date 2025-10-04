import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import '../../../utils/logger.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Stream of auth state changes
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  // Get current user from Firebase Auth only (sync)
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  // Get current user with Firestore data (async)
  Future<UserModel?> getCurrentUserWithFirestore() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final firestoreUser = await _firestoreService.getUser(user.uid);
        return firestoreUser ?? UserModel.fromFirebaseUser(user);
      } catch (error) {
        Logger.error('Error getting user from Firestore: $error');
        return UserModel.fromFirebaseUser(user);
      }
    }
    return null;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      Logger.info('Starting Google Sign-In process');

      // Clear any previous Google Sign-In session to prevent issues
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Logger.info('Google Sign-In cancelled by user');
        return null; // The user canceled the sign-in
      }

      Logger.info('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      Logger.info('Google authentication obtained');
      Logger.info('Access token: ${googleAuth.accessToken != null ? 'Present' : 'Missing'}');
      Logger.info('ID token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Missing Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      Logger.info('Firebase credential created');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      Logger.info('Firebase authentication completed');

      final user = userCredential.user;
      if (user != null) {
        Logger.info('Google Sign-In successful for user: ${user.email}');

        // Create UserModel from Firebase user
        final userModel = UserModel.fromFirebaseUser(user);

        // Handle user in Firestore - check if exists, create or update as needed
        try {
          Logger.info('Checking if user exists in Firestore: ${user.uid}');

          // First, check if user already exists in Firestore
          final existingUser = await _firestoreService.getUser(user.uid);

          if (existingUser != null) {
            Logger.info('User already exists in Firestore - ${existingUser.email}');
            Logger.info('Updating only necessary fields (lastSignIn)');

            // User exists, only update lastSignIn timestamp and other non-destructive fields
            await _firestoreService.updateUserSignIn(user.uid);

            // Return existing user with updated data
            final updatedUser = await _firestoreService.getUser(user.uid);
            return updatedUser ?? existingUser;

          } else {
            Logger.info('New user - creating Firestore record: ${user.email}');

            // New user, save complete profile to Firestore
            await _firestoreService.saveUser(userModel);
            Logger.info('New user saved to Firestore successfully');

            // Get the saved user from Firestore (with timestamps)
            final savedUser = await _firestoreService.getUser(user.uid);
            return savedUser ?? userModel;
          }

        } catch (error) {
          Logger.warning('Firestore error: $error');

          // Handle specific Firestore errors
          if (error.toString().contains('database') &&
              error.toString().contains('does not exist')) {
            Logger.error('Please create Firestore database in Firebase Console:');
            Logger.error('https://console.firebase.google.com/project/appmap-1ef34/firestore');
          } else if (error.toString().contains('cloud-resource-location-not-set')) {
            Logger.error('⚠️ FIRESTORE LOCATION NOT SET ⚠️');
            Logger.error('Please set Firestore location in Firebase Console');
          } else if (error.toString().contains('permission-denied')) {
            Logger.error('⚠️ FIRESTORE PERMISSIONS ERROR ⚠️');
            Logger.error('Please check Firestore security rules');
          }

          // Return user from Firebase Auth even if Firestore fails
          Logger.info('Continuing with Firebase Auth user data only');
          return userModel;
        }
      }

      throw Exception('Failed to get user after Firebase authentication');
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage = 'Error de autenticación';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'Ya existe una cuenta con este email usando otro método de autenticación';
          break;
        case 'invalid-credential':
          errorMessage = 'Credenciales de Google inválidas';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Autenticación con Google no está habilitada';
          break;
        case 'user-disabled':
          errorMessage = 'La cuenta del usuario está deshabilitada';
          break;
        case 'user-not-found':
          errorMessage = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (error) {
      Logger.error('Error during Google Sign-In: $error');

      // Provide more specific error messages
      String errorMessage = 'Error al iniciar sesión con Google';

      if (error.toString().contains('network')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      } else if (error.toString().contains('canceled') || error.toString().contains('cancelled')) {
        errorMessage = 'Inicio de sesión cancelado';
      } else if (error.toString().contains('sign_in_failed')) {
        errorMessage = 'Falló el inicio de sesión. Verifica la configuración de Google Sign-In';
      } else if (error.toString().contains('sign_in_required')) {
        errorMessage = 'Se requiere autenticación. Intenta nuevamente';
      }

      throw Exception(errorMessage);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      Logger.info('Signing out user');
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      Logger.info('User signed out successfully');
    } catch (error) {
      Logger.error('Error during sign out: $error');
      rethrow;
    }
  }
}