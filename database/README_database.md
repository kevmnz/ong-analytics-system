# Base de Datos - Guía de Instalación

## Descripción

Sistema Contable para ONGs.

**Contenido:**
- 7 tablas normalizadas
- 44 cuentas contables
- 8 vistas analíticas
- 3 procedimientos/funciones
- 3 triggers activos
- Sistema de auditoría con JSONB

---

## Instalación

### 1. Crear base de datos

```sql
CREATE DATABASE ong_contabilidad
    WITH ENCODING 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;
```

### 2. Ejecutar scripts en orden

```bash
psql -U postgres -d ong_contabilidad -f 01_schema.sql
psql -U postgres -d ong_contabilidad -f 02_cuentas.sql
psql -U postgres -d ong_contabilidad -f 03_vistas.sql
psql -U postgres -d ong_contabilidad -f 04_functions.sql
psql -U postgres -d ong_contabilidad -f 05_auditoria.sql
```

En pgAdmin: clic derecho → Query Tool → abrir archivo

---

## Verificación

```sql
SELECT COUNT(*) FROM DONANTE;                -- 19
SELECT COUNT(*) FROM PROVEEDOR;              -- 54
SELECT COUNT(*) FROM CUENTA_CONTABLE;        -- 44
SELECT COUNT(*) FROM MOVIMIENTO_CONTABLE;    -- 680+
```

---

## Vistas Disponibles

| Vista | Descripción |
|-------|-------------|
| `v_donantes_estado_actual` | Donors activos con total donado |
| `v_balance_general` | Resumen de activos, pasivos, ingresos, gastos |
| `v_top_donantes` | Ranking de donors por monto |
| `v_movimientos_completos` | Movimientos con nombres de entidades |
| `v_resumen_movimientos` | Totales por tipo y mes |
| `v_auditoria_reciente` | Últimos 100 cambios |

---

## Procedimientos

```sql
-- Dar de baja donor
CALL sp_dar_baja_donante('D00108', '2024-08-20');

-- Reactivar donor
CALL sp_reactivar_donante('D00108', '2024-09-01', 'Mensual');
```

---

## Funciones

```sql
-- Resumen financiero por período
SELECT * FROM fn_resumen_financiero('2024-01-01', '2024-12-31');

-- Clasificar donor
SELECT fn_clasificar_donante('D00108');

-- Historial de movimiento
SELECT * FROM fn_historial_movimiento(1);

-- Cambios del día
SELECT * FROM fn_cambios_del_dia();
```

---

## Auditoría

Todo cambio en `MOVIMIENTO_CONTABLE` se registra automáticamente:

```sql
SELECT * FROM v_auditoria_reciente LIMIT 20;
```

---

## Requisitos

- PostgreSQL 18+
- Encoding: UTF8
