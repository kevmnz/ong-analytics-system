-- Sistema Contable ONG - Estructura de Base de Datos

-- Eliminación de vistas existentes (en orden de dependencias)
DROP VIEW IF EXISTS v_movimientos_completos CASCADE;
DROP VIEW IF EXISTS v_resumen_donantes CASCADE;
DROP VIEW IF EXISTS v_balance_general CASCADE;
DROP VIEW IF EXISTS v_donantes_estado_actual CASCADE;

-- Eliminación de triggers y funciones
DROP TRIGGER IF EXISTS trg_auditoria_movimiento ON MOVIMIENTO_CONTABLE;
DROP TRIGGER IF EXISTS trg_validar_estado_actual_update ON ESTADO_DONANTE;
DROP TRIGGER IF EXISTS trg_validar_estado_actual_insert ON ESTADO_DONANTE;
DROP FUNCTION IF EXISTS trg_validar_estado_actual();
DROP FUNCTION IF EXISTS trg_auditoria_movimiento();

-- Eliminación de procedimientos
DROP PROCEDURE IF EXISTS sp_dar_baja_donante(VARCHAR, DATE);
DROP PROCEDURE IF EXISTS sp_reactivar_donante(VARCHAR, DATE, VARCHAR);

-- Eliminación de tablas
DROP TABLE IF EXISTS MOVIMIENTO_CONTABLE CASCADE;
DROP TABLE IF EXISTS auditoria_movimientos CASCADE;
DROP TABLE IF EXISTS DATOS_FISCALES_PROVEEDOR CASCADE;
DROP TABLE IF EXISTS DATOS_FISCALES_DONANTE CASCADE;
DROP TABLE IF EXISTS ESTADO_DONANTE CASCADE;
DROP TABLE IF EXISTS PROVEEDOR CASCADE;
DROP TABLE IF EXISTS CUENTA_CONTABLE CASCADE;
DROP TABLE IF EXISTS DONANTE CASCADE;

-- Tabla DONANTE
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

COMMENT ON TABLE DONANTE IS 'Catálogo de donantes de la organización';
COMMENT ON COLUMN DONANTE.ID_Donante IS 'Código manual de negocio (ej: D00108, D00109)';
COMMENT ON COLUMN DONANTE.Tipo IS 'Categoría: Empresa, Estado, Persona';

-- Tabla ESTADO_DONANTE
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

COMMENT ON TABLE ESTADO_DONANTE IS 'Historial de estados y recurrencia de los donantes';
COMMENT ON COLUMN ESTADO_DONANTE.Fecha_Desde IS 'Inicio de vigencia de este estado';
COMMENT ON COLUMN ESTADO_DONANTE.Fecha_Alta IS 'Fin de vigencia del estado (NULL si sigue activo hoy)';
COMMENT ON COLUMN ESTADO_DONANTE.Frecuencia IS 'Periodicidad de la donación (Mensual, Anual, etc.)';
COMMENT ON COLUMN ESTADO_DONANTE.Es_Actual IS 'Indica si es el estado vigente actual (solo uno activo a la vez)';

-- Tabla DATOS_FISCALES_DONANTE
CREATE TABLE DATOS_FISCALES_DONANTE (
    ID_Donante VARCHAR(20) PRIMARY KEY,
    Razon_Social VARCHAR(200),
    Tipo_Contribuyente VARCHAR(100),
    CUIT VARCHAR(20),
    CONSTRAINT fk_fiscal_donante FOREIGN KEY (ID_Donante) REFERENCES DONANTE(ID_Donante) ON DELETE CASCADE
);

CREATE INDEX idx_fiscal_cuit ON DATOS_FISCALES_DONANTE(CUIT);
CREATE INDEX idx_fiscal_tipo_contribuyente ON DATOS_FISCALES_DONANTE(Tipo_Contribuyente);

