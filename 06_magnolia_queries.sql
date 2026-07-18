-- Consulta 2: proveedores con mayor facturación --
SELECT pr.nombre AS proveedor,
       SUM(dv.cantidad * dv.precio_unitario) AS facturacion
FROM detalle_venta AS dv
JOIN producto  AS p  ON dv.producto_codigo = p.codigo
JOIN proveedor AS pr ON p.id_proveedor = pr.id_proveedor
GROUP BY pr.nombre
ORDER BY facturacion DESC;


-- Consulta 6: mejor vendedor por sucursal --
SELECT sucursal, vendedor, total_vendido
FROM (
    SELECT s.nombre        AS sucursal,
           v.nombre        AS vendedor,
           SUM(dv.cantidad * dv.precio_unitario) AS total_vendido,
           ROW_NUMBER() OVER (
               PARTITION BY s.id_sucursal
               ORDER BY SUM(dv.cantidad * dv.precio_unitario) DESC
           ) AS puesto
    FROM detalle_venta AS dv
    JOIN venta    AS ve ON dv.id_venta = ve.id_venta
    JOIN vendedor AS v  ON ve.vendedor_documento = v.documento
    JOIN sucursal AS s  ON v.id_sucursal = s.id_sucursal
    GROUP BY s.id_sucursal, s.nombre, v.nombre
) AS ranking
WHERE puesto = 1
ORDER BY total_vendido DESC;


-- Consulta 3: el producto que más vende la tienda --
SELECT p.nombre AS producto,
       SUM(dv.cantidad) AS unidades_vendidas
FROM detalle_venta AS dv
JOIN producto AS p ON dv.producto_codigo = p.codigo
GROUP BY p.nombre
ORDER BY unidades_vendidas DESC
LIMIT 1;

-- Consulta 3: el producto que más vende la tienda 
-- por cada ciudad (el más vendido en cada una) --
SELECT ciudad, producto, unidades
FROM (
    SELECT c.ciudad AS ciudad,
           p.nombre AS producto,
           SUM(dv.cantidad) AS unidades,
           ROW_NUMBER() OVER (
               PARTITION BY c.ciudad
               ORDER BY SUM(dv.cantidad) DESC
           ) AS puesto
    FROM detalle_venta AS dv
    JOIN producto AS p  ON dv.producto_codigo = p.codigo
    JOIN venta    AS ve ON dv.id_venta = ve.id_venta
    JOIN cliente  AS c  ON ve.cliente_documento = c.documento
    GROUP BY c.ciudad, p.nombre
) AS ranking
WHERE puesto = 1
ORDER BY ciudad;


-- Consulta 5: la ciudad donde cada proveedor vende más --
SELECT proveedor, ciudad, total_vendido
FROM (
    SELECT pr.nombre AS proveedor,
           c.ciudad  AS ciudad,
           SUM(dv.cantidad * dv.precio_unitario) AS total_vendido,
           ROW_NUMBER() OVER (
               PARTITION BY pr.id_proveedor
               ORDER BY SUM(dv.cantidad * dv.precio_unitario) DESC
           ) AS puesto
    FROM detalle_venta AS dv
    JOIN producto  AS p  ON dv.producto_codigo = p.codigo
    JOIN proveedor AS pr ON p.id_proveedor = pr.id_proveedor
    JOIN venta     AS ve ON dv.id_venta = ve.id_venta
    JOIN cliente   AS c  ON ve.cliente_documento = c.documento
    GROUP BY pr.id_proveedor, pr.nombre, c.ciudad
) AS ranking
WHERE puesto = 1
ORDER BY proveedor;


-- Consulta 1: monto total vendido por cada ciudad donde hay sede --
SELECT s.ciudad AS ciudad_sede,
       SUM(dv.cantidad * dv.precio_unitario) AS monto_total
FROM detalle_venta AS dv
JOIN venta    AS ve ON dv.id_venta = ve.id_venta
JOIN vendedor AS v  ON ve.vendedor_documento = v.documento
JOIN sucursal AS s  ON v.id_sucursal = s.id_sucursal
GROUP BY s.ciudad
ORDER BY monto_total DESC;


-- Consulta 4: Un cliente es fiel a un proveedor si NO EXISTE 
-- ningún producto de ese proveedor que el cliente no haya comprado --
SELECT c.documento, c.nombre, pr.nombre AS proveedor
FROM cliente AS c
CROSS JOIN proveedor AS pr
WHERE NOT EXISTS (
    -- ¿Hay algún producto de este proveedor...
    SELECT 1
    FROM producto AS p
    WHERE p.id_proveedor = pr.id_proveedor
      AND NOT EXISTS (
          -- ...que este cliente NO haya comprado?
          SELECT 1
          FROM detalle_venta AS dv
          JOIN venta AS ve ON dv.id_venta = ve.id_venta
          WHERE ve.cliente_documento = c.documento
            AND dv.producto_codigo = p.codigo
      )
)
ORDER BY proveedor, c.nombre;


SELECT COUNT(*) FROM venta;
