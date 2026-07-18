-- ============================================================
--  Tienda de doña Magnolia — Migración de datos
--
--  Transfiere la información desde la tabla desnormalizada
--  pos_general hacia el modelo normalizado (3FN), sin pérdida.
--  Ejecutar DESPUÉS de crear las tablas (02b) y en este orden,
--  de tablas padre a tablas hijas, para respetar las FK.
-- ============================================================


-- 1. CIUDAD — reúne las ciudades de clientes y proveedores.
--    Se agrupa por ciudad y se toma un departamento con MAX (el lado
--    del proveedor no tenía departamento; MAX ignora los nulos).
INSERT INTO ciudad (ciudad, departamento)
SELECT ciudad_nom, MAX(depto)
FROM (
    SELECT cliente_ciudad AS ciudad_nom, cliente_departamento AS depto
    FROM pos_general
    WHERE cliente_ciudad IS NOT NULL
    UNION ALL
    SELECT proveedor_ciudad, proveedor_departamento
    FROM pos_general
    WHERE proveedor_ciudad IS NOT NULL
) AS todas
GROUP BY ciudad_nom;

-- 2. Ciudades que solo existen como nombre de sucursal (no venían
--    en clientes ni proveedores). Necesarias para el paso 6.
INSERT INTO ciudad (ciudad, departamento) VALUES
    ('Jamundí', 'Valle del Cauca'),
    ('Yumbo',   'Valle del Cauca');

-- 3. CLIENTE — combinaciones únicas por documento.
INSERT INTO cliente (documento, nombre, telefono, ciudad)
SELECT DISTINCT cliente_documento, cliente_nombre, cliente_telefono, cliente_ciudad
FROM pos_general
WHERE cliente_documento IS NOT NULL;

-- 4. PROVEEDOR — clave sustituta autogenerada. Como un mismo proveedor
--    aparecía con varias ciudades, se elige la MÁS FRECUENTE con ROW_NUMBER().
INSERT INTO proveedor (nombre, ciudad)
SELECT nombre, ciudad
FROM (
    SELECT proveedor_nombre AS nombre,
           proveedor_ciudad AS ciudad,
           ROW_NUMBER() OVER (PARTITION BY proveedor_nombre
                              ORDER BY COUNT(*) DESC) AS puesto
    FROM pos_general
    WHERE proveedor_nombre IS NOT NULL
    GROUP BY proveedor_nombre, proveedor_ciudad
) AS ranking
WHERE puesto = 1;

-- 5. SUCURSAL — nombres únicos de sede (la ciudad se asigna en el paso 6).
INSERT INTO sucursal (nombre)
SELECT DISTINCT vendedor_sucursal
FROM pos_general
WHERE vendedor_sucursal IS NOT NULL;

-- 6. Asignación de ciudad a cada sucursal (dato ausente en el origen).
--    Jamundí y Yumbo son ciudades; Sur, Centro y Norte se asumen en Cali.
UPDATE sucursal SET ciudad = 'Jamundí' WHERE nombre = 'Jamundí';
UPDATE sucursal SET ciudad = 'Yumbo'   WHERE nombre = 'Yumbo';
UPDATE sucursal SET ciudad = 'Cali'    WHERE nombre IN ('Sur', 'Centro', 'Norte');

-- 7. VENDEDOR — traduce el nombre de sucursal a su id con un JOIN.
INSERT INTO vendedor (documento, nombre, id_sucursal)
SELECT DISTINCT p.vendedor_documento, p.vendedor_nombre, s.id_sucursal
FROM pos_general AS p
JOIN sucursal AS s ON p.vendedor_sucursal = s.nombre
WHERE p.vendedor_documento IS NOT NULL;

-- 8. PRODUCTO — traduce el nombre de proveedor a su id con un JOIN.
INSERT INTO producto (codigo, nombre, categoria, subcategoria, id_proveedor)
SELECT DISTINCT p.producto_codigo, p.producto_nombre, p.categoria,
       p.subcategoria, pr.id_proveedor
FROM pos_general AS p
JOIN proveedor AS pr ON p.proveedor_nombre = pr.nombre
WHERE p.producto_codigo IS NOT NULL;

-- 9. VENTA — cabecera. Conserva el id_venta original (sin DISTINCT ni JOIN).
INSERT INTO venta (id_venta, fecha, cliente_documento, vendedor_documento, metodo_pago, banco)
SELECT id_venta, fecha, cliente_documento, vendedor_documento, metodo_pago, banco
FROM pos_general
WHERE id_venta IS NOT NULL;

-- 10. DETALLE_VENTA — líneas de cada venta.
INSERT INTO detalle_venta (id_venta, producto_codigo, cantidad, precio_unitario, garantia_meses)
SELECT id_venta, producto_codigo, cantidad, precio_unitario, garantia_meses
FROM pos_general
WHERE id_venta IS NOT NULL
  AND producto_codigo IS NOT NULL;

-- 11. Verificación de no-pérdida: ambos totales deben coincidir.
SELECT (SELECT COUNT(*) FROM pos_general) AS original,
       (SELECT COUNT(*) FROM venta)       AS migrado;
