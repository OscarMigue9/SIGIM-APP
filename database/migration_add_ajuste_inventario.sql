-- (user_uuid eliminado) Funciones de rol definidas en migración RLS basada en email.
-- Si no existen todavía, se redefinen aquí de forma idempotente usando email del JWT.
CREATE OR REPLACE FUNCTION is_admin() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE lower(u.email) = lower((auth.jwt()->>'email')) AND u.id_rol = 1
  );
$$;

CREATE OR REPLACE FUNCTION is_vendedor() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE lower(u.email) = lower((auth.jwt()->>'email')) AND u.id_rol = 2
  );
$$;

-- Requisitos: funciones is_admin() e is_vendedor() ya creadas (ver migration_secure_rls.sql)

CREATE TABLE IF NOT EXISTS ajuste_inventario (
  id_ajuste SERIAL PRIMARY KEY,
  id_producto INT NOT NULL REFERENCES producto(id_producto) ON DELETE CASCADE,
  id_usuario INT NULL REFERENCES usuario(id_usuario) ON DELETE SET NULL,
  delta INT NOT NULL CHECK (delta <> 0),
  stock_inicial INT NOT NULL,
  stock_final INT NOT NULL,
  motivo TEXT NOT NULL CHECK (char_length(motivo) > 0),
  fecha TIMESTAMP NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_ajuste_inventario_producto ON ajuste_inventario(id_producto);
CREATE INDEX IF NOT EXISTS idx_ajuste_inventario_fecha ON ajuste_inventario(fecha);

-- Función para aplicar ajuste de inventario de forma atómica
CREATE OR REPLACE FUNCTION aplicar_ajuste_inventario(p_id_producto INT, p_delta INT, p_motivo TEXT)
RETURNS ajuste_inventario
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_prod RECORD;
  v_new_stock INT;
  v_user_id INT;
  v_row ajuste_inventario%ROWTYPE;
BEGIN
  IF NOT (is_admin() OR is_vendedor()) THEN
    RAISE EXCEPTION 'No autorizado para ajustes de inventario';
  END IF;

  SELECT * INTO v_prod FROM producto WHERE id_producto = p_id_producto FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Producto no encontrado';
  END IF;

  IF p_delta = 0 THEN
    RAISE EXCEPTION 'Delta no puede ser 0';
  END IF;

  v_new_stock := v_prod.stock + p_delta;
  IF v_new_stock < 0 THEN
    RAISE EXCEPTION 'Stock resultante negativo';
  END IF;

  -- Obtener id_usuario del JWT por email
  SELECT id_usuario INTO v_user_id FROM usuario WHERE lower(email) = lower((auth.jwt()->>'email'));
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario autenticado no vinculado';
  END IF;

  UPDATE producto SET stock = v_new_stock WHERE id_producto = p_id_producto;

  INSERT INTO ajuste_inventario(id_producto, id_usuario, delta, stock_inicial, stock_final, motivo)
  VALUES (p_id_producto, v_user_id, p_delta, v_prod.stock, v_new_stock, p_motivo)
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

-- Habilitar RLS y políticas
ALTER TABLE ajuste_inventario ENABLE ROW LEVEL SECURITY;

-- Lectura: admin y vendedor
CREATE POLICY ajuste_inventario_select ON ajuste_inventario FOR SELECT USING (is_admin() OR is_vendedor());
-- Insert: se realiza vía función; permitir insert directo solo para admin/vendedor si fuera necesario
CREATE POLICY ajuste_inventario_insert ON ajuste_inventario FOR INSERT WITH CHECK (is_admin() OR is_vendedor());
-- Delete: solo admin
CREATE POLICY ajuste_inventario_delete ON ajuste_inventario FOR DELETE USING (is_admin());

-- Nota: No se define UPDATE para mantener integridad histórica de los ajustes.
