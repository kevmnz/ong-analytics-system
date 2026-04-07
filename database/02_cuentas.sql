-- ============================================
-- bd_ong_01_cuentas.sql
-- Sistema Contable ONG - Plan de Cuentas Contables
-- ============================================
-- Versión: 1.0
-- Fecha: 2026-03-31
-- Descripción: Carga inicial del plan de cuentas (44 cuentas)
-- Origen: Numero_cuentas_ONG.csv
-- ============================================

-- ============================================
-- CARGA DE CUENTAS CONTABLES
-- ============================================

INSERT INTO CUENTA_CONTABLE (Nro_Cuenta, Nombre_Cuenta, Tipo_Cuenta, Descripcion) VALUES
-- ACTIVOS (1XX)
('102201', 'Gastos Pagados por Adelantado', 'Activos', 'Gastos pagados por adelantado'),
('202001', 'Prestamos', 'Pasivos', 'Prestamos'),

-- PATRIMONIO (3XX)
('300010', 'Apertura Balance Inicial', 'Patrimonio', 'Apertura Balance Inicial'),

-- INGRESOS (4XX)
('401200', 'Ingresos Institucionales', 'Ingresos', 'Programas / Proyectos Sociales, Internacionales, Concursos'),
('402101', 'Ingresos Institucionales Mensuales', 'Ingresos', 'Ingresos Institucionales Mensuales'),
('402102', 'Donaciones Personales Mensuales', 'Ingresos', 'Donaciones Personales Mensuales'),
('403101', 'Donaciones Personales No Recurrentes', 'Ingresos', 'Donaciones Personales No Recurrentes'),
('403102', 'Ingresos Cuotas Asociados', 'Ingresos', 'Ingresos Cuotas Asociados'),
('403103', 'Ingresos Bonos Contribucion', 'Ingresos', 'Para fines generales'),
('403106', 'Ingresos Internacionales Personales', 'Ingresos', 'De Personas en Moneda Extranjera (se valoriza en $ al TC)'),
('404100', 'Ingresos Estado', 'Ingresos', 'Subsidios Cargas Sociales, Programas Estatales, Becas Estatales, etc'),
('405100', 'Ingresos Servicios', 'Ingresos', 'Servicios Sociales, Asistencia Tecnica, Educacion, Matriculas, etc'),
('406100', 'Ingresos Eventos Institucionales', 'Ingresos', 'Institucionales o Bonos Contribucion al Evento, Ingresos adicionales institucionales o Personales al Evento, Otros, etc'),
('409021', 'Donaciones en Especies', 'Ingresos', 'Donacion de mercaderia que, si se registra, debe ser a un valor en $$$ que sea correcto de acuerdo al valor de mercado'),
('409099', 'Ingresos / Donaciones a Clasificar o Identificar', 'Ingresos', 'Ingreso sin identificar / clasificar. Al cierre dejar nula.'),

