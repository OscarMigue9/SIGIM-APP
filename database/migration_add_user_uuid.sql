-- Sprint 4: Migración a Supabase Auth
-- Añadir columna user_uuid para enlazar con auth.users
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS user_uuid uuid;

-- Vincular por email (requiere que los usuarios ya existan en auth.users con mismo correo)
UPDATE usuario u
SET user_uuid = au.id
FROM auth.users au
WHERE au.email = u.email AND u.user_uuid IS NULL;

-- Restringir unicidad y no nulos (solo si todas las filas fueron mapeadas)
DO $$
DECLARE
  faltantes INT;
BEGIN
  SELECT COUNT(*) INTO faltantes FROM usuario WHERE user_uuid IS NULL;
  IF faltantes = 0 THEN
    ALTER TABLE usuario ADD CONSTRAINT usuario_user_uuid_unique UNIQUE (user_uuid);
    ALTER TABLE usuario ALTER COLUMN user_uuid SET NOT NULL;
  END IF;
END $$;

-- Nota: si existen filas sin user_uuid, crear cuentas en auth.users o hacer reset de contraseña
