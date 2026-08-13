import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/school_year.dart';
import '../../services/groups_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _service = GroupsService();
  late Future<List<Group>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getGroups();
  }

  void _reload() => setState(() => _future = _service.getGroups());

  Future<void> _openCreateGroup() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateGroupSheet(service: _service),
      ),
    );

    if (created == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Grupo creado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        backgroundColor: SofiaColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Crear grupo'),
      ),
      body: FutureBuilder<List<Group>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _CenteredMessage(
              icon: Icons.error_outline,
              title: 'No se pudieron cargar los grupos',
              subtitle: snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'Revisa tu conexión e intenta de nuevo.',
              actionLabel: 'Reintentar',
              onAction: _reload,
            );
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return const _CenteredMessage(
              icon: Icons.grid_view_outlined,
              title: 'Aún no hay grupos',
              subtitle: 'Toca “Crear grupo” para registrar el primero.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _GroupCard(group: groups[i]),
            ),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SofiaColors.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              group.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: SofiaColors.brand,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupo ${group.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SofiaColors.ink)),
                const SizedBox(height: 2),
                Text(
                  '${group.schoolYearName} · ${group.studentCount} alumnos',
                  style: const TextStyle(color: SofiaColors.soft, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9AA0AE)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet para crear un grupo (con selector de ciclo)
// ─────────────────────────────────────────────────────────────
class _CreateGroupSheet extends StatefulWidget {
  final GroupsService service;
  const _CreateGroupSheet({required this.service});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();

  List<SchoolYear>? _cycles; // null mientras carga
  String? _selectedCycleId;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCycles() async {
    setState(() {
      _cycles = null;
      _error = null;
    });
    try {
      final cycles = await widget.service.getSchoolYears();
      setState(() {
        _cycles = cycles;
        if (cycles.isNotEmpty) _selectedCycleId = cycles.first.id;
      });
    } catch (e) {
      setState(() {
        _cycles = [];
        _error = e is ApiException ? e.message : 'Error al cargar ciclos';
      });
    }
  }

  Future<void> _createCycle() async {
    final created = await showModalBottomSheet<SchoolYear>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CreateCycleSheet(service: widget.service),
      ),
    );
    if (created != null) {
      await _loadCycles();
      setState(() => _selectedCycleId = created.id);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el nombre del grupo');
      return;
    }
    if (_selectedCycleId == null) {
      setState(() => _error = 'Selecciona un ciclo escolar');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createGroup(
        name: _nameCtrl.text.trim(),
        schoolYearId: _selectedCycleId!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No se pudo crear');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycles = _cycles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nuevo grupo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SofiaColors.ink)),
          const SizedBox(height: 16),
          if (cycles == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cycles.isEmpty)
            _NoCyclesState(onCreate: _createCycle)
          else
            _buildForm(cycles),
        ],
      ),
    );
  }

  Widget _buildForm(List<SchoolYear> cycles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Nombre del grupo',
            hintText: 'Ej. 3°B',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCycleId,
          decoration: const InputDecoration(labelText: 'Ciclo escolar'),
          items: cycles
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCycleId = v),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _createCycle,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear otro ciclo'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFC6503B), fontSize: 13)),
          ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Text('Guardar grupo'),
        ),
      ],
    );
  }
}

class _NoCyclesState extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoCyclesState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 40, color: SofiaColors.soft),
        const SizedBox(height: 12),
        const Text('No hay ciclos escolares',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: SofiaColors.ink)),
        const SizedBox(height: 4),
        const Text(
          'Necesitas crear un ciclo antes de registrar grupos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SofiaColors.soft, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Crear ciclo escolar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet para crear un ciclo escolar
// ─────────────────────────────────────────────────────────────
class _CreateCycleSheet extends StatefulWidget {
  final GroupsService service;
  const _CreateCycleSheet({required this.service});

  @override
  State<_CreateCycleSheet> createState() => _CreateCycleSheetState();
}

class _CreateCycleSheetState extends State<_CreateCycleSheet> {
  final _nameCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_start ?? now) : (_end ?? now),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el nombre del ciclo (ej. 2026-2027)');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Selecciona la fecha de inicio y de fin');
      return;
    }
    setState(() => _saving = true);
    try {
      final cycle = await widget.service.createSchoolYear(
        name: _nameCtrl.text.trim(),
        startDate: _fmt(_start!),
        endDate: _fmt(_end!),
        active: true,
      );
      if (mounted) Navigator.pop(context, cycle);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No se pudo crear');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nuevo ciclo escolar',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SofiaColors.ink)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. 2026-2027',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Inicio',
                  value: _start == null ? null : _fmt(_start!),
                  onTap: () => _pick(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'Fin',
                  value: _end == null ? null : _fmt(_end!),
                  onTap: () => _pick(isStart: false),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style:
                      const TextStyle(color: Color(0xFFC6503B), fontSize: 13)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Guardar ciclo'),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value ?? 'Seleccionar',
          style: TextStyle(
            color: value == null ? SofiaColors.soft : SofiaColors.ink,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Estado centrado reutilizable (vacío / error)
// ─────────────────────────────────────────────────────────────
class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SofiaColors.soft),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SofiaColors.ink)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SofiaColors.soft)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}