-- GASTOS (5XX)
('501100', 'Sueldos Empleados', 'Gastos', 'Hacen al sueldo: Sueldo bruto, SAC, cargas sociales patronales, horas extras, sindicatos, seguros, vacaciones, etc'),
('501200', 'Honorarios Programas Sociales', 'Gastos', 'Trabajadores sociales, medicos, nutricionistas, enfermeria, pedagogicos, tutores, coordinacion, limpieza y cocina, apoyo escolar, etc'),
('501300', 'Honorarios Generales', 'Gastos', 'Contables, Administrativos, Legales, Escribania, Auditoria, Liquidacion Sueldos, RRHH, desarrollo fondos, voluntarios, etc'),
('501400', 'Honorarios Asesoria General', 'Gastos', 'Gestion, Comunicacion Institucional, Voluntariado, Desarrollo de Fondos'),
('502100', 'Servicios Protagonistas', 'Gastos', 'Translados, lavado, cuidadores nocturnos, servicios sepelios, actividades recreativas, regalos, etc'),
('503100', 'Alimentacion', 'Gastos', 'Comida protagonistas, bolsones comida, leche, suplemento nutricional, etc'),
('504100', 'Sanitarios', 'Gastos', 'Insumos medicos/enfermeria/odontologicos, medicamentos, analisis, consultas, emergencias, etc'),
('505100', 'Ayudas Economicas', 'Gastos', 'Becas Protagonistas, subsidios, descuentos, incobrables, becas aranceles educativos, etc'),
('506100', 'Insumos Pedagogicos', 'Gastos', 'Material didactico, laboratorio, deportivo, artistico, libros, revistas y subscripciones'),
('507100', 'Insumos Varios Programas Sociales', 'Gastos', 'Accesorios, utiles, higiene personal, materia prima, etc'),
('508100', 'Formacion', 'Gastos', 'Entrenamiento, capacitacion, alquileres proyectores, pantallas, salas, etc'),
('509100', 'Servicios Soporte', 'Gastos', 'Reparaciones, mantenimiento, insumos y servicios de limpieza, matafuegos, jardineria, seguridad, alarmas, vigilancia, etc'),
('510100', 'Viatico General', 'Gastos', 'Refrigerio, transporte publico, taxi, remisse, combi, fletes, etc'),
('510200', 'Viajes Locales', 'Gastos', 'Pasajes, hoteles, gasto representacion, etc en viajes DENTRO del Pais'),
('510300', 'Viajes Internacionales', 'Gastos', 'Pasajes, hoteles, gasto representacion, etc en viajes FUERA del Pais'),
('510500', 'Gastos Rodados', 'Gastos', 'Patente, seguro, lavado, mantenimiento, reparaciones, etc'),
('511000', 'Sede', 'Gastos', 'Gastos relacionados a la Sede: Alquiler, expensas, refrigerio, telefonia, internet, tv, etc'),
('511200', 'Servicios Basicos', 'Gastos', 'Luz, Gas, Agua, Tasas y Contribuciones Municipales, etc'),
('512100', 'Sistemas Informaticos', 'Gastos', 'Sueldos, Contable, Microfinanzas, mantenimiento, desarrollo, asesoria, etc'),
('513000', 'Basicos Generales', 'Gastos', 'Bancarios, Cobranza Fondos, Impuestos, Basicos Oficina, Libreria, Envios masivos, Seguros, Tramites ONG, etc'),
('514100', 'Institucionales Varios', 'Gastos', 'Desarrollo y material, reconocimiento, publicidad, promocion, telemarketing, internet, hosting, membrecias, herramientas digitales, etc'),
('515100', 'Eventos Institucionales', 'Gastos', 'Alquileres, catering, planners, musicalizacion, salas, proyecciones, espectaculos, presentadores, SADAIC, seguros, premios, etc'),
('516000', 'Gastos Varios', 'Gastos', 'Celulares, capacitacion equipo interno, uniformes, delantales, decoracion sede, busqueda y despido personal, multas, otros gastos, etc'),

-- RESULTADOS FINANCIEROS (6XX)
('601001', 'Intereses Ganados en Pesos', 'Resultados financieros netos', 'Intereses Ganados - Moneda Local'),
('601002', 'Intereses Pagados', 'Resultados financieros netos', 'Intereses Pagados'),
('601003', 'Intereses Ganados en u$s', 'Resultados financieros netos', 'Intereses Ganados - Moneda Extranjera'),
('601005', 'Diferencia de Cambio', 'Resultados financieros netos', 'Diferencia de Cambio'),
('601007', 'Resultado por Tenencia', 'Resultados financieros netos', 'Tenencia de bienes o valores cuotasparte en fondos inversion'),
('601008', 'Resultado por Compraventa de Bonos', 'Resultados financieros netos', 'Compraventa Acciones, Bonos y otros Titulos Valores');

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ 44 cuentas cargadas' AS Mensaje;
SELECT COUNT(*) AS Total_Cuentas FROM CUENTA_CONTABLE;
SELECT Tipo_Cuenta, COUNT(*) AS Cantidad FROM CUENTA_CONTABLE GROUP BY Tipo_Cuenta ORDER BY Tipo_Cuenta;
