-- Función 1 --
CREATE OR REPLACE FUNCTION facturacion_proveedor(p_nombre VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(dv.cantidad * dv.precio_unitario), 0)
    INTO total
    FROM detalle_venta AS dv
    JOIN producto  AS p  ON dv.producto_codigo = p.codigo
    JOIN proveedor AS pr ON p.id_proveedor = pr.id_proveedor
    WHERE pr.nombre = p_nombre;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Consulta --
SELECT facturacion_proveedor('Alpina');


-- Función 2 --
CREATE OR REPLACE FUNCTION total_ventas_ciudad(p_ciudad VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(dv.cantidad * dv.precio_unitario), 0)
    INTO total
    FROM detalle_venta AS dv
    JOIN venta    AS ve ON dv.id_venta = ve.id_venta
    JOIN vendedor AS v  ON ve.vendedor_documento = v.documento
    JOIN sucursal AS s  ON v.id_sucursal = s.id_sucursal
    WHERE s.ciudad = p_ciudad;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Consulta --
SELECT total_ventas_ciudad('Cali');


-- Procedimiento --
CREATE OR REPLACE PROCEDURE registrar_venta(
    p_id_venta          INTEGER,
    p_cliente           VARCHAR,
    p_vendedor          VARCHAR,
    p_metodo_pago       MPAGO,
    p_producto          VARCHAR,
    p_cantidad          INTEGER,
    p_precio_unitario   NUMERIC
)
AS $$
BEGIN
    -- 1. Insertar la cabecera de la venta
    INSERT INTO venta (id_venta, fecha, cliente_documento, vendedor_documento, metodo_pago)
    VALUES (p_id_venta, CURRENT_TIMESTAMP, p_cliente, p_vendedor, p_metodo_pago);

    -- 2. Insertar la línea de detalle
    INSERT INTO detalle_venta (id_venta, producto_codigo, cantidad, precio_unitario)
    VALUES (p_id_venta, p_producto, p_cantidad, p_precio_unitario);

    RAISE NOTICE 'Venta % registrada correctamente', p_id_venta;
END;
$$ LANGUAGE plpgsql;

--Consulta --
CALL registrar_venta(
    9000001,              -- id_venta nuevo
    '65895752',           -- un cliente que existe (de los que vimos antes)
    '871702129',          -- José Esteban, vendedor que existe
    'efectivo',           -- método de pago
    'P0049',              -- un producto que existe
    5,                    -- cantidad
    3500                  -- precio unitario
);

-- Consulta --
SELECT * FROM venta WHERE id_venta = 9000001;
SELECT * FROM detalle_venta WHERE id_venta = 9000001;
