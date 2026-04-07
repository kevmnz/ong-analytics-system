import pandas as pd
import os

# Ruta de tu archivo original
archivo_original = 'Dashboard Looker.xlsx'
carpeta_destino = 'procesados/'

# Crear carpeta si no existe
if not os.path.exists(carpeta_destino):
    os.makedirs(carpeta_destino)

# Leer todas las hojas a la vez (devuelve un diccionario)
hojas = pd.read_excel(archivo_original, sheet_name=None)

for nombre_hoja, contenido in hojas.items():
    ruta_salida = os.path.join(carpeta_destino, f'{nombre_hoja}.csv')
    # Guardar como CSV (más liviano para subir a SQL después)
    contenido.to_csv(ruta_salida, index=False, encoding='utf-8')
    print(f'Guardado: {ruta_salida}')