-- Backfill de user_uuid para usuarios existentes sin vinculación
-- Ejecutar después de tener cuentas creadas en auth.users (mismo email)

-- 1. Intento de mapeo por email nuevamente
UPDATE usuario u
SET user_uuid = au.id
FROM auth.users au
WHERE au.email = u.email AND u.user_uuid IS NULL;

-- 2. Reporte rápido de filas restantes sin user_uuid
SELECT id_usuario, email FROM usuario WHERE user_uuid IS NULL;

-- 3. (Opcional) Al completar el backfill, aplicar restricciones si no se aplicaron antes
DO $$
DECLARE
  faltantes INT;
BEGIN
  SELECT COUNT(*) INTO faltantes FROM usuario WHERE user_uuid IS NULL;
  IF faltantes = 0 THEN
    -- Solo añadir si no existe ya el constraint
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE table_name='usuario' AND constraint_name='usuario_user_uuid_unique'
    ) THEN
      ALTER TABLE usuario ADD CONSTRAINT usuario_user_uuid_unique UNIQUE (user_uuid);
    END IF;
    -- Asegurar NOT NULL
    ALTER TABLE usuario ALTER COLUMN user_uuid SET NOT NULL;
  END IF;
END $$;
