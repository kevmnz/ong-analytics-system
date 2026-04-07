import pandas as pd
from sqlalchemy import create_engine
import sys
import os
from dotenv import load_dotenv

load_dotenv()

# --- 1. CONFIGURACIÓN DE CONEXIÓN ---
DB_URL = os.environ.get('DB_URL')
if not DB_URL:
    print("❌ Error: No se encontró la variable de entorno DB_URL.")
    print("Copiá .env.example a .env y configurá tu contraseña.")
    sys.exit()
engine = create_engine(DB_URL)

# --- 2. CARGA DE ARCHIVOS ---
try:
    # 1. Leemos con latin1 (esto NO va a fallar al abrir)
    df_donantes_raw = pd.read_csv('./procesados/Donantes.csv', sep=None, engine='python', encoding='latin1')
    df_prov_raw = pd.read_csv('./procesados/Proveedores.csv', sep=None, engine='python', encoding='latin1')

    # 2. FUNCIÓN MÁGICA: Repara el texto "mojibake" (ej: Nãºmero -> Número)
    def reparar_encoding(df):
        for col in df.select_dtypes(include=['object']).columns:
            try:
                # Intentamos re-codificar de latin1 a utf-8
                df[col] = df[col].str.encode('latin1').str.decode('utf-8', errors='ignore')
            except:
                pass
        return df

    # Reparamos las columnas de proveedores
    df_prov_raw = reparar_encoding(df_prov_raw)
    
    # También reparamos los NOMBRES de las columnas
    df_prov_raw.columns = [c.encode('latin1').decode('utf-8', errors='ignore').strip() for c in df_prov_raw.columns]
    df_donantes_raw.columns = df_donantes_raw.columns.str.strip()

    print("✅ Archivos cargados y 'reparados' automáticamente.")
    print(f"Columnas detectadas en Proveedores: {df_prov_raw.columns.tolist()}")

except Exception as e:
    print(f"❌ Error al abrir los archivos: {e}")
    sys.exit()

# ==========================================================
# BLOQUE 1: TABLA 'donante' (Usa df_donantes_raw)
# ==========================================================
print("--- Paso 1: Sincronizando 'donante' ---")
map_donante = {
    'Numero': 'id_donante',
    'Nombre': 'nombre',
    'Tipo': 'tipo',
    'Correo_electronico': 'email',
    'Telefono': 'telefono',
    'Pais': 'pais'
}

df_donante = df_donantes_raw[list(map_donante.keys())].rename(columns=map_donante).copy()
donantes_db = pd.read_sql('SELECT id_donante FROM donante', con=engine)
df_donante_nuevo = df_donante[~df_donante['id_donante'].astype(str).isin(donantes_db['id_donante'].astype(str))]
df_donante_nuevo = df_donante_nuevo.drop_duplicates(subset=['id_donante'])

if not df_donante_nuevo.empty:
    df_donante_nuevo.to_sql('donante', con=engine, if_exists='append', index=False)
    print(f"✅ Se agregaron {len(df_donante_nuevo)} donantes nuevos.")
else:
    print("ℹ️ No hay donantes nuevos.")


# ==========================================================
# BLOQUE 2: TABLA 'datos_fiscales_donante' (Usa df_donantes_raw)
# ==========================================================
print("\n--- Paso 2: Sincronizando 'datos_fiscales_donante' ---")
map_fiscal = {
    'Numero': 'id_donante',
    'Razon_Social': 'razon_social',
    'Tipo_Contribuyente': 'tipo_contribuyente',
    'CUIT': 'cuit'
}

df_fiscal = df_donantes_raw[list(map_fiscal.keys())].rename(columns=map_fiscal).copy()
df_fiscal = df_fiscal.dropna(subset=['cuit']).drop_duplicates(subset=['id_donante'])
fiscal_db = pd.read_sql('SELECT id_donante FROM datos_fiscales_donante', con=engine)
df_fiscal_nuevo = df_fiscal[~df_fiscal['id_donante'].astype(str).isin(fiscal_db['id_donante'].astype(str))]

if not df_fiscal_nuevo.empty:
    df_fiscal_nuevo.to_sql('datos_fiscales_donante', con=engine, if_exists='append', index=False)
    print(f"✅ Se agregaron {len(df_fiscal_nuevo)} registros fiscales.")
else:
    print("ℹ️ No hay datos fiscales nuevos.")


# ==========================================================
# BLOQUE 3: TABLA 'estado_donante' (Usa df_donantes_raw)
# ==========================================================
print("\n--- Paso 3: Sincronizando 'estado_donante' ---")
map_estado = {
    'Numero': 'id_donante',
    'Alta': 'fecha_desde',
    'Baja': 'fecha_alta',
    'Activo': 'activo',
    'Frecuencia': 'frecuencia'
}

