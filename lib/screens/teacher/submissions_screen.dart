import 'package:flutter/material.dart';
import '../../models/submission.dart';
import '../../services/tasks_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class SubmissionsScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  const SubmissionsScreen(
      {super.key, required this.taskId, required this.taskTitle});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final _service = TasksService();
  late Future<SubmissionRoster> _future;
  List<SubmissionStudent> _students = [];
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SubmissionRoster> _load() async {
    final roster = await _service.getSubmissions(widget.taskId);
    _students = roster.students;
    return roster;
  }

  Future<void> _save() async {
    setState(() => _error = null);

    // Valida calificaciones (0–10) donde haya texto.
    for (final s in _students) {
      final t = s.gradeText.trim();
      if (t.isNotEmpty) {
        final v = s.gradeValue;
        if (v == null) {
          setState(() => _error = 'Calificación inválida en ${s.name}');
          return;
        }
        if (v < 0 || v > 10) {
          setState(() => _error = 'La calificación de ${s.name} debe ser 0–10');
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      await _service.saveSubmissions(widget.taskId, _students);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entregas guardadas')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() =>
          _error = e is ApiException ? e.message : 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      body: FutureBuilder<SubmissionRoster>(
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
                    : 'No se pudo cargar.',
                style: const TextStyle(color: SofiaColors.soft),
              ),
            );
          }
          if (_students.isEmpty) {
            return const Center(
              child: Text('Este grupo no tiene alumnos.',
                  style: TextStyle(color: SofiaColors.soft)),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.taskTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: SofiaColors.ink)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFECEAE3)),
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: SofiaColors.ink)),
                          ),
                          // Entregó
                          Row(
                            children: [
                              const Text('Entregó',
                                  style: TextStyle(
                                      fontSize: 12, color: SofiaColors.soft)),
                              Switch(
                                value: s.delivered,
                                activeThumbColor: const Color(0xFF2E8C68),
                                onChanged: (v) =>
                                    setState(() => s.delivered = v),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          // Calificación
                          SizedBox(
                            width: 64,
                            child: TextFormField(
                              key: ObjectKey(s),
                              initialValue: s.gradeText,
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                hintText: '—',
                                labelText: 'Calif.',
                                isDense: true,
                              ),
                              onChanged: (v) => s.gradeText = v,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFC6503B), fontSize: 13)),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Guardar entregas'),
          ),
        ),
      ),
    );
  }
}