import 'package:flutter/material.dart';
import '../../models/class_slot.dart';
import '../../services/tasks_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class CreateTaskScreen extends StatefulWidget {
  final List<ClassGroup> groups; // grupos del docente
  const CreateTaskScreen({super.key, required this.groups});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _service = TasksService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'TAREA';
  DateTime? _dueDate;
  final Set<String> _selectedGroups = {};

  String? _error;
  bool _saving = false;

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
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un título');
      return;
    }
    if (_dueDate == null) {
      setState(() => _error = 'Selecciona la fecha de entrega');
      return;
    }
    if (_selectedGroups.isEmpty) {
      setState(() => _error = 'Selecciona al menos un grupo');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createTask(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        type: _type,
        dueDate: _fmtDate(_dueDate!),
        groupIds: _selectedGroups.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No se pudo publicar');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tipo
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'TAREA', label: Text('Tarea')),
              ButtonSegment(value: 'ACTIVIDAD', label: Text('Actividad')),
              ButtonSegment(value: 'EXAMEN', label: Text('Examen')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                labelText: 'Título', hintText: 'Ej. Ejercicios pág. 45'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          // Fecha de entrega
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration:
                  const InputDecoration(labelText: 'Fecha de entrega'),
              child: Text(
                _dueDate == null ? 'Seleccionar' : _fmtDate(_dueDate!),
                style: TextStyle(
                    color:
                        _dueDate == null ? SofiaColors.soft : SofiaColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Publicar en',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: SofiaColors.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.groups.map((g) {
              final sel = _selectedGroups.contains(g.id);
              return FilterChip(
                label: Text(g.name),
                selected: sel,
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedGroups.add(g.id);
                  } else {
                    _selectedGroups.remove(g.id);
                  }
                }),
                selectedColor: SofiaColors.brand.withValues(alpha: 0.15),
                checkmarkColor: SofiaColors.brand,
              );
            }).toList(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFFC6503B), fontSize: 13)),
            ),
        ],
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
                : const Text('Publicar'),
          ),
        ),
      ),
    );
  }
}