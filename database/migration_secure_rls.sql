-- Sprint 4: Políticas RLS seguras usando Supabase Auth (user_uuid)
-- Requisitos previos: columna user_uuid en tabla usuario poblada y UNIQUE/NOT NULL.

-- 1. Habilitar RLS (si aún no está habilitado) y remover políticas abiertas temporales
ALTER TABLE usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE producto ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_historial ENABLE ROW LEVEL SECURITY;

-- Limpieza de políticas previas (no falla si no existen)
DROP POLICY IF EXISTS usuario_select_all ON usuario;
DROP POLICY IF EXISTS usuario_insert_all ON usuario;
DROP POLICY IF EXISTS usuario_update_all ON usuario;

DROP POLICY IF EXISTS pedido_select_all ON pedido;
DROP POLICY IF EXISTS pedido_insert_all ON pedido;
DROP POLICY IF EXISTS pedido_update_all ON pedido;

DROP POLICY IF EXISTS detalle_pedido_select_all ON detalle_pedido;
DROP POLICY IF EXISTS detalle_pedido_insert_all ON detalle_pedido;

DROP POLICY IF EXISTS pedido_historial_select_all ON pedido_historial;
DROP POLICY IF EXISTS pedido_historial_insert_all ON pedido_historial;

-- 2. Helpers de rol (evita recursion compleja en políticas)
-- SECURITY DEFINER permite ejecutar con privilegios del creador.
CREATE OR REPLACE FUNCTION is_admin() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_rol = 1
  );
$$;

CREATE OR REPLACE FUNCTION is_vendedor() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_rol = 2
  );
$$;

CREATE OR REPLACE FUNCTION is_cliente() RETURNS boolean
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS(
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_rol = 3
  );
$$;

-- 3. Políticas sobre USUARIO
-- Ver su propio perfil o si es admin ver todos.
CREATE POLICY usuario_select ON usuario FOR SELECT USING (
  user_uuid = auth.uid() OR is_admin()
);
-- Insert: solo durante registro backend, permitir a admin crear otros usuarios.
CREATE POLICY usuario_insert ON usuario FOR INSERT WITH CHECK (
  is_admin() OR user_uuid = auth.uid()
);
-- Update: usuario modifica su fila (perfil), admin modifica cualquiera.
CREATE POLICY usuario_update ON usuario FOR UPDATE USING (
  user_uuid = auth.uid() OR is_admin()
) WITH CHECK (
  user_uuid = auth.uid() OR is_admin()
);

-- 4. Políticas sobre PRODUCTO
-- Lectura: todos pueden ver productos.
CREATE POLICY producto_select ON producto FOR SELECT USING (true);
-- Insert / Update / Delete: admin o vendedor.
CREATE POLICY producto_ins ON producto FOR INSERT WITH CHECK (is_admin() OR is_vendedor());
CREATE POLICY producto_upd ON producto FOR UPDATE USING (is_admin() OR is_vendedor()) WITH CHECK (is_admin() OR is_vendedor());
CREATE POLICY producto_del ON producto FOR DELETE USING (is_admin() OR is_vendedor());

-- 5. Políticas sobre PEDIDO
-- Lectura: admin y vendedor ven todos; cliente solo sus pedidos.
CREATE POLICY pedido_select ON pedido FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_usuario = pedido.id_cliente
  )
);
-- Insert: cliente creando pedido propio (id_cliente vinculado) o vendedor/admin creando para cliente.
CREATE POLICY pedido_insert ON pedido FOR INSERT WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_usuario = pedido.id_cliente
  )
);
-- Update: admin y vendedor gestionan estados; cliente solo puede actualizar si es cancelación y le pertenece.
-- Para simplificar: permitir UPDATE si admin/vendedor o dueño.
CREATE POLICY pedido_update ON pedido FOR UPDATE USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_usuario = pedido.id_cliente
  )
) WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_usuario = pedido.id_cliente
  )
);

-- 6. Políticas sobre DETALLE_PEDIDO
-- Lectura: misma regla que pedido (asociado por id_pedido)
CREATE POLICY detalle_pedido_select ON detalle_pedido FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = detalle_pedido.id_pedido AND u.user_uuid = auth.uid()
  )
);
-- Insert: seguir reglas de creación de pedido (ya controlado en backend). Permitir admin/vendedor o dueño del pedido.
CREATE POLICY detalle_pedido_insert ON detalle_pedido FOR INSERT WITH CHECK (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = detalle_pedido.id_pedido AND u.user_uuid = auth.uid()
  )
);

-- 7. Políticas sobre PEDIDO_HISTORIAL
-- Lectura: cualquiera que pueda ver el pedido asociado.
CREATE POLICY pedido_historial_select ON pedido_historial FOR SELECT USING (
  is_admin() OR is_vendedor() OR EXISTS (
    SELECT 1 FROM pedido p JOIN usuario u ON u.id_usuario = p.id_cliente
    WHERE p.id_pedido = pedido_historial.id_pedido AND u.user_uuid = auth.uid()
  )
);
-- Insert: backend (admin/vendedor) al cambiar estado.
CREATE POLICY pedido_historial_insert ON pedido_historial FOR INSERT WITH CHECK (is_admin() OR is_vendedor());

-- 8. Validación rápida: asegurar que no quedan políticas abiertas
-- (Opcional: SELECT * FROM pg_policies WHERE tablename IN (...))

-- NOTA: Ajustar lógica de cancelación en backend para impedir que cliente modifique otros campos no permitidos.
-- FUTURO: Separar políticas por tipo de operación más granular (ej. cliente solo UPDATE donde nuevo estado = cancelado).