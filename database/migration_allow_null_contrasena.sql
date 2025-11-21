-- Migración: permitir clientes sin contraseña (solo registro interno)
-- Hacer la columna contrasena nullable
ALTER TABLE usuario ALTER COLUMN contrasena DROP NOT NULL;

-- Nota: Los registros con contrasena NULL no podrán iniciar sesión; se usan solo para referencia como clientes.
