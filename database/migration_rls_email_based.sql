-- Migración: RLS basada en email (sin depender de user_uuid)
-- Usa el email del JWT actual: (auth.jwt()->>'email')

-- 0) Reemplazar helpers de rol
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

CREATE OR REPLACE FUNCTION is_cliente() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE lower(u.email) = lower((auth.jwt()->>'email')) AND u.id_rol = 3
  );
$$;

-- 1) Asegurar RLS habilitado
ALTER TABLE usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE producto ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_historial ENABLE ROW LEVEL SECURITY;

-- 2) Eliminar políticas previas para re-crear con email
DROP POLICY IF EXISTS usuario_select ON usuario;
DROP POLICY IF EXISTS usuario_insert ON usuario;
DROP POLICY IF EXISTS usuario_update ON usuario;

DROP POLICY IF EXISTS producto_select ON producto;
DROP POLICY IF EXISTS producto_ins ON producto;
DROP POLICY IF EXISTS producto_upd ON producto;
DROP POLICY IF EXISTS producto_del ON producto;

DROP POLICY IF EXISTS pedido_select ON pedido;
DROP POLICY IF EXISTS pedido_insert ON pedido;
DROP POLICY IF EXISTS pedido_update ON pedido;

DROP POLICY IF EXISTS detalle_pedido_select ON detalle_pedido;
DROP POLICY IF EXISTS detalle_pedido_insert ON detalle_pedido;

DROP POLICY IF EXISTS pedido_historial_select ON pedido_historial;
DROP POLICY IF EXISTS pedido_historial_insert ON pedido_historial;

-- 3) Políticas nuevas basadas en email
-- USUARIO
CREATE POLICY usuario_select ON usuario FOR SELECT USING (
  lower(email) = lower((auth.jwt()->>'email')) OR is_admin()
);
CREATE POLICY usuario_insert ON usuario FOR INSERT WITH CHECK (
  is_admin() OR lower(email) = lower((auth.jwt()->>'email'))
);
CREATE POLICY usuario_update ON usuario FOR UPDATE USING (
  lower(email) = lower((auth.jwt()->>'email')) OR is_admin()
) WITH CHECK (
  lower(email) = lower((auth.jwt()->>'email')) OR is_admin()
);

-- PRODUCTO
CREATE POLICY producto_select ON producto FOR SELECT USING (true);
CREATE POLICY producto_ins ON producto FOR INSERT WITH CHECK (is_admin() OR is_vendedor());
CREATE POLICY producto_upd ON producto FOR UPDATE USING (is_admin() OR is_vendedor()) WITH CHECK (is_admin() OR is_vendedor());
CREATE POLICY producto_del ON producto FOR DELETE USING (is_admin() OR is_vendedor());

-- PEDIDO: cliente ve/crea los suyos; admin/vendedor todo
CREATE POLICY pedido_select ON pedido FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_usuario = pedido.id_cliente AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);
CREATE POLICY pedido_insert ON pedido FOR INSERT WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_usuario = pedido.id_cliente AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);
CREATE POLICY pedido_update ON pedido FOR UPDATE USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_usuario = pedido.id_cliente AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
) WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_usuario = pedido.id_cliente AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);

-- DETALLE_PEDIDO
CREATE POLICY detalle_pedido_select ON detalle_pedido FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = detalle_pedido.id_pedido AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);
CREATE POLICY detalle_pedido_insert ON detalle_pedido FOR INSERT WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = detalle_pedido.id_pedido AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);

-- PEDIDO_HISTORIAL
CREATE POLICY pedido_historial_select ON pedido_historial FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = pedido_historial.id_pedido AND lower(u.email) = lower((auth.jwt()->>'email'))
  )
);
CREATE POLICY pedido_historial_insert ON pedido_historial FOR INSERT WITH CHECK (is_admin() OR is_vendedor());

-- Nota: Puedes ajustar granularidad de UPDATE (cancelación cliente) posteriormente.
