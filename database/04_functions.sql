-- ============================================
-- bd_ong_06_functions.sql
-- Sistema Contable ONG - Funciones y Triggers
-- ============================================
-- Versión: 2.0
-- Fecha: 2026-04-06
-- Descripción: Procedimientos almacenados y triggers de validación
-- ============================================

-- ============================================
-- FUNCION: Validar estado actual (solo uno por donante)
-- ============================================

CREATE OR REPLACE FUNCTION trg_validar_estado_actual()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    count_actual INT;
BEGIN
    IF NEW.Es_Actual = TRUE THEN
        SELECT COUNT(*) INTO count_actual
        FROM ESTADO_DONANTE
        WHERE ID_Donante = NEW.ID_Donante
        AND Es_Actual = TRUE
        AND ID_Estado != COALESCE(NEW.ID_Estado, 0);
        
        IF count_actual > 0 THEN
            RAISE EXCEPTION 'Ya existe un estado actual para este donante. Debe cerrar el anterior primero.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- ============================================
-- TRIGGER: Validar estado actual (INSERT)
-- ============================================

CREATE TRIGGER trg_validar_estado_actual_insert
BEFORE INSERT ON ESTADO_DONANTE
FOR EACH ROW EXECUTE FUNCTION trg_validar_estado_actual();

-- ============================================
-- TRIGGER: Validar estado actual (UPDATE)
-- ============================================

CREATE TRIGGER trg_validar_estado_actual_update
BEFORE UPDATE ON ESTADO_DONANTE
FOR EACH ROW EXECUTE FUNCTION trg_validar_estado_actual();

-- ============================================
-- PROCEDURE: Dar de baja un donante
-- ============================================

CREATE OR REPLACE PROCEDURE sp_dar_baja_donante(
    p_id_donante VARCHAR(20),
    p_fecha_baja DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id_donante IS NULL OR p_fecha_baja IS NULL THEN
        RAISE EXCEPTION 'Los parametros no pueden ser nulos';
    END IF;

    UPDATE ESTADO_DONANTE 
    SET Fecha_Alta = p_fecha_baja, 
        Es_Actual = FALSE
    WHERE ID_Donante = p_id_donante 
    AND Es_Actual = TRUE;
    
    INSERT INTO ESTADO_DONANTE 
    (ID_Donante, Fecha_Desde, Fecha_Alta, Activo, Frecuencia, Es_Actual)
    VALUES 
    (p_id_donante, p_fecha_baja, NULL, FALSE, NULL, TRUE);
    
END;
$$;

-- ============================================
-- PROCEDURE: Reactivar un donante dado de baja
-- ============================================

CREATE OR REPLACE PROCEDURE sp_reactivar_donante(
    p_id_donante VARCHAR(20),
    p_fecha_reactivacion DATE,
    p_frecuencia VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id_donante IS NULL OR p_fecha_reactivacion IS NULL THEN
        RAISE EXCEPTION 'Los parametros no pueden ser nulos';
    END IF;

    UPDATE ESTADO_DONANTE 
    SET Fecha_Alta = p_fecha_reactivacion, 
        Es_Actual = FALSE
    WHERE ID_Donante = p_id_donante 
    AND Es_Actual = TRUE;
    
    INSERT INTO ESTADO_DONANTE 
    (ID_Donante, Fecha_Desde, Fecha_Alta, Activo, Frecuencia, Es_Actual)
    VALUES 
    (p_id_donante, p_fecha_reactivacion, NULL, TRUE, p_frecuencia, TRUE);
    
END;
$$;

-- ============================================
-- FUNCION: Obtener resumen financiero por período
-- ============================================

CREATE OR REPLACE FUNCTION fn_resumen_financiero(
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE (
    Tipo_Movimiento VARCHAR(10),
    Total_Ingresos DECIMAL,
    Total_Egresos DECIMAL,
    Balance DECIMAL
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'RESUMEN'::VARCHAR(10) AS Tipo_Movimiento,
        COALESCE(SUM(CASE WHEN Tipo_Movimiento = 'INGRESO' THEN Importe ELSE 0 END), 0)::DECIMAL AS Total_Ingresos,
        COALESCE(SUM(CASE WHEN Tipo_Movimiento = 'EGRESO' THEN Importe ELSE 0 END), 0)::DECIMAL AS Total_Egresos,
        (COALESCE(SUM(CASE WHEN Tipo_Movimiento = 'INGRESO' THEN Importe ELSE 0 END), 0) - 
         COALESCE(SUM(CASE WHEN Tipo_Movimiento = 'EGRESO' THEN Importe ELSE 0 END), 0))::DECIMAL AS Balance
    FROM MOVIMIENTO_CONTABLE
    WHERE Fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
END;
$$;

-- ============================================
-- FUNCION: Clasificar donor según actividad
-- ============================================

CREATE OR REPLACE FUNCTION fn_clasificar_donante(p_id_donante VARCHAR(20))
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ultima_donacion DATE;
    v_total_donaciones INT;
    v_activo BOOLEAN;
BEGIN
    SELECT MAX(m.Fecha), COUNT(m.ID_Movimiento), ed.Activo
    INTO v_ultima_donacion, v_total_donaciones, v_activo
    FROM MOVIMIENTO_CONTABLE m
    LEFT JOIN ESTADO_DONANTE ed ON m.ID_Donante = ed.ID_Donante AND ed.Es_Actual = TRUE
    WHERE m.ID_Donante = p_id_donante
    GROUP BY ed.Activo;
    
    IF v_activo = FALSE THEN
        RETURN 'Inactivo';
    ELSIF v_total_donaciones = 0 THEN
        RETURN 'Prospecto';
    ELSIF v_ultima_donacion >= CURRENT_DATE - INTERVAL '180 days' THEN
        RETURN 'Activo Comprometido';
    ELSIF v_ultima_donacion >= CURRENT_DATE - INTERVAL '365 days' THEN
        RETURN 'Activo con Seguimiento';
    ELSE
        RETURN 'Activo Dormido';
    END IF;
END;
$$;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ Functions y Triggers creados' AS Mensaje;
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION'
ORDER BY routine_name;
