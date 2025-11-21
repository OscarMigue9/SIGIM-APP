import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/password_utils.dart';
import '../perfil/perfil_screen.dart';
import '../info/ayuda_screen.dart';
import '../info/acerca_screen.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.brightness_6),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Tema claro / oscuro')),
                  Switch(
                    value: mode == ThemeMode.dark,
                    onChanged: (_) => controller.toggle(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Política de Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('• Mínimo ${PasswordUtils.minLength} caracteres'),
                  const Text('• Al menos una mayúscula'),
                  const Text('• Al menos una minúscula'),
                  const Text('• Al menos un número'),
                  const Text('• Al menos un símbolo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar Perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AyudaScreen()),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AcercaScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}