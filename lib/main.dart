import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Recupera la sesión guardada ANTES de arrancar la UI,
  // para que el router ya sepa a dónde mandar al usuario.
  final auth = AuthProvider();
  await auth.init();

  runApp(SofiaApp(auth: auth));
}

class SofiaApp extends StatefulWidget {
  final AuthProvider auth;
  const SofiaApp({super.key, required this.auth});

  @override
  State<SofiaApp> createState() => _SofiaAppState();
}

class _SofiaAppState extends State<SofiaApp> {
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.auth,
      child: MaterialApp.router(
        title: 'SOFIA', 
        debugShowCheckedModeBanner: false,
        theme: buildSofiaTheme(),
        routerConfig: _router,
      ),
    );
  }
}