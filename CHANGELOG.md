# Changelog

## v3.0.0 - 2026-04-02

Release mayor: overhaul visual, reportes HTML, 4 nuevos modulos, README bilingue.

### Visual

- Banner con gradiente de colores estilo retro cartoon (~*~ rubber-hose ~*~).
- Spinner animado durante ejecucion de herramientas externas.
- Barra de progreso para operaciones multi-objetivo.
- Cabeceras de modulo con box-drawing decorativo.
- Teach boxes rediseñadas con bordes y colores por campo.
- Grid visual de 4 columnas para el resumen de herramientas.
- Dashboard de resumen en terminal al finalizar.
- Menu principal agrupado por categorias (Reconocimiento, Web, Infraestructura, Otros).
- Fallback automatico a ASCII si el terminal no soporta Unicode.

### Nuevos modulos

- `headers`: Analisis de cabeceras HTTP de seguridad (CSP, HSTS, X-Frame-Options, etc.).
- `emails`: Recoleccion de correos desde datos existentes + crosslinked.
- `cors`: Deteccion de misconfiguracion CORS (origen reflejado, null, credenciales).
- `favicon`: Identificacion de tecnologias por hash de favicon (~30 hashes conocidos).

### Reportes HTML

- Nuevo reporte HTML autocontenido con tema oscuro.
- Dashboard ejecutivo con tarjetas de metricas.
- Tabla de activos, hallazgos, historial de comandos.
- Graficos de puertos y tecnologias con CSS puro.
- Responsivo y optimizado para impresion.

### Documentacion

- README completamente bilingue (ES + EN) con badges de CI, version, licencia.
- Tabla de 17 modulos con herramientas asociadas.
- Seccion de reportes HTML y estructura de salidas.

### Infraestructura

- Version bump a 3.0.0.
- 17 modulos totales (13 existentes + 4 nuevos).
- Nuevos aliases: header, email, cors-check, fav, correos, favhash.
- `crosslinked` y `curl` añadidos a KEY_TOOLS.
- Tests actualizados para nuevos modulos y reporte HTML.

## v2.5.0 - 2026-03-21

Release de endurecimiento y publicación:

- Se prioriza la claridad documental y la coherencia de release pública.
- Se alinea la experiencia prevista con el enfoque educativo del proyecto.
- Se refuerza el mensaje de uso ético, defensivo y autorizado.
- Se consolida la narrativa de módulos, perfiles, artefactos y troubleshooting para GitHub.

### En esta versión

- Mejoras de arquitectura y flujo para que `--lang`, `--teach` y `--profile` tengan precedencia real.
- `--list-modules`, `--list-profiles` y `--self-check` como acciones de inspección independientes.
- `--output-dir` como base de una sesión aislada.
- `passive` estrictamente pasivo.
- Reporting consistente con `RECON_REPORT.md`, `FINDINGS.md`, `ASSETS.csv` y `SUMMARY.json`.
- Instalación por copia o enlace con guardrails.
- CI sobre Ubuntu con validación Bash y ShellCheck.

## v2.4.0

- Corrección de la selección parcial de módulos con `--modules` bajo `set -Eeuo pipefail`.
- `dedupe_file` endurecido para no abortar con consolidaciones vacías.
- Aliases de módulos: `osint`, `live`, `web`, `content`, `params`.
- La ejecución de módulos continúa si uno devuelve un código inesperado.
- Smoke test reforzado para selección parcial e instalación `--copy`/`--link`.
- `uninstall.sh` acepta `--prefix` y `--install-root`.

## v2.3.0

- Sanitizado del nombre de sesión para conservar el objetivo.
- Nuevo modo de instalación por copia o enlace simbólico.
- Nuevas opciones CLI: `--modules`, `--list-modules`, `--list-profiles`, `--self-check`, `--version`.
- Mejor separación entre runner y funciones internas.
- `httpx` con salida JSONL para enriquecer hosts vivos.
- Consolidación automática de tecnologías desde `httpx`.
- Parsers para rutas interesantes y endpoints históricos.
- `naabu` como alternativa ligera cuando no hay `nmap` ni `rustscan`.
- Nuevo instalador, desinstalador y workflow de CI.

## v2.2.0

- Reestructuración del proyecto a formato modular.
- Nuevo cargador de perfiles desde `profiles/*.conf`.
- Nuevo sistema de logging y runtime con `trap ERR`.
- Runner endurecido sin `eval`, con historial TSV y control de salida.
- Validación reforzada para IPv4, IPv6, URL, dominio y CIDR.
- Reporte final con Markdown, CSV y JSON.
