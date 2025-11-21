# SIGIM-APP (Flutter + Supabase)

Aplicación móvil para gestión de inventarios, pedidos y usuarios construida en Flutter con un backend en Supabase.

## Funcionalidades
- Autenticación por correo y gestión de roles (administrador, vendedor, cliente)
- CRUD de productos con control de stock y ajustes de inventario
- Carrito, pedidos, historial y estados con línea de tiempo
- Gestión de usuarios, clientes, direcciones y métodos de pago
- Reportes y métricas básicas de ventas e inventario

## Requerimientos
- Flutter 3.x
- Proyecto Supabase con URL y anon/public key
- Dart/Flutter configurado en el PATH

## Configuración rápida
1. Clona el repositorio y entra en la carpeta:
   ```bash
   git clone https://github.com/OscarMigue9/SIGIM-APP.git
   cd SIGIM-APP
   ```
2. Instala dependencias:
   ```bash
   flutter pub get
   ```
3. Configura Supabase:
   - Coloca las credenciales en `lib/config/supabase_config.dart`.
   - Ejecuta `database/setup.sql` y, si aplica, las migraciones adicionales (`database/migration_*.sql`) en tu proyecto Supabase.
4. Ejecuta la app (emulador o dispositivo conectado):
   ```bash
   flutter run
   ```

## Estructura
- `lib/`: vistas, controladores, servicios y modelos.
- `database/`: scripts iniciales y migraciones de Supabase.
- `diagrams/`: diagramas de soporte.
- `tools/`: utilidades para compilación e integraciones.

## Notas
- No incluyas llaves o secretos reales en el repositorio; usa el archivo de configuración local.
- `android/key.properties.example` sirve como plantilla para el keystore.
