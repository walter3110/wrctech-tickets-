"""Ajusta el proyecto Android que genera `flutter create` en la compilación:
nombre visible de la app y permiso de internet.

Uso: python3 tool/ajustar_android.py apps/soporte "WRCtech Soporte"
"""
import re
import sys
from pathlib import Path

carpeta, nombre = Path(sys.argv[1]), sys.argv[2]
manifest = carpeta / "android/app/src/main/AndroidManifest.xml"
texto = manifest.read_text(encoding="utf-8")

texto, n = re.subn(r'android:label="[^"]*"', f'android:label="{nombre}"', texto, count=1)
if n != 1:
    sys.exit("No encontré android:label en el manifest")

permiso = '<uses-permission android:name="android.permission.INTERNET"/>'
if "android.permission.INTERNET" not in texto:
    texto, n = re.subn(r"(<manifest[^>]*>)", r"\1\n    " + permiso, texto, count=1)
    if n != 1:
        sys.exit("No encontré la etiqueta <manifest>")

manifest.write_text(texto, encoding="utf-8")
print(f"OK: {manifest} -> {nombre}")
