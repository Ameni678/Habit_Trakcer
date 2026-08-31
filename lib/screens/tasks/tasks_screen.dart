import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _taskController = TextEditingController();
  String _selectedStatus = 'À Faire';
  String _selectedPriority = 'Normal';

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _tasksRef =>
      _db.collection('users').doc(_uid).collection('tasks');

  final List<String> _statuses = ['À Faire', 'En Attente', 'En Cours', 'Terminées'];
  final List<String> _priorities = ['Normal', 'Urgent', 'Demain'];

  final Map<String, Color> _statusColors = {
    'À Faire': const Color(0xFF2196F3),
    'En Attente': const Color(0xFF9C27B0),
    'En Cours': const Color(0xFFFF9800),
    'Terminées': const Color(0xFF4CAF50),
  };

  final Map<String, Color> _priorityColors = {
    'Normal': Colors.grey,
    'Urgent': Colors.red,
    'Demain': const Color(0xFF2196F3),
  };

  Stream<List<Map<String, dynamic>>> getTasks() {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _tasksRef
        .where('date', isEqualTo: key)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _tasksRef.add({
      'title': title.trim(),
      'completed': _selectedStatus == 'Terminées',
      'status': _selectedStatus,
      'priority': _selectedPriority,
      'date': key,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _updateStatus(String taskId, String newStatus) async {
    await _tasksRef.doc(taskId).update({
      'status': newStatus,
      'completed': newStatus == 'Terminées',
    });
  }

  Future<void> _deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle Tâche',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: 'Nom de la tâche...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Statut
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Statut',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _statuses.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              )).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(height: 12),
            // Priorité
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: 'Priorité',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _priorities.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p),
              )).toList(),
              onChanged: (val) => setState(() => _selectedPriority = val!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            onPressed: () => _addTask(_taskController.text),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes Tâches',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getTasks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTasks = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: _statuses.map((status) {
              final statusTasks = allTasks
                  .where((t) => (t['status'] ?? 'À Faire') == status)
                  .toList();

              if (statusTasks.isEmpty && status != 'À Faire') {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header catégorie
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _statusColors[status],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${statusTasks.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tâches
                    if (statusTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucune tâche',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    else
                      ...statusTasks.map((task) {
                        final priority = task['priority'] ?? 'Normal';
                        return Dismissible(
                          key: Key(task['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteTask(task['id']),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                final nextStatus = status == 'Terminées'
                                    ? 'À Faire'
                                    : status == 'À Faire'
                                        ? 'En Cours'
                                        : status == 'En Cours'
                                            ? 'Terminées'
                                            : 'Terminées';
                                _updateStatus(task['id'], nextStatus);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: status == 'Terminées'
                                      ? const Color(0xFF4CAF50)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _statusColors[status]!,
                                    width: 2,
                                  ),
                                ),
                                child: status == 'Terminées'
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            ),
                            title: Text(
                              task['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                decoration: status == 'Terminées'
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: status == 'Terminées'
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            trailing: priority != 'Normal'
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _priorityColors[priority],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      priority,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2196F3),
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}