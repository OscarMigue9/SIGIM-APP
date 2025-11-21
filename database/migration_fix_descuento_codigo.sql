-- Fix: asegurar columna codigo existe en tabla descuento existente
DO $$
DECLARE
  col_present BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'descuento' AND column_name = 'codigo'
  ) INTO col_present;

  IF NOT col_present THEN
    ALTER TABLE descuento ADD COLUMN codigo TEXT;
  END IF;

  -- Si la columna existe pero hay NULLs, rellenar con código generado
  UPDATE descuento SET codigo = CONCAT('DESC-', id_descuento)
  WHERE codigo IS NULL;

  -- Asegurar NOT NULL y unicidad
  ALTER TABLE descuento ALTER COLUMN codigo SET NOT NULL;
  -- Crear índice único separado si aún no existe (nombre distinto para evitar conflicto con índice previo no-único)
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = current_schema() AND indexname = 'idx_descuento_codigo_unique'
  ) THEN
    CREATE UNIQUE INDEX idx_descuento_codigo_unique ON descuento(codigo);
  END IF;
END $$;

-- Nota: Si originalmente se creó la tabla sin columna codigo, este script la agrega y normaliza.