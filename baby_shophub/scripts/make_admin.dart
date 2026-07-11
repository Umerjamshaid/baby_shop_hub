// Simple script to make a user an admin
// Run with: dart scripts/make_admin.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // User ID to make admin (replace with actual user ID)
  String userId = 'qno0HQOYHhTxfvCFbx0AVnCHrdz1'; // Replace with your user ID

  try {
    // Update user role to admin
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': 'admin',
    });

    print('User $userId has been made an admin successfully!');
  } catch (e) {
    print('Error making user admin: $e');
  }
}
