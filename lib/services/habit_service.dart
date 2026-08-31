import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _habitsRef =>
      _db.collection('users').doc(_uid).collection('habits');

  // Habitudes par défaut
  static const List<Map<String, String>> defaultHabits = [
    {'name': 'Wake up at 5 a.m.', 'icon': '⏰'},
    {'name': 'Gym', 'icon': '🏋️'},
    {'name': 'Reading', 'icon': '📚'},
    {'name': 'Learning', 'icon': '🎓'},
    {'name': 'Day Planning', 'icon': '📅'},
    {'name': 'Budget Tracking', 'icon': '💰'},
    {'name': 'Project Work', 'icon': '💼'},
    {'name': 'No Alcohol', 'icon': '🚫'},
    {'name': 'Social Media Detox', 'icon': '📵'},
    {'name': 'Goal Journey', 'icon': '🎯'},
    {'name': 'Journaling', 'icon': '✍️'},
    {'name': 'Cold Shower', 'icon': '🚿'},
  ];

  // Initialiser les habitudes par défaut
  Future<void> initDefaultHabits() async {
    final existing = await _habitsRef.get();
    if (existing.docs.isEmpty) {
      for (int i = 0; i < defaultHabits.length; i++) {
        await _habitsRef.add({
          'name': defaultHabits[i]['name'],
          'icon': defaultHabits[i]['icon'],
          'completedDays': [],
          'order': i,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Récupérer les habitudes
  Stream<List<Map<String, dynamic>>> getHabits() {
    return _habitsRef.orderBy('order').snapshots().map(
      (snap) => snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList(),
    );
  }

  // Ajouter une habitude
  Future<void> addHabit(String name, String icon) async {
    final count = (await _habitsRef.get()).docs.length;
    await _habitsRef.add({
      'name': name,
      'icon': icon,
      'completedDays': [],
      'order': count,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Cocher/décocher aujourd'hui
  Future<void> toggleToday(String habitId, List completedDays) async {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final updated = List<String>.from(completedDays);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    await _habitsRef.doc(habitId).update({'completedDays': updated});
  }

  // Supprimer une habitude
  Future<void> deleteHabit(String habitId) async {
    await _habitsRef.doc(habitId).delete();
  }

  // Vérifier si complété aujourd'hui
  bool isCompletedToday(List completedDays) {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return completedDays.contains(key);
  }
}