-- Sprint 4: Tabla de descuentos/promociones
CREATE TABLE IF NOT EXISTS descuento (
  id_descuento SERIAL PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('PORCENTAJE','FIJO')),
  valor NUMERIC NOT NULL CHECK (valor > 0),
  activo BOOLEAN NOT NULL DEFAULT true,
  fecha_inicio TIMESTAMP NULL,
  fecha_fin TIMESTAMP NULL,
  min_total NUMERIC NULL,
  id_producto INT NULL REFERENCES producto(id_producto) ON DELETE SET NULL,
  categoria TEXT NULL,
  uso_max INT NULL,
  uso_actual INT NOT NULL DEFAULT 0,
  CONSTRAINT descuento_fechas_validas CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Índices útiles
CREATE INDEX IF NOT EXISTS idx_descuento_activo ON descuento(activo);
CREATE INDEX IF NOT EXISTS idx_descuento_codigo ON descuento(codigo);

-- Nota: Para reglas complejas (stack de descuentos) se puede crear posteriormente tabla puente pedido_descuento.
