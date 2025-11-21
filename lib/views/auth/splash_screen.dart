import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import 'login_screen.dart';
import '../admin/admin_home_screen.dart';
import '../vendedor/vendedor_home_screen.dart';
import '../cliente/cliente_home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar estado de autenticación después de un breve delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authControllerProvider);

    if (authState.isAuthenticated && authState.usuario != null) {
      // Usuario autenticado, navegar según su rol
      _navigateByRole();
    } else {
      // Usuario no autenticado, ir a login
      _navigateToLogin();
    }
  }

  void _navigateByRole() {
    final usuario = ref.read(authControllerProvider).usuario!;

    Widget destinationScreen;

    if (usuario.esAdministrador) {
      destinationScreen = const AdminHomeScreen();
    } else if (usuario.esVendedor) {
      destinationScreen = const VendedorHomeScreen();
    } else {
      destinationScreen = const ClienteHomeScreen();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destinationScreen));
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.inventory, size: 60, color: Colors.blue),
            ),

            const SizedBox(height: 24),

            // Título de la aplicación
            const Text(
              'SIGIM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Subtítulo
            const Text(
              'Gestión integral de inventarios',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 48),

            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
