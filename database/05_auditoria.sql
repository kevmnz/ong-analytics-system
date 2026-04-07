-- ============================================
-- bd_ong_07_auditoria.sql
-- Sistema Contable ONG - Sistema de Auditoría
-- ============================================
-- Versión: 2.0
-- Fecha: 2026-04-06
-- Descripción: Tabla y trigger de auditoría para movimientos contables
-- ============================================

-- ============================================
-- FUNCION: Registrar cambios en movimientos
-- ============================================

CREATE OR REPLACE FUNCTION trg_auditoria_movimiento()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria_movimientos (Accion, Usuario, ID_Movimiento, Datos_Nuevos)
        VALUES (
            TG_OP,
            CURRENT_USER,
            NEW.ID_Movimiento,
            row_to_json(NEW)
        );
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria_movimientos (Accion, Usuario, ID_Movimiento, Datos_Anteriores, Datos_Nuevos)
        VALUES (
            TG_OP,
            CURRENT_USER,
            OLD.ID_Movimiento,
            row_to_json(OLD),
            row_to_json(NEW)
        );
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria_movimientos (Accion, Usuario, ID_Movimiento, Datos_Anteriores)
        VALUES (
            TG_OP,
            CURRENT_USER,
            OLD.ID_Movimiento,
            row_to_json(OLD)
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- ============================================
-- TRIGGER: Auditoría de movimientos (INSERT/UPDATE/DELETE)
-- ============================================

CREATE TRIGGER trg_auditoria_movimiento
AFTER INSERT OR UPDATE OR DELETE ON MOVIMIENTO_CONTABLE
FOR EACH ROW EXECUTE FUNCTION trg_auditoria_movimiento();

-- ============================================
-- FUNCION: Obtener historial de cambios de un movimiento
-- ============================================

CREATE OR REPLACE FUNCTION fn_historial_movimiento(p_id_movimiento INTEGER)
RETURNS TABLE (
    ID_Auditoria BIGINT,
    Accion VARCHAR(10),
    Usuario VARCHAR(100),
    Fecha_Hora TIMESTAMP,
    Datos_Anteriores JSONB,
    Datos_Nuevos JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.ID_Auditoria,
        a.Accion,
        a.Usuario,
        a.Fecha_Hora,
        a.Datos_Anteriores,
        a.Datos_Nuevos
    FROM auditoria_movimientos a
    WHERE a.ID_Movimiento = p_id_movimiento
    ORDER BY a.Fecha_Hora DESC;
END;
$$;

-- ============================================
-- FUNCION: Obtener todos los cambios de un día
-- ============================================

CREATE OR REPLACE FUNCTION fn_cambios_del_dia(p_fecha DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    ID_Auditoria BIGINT,
    Accion VARCHAR(10),
    Usuario VARCHAR(100),
    Fecha_Hora TIMESTAMP,
    ID_Movimiento INTEGER,
    Tipo_Movimiento VARCHAR(10),
    Importe DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.ID_Auditoria,
        a.Accion,
        a.Usuario,
        a.Fecha_Hora,
        a.ID_Movimiento,
        COALESCE(
            a.Datos_Nuevos->>'Tipo_Movimiento',
            a.Datos_Anteriores->>'Tipo_Movimiento'
        )::VARCHAR(10) AS Tipo_Movimiento,
        COALESCE(
            (a.Datos_Nuevos->>'Importe')::DECIMAL,
            (a.Datos_Anteriores->>'Importe')::DECIMAL
        ) AS Importe
    FROM auditoria_movimientos a
    WHERE DATE(a.Fecha_Hora) = p_fecha
    ORDER BY a.Fecha_Hora DESC;
END;
$$;

-- ============================================
-- VISTA: Resumen de auditoría reciente
-- ============================================

CREATE OR REPLACE VIEW v_auditoria_reciente AS
SELECT 
    a.Fecha_Hora,
    a.Accion,
    a.Usuario,
    a.ID_Movimiento,
    COALESCE(
        a.Datos_Nuevos->>'Tipo_Movimiento',
        a.Datos_Anteriores->>'Tipo_Movimiento'
    ) AS Tipo_Movimiento,
    COALESCE(
        (a.Datos_Nuevos->>'Importe')::DECIMAL,
        (a.Datos_Anteriores->>'Importe')::DECIMAL
    ) AS Importe,
    CASE 
        WHEN a.Accion = 'INSERT' THEN 'Nuevo registro'
        WHEN a.Accion = 'UPDATE' THEN 'Modificacion'
        WHEN a.Accion = 'DELETE' THEN 'Registro eliminado'
    END AS Descripcion_Cambio
FROM auditoria_movimientos a
ORDER BY a.Fecha_Hora DESC
LIMIT 100;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ Sistema de auditoria implementado' AS Mensaje;
SELECT COUNT(*) AS Total_Registros_Auditoria FROM auditoria_movimientos;
SELECT 'Triggers activos:' AS Info;
SELECT tgname, tablename 
FROM pg_trigger t
JOIN pg_class c ON t.relid = c.oid
WHERE c.relname = 'movimiento_contable';
