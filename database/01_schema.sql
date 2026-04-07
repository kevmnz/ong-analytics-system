-- ============================================
-- bd_ong_00_schema.sql
-- Sistema Contable ONG - Estructura de Base de Datos
-- ============================================
-- Versión: 2.0
-- Fecha: 2026-04-06
-- Autor: Kevin
-- Descripción: Schema principal con 7 tablas, índices y comentarios
-- ============================================

-- ============================================
-- PASO 1: CREAR LA BASE DE DATOS
-- ============================================
-- Ejecutar en pgAdmin o psql ANTES de correr este script:
-- 
-- CREATE DATABASE ong_contabilidad
--     WITH ENCODING 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TEMPLATE = template0;
--
-- Luego conectar: \c ong_contabilidad
-- O en pgAdmin: clic derecho > Connect

-- ============================================
-- PASO 2: ELIMINAR OBJETOS EXISTENTES (en orden correcto)
-- ============================================

-- Primero las vistas que dependen de tablas
DROP VIEW IF EXISTS v_movimientos_completos CASCADE;
DROP VIEW IF EXISTS v_resumen_donantes CASCADE;
DROP VIEW IF EXISTS v_balance_general CASCADE;
DROP VIEW IF EXISTS v_donantes_estado_actual CASCADE;

-- Funciones y triggers
DROP TRIGGER IF EXISTS trg_auditoria_movimiento ON MOVIMIENTO_CONTABLE;
DROP TRIGGER IF EXISTS trg_validar_estado_actual_update ON ESTADO_DONANTE;
DROP TRIGGER IF EXISTS trg_validar_estado_actual_insert ON ESTADO_DONANTE;
DROP FUNCTION IF EXISTS trg_validar_estado_actual();
DROP FUNCTION IF EXISTS trg_auditoria_movimiento();

-- Procedimientos
DROP PROCEDURE IF EXISTS sp_dar_baja_donante(VARCHAR, DATE);
DROP PROCEDURE IF EXISTS sp_reactivar_donante(VARCHAR, DATE, VARCHAR);

-- Tablas en orden de dependencias (primero las que tienen FK)
DROP TABLE IF EXISTS MOVIMIENTO_CONTABLE CASCADE;
DROP TABLE IF EXISTS auditoria_movimientos CASCADE;
DROP TABLE IF EXISTS DATOS_FISCALES_PROVEEDOR CASCADE;
DROP TABLE IF EXISTS DATOS_FISCALES_DONANTE CASCADE;
DROP TABLE IF EXISTS ESTADO_DONANTE CASCADE;
DROP TABLE IF EXISTS PROVEEDOR CASCADE;
DROP TABLE IF EXISTS CUENTA_CONTABLE CASCADE;
DROP TABLE IF EXISTS DONANTE CASCADE;

-- ============================================
-- PASO 3: CREAR TABLA DONANTE
-- ============================================

CREATE TABLE DONANTE (
    ID_Donante VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(200) NOT NULL,
    Tipo VARCHAR(50),
    Email VARCHAR(150),
    Telefono VARCHAR(50),
    Pais VARCHAR(100)
);

CREATE INDEX idx_donante_nombre ON DONANTE(Nombre);
CREATE INDEX idx_donante_tipo ON DONANTE(Tipo);
CREATE INDEX idx_donante_pais ON DONANTE(Pais);

COMMENT ON TABLE DONANTE IS 'Catálogo de donantes (personas, empresas o entidades estatales)';
COMMENT ON COLUMN DONANTE.ID_Donante IS 'Código único del donante (D00108, D00109...)';
COMMENT ON COLUMN DONANTE.Nombre IS 'Nombre completo del donante';
COMMENT ON COLUMN DONANTE.Tipo IS 'Empresa, Estado, Persona';
COMMENT ON COLUMN DONANTE.Email IS 'Correo electrónico';
COMMENT ON COLUMN DONANTE.Telefono IS 'Número de teléfono';
COMMENT ON COLUMN DONANTE.Pais IS 'País de residencia';

-- ============================================
-- PASO 4: CREAR TABLA ESTADO_DONANTE
-- ============================================

