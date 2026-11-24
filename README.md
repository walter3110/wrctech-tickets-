# WRCtech Tickets

Sistema de tickets de soporte de Sistemas para la farmacia.

| App | Celular | Estado |
|---|---|---|
| WRCtech Soporte | Farmacia | Fase 1 |
| WRCtech Tickets | Sistemas | Fase 1 |
| WRCtech Supervisión | Farmacéutico | Fase 2 |

## Estructura

- `supabase/` – scripts de la base de datos (ya aplicados).
- `packages/core/` – código compartido (conexión, tickets, colores).
- `apps/soporte/` – app de la farmacia.
- `.github/workflows/compilar.yml` – compila los APK en GitHub en cada cambio.

## Cómo bajar el APK

1. Esperá a que termine la compilación en la pestaña **Actions** (unos 5–8 minutos).
2. Entrá a **Releases** y bajá `wrctech-soporte.apk` desde el celular.
3. Instalalo (Android pide permitir "instalar apps de origen desconocido").
4. La primera vez, ingresá la contraseña del usuario de la farmacia.
