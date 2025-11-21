-- REEMPLAZO: Las políticas anteriores generan recursion infinita al referenciar la misma
-- tabla dentro del USING. Se sustituyen por versiones temporales sin lógica de roles
-- hasta que se integre Supabase Auth con una columna user_uuid.

-- Limpieza de políticas defectuosas (ignorar errores si no existen)
DROP POLICY IF EXISTS usuario_select_admin ON usuario;
DROP POLICY IF EXISTS usuario_select_self ON usuario;
DROP POLICY IF EXISTS usuario_insert_admin ON usuario;
DROP POLICY IF EXISTS usuario_update_admin ON usuario;
DROP POLICY IF EXISTS pedido_select_roles ON pedido;
DROP POLICY IF EXISTS pedido_historial_select ON pedido_historial;

-- Activar RLS (si se desea mantenerlo activo). Si causa fricción, comentar estas líneas.
ALTER TABLE usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_historial ENABLE ROW LEVEL SECURITY;

-- Políticas TEMPORALES: acceso abierto (control por backend). Cambiar una vez haya auth real.
CREATE POLICY usuario_select_all ON usuario FOR SELECT USING (true);
CREATE POLICY usuario_insert_all ON usuario FOR INSERT WITH CHECK (true);
CREATE POLICY usuario_update_all ON usuario FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY pedido_select_all ON pedido FOR SELECT USING (true);
CREATE POLICY pedido_insert_all ON pedido FOR INSERT WITH CHECK (true);
CREATE POLICY pedido_update_all ON pedido FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY detalle_pedido_select_all ON detalle_pedido FOR SELECT USING (true);
CREATE POLICY detalle_pedido_insert_all ON detalle_pedido FOR INSERT WITH CHECK (true);

CREATE POLICY pedido_historial_select_all ON pedido_historial FOR SELECT USING (true);
CREATE POLICY pedido_historial_insert_all ON pedido_historial FOR INSERT WITH CHECK (true);

-- FUTURO (GUIDE):
-- 1. Agregar columna: ALTER TABLE usuario ADD COLUMN user_uuid uuid REFERENCES auth.users(id);
-- 2. Marcar user_uuid UNIQUE y sincronizar en registro.
-- 3. Crear política segura (ejemplo):
--    CREATE POLICY usuario_select_self_or_admin ON usuario FOR SELECT USING (
--      auth.uid() = user_uuid OR user_uuid IN (
--        SELECT u.user_uuid FROM usuario u WHERE u.user_uuid = auth.uid() AND u.id_rol = 1
--      )
--    );
-- Evitar subquery recursiva por id_usuario, preferir user_uuid.