COMMENT ON TABLE DATOS_FISCALES_DONANTE IS 'Información fiscal de donantes que requieren facturación/recibo formal';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.ID_Donante IS 'PK y FK a DONANTE (Relación 1:1)';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.Tipo_Contribuyente IS 'Categoría fiscal (Monotributista, Responsable Inscripto, Exento)';
COMMENT ON COLUMN DATOS_FISCALES_DONANTE.CUIT IS 'CUIT o CUIL del donante';

-- Tabla PROVEEDOR
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

COMMENT ON TABLE PROVEEDOR IS 'Catálogo de proveedores de la organización';
COMMENT ON COLUMN PROVEEDOR.ID_Proveedor IS 'Código manual de negocio (ej: P00001, P00002)';
COMMENT ON COLUMN PROVEEDOR.Categoria_Proveedor IS 'Rubro: Servicios, Materiales, Tecnología, etc.';

-- Tabla DATOS_FISCALES_PROVEEDOR
CREATE TABLE DATOS_FISCALES_PROVEEDOR (
    ID_Proveedor VARCHAR(20) PRIMARY KEY,
    Razon_Social VARCHAR(200),
    Tipo_Contribuyente VARCHAR(100),
    CUIT VARCHAR(20),
    CONSTRAINT fk_fiscal_proveedor FOREIGN KEY (ID_Proveedor) REFERENCES PROVEEDOR(ID_Proveedor) ON DELETE CASCADE
);

CREATE INDEX idx_fiscal_proveedor_cuit ON DATOS_FISCALES_PROVEEDOR(CUIT);

COMMENT ON TABLE DATOS_FISCALES_PROVEEDOR IS 'Información fiscal y tributaria de proveedores';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.ID_Proveedor IS 'PK y FK a PROVEEDOR (Relación 1:1)';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.Tipo_Contribuyente IS 'Categoría fiscal (Monotributista, Responsable Inscripto, IVA Responsable)';
COMMENT ON COLUMN DATOS_FISCALES_PROVEEDOR.CUIT IS 'CUIT o CUIL del proveedor';

-- Tabla CUENTA_CONTABLE
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

COMMENT ON TABLE CUENTA_CONTABLE IS 'Plan de cuentas del sistema contable (catálogo de cuentas)';
COMMENT ON COLUMN CUENTA_CONTABLE.Nro_cuenta IS 'Número identificador de cuenta (ej: 401200, 501400)';
COMMENT ON COLUMN CUENTA_CONTABLE.Tipo_cuenta IS 'Clasificación: Ingresos, Gastos, Activos, Pasivos, Patrimonio, Resultados';

-- Tabla MOVIMIENTO_CONTABLE
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

COMMENT ON TABLE MOVIMIENTO_CONTABLE IS 'Libro mayor - Registro unificado de ingresos y egresos';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Tipo_Movimiento IS 'Categoría del movimiento: INGRESO o EGRESO';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.ID_Donante IS 'Asociado al movimiento (solo si Tipo = INGRESO)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.ID_Proveedor IS 'Asociado al movimiento (solo si Tipo = EGRESO)';
COMMENT ON COLUMN MOVIMIENTO_CONTABLE.Nro_cuenta IS 'Cuenta contable imputada para este movimiento';

-- Tabla auditoria_movimientos
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

COMMENT ON TABLE auditoria_movimientos IS 'Historial de auditoría para el registro de cambios en el libro mayor';
COMMENT ON COLUMN auditoria_movimientos.Accion IS 'Operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN auditoria_movimientos.Datos_Anteriores IS 'Registro de datos en formato JSON previo a la modificación';
COMMENT ON COLUMN auditoria_movimientos.Datos_Nuevos IS 'Registro de datos en formato JSON posterior a la modificación';

COMMENT ON DATABASE ong_contabilidad IS 'Sistema Contable para ONG - Gestión de Donantes, Proveedores y Movimientos Contables';