df_estado = df_donantes_raw[list(map_estado.keys())].rename(columns=map_estado).copy()
df_estado['activo'] = df_estado['activo'].str.strip().str.upper().map({'SI': True, 'NO': False})
df_estado['fecha_desde'] = pd.to_datetime(df_estado['fecha_desde'], errors='coerce')
df_estado['fecha_alta'] = pd.to_datetime(df_estado['fecha_alta'], errors='coerce')
df_estado['es_actual'] = df_estado['fecha_alta'].isna()

# Evitar conflicto con Trigger de 'estado_actual'
actuales_db = pd.read_sql('SELECT id_donante FROM estado_donante WHERE es_actual = TRUE', con=engine)
mask_conflicto = (df_estado['es_actual'] == True) & (df_estado['id_donante'].isin(actuales_db['id_donante']))
df_estado = df_estado[~mask_conflicto]

estado_db = pd.read_sql('SELECT id_donante, fecha_desde FROM estado_donante', con=engine)
estado_db['check'] = estado_db['id_donante'].astype(str) + estado_db['fecha_desde'].astype(str)
df_estado['check'] = df_estado['id_donante'].astype(str) + df_estado['fecha_desde'].astype(str)

df_estado_nuevo = df_estado[~df_estado['check'].isin(estado_db['check'])].drop(columns=['check'])
df_estado_nuevo = df_estado_nuevo.drop_duplicates(subset=['id_donante', 'fecha_desde'])

if not df_estado_nuevo.empty:
    try:
        df_estado_nuevo.to_sql('estado_donante', con=engine, if_exists='append', index=False)
        print(f"✅ Se agregaron {len(df_estado_nuevo)} estados nuevos.")
    except Exception as e:
        print(f"❌ Error de Trigger: {e}")
else:
    print("ℹ️ No hay estados nuevos.")


# ==========================================================
# BLOQUE 4: TABLA 'proveedor' (VERSIÓN REPARADA)
# ==========================================================
print("\n--- Paso 4: Sincronizando 'proveedor' ---")

# Ahora las columnas deberían llamarse NORMAL, sin símbolos raros:
map_proveedor = {
    'Número_Proveedor': 'id_proveedor',
    'Nombre_Proveedor': 'nombre_proveedor',
    'Categoria_Proveedor': 'categoria_proveedor',
    'Contacto': 'contacto',
    'Correo_Electrónico': 'email',
    'Teléfono': 'telefono',
    'Ciudad': 'ciudad',
    'Pais': 'pais'
}

try:
    # 1. Filtramos las columnas que ya reparamos arriba
    df_prov = df_prov_raw[list(map_proveedor.keys())].rename(columns=map_proveedor).copy()
    
    # 2. Limpieza básica
    df_prov = df_prov.drop_duplicates(subset=['id_proveedor']).dropna(subset=['nombre_proveedor'])

    # 3. Carga Incremental
    prov_db = pd.read_sql('SELECT id_proveedor FROM proveedor', con=engine)
    df_prov_nuevo = df_prov[~df_prov['id_proveedor'].astype(str).isin(prov_db['id_proveedor'].astype(str))]

    if not df_prov_nuevo.empty:
        df_prov_nuevo.to_sql('proveedor', con=engine, if_exists='append', index=False)
        print(f"✅ ¡Victoria! Se cargaron {len(df_prov_nuevo)} proveedores con datos limpios.")
    else:
        print("ℹ️ No hay proveedores nuevos.")

except KeyError as e:
    print(f"❌ Error: La columna {e} no se encuentra.")
    print("Asegurate de que el nombre coincida con lo que sale en 'Columnas detectadas' arriba.")
except Exception as e:
    print(f"❌ Error en proveedores: {e}")

# ==========================================================
# BLOQUE 5: TABLA 'datos_fiscales_proveedor'
# ==========================================================
print("\n--- Paso 5: Sincronizando 'datos_fiscales_proveedor' ---")

# Mapeo: Izquierda (CSV) -> Derecha (Postgres)
map_fiscal_prov = {
    'Número_Proveedor': 'id_proveedor',
    'Razón_Social': 'razon_social',
    'Tipo_Contribuyente': 'tipo_contribuyente',
    'CUIT': 'cuit'
}

