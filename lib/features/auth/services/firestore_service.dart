import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Save or update user in Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      Logger.info('Saving user to Firestore: ${user.email}');

      final userData = user.toFirestore();

      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(userData, SetOptions(merge: true));

      Logger.info('User saved successfully to Firestore');
    } catch (error) {
      Logger.error('Error saving user to Firestore: $error');
      rethrow;
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUser(String userId) async {
    try {
      Logger.info('Getting user from Firestore: $userId');

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        Logger.info('User found in Firestore');
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }

      Logger.info('User not found in Firestore');
      return null;
    } catch (error) {
      Logger.error('Error getting user from Firestore: $error');
      rethrow;
    }
  }

  // Stream of user data from Firestore
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update user fields
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      Logger.info('Updating user in Firestore: $userId');

      // Add timestamp for last update
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updates);

      Logger.info('User updated successfully in Firestore');
    } catch (error) {
      Logger.error('Error updating user in Firestore: $error');
      rethrow;
    }
  }

  // Update only sign-in related fields for existing users
  Future<void> updateUserSignIn(String userId) async {
    try {
      Logger.info('Updating sign-in timestamp for user: $userId');

      final updates = {
        'lastSignIn': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updates);

      Logger.info('User sign-in timestamp updated successfully');
    } catch (error) {
      Logger.error('Error updating user sign-in: $error');
      rethrow;
    }
  }

  // Delete user from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      Logger.info('Deleting user from Firestore: $userId');

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();

      Logger.info('User deleted successfully from Firestore');
    } catch (error) {
      Logger.error('Error deleting user from Firestore: $error');
      rethrow;
    }
  }
}