CREATE TABLE ESTADO_DONANTE (
    ID_Estado SERIAL PRIMARY KEY,
    ID_Donante VARCHAR(20) NOT NULL,
    Fecha_Desde DATE NOT NULL,
    Fecha_Alta DATE,
    Activo BOOLEAN NOT NULL,
    Frecuencia VARCHAR(50),
    Es_Actual BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_estado_donante FOREIGN KEY (ID_Donante) REFERENCES DONANTE(ID_Donante) ON DELETE CASCADE,
    CONSTRAINT chk_fechas_logicas CHECK (Fecha_Alta IS NULL OR Fecha_Alta >= Fecha_Desde),
    CONSTRAINT chk_estado_actual_coherente CHECK (
        (Es_Actual = TRUE AND Fecha_Alta IS NULL) OR (Es_Actual = FALSE)
    )
);

CREATE INDEX idx_estado_donante_actual ON ESTADO_DONANTE(ID_Donante, Es_Actual);
CREATE INDEX idx_estado_fecha_desde ON ESTADO_DONANTE(Fecha_Desde);
CREATE INDEX idx_estado_activo ON ESTADO_DONANTE(Activo);

COMMENT ON TABLE ESTADO_DONANTE IS 'Historial de estados del donante (activo/inactivo, fechas, frecuencia)';
COMMENT ON COLUMN ESTADO_DONANTE.ID_Estado IS 'ID único de cada cambio de estado';
COMMENT ON COLUMN ESTADO_DONANTE.ID_Donante IS 'Referencia al donante';
COMMENT ON COLUMN ESTADO_DONANTE.Fecha_Desde IS 'Inicio del período de este estado';
COMMENT ON COLUMN ESTADO_DONANTE.Fecha_Alta IS 'Fin del período (NULL si es estado actual)';
COMMENT ON COLUMN ESTADO_DONANTE.Activo IS 'TRUE = activo en ese período, FALSE = inactivo';
COMMENT ON COLUMN ESTADO_DONANTE.Frecuencia IS 'Mensual, Bimestral, Trimestral, Anual';
COMMENT ON COLUMN ESTADO_DONANTE.Es_Actual IS 'TRUE = estado vigente HOY, FALSE = histórico';

-- ============================================
-- PASO 5: CREAR TABLA DATOS_FISCALES_DONANTE
-- ============================================

CREATE TABLE DATOS_FISCALES_DONANTE (
    ID_Donante VARCHAR(20) PRIMARY KEY,
    Razon_Social VARCHAR(200),
    Tipo_Contribuyente VARCHAR(100),
    CUIT VARCHAR(20),
    CONSTRAINT fk_fiscal_donante FOREIGN KEY (ID_Donante) REFERENCES DONANTE(ID_Donante) ON DELETE CASCADE
);

CREATE INDEX idx_fiscal_cuit ON DATOS_FISCALES_DONANTE(CUIT);
CREATE INDEX idx_fiscal_tipo_contribuyente ON DATOS_FISCALES_DONANTE(Tipo_Contribuyente);

COMMENT ON TABLE DATOS_FISCALES_DONANTE IS 'Información fiscal y tributaria de donantes (para facturación)';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.ID_Donante IS 'PK y FK - Referencia al donante';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.Razon_Social IS 'Denominación legal de la empresa';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.Tipo_Contribuyente IS 'Monotributista, Responsable Inscripto, Exento';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.CUIT IS 'CUIT o CUIL';

-- ============================================
-- PASO 6: CREAR TABLA PROVEEDOR
-- ============================================

CREATE TABLE PROVEEDOR (
    ID_Proveedor VARCHAR(20) PRIMARY KEY,
    Nombre_Proveedor VARCHAR(200) NOT NULL,
    Categoria_Proveedor VARCHAR(100),
    Contacto VARCHAR(200),
    Email VARCHAR(150),
    Telefono VARCHAR(50),
    Ciudad VARCHAR(100),
    Pais VARCHAR(100)
);

CREATE INDEX idx_proveedor_nombre ON PROVEEDOR(Nombre_Proveedor);
CREATE INDEX idx_proveedor_categoria ON PROVEEDOR(Categoria_Proveedor);
CREATE INDEX idx_proveedor_ciudad ON PROVEEDOR(Ciudad);

COMMENT ON TABLE PROVEEDOR IS 'Catálogo de proveedores';
COMMENT ON COLUMN PROVEEDOR.ID_Proveedor IS 'Código único del proveedor (P00001, P00002...)';
COMMENT ON COLUMN PROVEEDOR.Nombre_Proveedor IS 'Nombre del proveedor';
COMMENT ON COLUMN PROVEEDOR.Categoria_Proveedor IS 'Servicios, Materiales, Tecnología, etc.';
COMMENT ON COLUMN PROVEEDOR.Contacto IS 'Persona de contacto';
COMMENT ON COLUMN PROVEEDOR.Email IS 'Correo electrónico';
COMMENT ON COLUMN PROVEEDOR.Telefono IS 'Número de teléfono';
COMMENT ON COLUMN PROVEEDOR.Ciudad IS 'Ciudad';
COMMENT ON COLUMN PROVEEDOR.Pais IS 'País';

