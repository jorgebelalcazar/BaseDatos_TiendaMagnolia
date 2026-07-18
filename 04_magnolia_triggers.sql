-- crear la tabla de bitácora donde se guardarán los registros --
CREATE TABLE IF NOT EXISTS auditoria_venta (
    id_log     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta   INTEGER,
    accion     VARCHAR(20),
    fecha_log  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Función --
CREATE OR REPLACE FUNCTION fn_auditar_venta()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_venta (id_venta, accion)
    VALUES (NEW.id_venta, 'INSERT');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger 1 - enganchar la función a la tabla venta --
CREATE TRIGGER trg_auditar_venta
AFTER INSERT ON venta
FOR EACH ROW
EXECUTE FUNCTION fn_auditar_venta();

-- Registrar-- 
CALL registrar_venta(9000002, '65895752', '871702129', 'efectivo', 'P0049', 3, 3500);

-- Consulta --
SELECT * FROM auditoria_venta;



-- Función --
CREATE OR REPLACE FUNCTION fn_validar_cantidad()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cantidad > 10000 THEN
        RAISE EXCEPTION 'Cantidad % excede el máximo permitido (10000) en la venta %',
            NEW.cantidad, NEW.id_venta;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger 2- enganchar a detalle_venta --
CREATE TRIGGER trg_validar_cantidad
BEFORE INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION fn_validar_cantidad();

-- Registrar --
CALL registrar_venta(9000003, '65895752', '871702129', 'efectivo', 'P0049', 50, 3500);

-- Registrar --
CALL registrar_venta(9000004, '65895752', '871702129', 'efectivo', 'P0049', 99999, 3500);

-- Consulta --
SELECT * FROM venta WHERE id_venta = 9000004;

