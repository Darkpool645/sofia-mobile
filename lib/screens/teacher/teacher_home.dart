import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_slot.dart';
import '../../models/teacher.dart' show dayNames;
import '../../services/portal_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import './create_task_scren.dart';
import 'attendance_screen.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final _portal = PortalService();
  late Future<List<ClassSlot>> _future;
  List<ClassSlot> _slots = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ClassSlot>> _load() async {
    _slots = await _portal.getMyClasses();
    return _slots;
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  // Clase en curso: coincide día y la hora actual cae en el rango.
  ClassSlot? _currentClass() {
    final now = DateTime.now();
    final nowStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    for (final s in _slots) {
      if (s.dayOfWeek == now.weekday &&
          s.startTime.compareTo(nowStr) <= 0 &&
          nowStr.compareTo(s.endTime) <= 0) {
        return s;
      }
    }
    return null;
  }

  // Grupos distintos (para el resumen y para el compositor).
  List<ClassGroup> _distinctGroups() {
    final map = <String, ClassGroup>{};
    for (final s in _slots) {
      map[s.group.id] = s.group;
    }
    return map.values.toList();
  }

  Future<void> _openComposer() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => CreateTaskScreen(groups: _distinctGroups())),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Publicación creada')));
    }
  }

  Future<void> _openAttendance(ClassSlot slot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AttendanceScreen(slot: slot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SofiaColors.paper,
        elevation: 0,
        title: const Text('Docente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: SofiaColors.soft),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: FutureBuilder<List<ClassSlot>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    snap.error is ApiException
                        ? (snap.error as ApiException).message
                        : 'No se pudo cargar tu información.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: SofiaColors.soft),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _reload, child: const Text('Reintentar')),
                ]),
              ),
            );
          }

          final current = _currentClass();
          final groups = _distinctGroups();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Hola, ${user?.name ?? ''}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: SofiaColors.ink)),
                const SizedBox(height: 16),

                // Clase en curso → pase de lista
                if (current != null) _currentClassCard(current),

                // Compositor tipo post
                _composerBox(),
                const SizedBox(height: 20),

                // Resumen de grupos
                Text('Tus grupos (${groups.length})',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Color(0xFF9AA0AE))),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Aún no tienes grupos asignados.',
                          style: TextStyle(color: SofiaColors.soft)),
                    ),
                  )
                else
                  ...groups.map((g) => _groupCard(g)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _currentClassCard(ClassSlot s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SofiaColors.brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: SofiaColors.gold, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('CLASE EN CURSO',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(s.subject,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${s.group.name} · ${s.startTime}–${s.endTime}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: SofiaColors.gold,
                  foregroundColor: SofiaColors.ink),
              onPressed: () => _openAttendance(s),
              icon: const Icon(Icons.checklist),
              label: const Text('Pasar lista'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composerBox() {
    return InkWell(
      onTap: _openComposer,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEAE3)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEAECF3),
              child: Icon(Icons.edit, size: 18, color: SofiaColors.brand),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('¿Qué vas a asignar hoy?',
                  style: TextStyle(color: SofiaColors.soft, fontSize: 15)),
            ),
            Icon(Icons.add_circle, color: SofiaColors.brand),
          ],
        ),
      ),
    );
  }

  Widget _groupCard(ClassGroup g) {
    // Materias/horarios que el docente da en este grupo.
    final slots = _slots.where((s) => s.group.id == g.id).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SofiaColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(g.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: SofiaColors.brand,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grupo ${g.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: SofiaColors.ink)),
                  Text('${g.studentCount} alumnos',
                      style: const TextStyle(
                          color: SofiaColors.soft, fontSize: 13)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...slots.map((s) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Color(0xFF9AA0AE)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${s.subject} · ${dayNames[s.dayOfWeek] ?? ""} ${s.startTime}–${s.endTime}',
                        style: const TextStyle(
                            fontSize: 12.5, color: SofiaColors.soft),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}