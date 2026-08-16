import 'package:flutter/material.dart';
import '../../models/class_slot.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

const _present = 'PRESENTE';
const _absent = 'AUSENTE';

String _fmtDay(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AttendanceScreen extends StatefulWidget {
  final ClassSlot slot;
  const AttendanceScreen({super.key, required this.slot});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AttendanceService();

  DateTime _date = DateTime.now();
  late Future<Roster> _future;
  List<RosterStudent> _students = [];
  bool _editable = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Roster> _load() async {
    final roster = await _service.getRoster(widget.slot.id, date: _fmtDay(_date));
    _students = roster.students;
    _editable = roster.editable;
    return roster;
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now, // no fechas futuras
    );
    if (picked != null) {
      _date = picked;
      _reload();
    }
  }

  int get _presentCount =>
      _students.where((s) => s.status == _present).length;
  int get _absentCount => _students.where((s) => s.status == _absent).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.save(widget.slot.id, _students, date: _fmtDay(_date));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asistencia guardada')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(e is ApiException ? e.message : 'No se pudo guardar')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia · ${widget.slot.group.name}'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selector de fecha
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18, color: SofiaColors.soft),
                const SizedBox(width: 8),
                Text(_fmtDay(_date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: SofiaColors.ink)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Cambiar fecha'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Roster>(
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
                          : 'No se pudo cargar la lista.',
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
                    // Banner de estado (editable / solo lectura)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _editable
                            ? const Color(0xFF2E8C68).withValues(alpha: 0.10)
                            : const Color(0xFF9AA0AE).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(_editable ? Icons.edit : Icons.lock_outline,
                              size: 16,
                              color: _editable
                                  ? const Color(0xFF2E8C68)
                                  : SofiaColors.soft),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _editable
                                  ? 'Puedes registrar la asistencia de hoy.'
                                  : 'Solo lectura. Esta lista ya no se puede modificar.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: _editable
                                      ? const Color(0xFF2E8C68)
                                      : SofiaColors.soft,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_editable)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Row(
                          children: [
                            _pill('$_presentCount presentes',
                                const Color(0xFF2E8C68)),
                            const SizedBox(width: 8),
                            _pill('$_absentCount ausentes',
                                const Color(0xFFC6503B)),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() {
                                for (final s in _students) {
                                  s.status = _present;
                                }
                              }),
                              child: const Text('Todos presentes'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFECEAE3)),
                        itemBuilder: (_, i) =>
                            _editable ? _editableRow(_students[i]) : _readonlyRow(_students[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _editable
          ? SafeArea(
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
                      : const Text('Guardar asistencia'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _editableRow(RosterStudent s) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(s.name,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: SofiaColors.ink)),
          ),
        ),
        _toggle(
          icon: Icons.check,
          on: s.status == _present,
          onColor: const Color(0xFF2E8C68),
          onTap: () => setState(
              () => s.status = s.status == _present ? null : _present),
        ),
        const SizedBox(width: 8),
        _toggle(
          icon: Icons.close,
          on: s.status == _absent,
          onColor: const Color(0xFFC6503B),
          onTap: () =>
              setState(() => s.status = s.status == _absent ? null : _absent),
        ),
      ],
    );
  }

  Widget _readonlyRow(RosterStudent s) {
    final label = s.status == _present
        ? 'Presente'
        : s.status == _absent
            ? 'Ausente'
            : s.status == 'RETARDO'
                ? 'Retardo'
                : 'Sin registro';
    final color = s.status == _present
        ? const Color(0xFF2E8C68)
        : s.status == _absent
            ? const Color(0xFFC6503B)
            : SofiaColors.soft;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(s.name,
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: SofiaColors.ink)),
          ),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );

  Widget _toggle({
    required IconData icon,
    required bool on,
    required Color onColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? onColor : onColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: on ? Colors.white : onColor),
        ),
      );
}