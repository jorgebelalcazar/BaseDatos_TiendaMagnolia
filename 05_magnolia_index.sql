-- ============================================================
--  Tienda de doña Magnolia — Índices
--
--  PostgreSQL crea índices automáticamente para las PRIMARY KEY
--  y las restricciones UNIQUE, pero NO para las claves foráneas.
--  Como las consultas de negocio (archivo 06) hacen JOIN justamente
--  por esas columnas, indexarlas acelera notablemente su ejecución,
--  sobre todo en las tablas grandes (venta y detalle_venta, con
--  3.395.200 filas cada una).
-- ============================================================

-- --- detalle_venta ---
-- Su PK es compuesta (id_venta, producto_codigo). El id_venta ya queda
-- indexado por ser la primera columna de la PK, pero producto_codigo no.
-- Este índice acelera los JOIN detalle_venta -> producto (requisitos 2, 3, 5).
CREATE INDEX IF NOT EXISTS ix_detalle_producto
    ON detalle_venta (producto_codigo);

-- --- venta ---
-- Acelera los JOIN venta -> cliente (requisitos 3B y 5)
CREATE INDEX IF NOT EXISTS ix_venta_cliente
    ON venta (cliente_documento);

-- Acelera los JOIN venta -> vendedor (requisitos 1 y 6)
CREATE INDEX IF NOT EXISTS ix_venta_vendedor
    ON venta (vendedor_documento);

-- --- producto ---
-- Acelera los JOIN producto -> proveedor (requisitos 2 y 5)
CREATE INDEX IF NOT EXISTS ix_producto_proveedor
    ON producto (id_proveedor);

-- --- vendedor ---
-- Acelera los JOIN vendedor -> sucursal (requisitos 1 y 6)
CREATE INDEX IF NOT EXISTS ix_vendedor_sucursal
    ON vendedor (id_sucursal);

-- --- Tablas de referencia (más pequeñas, pero completan el esquema) ---
CREATE INDEX IF NOT EXISTS ix_cliente_ciudad   ON cliente   (ciudad);
CREATE INDEX IF NOT EXISTS ix_proveedor_ciudad ON proveedor (ciudad);
CREATE INDEX IF NOT EXISTS ix_sucursal_ciudad  ON sucursal  (ciudad);

-- Actualiza las estadísticas del planificador para que aproveche
-- los índices recién creados al decidir cómo ejecutar las consultas.
ANALYZE;