-- ============================================
-- PASO 7: CREAR TABLA DATOS_FISCALES_PROVEEDOR
-- ============================================

CREATE TABLE DATOS_FISCALES_PROVEEDOR (
    ID_Proveedor VARCHAR(20) PRIMARY KEY,
    Razon_Social VARCHAR(200),
    Tipo_Contribuyente VARCHAR(100),
    CUIT VARCHAR(20),
    CONSTRAINT fk_fiscal_proveedor FOREIGN KEY (ID_Proveedor) REFERENCES PROVEEDOR(ID_Proveedor) ON DELETE CASCADE
);

CREATE INDEX idx_fiscal_proveedor_cuit ON DATOS_FISCALES_PROVEEDOR(CUIT);

COMMENT ON TABLE DATOS_FISCALES_PROVEEDOR IS 'Información fiscal y tributaria de proveedores';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.ID_Proveedor IS 'PK y FK - Referencia al proveedor';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.Razon_Social IS 'Denominación legal';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.Tipo_Contribuyente IS 'Monotributista, Responsable Inscripto, IVA Responsable';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.CUIT IS 'CUIT o CUIL';

-- ============================================
-- PASO 8: CREAR TABLA CUENTA_CONTABLE
-- ============================================

CREATE TABLE CUENTA_CONTABLE (
    Nro_cuenta VARCHAR(10) PRIMARY KEY,
    Nombre_cuenta VARCHAR(200) NOT NULL,
    Tipo_cuenta VARCHAR(50) NOT NULL,
    Descripcion TEXT,
    CONSTRAINT chk_tipo_cuenta CHECK (
        Tipo_cuenta IN (
            'Ingresos', 
            'Gastos', 
            'Activos', 
            'Pasivos', 
            'Patrimonio',
            'Resultados financieros netos'
        )
    )
);

CREATE INDEX idx_cuenta_tipo ON CUENTA_CONTABLE(Tipo_cuenta);
CREATE INDEX idx_cuenta_nombre ON CUENTA_CONTABLE(Nombre_cuenta);

COMMENT ON TABLE CUENTA_CONTABLE IS 'Plan de cuentas contable (catálogo de cuentas)';
COMMENT ON COLUMN CUENTA_CONTABLE.Nro_cuenta IS 'Número de cuenta (401200, 501400, 503100...)';
COMMENT ON COLUMN CUENTA_CONTABLE.Nombre_cuenta IS 'Nombre descriptivo de la cuenta';
COMMENT ON COLUMN CUENTA_CONTABLE.Tipo_cuenta IS 'Ingresos, Gastos, Activos, Pasivos, Patrimonio, Resultados financieros netos';
COMMENT ON COLUMN CUENTA_CONTABLE.Descripcion IS 'Detalle de qué incluye la cuenta';

-- ============================================
-- PASO 9: CREAR TABLA MOVIMIENTO_CONTABLE
-- ============================================

CREATE TABLE MOVIMIENTO_CONTABLE (
    ID_Movimiento SERIAL PRIMARY KEY,
    Tipo_Movimiento VARCHAR(10) NOT NULL,
    ID_Donante VARCHAR(20),
    ID_Proveedor VARCHAR(20),
    Nro_cuenta VARCHAR(10) NOT NULL,
    Fecha DATE NOT NULL,
    Importe DECIMAL(15,2) NOT NULL,
    Concepto TEXT,
    CONSTRAINT fk_mov_donante FOREIGN KEY (ID_Donante) REFERENCES DONANTE(ID_Donante),
    CONSTRAINT fk_mov_proveedor FOREIGN KEY (ID_Proveedor) REFERENCES PROVEEDOR(ID_Proveedor),
    CONSTRAINT fk_mov_cuenta FOREIGN KEY (Nro_cuenta) REFERENCES CUENTA_CONTABLE(Nro_cuenta),
    CONSTRAINT chk_tipo_movimiento CHECK (Tipo_Movimiento IN ('INGRESO', 'EGRESO')),
    CONSTRAINT chk_ingreso_egreso CHECK (
        (Tipo_Movimiento = 'INGRESO' AND ID_Donante IS NOT NULL AND ID_Proveedor IS NULL)
        OR
        (Tipo_Movimiento = 'EGRESO' AND ID_Proveedor IS NOT NULL AND ID_Donante IS NULL)
    ),
    CONSTRAINT chk_cuenta_tipo CHECK (
        (Nro_cuenta LIKE '4%' AND Tipo_Movimiento = 'INGRESO')
        OR
        (Nro_cuenta LIKE '5%' AND Tipo_Movimiento = 'EGRESO')
        OR
        (Nro_cuenta LIKE '1%' OR Nro_cuenta LIKE '2%' OR Nro_cuenta LIKE '3%' OR Nro_cuenta LIKE '6%')
    ),
    CONSTRAINT chk_importe_positivo CHECK (Importe > 0)
);

