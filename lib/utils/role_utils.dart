import '../models/usuario.dart';

class RoleUtils {
  static bool isAdmin(Usuario? u) => u?.idRol == 1;
  static bool isVendedor(Usuario? u) => u?.idRol == 2;
  static bool isCliente(Usuario? u) => u?.idRol == 3;

  static void requireAdmin(Usuario? u) {
    if (!isAdmin(u)) {
      throw Exception('Acceso denegado: se requiere rol Administrador');
    }
  }

  static void requireAdminOrVendedor(Usuario? u) {
    if (!(isAdmin(u) || isVendedor(u))) {
      throw Exception('Acceso denegado: se requiere Administrador o Vendedor');
    }
  }
}