import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'habits/habits_screen.dart';
import 'progress/progress_screen.dart';
import 'tasks/tasks_screen.dart';
import '../services/habit_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HabitsScreen(),
    const ProgressScreen(),
    const TasksScreen(),
    const WellnessScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Habitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Tâches'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Bien-être'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ============ WELLNESS SCREEN ============
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final _habitService = HabitService();

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Heureux'},
    {'emoji': '😐', 'label': 'Neutre'},
    {'emoji': '😔', 'label': 'Triste'},
    {'emoji': '😤', 'label': 'Stressé'},
    {'emoji': '🤩', 'label': 'Motivé'},
  ];

  int _selectedMood = -1;
  int _sleepHours = 7;
  int _waterGlasses = 4;

  String _getWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return 'Semaine du ${startOfWeek.day} - ${endOfWeek.day} ${months[endOfWeek.month - 1]}';
  }

  double _getDayCompletion(List<Map<String, dynamic>> habits, int dayOffset) {
    if (habits.isEmpty) return 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final day = startOfWeek.add(Duration(days: dayOffset));
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final done = habits.where((h) => (h['completedDays'] ?? []).contains(key)).length;
    return done / habits.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _habitService.getHabits(),
        builder: (context, snapshot) {
          final habits = snapshot.data ?? [];
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Text('💚', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bien-être',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          Text(_getWeekRange(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Contenu blanc
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Humeur
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("😊 Comment tu te sens aujourd'hui ?",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: List.generate(_moods.length, (i) {
                                    final isSelected = _selectedMood == i;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedMood = i),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected
                                              ? Border.all(color: const Color(0xFF1565C0), width: 2)
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(_moods[i]['emoji'], style: const TextStyle(fontSize: 28)),
                                            Text(
                                              _moods[i]['label'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Sommeil + Eau
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EAF6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('😴 Sommeil',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() { if (_sleepHours > 0) _sleepHours--; }),
                                            child: const Icon(Icons.remove_circle_outline, color: Color(0xFF1565C0)),
                                          ),
                                          Text('$_sleepHours h',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1565C0))),
                                          GestureDetector(
                                            onTap: () => setState(() { if (_sleepHours < 12) _sleepHours++; }),
                                            child: const Icon(Icons.add_circle_outline, color: Color(0xFF1565C0)),
                                          ),
                                        ],
                                      ),
                                      const Text('heures de sommeil',
                                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('💧 Eau',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() { if (_waterGlasses > 0) _waterGlasses--; }),
                                            child: const Icon(Icons.remove_circle_outline, color: Color(0xFF1565C0)),
                                          ),
                                          Text('$_waterGlasses',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1565C0))),
                                          GestureDetector(
                                            onTap: () => setState(() { if (_waterGlasses < 12) _waterGlasses++; }),
                                            child: const Icon(Icons.add_circle_outline, color: Color(0xFF1565C0)),
                                          ),
                                        ],
                                      ),
                                      const Text("verres d'eau",
                                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Graphe barres
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📊 Progression hebdomadaire',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 100,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: 1,
                                      barTouchData: BarTouchData(enabled: false),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                                              return Text(days[value.toInt()],
                                                  style: const TextStyle(fontSize: 11, color: Colors.black54));
                                            },
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      barGroups: List.generate(7, (i) {
                                        final val = _getDayCompletion(habits, i);
                                        return BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: val == 0 ? 0.05 : val,
                                              color: const Color(0xFF90CAF9),
                                              width: 16,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mes Habitudes
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const Text('📋 Mes Habitudes',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('${habits.length} habits',
                                            style: const TextStyle(
                                                color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                                ...habits.take(5).map((habit) {
                                  final isDone = _habitService.isCompletedToday(habit['completedDays'] ?? []);
                                  final count = (habit['completedDays'] ?? []).length;
                                  return ListTile(
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(habit['icon'] ?? '⭐', style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                    title: Text(habit['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text('$count jours complétés',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    trailing: Icon(
                                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isDone ? const Color(0xFF4CAF50) : Colors.grey,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============ PROFILE SCREEN ============
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec Avatar et Nom/Email
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bloc blanc avec nom, email et déconnexion
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Nom
                      ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF1565C0)),
                        title: const Text('Nom', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        subtitle: Text(
                          user?.displayName ?? user?.email?.split('@')[0] ?? 'Non défini',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      ),
                      const Divider(height: 1),

                      // Email/Adresse
                      ListTile(
                        leading: const Icon(Icons.email, color: Color(0xFF1565C0)),
                        title: const Text('Email', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        subtitle: Text(
                          user?.email ?? 'Non défini',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      ),

                      const Spacer(),

                      // Bouton Déconnexion
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            await _auth.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}