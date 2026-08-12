import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class _RoleHome extends StatelessWidget {
  final String roleLabel;
  final Color accent;
  final List<Widget> children;

  const _RoleHome({
    required this.roleLabel,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SofiaColors.paper,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: SofiaColors.soft),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${user?.name ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: SofiaColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: SofiaColors.soft),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      )
    );
  }
}

Widget _placeholderCard(String title, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFECEAE3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: SofiaColors.brand),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: SofiaColors.ink)),
      ],
    ),
  );
}



class AdminHome extends StatelessWidget {
  const AdminHome({ super.key });
  @override
  Widget build(BuildContext context) => _RoleHome(
    roleLabel : 'ADMINISTRADOR',
    accent: SofiaColors.brand,
    children: [
      _placeholderCard('Usuarios (profesores y padres)', Icons.group_outlined),
      _placeholderCard('Grupo y alumnos', Icons.grid_view_outlined),
      _placeholderCard('Ciclos escolares', Icons.calendar_month_outlined),
    ],
  );
}

class ProfesorHome extends StatelessWidget {
  const ProfesorHome({super.key});
  @override
  Widget build(BuildContext context) => _RoleHome(
        roleLabel: 'PROFESOR',
        accent: const Color(0xFF2E8C68),
        children: [
          _placeholderCard('Pasar lista', Icons.checklist_outlined),
          _placeholderCard('Tareas', Icons.assignment_outlined),
          _placeholderCard('Muro de avisos', Icons.campaign_outlined),
        ],
      );
}
 
class PadreHome extends StatelessWidget {
  const PadreHome({super.key});
  @override
  Widget build(BuildContext context) => _RoleHome(
        roleLabel: 'PADRE',
        accent: const Color(0xFF2E8C68),
        children: [
          _placeholderCard('Resumen de mi hijo', Icons.dashboard_outlined),
          _placeholderCard('Tareas y asistencias', Icons.fact_check_outlined),
          _placeholderCard('Avisos', Icons.notifications_outlined),
        ],
      );
}