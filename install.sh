#!/usr/bin/env bash
set -e

# Target directory: default to current directory if not provided
TARGET_DIR="${1:-.}"
AGENTS_DIR="$TARGET_DIR/.agents"

echo "Instalando Spotify Token Guard en: $TARGET_DIR"

mkdir -p "$AGENTS_DIR/scripts"
mkdir -p "$AGENTS_DIR/rules"

# 1. Script del Guardian
cat << 'EOS' > "$AGENTS_DIR/scripts/guard_large_files.py"
#!/usr/bin/env python3
import json
import os
import sys

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    args = data.get("toolCall", {}).get("args", {})
    file_path = args.get("AbsolutePath", "")
    start_line = args.get("StartLine")
    end_line = args.get("EndLine")
    THRESHOLD = 350

    # Si ya se especifico un rango menor o igual al umbral, permitir lectura
    if start_line is not None and end_line is not None:
        if (end_line - start_line) <= THRESHOLD:
            print(json.dumps({"decision": "allow"}))
            return

    # Si el archivo no existe o no es un archivo regular, dejar continuar a la herramienta
    if not file_path or not os.path.isfile(file_path):
        print(json.dumps({"decision": "allow"}))
        return

    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            count = sum(1 for _ in f)
    except Exception:
        count = 0

    if count > THRESHOLD:
        name = os.path.basename(file_path)
        print(json.dumps({
            "decision": "deny",
            "reason": (
                f"[TOKEN GUARD - SPOTIFY PATTERN ACTIVADO]\n"
                f"El archivo '{name}' tiene {count} lineas (limite: {THRESHOLD}).\n"
                f"Para reducir consumo de tokens y evitar saturar el contexto:\n"
                f"1. DELEGA la lectura a un subagente de tipo 'research' con Model='flash_lite' o Model='flash' "
                f"para que extraiga o resuma unicamente las secciones necesarias.\n"
                f"2. O acota la lectura usando StartLine y EndLine (rango <= {THRESHOLD} lineas)."
            )
        }))
        return

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
EOS

chmod +x "$AGENTS_DIR/scripts/guard_large_files.py"

# 2. Archivo de configuracion de hooks
cat << 'EOS' > "$AGENTS_DIR/hooks.json"
{
  "token-guard": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "view_file",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .agents/scripts/guard_large_files.py",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOS

# 3. Reglas de operacion para el orquestador
cat << 'EOS' > "$AGENTS_DIR/rules/token_efficiency.md"
# Token Efficiency & Multi-Agent Delegation (Spotify Pattern)

Como Orquestador Principal, tu objetivo es maximizar la precision arquitectonica y minimizar el consumo de contexto.

1. **Lectura de Archivos Extensos (> 350 lineas)**:
   - Un hook activo bloqueara lecturas completas mediante `view_file` en archivos de mas de 350 lineas.
   - DEBES delegar la lectura a un subagente de tipo `research` con `Model: "flash_lite"` o `Model: "flash"` solicitando unicamente las firmas, funciones o resumen puntual requerido.
   - Alternativamente, utiliza `StartLine` y `EndLine` para leer exclusivamente el bloque relevante (<= 350 lineas).

2. **Generacion de Codigo Repetitivo (Boilerplate / Tests)**:
   - Para suites de pruebas unitarias, DTOs, migraciones o bindings, invoca un subagente `self` con `Model: "flash"`.
   - El subagente debe escribir el codigo directamente en disco (`write_to_file`) y reportar unicamente el estado o resultado de ejecucion, sin verter el contenido completo en el contexto principal.

3. **Edicion Quirurgica**:
   - Conserva la ventana de contexto del orquestador para analisis critico y modificaciones puntuales (`replace_file_content`).
EOS

echo "Instalacion completada en $AGENTS_DIR."