try:
    # 1. Extraemos del archivo de proveedores que ya cargamos (df_prov_raw)
    df_fiscal_p = df_prov_raw[list(map_fiscal_prov.keys())].rename(columns=map_fiscal_prov).copy()

    # 2. Limpieza de caracteres (usamos la misma lógica que antes para los acentos)
    def limpiar_fiscal(texto):
        if not isinstance(texto, str): return texto
        return texto.replace('RazÃ³n', 'Razón').replace('Ã³', 'ó').strip()

    df_fiscal_p['razon_social'] = df_fiscal_p['razon_social'].apply(limpiar_fiscal)
    df_fiscal_p['tipo_contribuyente'] = df_fiscal_p['tipo_contribuyente'].apply(limpiar_fiscal)

    # 3. Limpieza de nulos y duplicados (No puede haber dos registros fiscales para el mismo proveedor)
    df_fiscal_p = df_fiscal_p.dropna(subset=['cuit']).drop_duplicates(subset=['id_proveedor'])

    # 4. Carga Incremental: ¿Quiénes NO tienen datos fiscales cargados aún?
    fiscal_p_db = pd.read_sql('SELECT id_proveedor FROM datos_fiscales_proveedor', con=engine)
    df_fiscal_p_nuevo = df_fiscal_p[~df_fiscal_p['id_proveedor'].astype(str).isin(fiscal_p_db['id_proveedor'].astype(str))]

    if not df_fiscal_p_nuevo.empty:
        df_fiscal_p_nuevo.to_sql('datos_fiscales_proveedor', con=engine, if_exists='append', index=False)
        print(f"✅ Se agregaron {len(df_fiscal_p_nuevo)} registros fiscales de proveedores.")
    else:
        print("ℹ️ No hay datos fiscales nuevos para proveedores.")

except Exception as e:
    print(f"❌ Error en datos fiscales: {e}")


# ==========================================================
# BLOQUE 6: MOVIMIENTO_CONTABLE (Unificado y Blindado)
# ==========================================================
print("\n--- Paso 6: Sincronizando MOVIMIENTO_CONTABLE ---")

try:
    # --- PARTE A: INGRESOS (Donantes) ---
    map_ingresos = {
        'Numero': 'id_donante',
        'Fecha_donacion': 'fecha',
        'Importe': 'importe',
        'Nro_Cuenta': 'nro_cuenta'
    }
    df_ingresos = df_donantes_raw[list(map_ingresos.keys())].rename(columns=map_ingresos).copy()
    df_ingresos['tipo_movimiento'] = 'INGRESO'
    df_ingresos['id_proveedor'] = None
    df_ingresos['concepto'] = 'Donación recibida'

    # --- PARTE B: EGRESOS (Proveedores) ---
    map_egresos = {
        'Número_Proveedor': 'id_proveedor',
        'Fecha': 'fecha',
        'Importe': 'importe',
        'Nro_Cuenta': 'nro_cuenta'
    }
    df_egresos = df_prov_raw[list(map_egresos.keys())].rename(columns=map_egresos).copy()
    df_egresos['tipo_movimiento'] = 'EGRESO'
    df_egresos['id_donante'] = None
    df_egresos['concepto'] = 'Pago a proveedor'

    # --- UNIFICACIÓN ---
    df_movimientos = pd.concat([df_ingresos, df_egresos], ignore_index=True)

    # 1. Limpieza de tipos de datos (Usamos nombres en minúscula)
    df_movimientos['fecha'] = pd.to_datetime(df_movimientos['fecha'], errors='coerce')
    df_movimientos['importe'] = pd.to_numeric(df_movimientos['importe'], errors='coerce')
    df_movimientos = df_movimientos.dropna(subset=['fecha', 'importe', 'nro_cuenta'])
    df_movimientos = df_movimientos[df_movimientos['importe'] > 0]

    # --- CARGA INCREMENTAL ---
    # Leemos de la DB. Importante: Postgres devuelve minúsculas
    query = "SELECT fecha, importe, nro_cuenta, tipo_movimiento FROM movimiento_contable"
    mov_db = pd.read_sql(query, con=engine)
    
    # Normalizamos los nombres de las columnas que vienen de la DB por si acaso
    mov_db.columns = mov_db.columns.str.lower()

    # Creamos la 'huella' para evitar duplicados
    def crear_huella(df):
        return (df['fecha'].astype(str) + 
                df['importe'].astype(str) + 
                df['nro_cuenta'].astype(str) + 
                df['tipo_movimiento'])

    mov_db['huella'] = crear_huella(mov_db)
    df_movimientos['huella'] = crear_huella(df_movimientos)

    # Solo lo que NO está en la base
    df_final = df_movimientos[~df_movimientos['huella'].isin(mov_db['huella'])].drop(columns=['huella'])

    if not df_final.empty:
        # Cargamos a la tabla (Pandas matchea por nombre de columna)
        df_final.to_sql('movimiento_contable', con=engine, if_exists='append', index=False)
        print(f"✅ ¡Golazo, Kevin! Se insertaron {len(df_final)} movimientos nuevos.")
    else:
        print("ℹ️ No hay movimientos nuevos (ya estaban cargados).")

except Exception as e:
    print(f"❌ Error al sincronizar con la DB: {e}")
