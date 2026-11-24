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

for nombre_permiso in ("INTERNET", "POST_NOTIFICATIONS"):
    if f"android.permission.{nombre_permiso}" in texto:
        continue
    permiso = f'<uses-permission android:name="android.permission.{nombre_permiso}"/>'
    texto, n = re.subn(r"(<manifest[^>]*>)", r"\1\n    " + permiso, texto, count=1)
    if n != 1:
        sys.exit("No encontré la etiqueta <manifest>")

# Canal de notificaciones por defecto (lo crea MainActivity.kt, si la app lo trae).
meta = ('<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"'
        ' android:value="tickets"/>')
if "default_notification_channel_id" not in texto:
    texto = texto.replace("</application>", f"    {meta}\n    </application>", 1)

manifest.write_text(texto, encoding="utf-8")
print(f"OK: {manifest} -> {nombre}")
