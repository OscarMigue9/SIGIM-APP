-- Migración: eliminación de dependencia user_uuid
-- Quita índice/constraint y columna user_uuid si existe (transición a modelo basado solo en email)
ALTER TABLE usuario DROP CONSTRAINT IF EXISTS usuario_user_uuid_unique;
ALTER TABLE usuario DROP COLUMN IF EXISTS user_uuid;

-- Asegurar unicidad de email (si no existe)
DO $$
DECLARE
  v_exists BOOL;
BEGIN
  SELECT TRUE INTO v_exists FROM information_schema.table_constraints
    WHERE table_name='usuario' AND constraint_type='UNIQUE' AND constraint_name='usuario_email_unique';
  IF NOT v_exists THEN
    ALTER TABLE usuario ADD CONSTRAINT usuario_email_unique UNIQUE (email);
  END IF;
END;$$;

-- (Opcional) Validar que no hay emails nulos
UPDATE usuario SET email = concat('placeholder_', id_usuario, '@example.com') WHERE email IS NULL;
ALTER TABLE usuario ALTER COLUMN email SET NOT NULL;