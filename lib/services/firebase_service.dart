import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload unsynced reminders to Firestore
  Future<void> uploadUnsyncedReminders(List<ReminderModel> reminders) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    for (final reminder in reminders.where((r) => !r.synced)) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder.id.toString());
      batch.set(docRef, reminder.toMap());
    }
    await batch.commit();
  }

  // Download reminders from Firestore and return them
  Future<List<ReminderModel>> downloadReminders() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .get();
    return snapshot.docs
        .map((doc) => ReminderModel.fromMap(doc.data()))
        .toList();
  }

  // Mark reminders as synced in Firestore
  Future<void> markRemindersSynced(List<ReminderModel> reminders) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    for (final reminder in reminders) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder.id.toString());
      batch.update(docRef, {'synced': true});
    }
    await batch.commit();
  }
}
