-- ============================================
-- bd_ong_05_vistas.sql
-- Sistema Contable ONG - Vistas Útiles
-- ============================================
-- Versión: 2.0
-- Fecha: 2026-04-06
-- Descripción: Vistas predefinidas para consultas comunes
-- ============================================

-- ============================================
-- VISTA 1: Estado Actual de Donantes
-- ============================================

CREATE OR REPLACE VIEW v_donantes_estado_actual AS
SELECT 
    d.ID_Donante,
    d.Nombre,
    d.Tipo,
    d.Email,
    d.Pais,
    ed.Activo,
    ed.Frecuencia,
    ed.Fecha_Desde AS Estado_Desde,
    CASE 
        WHEN ed.Activo THEN 'Activo' 
        ELSE 'Inactivo' 
    END AS Estado_Texto
FROM DONANTE d
LEFT JOIN ESTADO_DONANTE ed 
    ON d.ID_Donante = ed.ID_Donante 
    AND ed.Es_Actual = TRUE;

-- ============================================
-- VISTA 2: Balance General
-- ============================================

CREATE OR REPLACE VIEW v_balance_general AS
SELECT 
    COALESCE(Tipo_Movimiento, 'TOTAL') AS Tipo_Movimiento,
    COUNT(*) AS Cantidad_Movimientos,
    SUM(Importe) AS Total_Importe,
    MIN(Fecha) AS Fecha_Primer_Movimiento,
    MAX(Fecha) AS Fecha_Ultimo_Movimiento,
    AVG(Importe) AS Importe_Promedio
FROM MOVIMIENTO_CONTABLE
GROUP BY ROLLUP(Tipo_Movimiento)
ORDER BY 
    CASE WHEN Tipo_Movimiento IS NULL THEN 2 ELSE 1 END,
    Tipo_Movimiento;

-- ============================================
-- VISTA 3: Resumen de Donantes
-- ============================================

CREATE OR REPLACE VIEW v_resumen_donantes AS
SELECT 
    d.ID_Donante,
    d.Nombre,
    d.Tipo,
    d.Pais,
    ed.Activo,
    COALESCE(COUNT(m.ID_Movimiento), 0) AS Total_Donaciones,
    COALESCE(SUM(m.Importe), 0) AS Total_Donado,
    MAX(m.Fecha) AS Ultima_Donacion,
    CASE 
        WHEN ed.Activo = FALSE THEN 'Inactivo'
        WHEN COUNT(m.ID_Movimiento) = 0 THEN 'Prospecto'
        WHEN MAX(m.Fecha) >= CURRENT_DATE - INTERVAL '180 days' THEN 'Activo'
        WHEN MAX(m.Fecha) >= CURRENT_DATE - INTERVAL '365 days' THEN 'Seguimiento'
        ELSE 'Dormido'
    END AS Clasificacion
FROM DONANTE d
LEFT JOIN ESTADO_DONANTE ed 
    ON d.ID_Donante = ed.ID_Donante 
    AND ed.Es_Actual = TRUE
LEFT JOIN MOVIMIENTO_CONTABLE m 
    ON d.ID_Donante = m.ID_Donante 
    AND m.Tipo_Movimiento = 'INGRESO'
GROUP BY d.ID_Donante, d.Nombre, d.Tipo, d.Pais, ed.Activo
ORDER BY Total_Donado DESC;

-- ============================================
-- VISTA 4: Movimientos Completos
-- ============================================

CREATE OR REPLACE VIEW v_movimientos_completos AS
SELECT 
    m.ID_Movimiento,
    m.Tipo_Movimiento,
    m.Fecha,
    m.Importe,
    m.Concepto,
    CASE 
        WHEN m.Tipo_Movimiento = 'INGRESO' THEN d.Nombre
        WHEN m.Tipo_Movimiento = 'EGRESO' THEN p.Nombre_Proveedor
    END AS Tercero,
    CASE 
        WHEN m.Tipo_Movimiento = 'INGRESO' THEN d.Pais
        WHEN m.Tipo_Movimiento = 'EGRESO' THEN p.Pais
    END AS Pais_Tercero,
    c.Nro_cuenta,
    c.Nombre_cuenta,
    c.Tipo_cuenta
