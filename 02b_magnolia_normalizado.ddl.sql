-- ============================================================
--  Tienda de doña Magnolia — Esquema normalizado (3FN)

--  Este script crea las tablas nuevas. NO toca pos_general,
--  que se conserva como fuente para la migración.
-- ============================================================

-- --- Tipo de pago: ya existe (creado en 01). Lo creamos solo si falta,
-- --- para que este script sea reutilizable en una base vacía.
DO $$
BEGIN
    CREATE TYPE MPAGO AS ENUM (
        'efectivo', 'tarjeta Crédito', 'tarjeta Débito',
        'transferencia', 'transferencia bolsillo (Nequ, Daviplata, otro)'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;  -- ya existía, no hacemos nada
END$$;

-- --- Limpieza para poder re-ejecutar el script durante el desarrollo.
-- --- Orden inverso al de creación (primero los hijos). Solo tablas nuevas.
DROP TABLE IF EXISTS detalle_venta CASCADE;
DROP TABLE IF EXISTS venta         CASCADE;
DROP TABLE IF EXISTS producto      CASCADE;
DROP TABLE IF EXISTS vendedor      CASCADE;
DROP TABLE IF EXISTS sucursal      CASCADE;
DROP TABLE IF EXISTS proveedor     CASCADE;
DROP TABLE IF EXISTS cliente       CASCADE;
DROP TABLE IF EXISTS ciudad        CASCADE;

-- ============================================================
--  TABLAS DE REFERENCIA (padres)
-- ============================================================

-- Resuelve la dependencia transitiva ciudad -> departamento
CREATE TABLE ciudad (
    ciudad       VARCHAR(50) NOT NULL,
    departamento VARCHAR(50) NOT NULL,
    CONSTRAINT pk_ciudad PRIMARY KEY (ciudad)
);

CREATE TABLE cliente (
    documento VARCHAR(20)  NOT NULL,
    nombre    VARCHAR(100) NOT NULL,
    telefono  VARCHAR(20),
    ciudad    VARCHAR(50),
    CONSTRAINT pk_cliente PRIMARY KEY (documento),
    CONSTRAINT fk_cliente_ciudad FOREIGN KEY (ciudad)
        REFERENCES ciudad (ciudad) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE proveedor (
    id_proveedor INT GENERATED ALWAYS AS IDENTITY,   -- clave sustituta
    nombre       VARCHAR(100) NOT NULL,
    ciudad       VARCHAR(50),
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT uq_proveedor_nombre UNIQUE (nombre),   -- el nombre no se repite
    CONSTRAINT fk_proveedor_ciudad FOREIGN KEY (ciudad)
        REFERENCES ciudad (ciudad) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE sucursal (
    id_sucursal INT GENERATED ALWAYS AS IDENTITY,
    nombre      VARCHAR(100) NOT NULL,
    ciudad      VARCHAR(50),   -- NULLABLE: el sistema viejo no guardaba la ciudad de la sede
    CONSTRAINT pk_sucursal PRIMARY KEY (id_sucursal),
    CONSTRAINT uq_sucursal_nombre UNIQUE (nombre),
    CONSTRAINT fk_sucursal_ciudad FOREIGN KEY (ciudad)
        REFERENCES ciudad (ciudad) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
--  TABLAS QUE DEPENDEN DE LAS ANTERIORES
-- ============================================================

CREATE TABLE vendedor (
    documento   VARCHAR(20)  NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    id_sucursal INT,
    CONSTRAINT pk_vendedor PRIMARY KEY (documento),
    CONSTRAINT fk_vendedor_sucursal FOREIGN KEY (id_sucursal)
        REFERENCES sucursal (id_sucursal) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE producto (
    codigo       VARCHAR(20)  NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    categoria    VARCHAR(50),
    subcategoria VARCHAR(50) DEFAULT 'NA',
    id_proveedor INT,
    CONSTRAINT pk_producto PRIMARY KEY (codigo),
    CONSTRAINT fk_producto_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_proveedor) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Cabecera de la venta (preserva el id_venta original de pos_general)
CREATE TABLE venta (
    id_venta           INTEGER      NOT NULL,
    fecha              TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cliente_documento  VARCHAR(20),
    vendedor_documento VARCHAR(20),
    metodo_pago        MPAGO        NOT NULL DEFAULT 'efectivo',
    banco              VARCHAR(50),
    CONSTRAINT pk_venta PRIMARY KEY (id_venta),
    CONSTRAINT fk_venta_cliente FOREIGN KEY (cliente_documento)
        REFERENCES cliente (documento) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_venta_vendedor FOREIGN KEY (vendedor_documento)
        REFERENCES vendedor (documento) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Tabla puente venta<->producto (resuelve el muchos-a-muchos)
CREATE TABLE detalle_venta (
    id_venta        INTEGER      NOT NULL,
    producto_codigo VARCHAR(20)  NOT NULL,
    cantidad        INTEGER      NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL DEFAULT 0,
    garantia_meses  INTEGER      DEFAULT 0,
    CONSTRAINT pk_detalle PRIMARY KEY (id_venta, producto_codigo),  -- clave compuesta
    CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT chk_detalle_garantia CHECK (garantia_meses >= 0),
    CONSTRAINT fk_detalle_venta FOREIGN KEY (id_venta)
        REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_codigo)
        REFERENCES producto (codigo) ON UPDATE CASCADE ON DELETE RESTRICT
);
