-- Migración: añadir columna email única para autenticación por correo
-- 1. Añadir columna si no existe
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Rellenar emails faltantes con placeholder único (solo para registros anteriores)
UPDATE usuario
SET email = lower(nombre || '.' || apellido || '_' || id_usuario || '@placeholder.local')
WHERE email IS NULL;

-- 3. Crear índice único (usa operador IF NOT EXISTS para idempotencia en Postgres 15+; si tu versión no lo soporta, elimínalo)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE schemaname = current_schema() AND indexname = 'usuario_email_unique'
    ) THEN
        EXECUTE 'CREATE UNIQUE INDEX usuario_email_unique ON usuario (email)';
    END IF;
END$$;

-- 4. (Opcional) Forzar NOT NULL si todas las filas ya tienen email
ALTER TABLE usuario ALTER COLUMN email SET NOT NULL;

-- 5. Nota: Actualiza tu código para usar login por email y exigir email en el registro.