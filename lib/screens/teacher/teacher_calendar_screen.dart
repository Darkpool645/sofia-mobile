import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../models/class_slot.dart';
import '../../models/task.dart';
import '../../services/portal_service.dart';
import '../../services/tasks_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class TeacherCalendarScreen extends StatefulWidget {
  const TeacherCalendarScreen({super.key});

  @override
  State<TeacherCalendarScreen> createState() => _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends State<TeacherCalendarScreen> {
  final _portal = PortalService();
  final _tasks = TasksService();
  final _controller = CalendarController();

  late Future<List<Appointment>> _future;
  CalendarView _view = CalendarView.month;

  // taskId -> tarea (para recuperar datos al tocar una cita)
  final Map<String, TeacherTask> _taskById = {};

  @override
  void initState() {
    super.initState();
    _controller.view = CalendarView.month;
    _future = _load();
  }

  Future<List<Appointment>> _load() async {
    final classes = await _portal.getMyClasses();
    final tasks = await _tasks.getMyTasks();

    _taskById.clear();
    final items = <Appointment>[];

    for (final c in classes) {
      final s = _timeParts(c.startTime);
      final e = _timeParts(c.endTime);
      final base = _dateForWeekday(c.dayOfWeek);
      items.add(Appointment(
        startTime: DateTime(base.year, base.month, base.day, s.$1, s.$2),
        endTime: DateTime(base.year, base.month, base.day, e.$1, e.$2),
        subject: '${c.subject} · ${c.group.name}',
        color: SofiaColors.brand,
        recurrenceRule:
            'FREQ=WEEKLY;INTERVAL=1;BYDAY=${_byDay(c.dayOfWeek)}',
      ));
    }

    for (final t in tasks) {
      final d = DateTime.tryParse(t.dueDate);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      _taskById[t.id] = t;
      items.add(Appointment(
        id: t.id, // guardamos el taskId en la cita
        startTime: day,
        endTime: day.add(const Duration(hours: 1)),
        isAllDay: true,
        subject: '${_typeLabel(t.type)}: ${t.title} · ${t.groupName}',
        color: _typeColor(t.type),
      ));
    }

    return items;
  }

  void _reload() => setState(() => _future = _load());

  void _setView(CalendarView v) {
    setState(() {
      _view = v;
      _controller.view = v;
    });
  }

  void _onTapCalendar(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.appointment) return;
    final appts = details.appointments;
    if (appts == null || appts.isEmpty) return;
    final appt = appts.first as Appointment;
    final taskId = appt.id?.toString();
    if (taskId == null) return; // es una clase, no una tarea
    final task = _taskById[taskId];
    if (task != null) _openTaskDialog(task);
  }

  Future<void> _openTaskDialog(TeacherTask task) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _TaskDialog(task: task, service: _tasks),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<CalendarView>(
              segments: const [
                ButtonSegment(value: CalendarView.month, label: Text('Mes')),
                ButtonSegment(value: CalendarView.week, label: Text('Semana')),
                ButtonSegment(value: CalendarView.day, label: Text('Día')),
              ],
              selected: {_view},
              onSelectionChanged: (s) => _setView(s.first),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Appointment>>(
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
                        : 'No se pudo cargar el calendario.',
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
          final items = snap.data ?? [];
          return SfCalendar(
            controller: _controller,
            onTap: _onTapCalendar,
            allowedViews: const [
              CalendarView.month,
              CalendarView.week,
              CalendarView.day,
            ],
            dataSource: _DataSource(items),
            firstDayOfWeek: 1,
            todayHighlightColor: SofiaColors.brand,
            showNavigationArrow: true,
            monthViewSettings: const MonthViewSettings(
              showAgenda: true,
              appointmentDisplayMode:
                  MonthAppointmentDisplayMode.appointment,
            ),
            timeSlotViewSettings: const TimeSlotViewSettings(
              startHour: 7,
              endHour: 19,
              timeFormat: 'HH:mm',
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Diálogo de detalle + edición de la tarea (grupo fijo)
// ─────────────────────────────────────────────────────────────
class _TaskDialog extends StatefulWidget {
  final TeacherTask task;
  final TasksService service;
  const _TaskDialog({required this.task, required this.service});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  bool _editing = false;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _due;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController();
    _due = DateTime.tryParse(widget.task.dueDate);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un título');
      return;
    }
    if (_due == null) {
      setState(() => _error = 'Selecciona la fecha de entrega');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.updateTask(
        id: widget.task.id,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        dueDate: _fmtDate(_due!),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() =>
          _error = e is ApiException ? e.message : 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return AlertDialog(
      title: Text(_editing ? 'Editar' : _typeLabel(t.type)),
      content: _editing ? _editForm() : _detail(),
      actions: _editing
          ? [
              TextButton(
                onPressed: _saving ? null : () => setState(() => _editing = false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
              ),
            ],
    );
  }

  Widget _detail() {
    final t = widget.task;
    final due = DateTime.tryParse(t.dueDate);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: SofiaColors.ink)),
        const SizedBox(height: 8),
        _row(Icons.grid_view_outlined, 'Grupo ${t.groupName}'),
        const SizedBox(height: 4),
        _row(Icons.event, 'Entrega: ${due != null ? _fmtDate(due) : t.dueDate}'),
        const SizedBox(height: 4),
        _row(Icons.people_outline, '${t.submissionCount} entrega(s) registradas'),
      ],
    );
  }

  Widget _editForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grupo fijo (no editable)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view_outlined,
                    size: 16, color: SofiaColors.soft),
                const SizedBox(width: 8),
                Text('Grupo ${widget.task.groupName}',
                    style: const TextStyle(
                        color: SofiaColors.soft,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Descripción (opcional)'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration:
                  const InputDecoration(labelText: 'Fecha de entrega'),
              child: Text(
                _due == null ? 'Seleccionar' : _fmtDate(_due!),
                style: TextStyle(
                    color: _due == null ? SofiaColors.soft : SofiaColors.ink),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!,
                  style:
                      const TextStyle(color: Color(0xFFC6503B), fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: SofiaColors.soft),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: SofiaColors.ink, fontSize: 14))),
        ],
      );
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}

// ── Helpers ──────────────────────────────────────────────────
(int, int) _timeParts(String hhmm) {
  final p = hhmm.split(':');
  return (int.tryParse(p[0]) ?? 0, p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
}

DateTime _dateForWeekday(int isoDow) {
  final now = DateTime.now();
  final diff = isoDow - now.weekday;
  return DateTime(now.year, now.month, now.day + diff);
}

String _byDay(int isoDow) {
  const codes = {1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA', 7: 'SU'};
  return codes[isoDow] ?? 'MO';
}

Color _typeColor(String type) {
  switch (type) {
    case 'EXAMEN':
      return const Color(0xFFC6503B);
    case 'ACTIVIDAD':
      return const Color(0xFF2E8C68);
    default:
      return SofiaColors.gold;
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