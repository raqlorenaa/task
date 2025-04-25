import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:task_app/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _taskController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String filtro = 'todos'; // 'todos', 'pendentes', 'concluidos'

  void _addTask() async {
    final task = _taskController.text.trim();
    if (task.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'uid': user?.uid,
        'title': task,
        'description': '',
        'done': false,
        'favorite': false,
        'timestamp': Timestamp.now(),
      });
      _taskController.clear();
    }
  }

  void _toggleDone(String docId, bool done) async {
    await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
      'done': !done,
    });
  }

  void _toggleFavorite(String docId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
      'favorite': !currentValue,
    });
  }

  void _editTask(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title']);
    final descController =
        TextEditingController(text: data['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Tarefa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título')),
            TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(doc.id)
                  .update({
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
              });
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String docId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _taskStream() {
    var query = FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: user?.uid);

    if (filtro == 'pendentes') {
      query = query.where('done', isEqualTo: false);
    } else if (filtro == 'concluidos') {
      query = query.where('done', isEqualTo: true);
    } else if (filtro == 'favoritas') {
      query = query.where('favorite', isEqualTo: true);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Data indisponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => Get.changeThemeMode(
                Get.isDarkMode ? ThemeMode.light : ThemeMode.dark),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => filtro = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'todos', child: Text('Todas')),
              PopupMenuItem(value: 'pendentes', child: Text('Pendentes')),
              PopupMenuItem(value: 'favoritas', child: Text('Favoritas')),
              PopupMenuItem(value: 'concluidos', child: Text('Concluídas')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthController.to.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Nova tarefa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _taskStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar tarefas.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data?.docs ?? [];

                if (tasks.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma tarefa encontrada.'));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final data = task.data();

                    final title = data['title'] ?? 'Sem título';
                    final done = data['done'] ?? false;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final time = _formatTimestamp(timestamp);

                    return ListTile(
                      leading: Checkbox(
                        value: done,
                        onChanged: (_) => _toggleDone(task.id, done),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                          '${data['description'] ?? ''}\nCriado em: $time'),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: Icon(
                              data['favorite'] == true
                                  ? Icons.star
                                  : Icons.star_border,
                              color: data['favorite'] == true
                                  ? Colors.amber
                                  : null,
                            ),
                            onPressed: () => _toggleFavorite(
                                task.id, data['favorite'] ?? false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTask(task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
