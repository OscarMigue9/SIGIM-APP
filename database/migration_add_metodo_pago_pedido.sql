-- Migración: añadir método de pago al pedido
ALTER TABLE pedido ADD COLUMN IF NOT EXISTS metodo_pago TEXT;

-- Opcional: valor por defecto 'efectivo' para pedidos nuevos sin especificar
-- ALTER TABLE pedido ALTER COLUMN metodo_pago SET DEFAULT 'efectivo';
