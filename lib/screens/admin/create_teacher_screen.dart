import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/teacher.dart';
import '../../services/groups_service.dart';
import '../../services/teachers_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

// ── Estructuras locales del formulario ───────────────────────────
class _Block {
  int? day;
  TimeOfDay? start;
  TimeOfDay? end;
}

class _Assignment {
  final String groupName;
  String subject = '';
  List<_Block> blocks = [_Block()];
  _Assignment(this.groupName);
}

class CreateTeacherScreen extends StatefulWidget {
  const CreateTeacherScreen({super.key});

  @override
  State<CreateTeacherScreen> createState() => _CreateTeacherScreenState();
}

class _CreateTeacherScreenState extends State<CreateTeacherScreen> {
  final _groupsService = GroupsService();
  final _teachersService = TeachersService();

  int _step = 0;

  // Paso 1
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Paso 2
  List<Group>? _groups;
  String? _groupsError;
  String _query = '';
  final Map<String, _Assignment> _selected = {}; // groupId -> asignación

  String? _error;
  bool _saving = false;
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

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupsService.getGroups();
      setState(() => _groups = groups);
    } catch (e) {
      setState(
        () => _groupsError = e is ApiException
            ? e.message
            : 'Error al cargar grupos',
      );
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  void _goToStep2() {
    if (_formKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
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
        assignments.add({
          'groupId': entry.key,
          'subject': a.subject.trim(),
          'dayOfWeek': b.day,
          'startTime': _fmt(b.start!),
          'endTime': _fmt(b.end!),
        });
      }
    }

    final clash = _clashError(assignments);
    if (clash != null) {
      setState(() => _error = clash);
      return;
    }

    setState(() => _saving = true);
    try {
      await _teachersService.createTeacher(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text,
        assignments: assignments,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(
        () => _error = e is ApiException ? e.message : 'No se pudo crear',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == 0 ? 'Nuevo docente · Datos' : 'Nuevo docente · Grupos',
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
                            : Text(
                                _selected.isEmpty
                                    ? 'Guardar sin grupos'
                                    : 'Guardar docente',
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── PASO 1 ──────────────────────────────────────────────────
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
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Escribe el correo';
              if (!v.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              helperText: 'Mínimo 6 caracteres',
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
        ],
      ),
    );
  }

  // ── PASO 2 ──────────────────────────────────────────────────
  Widget _buildStep2() {
    if (_groupsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: SofiaColors.soft,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                _groupsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SofiaColors.soft),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _groupsError = null);
                  _loadGroups();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_groups == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _groups!
        .where((g) => g.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Buscador
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar grupo…',
            prefixIcon: const Icon(Icons.search),
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

        // Lista de grupos con checkbox
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
                    _selected[g.id] = _Assignment(g.name);
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

        // Editores de horario por grupo seleccionado
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
                  // Día
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: b.day,
                      isDense: true,
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
                  const SizedBox(width: 8),
                  // Inicio
                  Expanded(
                    flex: 2,
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
                  const SizedBox(width: 8),
                  // Fin
                  Expanded(
                    flex: 2,
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
                  // Borrar bloque (si hay más de uno)
                  if (a.blocks.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFFC6503B),
                      onPressed: () => setState(() => a.blocks.removeAt(index)),
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
