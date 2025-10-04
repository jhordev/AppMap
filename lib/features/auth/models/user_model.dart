import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSignIn;
  final bool isActive;
  final String? phoneNumber;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.lastSignIn,
    this.isActive = true,
    this.phoneNumber,
  });

  // Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSignIn: DateTime.now(),
      isActive: true,
    );
  }

  // Create UserModel from Firestore data
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSignIn': lastSignIn != null
          ? Timestamp.fromDate(lastSignIn!)
          : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSignIn,
    bool? isActive,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, displayName: $displayName, isActive: $isActive}';
  }
}