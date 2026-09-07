# Spotify Token Guard para Antigravity

Implementacion modular y portable del patron de delegacion jerarquica presentado por el equipo de ingenieria de Spotify para reducir hasta un 90% el consumo de tokens en lecturas de archivos y generacion de boilerplate.

## Como funciona

1. **Intercepcion Determinista (`PreToolUse` Hook)**: Monitorea llamadas a la herramienta `view_file`. Si un archivo supera las 350 lineas y no se especifico un rango acotado (`StartLine`/`EndLine`), bloquea la lectura devolviendo una decision de rechazo con instrucciones al modelo.
2. **Delegacion a Subagentes Economicos**: El modelo principal (Orquestador / Tech Lead) delega lecturas extensas a subagentes de tipo `research` (`Model: "flash_lite"` o `"flash"`) que extraen unicamente el resumen o bloque requerido.
3. **Generacion Directa a Disco**: Los subagentes de generacion repetitiva escriben codigo directamente a disco (`write_to_file`) sin volcar miles de lineas de codigo en el contexto del modelo principal.
4. **Edicion Quirurgica**: El orquestador principal preserva su ventana de contexto libre de ruido para decisiones arquitectonicas y ediciones puntuales mediante rangos exactos.

## Estructura generada en el proyecto

```text
.agents/
├── hooks.json
├── scripts/
│   └── guard_large_files.py
└── rules/
    └── token_efficiency.md
```

## Instalacion rapida

### Opcion A: En el directorio actual
Desde la raiz del proyecto donde desees aplicar la optimizacion:
```bash
/ruta/a/spotify-token-guard/install.sh
```

### Opcion B: Indicando la ruta de destino
```bash
/ruta/a/spotify-token-guard/install.sh /ruta/al/proyecto
```

### Opcion C: Descarga directa via curl (una vez subido a GitHub)
```bash
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/spotify-token-guard/main/install.sh | bash
```

## Requisitos
- Python 3.8 o superior (utiliza unicamente modulos de la biblioteca estandar: `json`, `os`, `sys`).
- Antigravity CLI / IDE con soporte para `.agents/hooks.json`.

## Desactivacion o reversion
- **Desactivar temporalmente**: Editar `.agents/hooks.json` y cambiar `"enabled": true` a `"enabled": false`.
- **Eliminar por completo**: Borrar el archivo `.agents/hooks.json`, el script `.agents/scripts/guard_large_files.py` y la regla `.agents/rules/token_efficiency.md`.
