import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../services/groups_service.dart';
import '../../services/parents_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class _Child {
  String name = '';
  String? groupId;
}

class CreateParentScreen extends StatefulWidget {
  const CreateParentScreen({super.key});

  @override
  State<CreateParentScreen> createState() => _CreateParentScreenState();
}

class _CreateParentScreenState extends State<CreateParentScreen> {
  final _groupsService = GroupsService();
  final _parentsService = ParentsService();

  int _step = 0;

  // Paso 1
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Paso 2
  List<Group>? _groups;
  String? _groupsError;
  final List<_Child> _children = [_Child()];

  String? _error;
  bool _saving = false;

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
      setState(() => _groupsError =
          e is ApiException ? e.message : 'Error al cargar grupos');
    }
  }

  void _goToStep2() {
    if (_formKey.currentState!.validate()) {
      setState(() => _step = 1);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    final children = <Map<String, dynamic>>[];
    for (final c in _children) {
      if (c.name.trim().isEmpty) {
        setState(() => _error = 'Escribe el nombre de cada hijo');
        return;
      }
      if (c.groupId == null) {
        setState(() => _error = 'Selecciona el grupo de cada hijo');
        return;
      }
      children.add({'name': c.name.trim(), 'groupId': c.groupId});
    }

    setState(() => _saving = true);
    try {
      await _parentsService.createParent(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text,
        children: children,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Nuevo padre · Datos' : 'Nuevo padre · Hijos'),
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
                  onPressed: _goToStep2, child: const Text('Siguiente'))
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
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('Guardar padre'),
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
          const Text('Datos del padre / tutor',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: SofiaColors.ink)),
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
                labelText: 'Contraseña', helperText: 'Mínimo 6 caracteres'),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: SofiaColors.soft, size: 44),
            const SizedBox(height: 12),
            Text(_groupsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SofiaColors.soft)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() => _groupsError = null);
                _loadGroups();
              },
              child: const Text('Reintentar'),
            ),
          ]),
        ),
      );
    }
    if (_groups == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Hijos',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SofiaColors.ink)),
        const SizedBox(height: 4),
        const Text('Agrega uno o varios hijos y asigna su grupo.',
            style: TextStyle(color: SofiaColors.soft, fontSize: 13)),
        const SizedBox(height: 16),
        ..._children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return _buildChildCard(index, child);
        }),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _children.add(_Child())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar otro hijo'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFC6503B), fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildChildCard(int index, _Child child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Hijo ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: SofiaColors.ink)),
              const Spacer(),
              if (_children.length > 1)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFFC6503B),
                  onPressed: () => setState(() => _children.removeAt(index)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ObjectKey(child),
            initialValue: child.name,
            decoration: const InputDecoration(
                labelText: 'Nombre del alumno', isDense: true),
            onChanged: (v) => child.name = v,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: child.groupId,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Grupo', isDense: true),
            items: _groups!
                .map((g) => DropdownMenuItem(
                    value: g.id,
                    child: Text('${g.name} · ${g.schoolYearName}')))
                .toList(),
            onChanged: (v) => setState(() => child.groupId = v),
          ),
        ],
      ),
    );
  }
}