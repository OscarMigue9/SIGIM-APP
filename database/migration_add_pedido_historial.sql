-- Historial de cambios de estado de pedidos
CREATE TABLE IF NOT EXISTS pedido_historial (
  id_historial SERIAL PRIMARY KEY,
  id_pedido INT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
  id_estado INT NOT NULL REFERENCES estado_pedido(id_estado),
  fecha TIMESTAMP NOT NULL DEFAULT NOW(),
  comentario TEXT
);

-- Índice para consultas por pedido
CREATE INDEX IF NOT EXISTS idx_pedido_historial_pedido ON pedido_historial(id_pedido);

-- (Opcional) Política RLS sugerida - requiere activar RLS y usar Supabase Auth real
-- ALTER TABLE pedido_historial ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "historial_select_admin" ON pedido_historial FOR SELECT
-- USING (EXISTS (SELECT 1 FROM usuario u WHERE u.id_usuario = auth.uid() AND u.id_rol = 1));