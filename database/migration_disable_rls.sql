-- Desactivar RLS para operar sólo con autenticación local (inseguro en producción)
ALTER TABLE usuario DISABLE ROW LEVEL SECURITY;
ALTER TABLE producto DISABLE ROW LEVEL SECURITY;
ALTER TABLE pedido DISABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_pedido DISABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_historial DISABLE ROW LEVEL SECURITY;
ALTER TABLE ajuste_inventario DISABLE ROW LEVEL SECURITY;

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
DROP POLICY IF EXISTS ajuste_inventario_select ON ajuste_inventario;
DROP POLICY IF EXISTS ajuste_inventario_insert ON ajuste_inventario;
DROP POLICY IF EXISTS ajuste_inventario_delete ON ajuste_inventario;

-- Advertencia: todo usuario con acceso a la API tendrá lectura/escritura según reglas sin RLS.