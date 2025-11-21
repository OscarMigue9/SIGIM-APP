<<<<<<< HEAD
# InventarioApp - Flutter + Supabase

Una aplicación móvil completa de gestión de inventarios desarrollada en Flutter con backend en Supabase.

## 🚀 Características

### Roles de Usuario
- **Administrador General**: Gestión completa de usuarios, productos, inventario, pedidos y reportes
- **Vendedor**: Gestión de productos, inventario, pedidos y ventas (limitado)
- **Cliente**: Tienda, carrito, pedidos y perfil

### Funcionalidades Principales
- ✅ **Autenticación completa** con Supabase Auth
- ✅ **Gestión de usuarios y roles**
- ✅ **CRUD completo de productos**
- ✅ **Control de inventario en tiempo real**
- ✅ **Sistema de pedidos con validación de stock**
- ✅ **Generación de reportes**
- ✅ **Navegación por roles** (Drawer/BottomNavigation)

## 🛠️ Instalación y Configuración

### Paso 1: Configurar Supabase
1. Ve a [supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Ve a **Settings > API**
4. Copia tu **Project URL** y **anon/public key**

### Paso 2: Configurar Base de Datos
1. Ve a **SQL Editor** en tu panel de Supabase
2. Ejecuta el script completo que está en `database/setup.sql`

### Paso 3: Configurar Credenciales
1. Abre `lib/config/supabase_config.dart`
2. Reemplaza con tus credenciales reales de Supabase

### Paso 4: Ejecutar
```bash
flutter pub get
flutter run
```

¡Tu aplicación InventarioApp está lista para usar! 🎉
=======
# Software_ll

Interfaz web MARLINE Dashboard para Muebles Lusander (HTML + CSS puro).

Estructura
- web/assets/global.css – Variables, layout y estilos globales (sidebar, topbar, cards, tablas, forms, panel preview, responsive)
- web/pages/ – Páginas estáticas con datos ficticios
	- login.html
	- dashboard.html
	- productos.html, producto.html
	- inventario.html
	- ventas.html
	- ordenes.html
	- recepcion.html
	- ajustes.html
	- devoluciones.html
	- reportes.html
	- usuarios.html
	- alertas.html

Cómo usar
1. Abrir cualquier archivo HTML en el navegador (doble clic) o servir la carpeta `web` con un servidor estático.
2. Las rutas de CSS y navegación son relativas, por lo que funcionan abriendo el archivo localmente.

Mockups (PNG/PDF)
- Rápido: abrir en Edge/Chrome, Device Toolbar móvil y capturar pantalla (PNG/PDF).
- Automatizado (Playwright):
	```powershell
	cd "c:\Users\Samue\OneDrive\Documents\EE_Scraping\Software_ll"
	npm init -y
	npm i -D playwright
	npx playwright install chromium
	node .\tools\capture-mockups.mjs
	start .\mockups
	```

Diseño
- Paleta y tokens basados en variables CSS: `--bg`, `--sidebar`, `--surface`, `--text`, `--text-muted`, `--primary`, `--green`, `--red`, `--gold`.
- Estilo “MARLINE Dashboard” con sidebar compact/expand (72/240px), topbar minimal, cards radius 12px, tablas densas, panel de preview a la derecha activado con `:target`.
- Responsive: grid 3 columnas en ≥1200px, 1 columna en móvil.

Accesibilidad
- Contraste AA y foco visible con anillo azul.
- Targets de 40×40px en botones principales.
>>>>>>> d08319fd2eb240bc2ef0a8374c5ab35bae760cbd
ón InventarioApp está lista para usar! 🎉