CREATE INDEX idx_mov_tipo ON MOVIMIENTO_CONTABLE(Tipo_Movimiento);
CREATE INDEX idx_mov_fecha ON MOVIMIENTO_CONTABLE(Fecha);
CREATE INDEX idx_mov_donante ON MOVIMIENTO_CONTABLE(ID_Donante);
CREATE INDEX idx_mov_proveedor ON MOVIMIENTO_CONTABLE(ID_Proveedor);
CREATE INDEX idx_mov_cuenta ON MOVIMIENTO_CONTABLE(Nro_cuenta);
CREATE INDEX idx_mov_fecha_tipo ON MOVIMIENTO_CONTABLE(Fecha, Tipo_Movimiento);

COMMENT ON TABLE MOVIMIENTO_CONTABLE IS 'Libro mayor unificado - Registro de todos los movimientos contables';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.ID_Movimiento IS 'ID único de cada movimiento';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Tipo_Movimiento IS 'INGRESO (de donantes) o EGRESO (a proveedores)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.ID_Donante IS 'FK a DONANTE (solo si es INGRESO)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.ID_Proveedor IS 'FK a PROVEEDOR (solo si es EGRESO)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Nro_cuenta IS 'FK a CUENTA_CONTABLE (obligatorio)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Fecha IS 'Fecha del movimiento';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Importe IS 'Monto del movimiento';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Concepto IS 'Descripción detallada del movimiento';

-- ============================================
-- PASO 10: CREAR TABLA DE AUDITORÍA
-- ============================================

CREATE TABLE auditoria_movimientos (
    ID_Auditoria SERIAL PRIMARY KEY,
    Accion VARCHAR(10) NOT NULL,
    Usuario VARCHAR(100),
    Fecha_Hora TIMESTAMP NOT NULL DEFAULT NOW(),
    ID_Movimiento INTEGER,
    Datos_Anteriores JSONB,
    Datos_Nuevos JSONB
);

CREATE INDEX idx_auditoria_fecha ON auditoria_movimientos(Fecha_Hora);
CREATE INDEX idx_auditoria_accion ON auditoria_movimientos(Accion);
CREATE INDEX idx_auditoria_usuario ON auditoria_movimientos(Usuario);

COMMENT ON TABLE auditoria_movimientos IS 'Tabla de auditoría para registro de cambios en movimientos contables';
COMMENT ON COLUMN auditoria_movimientos.ID_Auditoria IS 'ID único del registro de auditoría';
COMMENT ON COLUMN auditoria_movimientos.Accion IS 'INSERT, UPDATE o DELETE';
COMMENT ON COLUMN auditoria_movimientos.Usuario IS 'Usuario que realizó el cambio';
COMMENT ON COLUMN auditoria_movimientos.Fecha_Hora IS 'Timestamp del cambio';
COMMENT ON COLUMN auditoria_movimientos.ID_Movimiento IS 'ID del movimiento modificado';
COMMENT ON COLUMN auditoria_movimientos.Datos_Anteriores IS 'Datos anteriores al cambio (JSON)';
COMMENT ON COLUMN auditoria_movimientos.Datos_Nuevos IS 'Datos nuevos después del cambio (JSON)';

-- ============================================
-- PASO 11: COMMENT EN LA BASE DE DATOS
-- ============================================

COMMENT ON DATABASE ong_contabilidad IS 'Sistema Contable para ONG - Gestión de Donantes, Proveedores y Movimientos Contables';

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

SELECT '✅ Schema creado exitosamente' AS Mensaje;
SELECT '7 tablas creadas:' AS Info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
