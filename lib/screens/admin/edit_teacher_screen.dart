import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/teacher.dart';
import '../../services/groups_service.dart';
import '../../services/teachers_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class _Block {
  String? id; // id del ClassSlot (null = nuevo)
  int? day;
  TimeOfDay? start;
  TimeOfDay? end;
}

class _Assignment {
  final String groupName;
  String subject = '';
  List<_Block> blocks = [];
  _Assignment(this.groupName);
}

class EditTeacherScreen extends StatefulWidget {
  final String teacherId;
  const EditTeacherScreen({super.key, required this.teacherId});

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  final _groupsService = GroupsService();
  final _teachersService = TeachersService();

  bool _loading = true;
  String? _loadError;
  String? _clashError(List<Map<String, dynamic>> assignments) {
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final a in assignments) {
      byDay.putIfAbsent(a['dayOfWeek'] as int, () => []).add(a);
    }
    for (final entry in byDay.entries) {
      final list = [...entry.value]
        ..sort(
          (x, y) =>
              (x['startTime'] as String).compareTo(y['startTime'] as String),
        );
      for (var i = 1; i < list.length; i++) {
        if ((list[i]['startTime'] as String).compareTo(
              list[i - 1]['endTime'] as String,
            ) <
            0) {
          return 'Se traslapan horarios el ${dayNames[entry.key]}: '
              '${list[i - 1]['startTime']}–${list[i - 1]['endTime']} y '
              '${list[i]['startTime']}–${list[i]['endTime']}.';
        }
      }
    }
    return null;
  }

  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  List<Group> _groups = [];
  String _query = '';
  final Map<String, _Assignment> _selected = {};

  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final groups = await _groupsService.getGroups();
      final teacher = await _teachersService.getTeacher(widget.teacherId);

      _nameCtrl.text = teacher.name;
      _usernameCtrl.text = teacher.username;

      // Agrupa las clases existentes por grupo, conservando el id de cada bloque.
      _selected.clear();
      for (final c in teacher.classes) {
        final a = _selected.putIfAbsent(
          c.groupId,
          () => _Assignment(c.groupName)..subject = c.subject,
        );
        a.blocks.add(
          _Block()
            ..id = c.id
            ..day = c.dayOfWeek
            ..start = _parseTime(c.startTime)
            ..end = _parseTime(c.endTime),
        );
      }

      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e is ApiException ? e.message : 'Error al cargar';
        _loading = false;
      });
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  void _goToStep2() {
    if (_formKey.currentState!.validate()) setState(() => _step = 1);
  }

  Future<void> _save() async {
    setState(() => _error = null);

    final assignments = <Map<String, dynamic>>[];
    for (final entry in _selected.entries) {
      final a = entry.value;
      if (a.subject.trim().isEmpty) {
        setState(() => _error = 'Escribe la materia para ${a.groupName}');
        return;
      }
      for (final b in a.blocks) {
        if (b.day == null || b.start == null || b.end == null) {
          setState(
            () => _error =
                'Completa día y horario en cada bloque de ${a.groupName}',
          );
          return;
        }
        if (_mins(b.start!) >= _mins(b.end!)) {
          setState(
            () => _error =
                'En ${a.groupName}, la hora de inicio debe ser menor a la de fin',
          );
          return;
        }
        final m = <String, dynamic>{
          'groupId': entry.key,
          'subject': a.subject.trim(),
          'dayOfWeek': b.day,
          'startTime': _fmt(b.start!),
          'endTime': _fmt(b.end!),
        };
        if (b.id != null)
          m['id'] = b.id; // existente => update; sin id => create
        assignments.add(m);
      }
    }

    final clash = _clashError(assignments);
    if (clash != null) {
      setState(() => _error = clash);
      return;
    }

    setState(() => _saving = true);
    try {
      await _teachersService.updateTeacher(
        id: widget.teacherId,
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text, // vacío => no cambia
        assignments: assignments,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(
        () => _error = e is ApiException ? e.message : 'No se pudo guardar',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar docente')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SofiaColors.soft),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loadAll,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == 0 ? 'Editar docente · Datos' : 'Editar docente · Grupos',
        ),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _step == 0 ? _buildStep1() : _buildStep2(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _step == 0
              ? ElevatedButton(
                  onPressed: _goToStep2,
                  child: const Text('Siguiente'),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step = 0),
                        child: const Text('Atrás'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Datos del docente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: SofiaColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Escribe el nombre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameCtrl,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              helperText: 'El correo no se puede editar',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña (opcional)',
              helperText: 'Déjalo vacío para no cambiarla',
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final filtered = _groups
        .where((g) => g.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar grupo…',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selected.length} grupo(s) seleccionado(s)',
          style: const TextStyle(
            color: SofiaColors.soft,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...filtered.map((g) {
          final isSel = _selected.containsKey(g.id);
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSel ? SofiaColors.brand : const Color(0xFFECEAE3),
              ),
            ),
            child: CheckboxListTile(
              value: isSel,
              activeColor: SofiaColors.brand,
              title: Text(
                'Grupo ${g.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SofiaColors.ink,
                ),
              ),
              subtitle: Text(
                g.schoolYearName,
                style: const TextStyle(color: SofiaColors.soft),
              ),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected[g.id] = _Assignment(g.name)..blocks.add(_Block());
                  } else {
                    _selected.remove(g.id);
                  }
                });
              },
            ),
          );
        }),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No hay grupos que coincidan.',
                style: TextStyle(color: SofiaColors.soft),
              ),
            ),
          ),
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Horarios por grupo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SofiaColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          ..._selected.entries.map((e) => _buildGroupEditor(e.key, e.value)),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFC6503B), fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupEditor(String groupId, _Assignment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SofiaColors.brand.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grupo ${a.groupName}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: SofiaColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: a.subject,
            decoration: const InputDecoration(
              labelText: 'Materia',
              hintText: 'Ej. Matemáticas',
              isDense: true,
            ),
            onChanged: (v) => a.subject = v,
          ),
          const SizedBox(height: 12),
          ...a.blocks.asMap().entries.map((entry) {
            final index = entry.key;
            final b = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      initialValue: b.day,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Día',
                        isDense: true,
                      ),
                      items: dayNames.entries
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.key,
                              child: Text(d.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => b.day = v),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _TimeBox(
                      label: 'Inicio',
                      value: b.start,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime:
                              b.start ?? const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (t != null) setState(() => b.start = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _TimeBox(
                      label: 'Fin',
                      value: b.end,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime:
                              b.end ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (t != null) setState(() => b.end = t);
                      },
                    ),
                  ),
                  if (a.blocks.length > 1)
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 18),
                        color: const Color(0xFFC6503B),
                        onPressed: () =>
                            setState(() => a.blocks.removeAt(index)),
                      ),
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => a.blocks.add(_Block())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar día/horario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(
          value == null
              ? '--:--'
              : '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: value == null ? SofiaColors.soft : SofiaColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