FROM MOVIMIENTO_CONTABLE m
LEFT JOIN DONANTE d 
    ON m.ID_Donante = d.ID_Donante
LEFT JOIN PROVEEDOR p 
    ON m.ID_Proveedor = p.ID_Proveedor
JOIN CUENTA_CONTABLE c 
    ON m.Nro_cuenta = c.Nro_cuenta
ORDER BY m.Fecha DESC;

-- ============================================
-- VISTA 5: Top Donantes por Importe
-- ============================================

CREATE OR REPLACE VIEW v_top_donantes AS
SELECT 
    d.ID_Donante,
    d.Nombre,
    d.Tipo,
    d.Pais,
    COUNT(m.ID_Movimiento) AS Cantidad_Donaciones,
    SUM(m.Importe) AS Total_Donado,
    AVG(m.Importe) AS Donacion_Promedio,
    MIN(m.Fecha) AS Primera_Donacion,
    MAX(m.Fecha) AS Ultima_Donacion
FROM DONANTE d
JOIN MOVIMIENTO_CONTABLE m 
    ON d.ID_Donante = m.ID_Donante
    AND m.Tipo_Movimiento = 'INGRESO'
GROUP BY d.ID_Donante, d.Nombre, d.Tipo, d.Pais
ORDER BY Total_Donado DESC
LIMIT 20;

-- ============================================
-- VISTA 6: Top Proveedores por Gasto
-- ============================================

CREATE OR REPLACE VIEW v_top_proveedores AS
SELECT 
    p.ID_Proveedor,
    p.Nombre_Proveedor,
    p.Categoria_Proveedor,
    p.Ciudad,
    p.Pais,
    COUNT(m.ID_Movimiento) AS Cantidad_Compras,
    SUM(m.Importe) AS Total_Gastado,
    AVG(m.Importe) AS Compra_Promedio,
    MIN(m.Fecha) AS Primera_Compra,
    MAX(m.Fecha) AS Ultima_Compra
FROM PROVEEDOR p
JOIN MOVIMIENTO_CONTABLE m 
    ON p.ID_Proveedor = m.ID_Proveedor
    AND m.Tipo_Movimiento = 'EGRESO'
GROUP BY p.ID_Proveedor, p.Nombre_Proveedor, p.Categoria_Proveedor, p.Ciudad, p.Pais
ORDER BY Total_Gastado DESC
LIMIT 20;

-- ============================================
-- VISTA 7: Resumen por Cuenta Contable
-- ============================================

CREATE OR REPLACE VIEW v_resumen_cuentas AS
SELECT 
    c.Nro_cuenta,
    c.Nombre_cuenta,
    c.Tipo_cuenta,
    COUNT(m.ID_Movimiento) AS Cantidad_Movimientos,
    SUM(m.Importe) AS Total_Importe,
    AVG(m.Importe) AS Importe_Promedio
FROM CUENTA_CONTABLE c
LEFT JOIN MOVIMIENTO_CONTABLE m 
    ON c.Nro_cuenta = m.Nro_cuenta
GROUP BY c.Nro_cuenta, c.Nombre_cuenta, c.Tipo_cuenta
ORDER BY c.Tipo_cuenta, c.Nro_cuenta;

-- ============================================
-- VISTA 8: Movimientos por Mes
-- ============================================

CREATE OR REPLACE VIEW v_movimientos_mensuales AS
SELECT 
    DATE_TRUNC('month', m.Fecha) AS Mes,
    m.Tipo_Movimiento,
    COUNT(*) AS Cantidad_Movimientos,
    SUM(m.Importe) AS Total_Importe,
    AVG(m.Importe) AS Importe_Promedio
FROM MOVIMIENTO_CONTABLE m
GROUP BY DATE_TRUNC('month', m.Fecha), m.Tipo_Movimiento
ORDER BY Mes DESC, m.Tipo_Movimiento;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ 8 vistas creadas' AS Mensaje;
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;
