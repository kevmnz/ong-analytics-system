# Dashboard - Potenciar Solidario

**[Ver Dashboard en Looker Studio](https://lookerstudio.google.com/reporting/f41cdd19-4981-401d-86e9-0dd185bf14d0)**

---

## Contexto

Este dashboard fue diseñado para dar visibilidad financiera a una organización sin fines de lucro. El objetivo es que cualquier stakeholder (directiva, contadores, auditores) pueda responder en segundos:

- ¿Cuánto ingresó y cuánto se gastó?
- ¿Quiénes son los principales donantes y proveedores?
- ¿Cómo evolucionan los movimientos en el tiempo?
- ¿Cuál es el balance neto actual?

---

## Arquitectura de Información

El dashboard sigue una estructura **top-down** (de lo general a lo particular), que es el estándar en dashboards ejecutivos:

```
┌─────────────────────────────────────────┐
│  FILTROS GLOBALES (período, tipo)      │
├─────────────────────────────────────────┤
│  KPIs: Resumen ejecutivo de un vistazo  │
├─────────────────────────────────────────┤
│  Tendencias: Evolución temporal         │
├─────────────────────────────────────────┤
│  Rankings: Top donantes / proveedores   │
├─────────────────────────────────────────┤
│  Distribución: Composición por categoría│
├─────────────────────────────────────────┤
│  Detalle: Tabla con todos los movimientos│
└─────────────────────────────────────────┘
```

---

## Visualizaciones y Justificación

### 1. KPI Cards - Resumen Ejecutivo

**Qué muestran**: Total Ingresos, Total Egresos, Balance Neto, Cantidad de Donantes, Cantidad de Proveedores

**Por qué cards y no gráficos**: Los KPIs son números que necesitan leerse de un vistazo. Un card comunica inmediatamente "este es el número que importa". Es la primera capa del dashboard porque responde a la pregunta más básica: **¿cómo estamos?**

**Qué comunica**: El estado financiero actual de la organización. El Balance Neto (Ingresos - Egresos) es el indicador más crítico: si es positivo, la ONG está en crecimiento; si es negativo, necesita atención.

---

### 2. Serie Temporal - Evolución de Movimientos

**Tipo**: Gráfico de líneas por mes

**Por qué líneas y no barras**: Las líneas comunican **tendencia** y **continuidad**. En datos temporales, el ojo humano sigue naturalmente una línea para detectar patrones: subidas, bajadas, estacionalidad. Las barras fragmentan esa percepción.

**Qué comunica**:
- Si los ingresos son consistentes o volátiles
- Si hay meses con picos de gastos (posible estacionalidad)
- La relación visual entre ingresos y egresos a lo largo del tiempo
- Si la ONG mantiene un crecimiento sostenido

---

### 3. Gráfico de Barras - Top 10 Donantes y Proveedores

**Tipo**: Barras horizontales ordenadas de mayor a menor

**Por qué barras horizontales y no verticales**: Los nombres de donantes y proveedores son textos largos. Las barras horizontales permiten leer los nombres sin rotar texto, lo que mejora la legibilidad. Ordenar de mayor a menor aplica el **principio de Pareto**: típicamente el 20% de los donantes aporta el 80% de los ingresos.

**Qué comunica**:
- Quiénes son los actores clave de la organización
- Dónde está concentrado el riesgo (si un solo donante representa gran parte de los ingresos)
- Qué proveedores reciben mayor volumen de pagos

---

### 4. Gráfico de Torta - Distribución por Categoría

**Tipo**: Donut chart / pie chart

**Por qué torta**: Cuando se necesita mostrar **composición** (cuánto representa cada parte del total), un gráfico de torta es la visualización más intuitiva. El cerebro compara áreas circulares naturalmente. Se limita a categorías principales para evitar el "chart junk" de demasiados segmentos.

**Qué comunica**:
- Cómo se distribuyen los gastos entre categorías
- Si hay una categoría que domina sobre las demás
- La diversificación (o concentración) del gasto

---

### 5. Tabla de Detalle - Movimientos Contables

**Tipo**: Tabla con todas las columnas relevantes

**Por qué tabla**: Después de las visualizaciones agregadas, el usuario puede necesitar **drill-down** al nivel transaccional. La tabla responde a "¿cuáles son exactamente estos movimientos?" con fecha, entidad, monto y cuenta contable.

**Qué comunica**: Transparencia total. Cada número en los KPIs y gráficos puede rastrearse hasta su origen en esta tabla.

---

### 6. Filtros Interactivos

**Filtros implementados**:
- **Rango de fechas**: Permite analizar cualquier período
- **Tipo de movimiento**: Ingresos / Egresos / Todos

**Por qué filtros**: Un dashboard sin filtros es una foto estática. Con filtros, se convierte en una **herramienta de exploración**. Un contador puede aislar un trimestre problemático, un auditor puede filtrar por un proveedor específico, la directiva puede ver la evolución anual.

---

## Decisiones de Diseño

| Decisión | Razón |
|----------|-------|
| Conexión a Google Sheets | Datos siempre actualizados sin redeploy |
| Looker Studio | Gratuito, colaborativo, se integra con el ecosistema Google |
| Jerarquía visual (KPIs → tendencias → detalle) | Sigue el patrón de lectura Z del ojo humano |
| Colores consistentes | Verde para ingresos, rojo para egresos (convención contable universal) |
| Sin clutter | Cada gráfico responde una pregunta específica, nada decorativo |

---

## Flujo de Datos

```
Excel desordenado
    ↓
scripts/separar_datos.py  →  CSVs normalizados
    ↓
scripts/cargar_datos.py   →  PostgreSQL
    ↓
Google Sheets (puente)
    ↓
Looker Studio (visualización)
```

---

## Tecnologías

| Componente | Herramienta |
|------------|-------------|
| Visualización | Looker Studio (Google) |
| Fuente de datos | Google Sheets |
| Base de datos | PostgreSQL (escalabilidad futura) |
| ETL | Python + Pandas |

---

## Datos de Origen

Los datos que alimentan este dashboard provienen de:

- `data/raw/sprint1/` - Archivos originales del primer sprint
- `data/raw/sprint2/` - Archivos originales del segundo sprint
- `procesados/` - CSVs normalizados listos para carga
