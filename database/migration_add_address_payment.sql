-- Migración para direcciones y métodos de pago de usuarios
-- Ejecutar en Supabase antes de usar las nuevas pantallas.

-- Tabla de direcciones
CREATE TABLE IF NOT EXISTS public.direccion_usuario (
  id_direccion SERIAL PRIMARY KEY,
  id_usuario INT NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  linea1 VARCHAR(200) NOT NULL,
  linea2 VARCHAR(200),
  ciudad VARCHAR(100) NOT NULL,
  provincia VARCHAR(100) NOT NULL,
  cp VARCHAR(20) NOT NULL,
  referencias TEXT,
  es_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_direccion_usuario_user ON public.direccion_usuario(id_usuario);

-- Garantizar solo una dirección default por usuario
CREATE OR REPLACE FUNCTION set_single_default_address() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.es_default THEN
    UPDATE public.direccion_usuario SET es_default = FALSE WHERE id_usuario = NEW.id_usuario AND id_direccion <> NEW.id_direccion;
  END IF;
  RETURN NEW;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_single_default_address ON public.direccion_usuario;
CREATE TRIGGER trg_single_default_address
AFTER INSERT OR UPDATE ON public.direccion_usuario
FOR EACH ROW EXECUTE FUNCTION set_single_default_address();

-- Tabla de métodos de pago
CREATE TABLE IF NOT EXISTS public.metodo_pago_usuario (
  id_metodo SERIAL PRIMARY KEY,
  id_usuario INT NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('tarjeta','transferencia','efectivo','nequi')),
  alias VARCHAR(100),
  datos JSONB,
  es_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_metodo_pago_usuario_user ON public.metodo_pago_usuario(id_usuario);

-- Garantizar un método default por usuario
CREATE OR REPLACE FUNCTION set_single_default_payment() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.es_default THEN
    UPDATE public.metodo_pago_usuario SET es_default = FALSE WHERE id_usuario = NEW.id_usuario AND id_metodo <> NEW.id_metodo;
  END IF;
  RETURN NEW;
END;$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_single_default_payment ON public.metodo_pago_usuario;
CREATE TRIGGER trg_single_default_payment
AFTER INSERT OR UPDATE ON public.metodo_pago_usuario
FOR EACH ROW EXECUTE FUNCTION set_single_default_payment();

-- Columnas opcionales en pedido (si no existen)
ALTER TABLE public.pedido ADD COLUMN IF NOT EXISTS tipo_entrega VARCHAR(20) DEFAULT 'envio';
ALTER TABLE public.pedido ADD COLUMN IF NOT EXISTS direccion_envio TEXT;
ALTER TABLE public.pedido ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(30);
ALTER TABLE public.pedido ADD COLUMN IF NOT EXISTS pago_referencia VARCHAR(120);

-- Mensaje
SELECT 'Migración de direcciones y métodos de pago aplicada' AS mensaje;
