import 'package:flutter/material.dart';
import '../../models/teacher.dart';
import '../../services/teachers_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'create_teacher_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _service = TeachersService();
  late Future<List<Teacher>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getTeachers();
  }

  Future<void> _reload() async {
    final future = _service.getTeachers();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTeacherScreen()),
    );
    if (created == true && mounted) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Docente registrado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docentes'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: SofiaColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo docente'),
      ),
      body: FutureBuilder<List<Teacher>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: SofiaColors.soft),
                    const SizedBox(height: 12),
                    Text(
                      snap.error is ApiException
                          ? (snap.error as ApiException).message
                          : 'No se pudieron cargar los docentes.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: SofiaColors.soft),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: _reload, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final teachers = snap.data ?? [];
          if (teachers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 48, color: SofiaColors.soft),
                    SizedBox(height: 12),
                    Text('Aún no hay docentes',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: SofiaColors.ink)),
                    SizedBox(height: 6),
                    Text('Toca “Nuevo docente” para registrar el primero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: SofiaColors.soft)),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: teachers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TeacherCard(teacher: teachers[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  const _TeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final groupNames =
        teacher.classes.map((c) => c.groupName).toSet().toList();
    final subtitle = teacher.classes.isEmpty
        ? 'Sin grupos asignados'
        : '${teacher.classes.length} clase(s) · ${groupNames.join(", ")}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: SofiaColors.brand.withValues(alpha: 0.12),
            child: Text(
              teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: SofiaColors.brand, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SofiaColors.ink)),
                const SizedBox(height: 2),
                Text(teacher.email,
                    style:
                        const TextStyle(color: SofiaColors.soft, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: SofiaColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}