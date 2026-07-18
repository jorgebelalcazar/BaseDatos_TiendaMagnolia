# Sistema POS — Tienda de doña Magnolia

Rediseño y re-implementación del sistema de punto de venta de la tienda de doña Magnolia para la materia de **Bases de Datos** (750006-C) de la Universidad del Valle.

El sistema original funcionaba sobre una única tabla desnormalizada (`pos_general`). Este proyecto la rediseña hasta la **Tercera Forma Normal (3FN)**, migra los datos históricos sin pérdida, e implementa restricciones de integridad, consultas de negocio, funciones, un procedimiento, disparadores e índices sobre **PostgreSQL 16** desplegado en **Docker**.

## Estructura del repositorio

| Archivo | Descripción |
|---|---|
| `Dockerfile` | Imagen de PostgreSQL 16 con los scripts de inicialización. |
| `01_magnolia_minimarket.ddl.sql` | Esquema original de una sola tabla (`pos_general`). |
| `02b_magnolia_normalizado.ddl.sql` | Esquema normalizado a 3FN con todas las restricciones. |
| `02c_magnolia_migracion.sql` | Migración de datos de `pos_general` al modelo normalizado. |
| `03_magnolia_functions.sql` | Dos funciones y un procedimiento de apoyo. |
| `04_magnolia_triggers.sql` | Disparadores de auditoría y de validación. |
| `05_magnolia_index.sql` | Índices sobre las claves foráneas. |
| `06_magnolia_queries.sql` | Consultas que responden a los seis requisitos de negocio. |

> **Nota sobre los datos:** el archivo de datos original `02_magnolia_minimarket.dml.sql` (~2 GB, ~3.4 millones de filas) no se incluye en el repositorio por su tamaño (GitHub limita a 100 MB por archivo). Corresponde al conjunto de datos entregado con el enunciado del proyecto.

## Despliegue

```bash
# Construir la imagen
docker build -t magnolia-db .

# Levantar el contenedor (puerto 5433 del equipo -> 5432 del contenedor)
docker run --name magnolia-cont -p 5433:5432 -d magnolia-db
```

Conexión desde un cliente (DBeaver, pgAdmin, etc.):

- **Host:** localhost
- **Puerto:** 5433
- **Base de datos:** db_magnolia
- **Usuario:** u_magnolia

Con la base desplegada, ejecutar los scripts en orden: `02b` (esquema), `02c` (migración), `03`, `04`, `05` y `06`.

## Requisitos de negocio resueltos

1. Monto total vendido por cada ciudad donde hay sede.
2. Proveedores con mayor facturación.
3. Producto que más vende la tienda, en general y por ciudad.
4. Clientes que compran todos los productos de un proveedor.
5. Ciudad donde cada proveedor vende más.
6. Mejor vendedor por sucursal.

## Enlaces

- **Video (Opcional 1):** _pendiente_
- **Video (Opcional 2):** _pendiente_
- **Informe (PDF):** ver `informe_magnolia.pdf`

## Autor

_Tu nombre — código de estudiante_
