import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/family.dart';
import '../../services/family_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

Color _typeColor(String type) {
  switch (type) {
    case 'EXAMEN':
      return const Color(0xFFC6503B);
    case 'ACTIVIDAD':
      return const Color(0xFF2E8C68);
    default:
      return SofiaColors.brand; // TAREA
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

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  final _service = FamilyService();

  late Future<List<FamilyChild>> _childrenFuture;
  List<FamilyChild> _children = [];
  FamilyChild? _selected;

  Future<List<FeedItem>>? _feedFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = _loadChildren();
  }

  Future<List<FamilyChild>> _loadChildren() async {
    final children = await _service.getChildren();
    _children = children;
    if (children.isNotEmpty) {
      _selected = children.first;
      _feedFuture = _service.getFeed(_selected!.id);
    }
    return children;
  }

  void _selectChild(FamilyChild child) {
    setState(() {
      _selected = child;
      _feedFuture = _service.getFeed(child.id);
    });
  }

  Future<void> _refreshFeed() async {
    if (_selected == null) return;
    final f = _service.getFeed(_selected!.id);
    setState(() => _feedFuture = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SofiaColors.paper,
        elevation: 0,
        title: const Text('Muro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: SofiaColors.soft),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: FutureBuilder<List<FamilyChild>>(
        future: _childrenFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _centered(
              snap.error is ApiException
                  ? (snap.error as ApiException).message
                  : 'No se pudo cargar tu información.',
              onRetry: () =>
                  setState(() => _childrenFuture = _loadChildren()),
            );
          }
          if (_children.isEmpty) {
            return _centered('No tienes hijos registrados.');
          }

          return Column(
            children: [
              // Saludo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hola, ${user?.name ?? ''}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: SofiaColors.ink)),
                ),
              ),

              // Selector de hijo (solo si hay 2 o más)
              if (_children.length > 1) _childSelector(),

              // Grupo del hijo seleccionado
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_selected!.name} · ${_selected!.groupName}',
                        style: const TextStyle(
                            color: SofiaColors.soft, fontSize: 13)),
                  ),
                ),

              // Muro
              Expanded(child: _feedView()),
            ],
          );
        },
      ),
    );
  }

  Widget _childSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _children[i];
          final sel = c.id == _selected?.id;
          return ChoiceChip(
            label: Text(c.name),
            selected: sel,
            onSelected: (_) => _selectChild(c),
            selectedColor: SofiaColors.brand.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: sel ? SofiaColors.brand : SofiaColors.soft,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  Widget _feedView() {
    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: FutureBuilder<List<FeedItem>>(
        future: _feedFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    snap.error is ApiException
                        ? (snap.error as ApiException).message
                        : 'No se pudo cargar el muro.',
                    style: const TextStyle(color: SofiaColors.soft),
                  ),
                ),
              ],
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Icon(Icons.forum_outlined, size: 48, color: SofiaColors.soft),
                SizedBox(height: 12),
                Center(
                  child: Text('Aún no hay publicaciones',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SofiaColors.ink)),
                ),
                SizedBox(height: 4),
                Center(
                  child: Text('Desliza hacia abajo para actualizar.',
                      style: TextStyle(color: SofiaColors.soft)),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _feedCard(items[i]),
          );
        },
      ),
    );
  }

  Widget _feedCard(FeedItem item) {
    final color = _typeColor(item.type);
    return Container(
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_typeLabel(item.type),
                    style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('Entrega: ${_fmtDate(item.dueDate)}',
                  style: const TextStyle(
                      color: SofiaColors.soft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: SofiaColors.ink)),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.description!,
                style: const TextStyle(color: SofiaColors.ink, height: 1.4)),
          ],
          if (item.hasSubmission) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    item.delivered ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: item.delivered
                        ? const Color(0xFF2E8C68)
                        : const Color(0xFFC6503B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.delivered ? 'Entregó' : 'No entregó',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: item.delivered
                          ? const Color(0xFF2E8C68)
                          : const Color(0xFFC6503B),
                    ),
                  ),
                  const Spacer(),
                  if (item.grade != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SofiaColors.brand,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Calif. ${item.grade!.toStringAsFixed(1)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    )
                  else
                    const Text('Sin calificar',
                        style: TextStyle(
                            color: SofiaColors.soft, fontSize: 12.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 15, color: Color(0xFF9AA0AE)),
              const SizedBox(width: 4),
              Text(item.teacherName,
                  style: const TextStyle(
                      color: SofiaColors.soft, fontSize: 12.5)),
              const Spacer(),
              Text('Publicado ${_fmtDate(item.createdAt)}',
                  style: const TextStyle(
                      color: Color(0xFF9AA0AE), fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _centered(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 48, color: SofiaColors.soft),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SofiaColors.soft)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}