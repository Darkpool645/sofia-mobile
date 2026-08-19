import 'package:flutter/material.dart';
import '../../models/parent.dart';
import '../../services/parents_service.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'create_parent_screen.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  final _service = ParentsService();
  late Future<List<Parent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getParents();
  }

  Future<void> _reload() async {
    final future = _service.getParents();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateParentScreen()),
    );
    if (created == true && mounted) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Padre registrado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Padres'),
        backgroundColor: SofiaColors.paper,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: SofiaColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo padre'),
      ),
      body: FutureBuilder<List<Parent>>(
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
                          : 'No se pudieron cargar los padres.',
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
          final parents = snap.data ?? [];
          if (parents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: SofiaColors.soft),
                    SizedBox(height: 12),
                    Text('Aún no hay padres',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: SofiaColors.ink)),
                    SizedBox(height: 6),
                    Text('Toca “Nuevo padre” para registrar el primero.',
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
              itemCount: parents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ParentCard(parent: parents[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  final Parent parent;
  const _ParentCard({required this.parent});

  @override
  Widget build(BuildContext context) {
    final childrenLabel = parent.children.isEmpty
        ? 'Sin hijos registrados'
        : parent.children
            .map((c) => '${c.name} (${c.groupName})')
            .join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2E8C68).withValues(alpha: 0.12),
            child: Text(
              parent.name.isNotEmpty ? parent.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF2E8C68), fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parent.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SofiaColors.ink)),
                const SizedBox(height: 2),
                Text(parent.username,
                    style:
                        const TextStyle(color: SofiaColors.soft, fontSize: 13)),
                const SizedBox(height: 4),
                Text(childrenLabel,
                    style: const TextStyle(
                        color: Color(0xFF2E8C68),
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