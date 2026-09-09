# Spotify Token Guard para Antigravity

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Harness de orquestacion multi-agente con gating determinista para Google Antigravity. Implementa el patron de delegacion jerarquica publicado por el equipo de ingenieria de Spotify para reducir hasta un 90% el consumo de tokens en lecturas de archivos extensos y generacion de codigo repetitivo.

---

## Como funciona

1. **Intercepcion Determinista (`PreToolUse` Hook)**: Intercepta las llamadas a `view_file`. Si un archivo supera las 350 lineas y no se especifico un rango acotado (`StartLine`/`EndLine`), bloquea la lectura devolviendo una decision de rechazo (`deny`) con instrucciones precisas al modelo.
2. **Delegacion a Subagentes Economicos**: El modelo principal (Tech Lead / Orquestador) delega lecturas pesadas a subagentes de tipo `research` (`Model: "flash_lite"` o `"flash"`), quienes extraen unicamente el resumen o bloque requerido.
3. **Generacion Directa a Disco**: Los subagentes de generacion repetitiva (boilerplate, tests unitarios, DTOs) escriben el codigo directamente a disco (`write_to_file`) sin volcar cientos de lineas en la ventana de contexto del modelo principal.
4. **Edicion Quirurgica**: El orquestador principal preserva su ventana de contexto libre de ruido para decisiones arquitectonicas y modificaciones puntuales mediante rangos exactos (`replace_file_content`).

---

## Estructura generada en el proyecto

Al instalarse en un proyecto, genera de forma aislada:

```text
.agents/
├── hooks.json
├── scripts/
│   └── guard_large_files.py
└── rules/
    └── token_efficiency.md
```

---

## Instalacion

### Opcion 1: En un proyecto local (con el repo clonado)

Desde la raiz del proyecto donde deseas aplicar la optimizacion:
```bash
/ruta/a/spotify-token-guard/install.sh
```
O indicando la ruta destino como argumento:
```bash
/ruta/a/spotify-token-guard/install.sh /ruta/al/proyecto
```

---

### Opcion 2: Instalacion remota via `curl`

Para usarlo en cualquier maquina sin necesidad de clonar este repositorio:

```bash
# Recomendado (inspeccionar el script antes de ejecutar):
curl -fsSL https://raw.githubusercontent.com/reddjedet/spotify-token-guard/main/install.sh -o install.sh
bash install.sh
rm install.sh

# O instalacion directa en una linea:
curl -fsSL https://raw.githubusercontent.com/reddjedet/spotify-token-guard/main/install.sh | bash
```

---

## Requisitos

- **Python 3.8+** (utiliza unicamente modulos de la biblioteca estandar: `json`, `os`, `sys`; no requiere dependencias externas ni `pip`).
- **Antigravity CLI / IDE** con soporte para `.agents/hooks.json`.

---

## Desactivacion y Reversion

- **Desactivar temporalmente**: En `.agents/hooks.json`, cambia `"enabled": true` por `"enabled": false`.
- **Eliminar por completo**:
  ```bash
  rm -rf .agents/hooks.json .agents/scripts/guard_large_files.py .agents/rules/token_efficiency.md
  ```

---

## Licencia

Distribuido bajo la Licencia MIT. Consulta [LICENSE](LICENSE) para mas detalles.
