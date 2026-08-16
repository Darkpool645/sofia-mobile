import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/tasks_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'submissions_screen.dart';

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

Color _typeColor(String type) {
  switch (type) {
    case 'EXAMEN':
      return const Color(0xFFC6503B);
    case 'ACTIVIDAD':
      return const Color(0xFF2E8C68);
    default:
      return SofiaColors.brand;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'EXAMEN':
      return 'Examen';
    case 'ACTIVIDAD':
      return 'Actividad';
    default:
      return 'Tarea';
  }
}

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final _service = TasksService();
  late Future<List<TeacherTask>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyTasks();
  }

  Future<void> _reload() async {
    final f = _service.getMyTasks();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis publicaciones'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      body: FutureBuilder<List<TeacherTask>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                snap.error is ApiException
                    ? (snap.error as ApiException).message
                    : 'No se pudieron cargar tus publicaciones.',
                style: const TextStyle(color: SofiaColors.soft),
              ),
            );
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
            return const Center(
              child: Text('Aún no has publicado nada.',
                  style: TextStyle(color: SofiaColors.soft)),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = tasks[i];
                final color = _typeColor(t.type);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SubmissionsScreen(taskId: t.id, taskTitle: t.title),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFECEAE3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(_typeLabel(t.type),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 8),
                              Text(t.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: SofiaColors.ink)),
                              const SizedBox(height: 2),
                              Text(
                                '${t.groupName} · entrega ${_fmtDate(t.dueDate)}',
                                style: const TextStyle(
                                    color: SofiaColors.soft, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF9AA0AE)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}