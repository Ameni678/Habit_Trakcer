import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/habit_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _habitService = HabitService();

  final List<String> _quotes = [
    '"Chaque petit pas compte.\nContinue d\'avancer."',
    '"La discipline est le pont entre\nles objectifs et les accomplissements."',
    '"Le succès n\'est pas final,\nl\'échec n\'est pas fatal."',
    '"Commence là où tu es,\nutilise ce que tu as."',
    '"Un jour à la fois,\nun pas à la fois."',
    '"La constance bat le talent\nquand le talent n\'est pas constant."',
    '"Chaque matin est\nune nouvelle chance."',
  ];

  String get _todayQuote {
    final dayIndex = DateTime.now().weekday - 1;
    return _quotes[dayIndex % _quotes.length];
  }

  String _getBestDay(List<Map<String, dynamic>> habits) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final counts = List<int>.filled(7, 0);

    for (final habit in habits) {
      final completedDays = List<String>.from(habit['completedDays'] ?? []);
      for (final dateStr in completedDays) {
        try {
          final date = DateTime.parse(dateStr);
          counts[date.weekday - 1]++;
        } catch (_) {}
      }
    }

    int maxIndex = 0;
    for (int i = 1; i < 7; i++) {
      if (counts[i] > counts[maxIndex]) maxIndex = i;
    }
    return counts[maxIndex] == 0 ? 'Pas encore de données' : days[maxIndex];
  }

  String _getWorstDay(List<Map<String, dynamic>> habits) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final counts = List<int>.filled(7, 0);

    for (final habit in habits) {
      final completedDays = List<String>.from(habit['completedDays'] ?? []);
      for (final dateStr in completedDays) {
        try {
          final date = DateTime.parse(dateStr);
          counts[date.weekday - 1]++;
        } catch (_) {}
      }
    }

    int minIndex = 0;
    for (int i = 1; i < 7; i++) {
      if (counts[i] < counts[minIndex]) minIndex = i;
    }
    return counts[minIndex] == 0 ? 'Pas encore de données' : days[minIndex];
  }

  String _getBestHabit(List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 'Pas encore de données';
    Map<String, dynamic>? best;
    int maxCount = 0;
    for (final h in habits) {
      final count = (h['completedDays'] ?? []).length;
      if (count > maxCount) {
        maxCount = count;
        best = h;
      }
    }
    return best != null ? '${best['icon']} ${best['name']}' : 'Pas encore de données';
  }

  String _getWorstHabit(List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 'Pas encore de données';
    Map<String, dynamic>? worst;
    int minCount = 999;
    for (final h in habits) {
      final count = (h['completedDays'] ?? []).length;
      if (count < minCount) {
        minCount = count;
        worst = h;
      }
    }
    return worst != null ? '${worst['icon']} ${worst['name']}' : 'Pas encore de données';
  }

  Map<String, dynamic> _getWeeklyBadge(int completedThisWeek) {
    if (completedThisWeek >= 50) {
      return {'name': 'Champion 🏆', 'desc': 'Incroyable cette semaine !', 'color': const Color(0xFF9C27B0)};
    } else if (completedThisWeek >= 30) {
      return {'name': 'Discipline ⭐', 'desc': 'Super semaine !', 'color': const Color.fromARGB(255, 202, 186, 40)};
    } else if (completedThisWeek >= 10) {
      return {'name': 'Progressif 📈', 'desc': 'Continue comme ça !', 'color': const Color(0xFF2196F3)};
    } else {
      return {'name': 'Débutant 🚀', 'desc': 'Commence à construire !', 'color': const Color(0xFF42A5F5)};
    }
  }

  int _getCompletionsThisWeek(List<Map<String, dynamic>> habits) {
    int count = 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    for (final habit in habits) {
      final completedDays = List<String>.from(habit['completedDays'] ?? []);
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        if (completedDays.contains(key)) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: const Text(
          'Analyse & Motivation',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _habitService.getHabits(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final habits = snapshot.data!;
          final completed = habits
              .where((h) => _habitService.isCompletedToday(h['completedDays'] ?? []))
              .length;
          final total = habits.length;
          final percent = total == 0 ? 0.0 : completed / total;
          final percentInt = (percent * 100).round();
          final weeklyCount = _getCompletionsThisWeek(habits);
          final badge = _getWeeklyBadge(weeklyCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Succès\ncette semaine',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 20),
                                const SizedBox(width: 6),
                                Text('$percentInt%',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$weeklyCount habitudes\ncette semaine',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    value: percent * 100,
                                    color: const Color(0xFF1565C0),
                                    radius: 20,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: (1 - percent) * 100,
                                    color: const Color(0xFFFFEB3B),
                                    radius: 20,
                                    showTitle: false,
                                  ),
                                ],
                              ),
                            ),
                            Text('$percentInt%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('💡', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Insights du jour',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InsightItem('🏆 Meilleure habitude : ${_getBestHabit(habits)}'),
                      _InsightItem('📅 Meilleur jour : ${_getBestDay(habits)}'),
                      _InsightItem('⚠️ À améliorer : ${_getWorstHabit(habits)}'),
                      _InsightItem('😴 Jour difficile : ${_getWorstDay(habits)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Motivation du jour',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _todayQuote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badge de la semaine 🏅',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: badge['color'],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(badge['name'],
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 238, 229, 229),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22)),
                            const SizedBox(height: 6),
                            Text(badge['desc'],
                                style: const TextStyle(color: Color.fromARGB(179, 235, 230, 230), fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('$weeklyCount habitudes complétées cette semaine',
                                style: const TextStyle(color: Color.fromARGB(255, 230, 222, 222), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
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

class _InsightItem extends StatelessWidget {
  final String text;
  const _InsightItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}