-- Migración: añadir columna opcional id_vendedor a pedido para asociar ventas a un vendedor
-- Permite que cada vendedor vea sus propias ventas y métricas.
-- Ejecutar una sola vez.

ALTER TABLE pedido
  ADD COLUMN IF NOT EXISTS id_vendedor INTEGER NULL REFERENCES usuario(id_usuario) ON DELETE SET NULL;

-- Índice para consultas por vendedor
CREATE INDEX IF NOT EXISTS idx_pedido_id_vendedor ON pedido(id_vendedor);

-- (Opcional) No se hace backfill; pedidos existentes quedarán con id_vendedor NULL.