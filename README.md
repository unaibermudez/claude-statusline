# claude-statusbar

Mi status line para [Claude Code](https://claude.com/claude-code): carpeta y rama,
modelo, y uso de contexto y de los límites de 5 horas / 7 días con barras de progreso.

```
dev:main │ Opus 5 │ ctx ██░░░░░░ 23% │ 5h █░░░░░░░ 12% (4:55) │ 7d ██░░░░░░ 18%
```

| Bloque | Qué muestra |
|---|---|
| `dev:main` | carpeta actual (cian) y rama de git (amarillo) |
| `Opus 5` | modelo activo |
| `ctx` | porcentaje de la ventana de contexto usada |
| `5h` | límite de uso de 5 horas + cuenta atrás hasta el reset |
| `7d` | límite de uso semanal |

Las barras cambian de color según el nivel: verde <50 %, amarillo ≥50 %, rojo ≥80 %.
Cada bloque desaparece solo si Claude Code no envía ese dato.

## Contenido

| Archivo | Para qué sirve |
|---|---|
| `statusline.sh` | el script que dibuja la línea. Recibe el JSON de la sesión por stdin y escribe la línea en stdout |
| `install.sh` | instalador para bash (Linux, macOS, Git Bash en Windows) |
| `install.ps1` | instalador para PowerShell en Windows |

## Requisitos

- **bash** — en Windows viene con [Git for Windows](https://git-scm.com/download/win).
- **jq** — el script parsea con él el JSON de la sesión.
  - Windows: `winget install jqlang.jq`
  - macOS: `brew install jq`
  - Debian/Ubuntu: `sudo apt install jq`
- **git** — solo para mostrar la rama; sin él el bloque de rama se omite.

## Instalación automática

Clona y ejecuta el instalador que corresponda:

```bash
git clone https://github.com/USUARIO/claude-statusbar.git
cd claude-statusbar
./install.sh          # Linux / macOS / Git Bash
```

```powershell
git clone https://github.com/USUARIO/claude-statusbar.git
cd claude-statusbar
powershell -ExecutionPolicy Bypass -File .\install.ps1    # Windows
```

O en un solo comando (bash), sin dejar el clon:

```bash
git clone --depth 1 https://github.com/USUARIO/claude-statusbar.git /tmp/claude-statusbar \
  && /tmp/claude-statusbar/install.sh \
  && rm -rf /tmp/claude-statusbar
```

El instalador:

1. copia `statusline.sh` a `~/.claude/statusline.sh` y lo hace ejecutable;
2. hace una copia de seguridad de `~/.claude/settings.json` (`settings.json.bak-<fecha>`);
3. añade el campo `statusLine` a ese `settings.json` **respetando el resto de tu configuración**.

Después reinicia Claude Code o abre una sesión nueva.

## Instalación manual

1. Copia `statusline.sh` a `~/.claude/statusline.sh` y dale permisos: `chmod +x ~/.claude/statusline.sh`
2. Añade esto a `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"C:/Users/TU_USUARIO/.claude/statusline.sh\"",
    "padding": 0
  }
}
```

En Linux/macOS basta con `bash ~/.claude/statusline.sh`. En Windows usa la ruta
absoluta con barras normales: Claude Code lanza el comando desde `cmd.exe`, que
no expande `~` ni entiende rutas estilo `/c/Users/...`.

## Desinstalar

Borra el campo `statusLine` de `~/.claude/settings.json` (o restaura uno de los
backups `settings.json.bak-*` que dejó el instalador) y elimina
`~/.claude/statusline.sh`.

## Probarlo sin instalar

```bash
echo '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Opus 5"},"context_window":{"used_percentage":23},"rate_limits":{"five_hour":{"used_percentage":12},"seven_day":{"used_percentage":18}}}' | bash statusline.sh
```

## Personalizar

Todo está en `statusline.sh`:

- **Colores**: las variables ANSI del principio (`CYAN`, `YELLOW`, `MAGENTA`…).
- **Ancho de las barras**: el segundo argumento de `progress_bar` (por defecto `8`).
- **Umbrales de color**: los `>= 80` / `>= 50` de `progress_bar` y `colored_pct`.
- **Separador**: la variable `SEP`.
- **Quitar un bloque**: borra o comenta su sección en «Assemble parts».
