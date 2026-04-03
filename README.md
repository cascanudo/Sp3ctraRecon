<div align="center">

```
  ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
   ____        _____      _             ____
  / ___| _ __ |___ /  ___| |_ _ __ __ |  _ \ ___  ___ ___  _ __
  \___ \| '_ \  |_ \ / __| __| '__/ _`| |_) / _ \/ __/ _ \| '_ \
   ___) | |_) |___) | (__| |_| | | (_|| |  _ \  __/ (_| (_) | | | |
  |____/| .__/|____/ \___|\__|_|  \__,_|_| \_\___|\___\___/|_| |_|
        |_|
  ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
```

# Sp3ctraRecon v3.0.0

[![CI](https://github.com/cascanudo/Sp3ctraRecon/actions/workflows/ci.yml/badge.svg)](https://github.com/cascanudo/Sp3ctraRecon/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-3.0.0-00d4ff?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4%2B-orange?style=flat-square)]()
[![Python](https://img.shields.io/badge/python-3-blue?style=flat-square)]()
[![Modules](https://img.shields.io/badge/modules-17-ff6b6b?style=flat-square)]()
[![Profiles](https://img.shields.io/badge/profiles-6-a855f7?style=flat-square)]()

**Defensive, ethical reconnaissance framework that teaches while you work.**

**Framework de reconocimiento defensivo y etico que ensena mientras trabajas.**

[English](#english) | [Espanol](#español)

</div>

---

## English

### What Is Sp3ctraRecon?

Sp3ctraRecon is a **modular bash reconnaissance framework** designed for cybersecurity professionals, students, and CTF competitors. It integrates the industry's best passive and active recon tools into a single guided workflow.

Unlike blind automation, Sp3ctraRecon **teaches you** when to use each tool, why it matters, and what to investigate next. Every module includes contextual explanations that adapt to your selected teach mode.

### Features at a Glance

| | Feature | Description |
|---|---|---|
| **17** | Reconnaissance Modules | From OSINT to cloud detection, covering the full attack surface |
| **6** | Operation Profiles | Adapt pace, stealth, and scope to your context |
| **3** | Teach Modes | Off / Normal / Deep — learn as you go |
| **2** | Languages | Full bilingual interface: English + Spanish |
| **5** | Report Formats | Markdown, HTML (dark theme), CSV, JSON, TSV |
| **30+** | External Tools | Integrated and orchestrated — all optional, graceful degradation |

### How It Works

```
                      +-----------------+
                      |   CLI / Menu    |
                      |  Target + Args  |
                      +--------+--------+
                               |
                      +--------v--------+
                      |   Validation    |
                      | IP/Domain/URL/  |
                      |  CIDR detect    |
                      +--------+--------+
                               |
                 +-------------+-------------+
                 |                           |
        +--------v--------+        +--------v--------+
        |  Profile Load   |        |  Module Select  |
        | threads/rate/   |        | auto or manual  |
        | stealth/timeout |        | 17 available    |
        +--------+--------+        +--------+--------+
                 |                           |
                 +-------------+-------------+
                               |
                      +--------v--------+
                      |  Module Runner  |
                      |  teach -> exec  |
                      |  -> summarize   |
                      +--------+--------+
                               |
                      +--------v--------+
                      |    Reporting    |
                      | MD + HTML + CSV |
                      | + JSON + TSV    |
                      +-----------------+
```

### Requirements

| Requirement | Details |
|---|---|
| **Bash** | Version 4 or higher |
| **Python 3** | For JSON/CSV parsing and favicon hashing |
| **External tools** | All optional — the framework detects availability and skips gracefully |

> **Tip**: Run `--self-check` at any time to see which tools are installed and which are missing.

### Quick Start

**Option A — Run directly:**

```bash
# 1. Clone the repository
git clone https://github.com/cascanudo/Sp3ctraRecon.git
cd sp3ctrarecon

# 2. Make executable
chmod +x bin/sp3ctrarecon

# 3. Run against a target
./bin/sp3ctrarecon -t example.com
```

**Option B — Install locally:**

```bash
# Install to ~/.local/bin (copy mode)
chmod +x install.sh
./install.sh --copy

# Now available globally
sp3ctrarecon -t example.com
```

**Option C — Symlink install (development):**

```bash
./install.sh --link
sp3ctrarecon -t example.com
```

**Non-interactive mode (CI/scripts):**

```bash
sp3ctrarecon -t example.com -p passive --non-interactive -y -q
```

### Uninstall

```bash
# If installed with --copy
./uninstall.sh

# With custom prefix
PREFIX=~/.local INSTALL_ROOT=~/.local/share/sp3ctrarecon ./uninstall.sh
```

### CLI Reference

| Flag | Description | Default |
|---|---|---|
| `-t, --target VALUE` | Target: IP, domain, URL, or CIDR | *required* |
| `-l, --lang es\|en` | Interface language | `es` |
| `-p, --profile NAME` | Operation profile | `webapp` |
| `--teach MODE` | Teaching mode: `off`, `normal`, `deep` | `normal` |
| `-m, --modules LIST` | Comma-separated modules or aliases | *all in profile* |
| `-o, --output-dir PATH` | Base output directory | `./` |
| `-y, --yes` | Auto-confirm all executions | off |
| `-q, --quiet` | Suppress visual output | off |
| `--non-interactive` | Run without interactive menus | off |
| `--list-modules` | Print available modules and exit | |
| `--list-profiles` | Print available profiles and exit | |
| `--self-check` | Check tool availability and exit | |
| `--version` | Show version and exit | |
| `-h, --help` | Show help and exit | |

### Target Types

Sp3ctraRecon automatically detects and classifies your target:

| Input | Detected As | Example |
|---|---|---|
| Domain | `domain` | `example.com` |
| URL | `url` | `https://app.example.com:8443/login` |
| IPv4 | `ip` | `192.168.1.1` |
| IPv6 | `ip` | `2001:db8::1` |
| CIDR | `cidr` | `10.0.0.0/24` |

### Profiles

Profiles control how aggressive, thorough, and noisy the reconnaissance is:

| Profile | Intent | Pace | Best For |
|---|---|---|---|
| `learning` | Guided learning with deep explanations | Conservative | Students, first-timers |
| `webapp` | Full web surface analysis | Balanced | Web app assessments |
| `bugbounty` | Passive-first, careful active validation | Careful | Bug bounty programs |
| `internal` | Corporate / Active Directory focus | Service-oriented | Internal pentests |
| `ctf` | Fast, lab-safe execution | Fast | CTF competitions |
| `passive` | Zero direct interaction with target | Passive only | Initial scoping, OSINT |

### Modules

The 17 modules are organized by reconnaissance phase. Each module supports **aliases** for quick access:

#### Reconnaissance

| Module | Aliases | What It Does | Key Tools |
|---|---|---|---|
| `passive_osint` | `osint`, `passive`, `passive-osint` | Public sources, WHOIS, initial context | theHarvester, whois, dig |
| `subdomains` | `subs`, `sub` | Passive subdomain enumeration | subfinder, assetfinder, amass |
| `dns` | — | DNS records, zone info, resolution | dig, dnsx |
| `emails` | `email`, `mail`, `correos` | Email harvesting from collected data | grep, crosslinked |

#### Web Analysis

| Module | Aliases | What It Does | Key Tools |
|---|---|---|---|
| `live_hosts` | `live`, `alive`, `hosts` | HTTP/HTTPS host validation | httpx |
| `web_fingerprint` | `web`, `fingerprint` | Technologies, frameworks, servers | whatweb, nuclei |
| `headers` | `header`, `security-headers` | HTTP security header analysis | curl |
| `cors` | `cors-check` | CORS misconfiguration detection | curl |
| `favicon` | `fav`, `favicon-hash`, `favhash` | Technology ID by favicon hash | curl, python3 |
| `content_discovery` | `content`, `dirs`, `fuzz` | Interesting paths and hidden files | ffuf, feroxbuster |
| `params_js` | `params`, `js`, `endpoints` | Historical URLs, JS files, parameters | waybackurls, gau, katana |
| `ssl` | `tls`, `certs` | Certificate and TLS configuration audit | openssl, sslscan |
| `cms` | `wordpress`, `wp` | CMS detection and vulnerability check | wpscan, joomscan |

#### Infrastructure

| Module | Aliases | What It Does | Key Tools |
|---|---|---|---|
| `network` | `ports`, `scan` | Port scanning and service enumeration | nmap, rustscan, naabu |
| `services` | `smb`, `snmp` | Non-web services (SMB, SNMP, NFS) | enum4linux-ng, smbclient, snmpwalk |
| `screenshots` | `screen`, `visual` | Visual evidence capture | gowitness |
| `cloud` | `aws`, `azure` | Cloud infrastructure detection | grep-based heuristics |

### Teach Mode

Control how much Sp3ctraRecon explains during execution:

| Mode | Behavior | Recommended For |
|---|---|---|
| `off` | Execute modules silently, no explanations | Experienced users, automation |
| `normal` | Brief contextual explanation per module | Daily use, balanced approach |
| `deep` | Extended context with tips, caveats, and reading suggestions | Learning, training, documentation |

Each teach box includes:
- **What**: What the module does and why
- **When**: When to run this module
- **Avoid**: Common mistakes and when NOT to use it
- **Next**: Logical next step after this module

### Recommended Workflow

```
 1. passive_osint + subdomains + dns    (Passive phase: understand the target)
          |
 2. live_hosts                          (Validate: which hosts are alive?)
          |
 3. web_fingerprint + headers           (Fingerprint: what's running?)
    + cors + favicon
          |
 4. content_discovery + params_js       (Explore: hidden paths, JS, parameters)
          |
 5. ssl + cms + network                 (Deepen: TLS, CMS vulns, open ports)
          |
 6. services + screenshots              (Evidence: services, visual proof)
    + cloud + emails
```

> **Rule of thumb**: Only proceed to the next phase when the previous phase gives you enough signal. Don't run active modules blindly.

### Output Structure

Every session creates an isolated directory with all results:

```
sp3ctrarecon_example.com_20260402_143022/
├── reports/
│   ├── RECON_REPORT.md        # Main reconnaissance report (Markdown)
│   ├── RECON_REPORT.html      # Visual report (dark theme, self-contained)
│   ├── FINDINGS.md            # Prioritized findings
│   ├── ASSETS.csv             # Consolidated assets (kind, value, source, notes)
│   └── SUMMARY.json           # Structured summary (target, profile, counts)
├── logs/
│   └── COMMAND_HISTORY.tsv    # Full execution history with timing
├── raw/                       # Raw output from each tool
│   ├── passive_osint/
│   ├── subdomains/
│   ├── dns/
│   ├── headers/
│   ├── cors/
│   ├── favicon/
│   ├── emails/
│   └── ...
└── summary/                   # Consolidated summaries per module
    ├── passive_osint/
    ├── subdomains/
    └── ...
```

### HTML Reports

Sp3ctraRecon generates a **self-contained HTML report** with a dark theme:

| Section | Content |
|---|---|
| **Executive Dashboard** | Key metrics: subdomains, alive hosts, open ports, findings |
| **Findings** | Prioritized list with visual severity indicators |
| **Assets Table** | All discovered assets with source attribution |
| **Port Distribution** | CSS-only bar chart of discovered ports |
| **Technology Stack** | Visual breakdown of detected technologies |
| **Command History** | Full execution log with return codes and timing |

The report is a single `.html` file — no external dependencies, no JavaScript, fully printable.

### Project Structure

```
sp3ctrarecon/
├── bin/
│   └── sp3ctrarecon           # Entry point script
├── lib/
│   ├── app.sh                 # Global state, constants, version
│   ├── i18n.sh                # Bilingual string system (ES/EN)
│   ├── ui.sh                  # Visual layer: banner, spinner, progress, menus
│   ├── validators.sh          # Input validation, target detection, module aliases
│   ├── core.sh                # Runtime engine, tool detection, session management
│   ├── reporting.sh           # Report generation (MD, HTML, JSON, CSV)
│   └── cli.sh                 # CLI parsing, interactive menus
├── modules/
│   └── recon.sh               # All 17 reconnaissance modules
├── profiles/
│   ├── learning.conf          # Conservative, guided learning
│   ├── webapp.conf            # Balanced web assessment
│   ├── bugbounty.conf         # Careful, passive-first
│   ├── internal.conf          # Corporate/AD environment
│   ├── ctf.conf               # Fast lab execution
│   └── passive.conf           # Zero direct noise
├── tests/
│   ├── smoke.sh               # Integration tests (all features)
│   └── validators.sh          # Unit tests (validation, parsing)
├── examples/
│   └── sample_run.md          # Example session documentation
├── .github/workflows/
│   └── ci.yml                 # GitHub Actions CI pipeline
├── install.sh                 # Installer (--copy / --link modes)
├── uninstall.sh               # Clean uninstaller
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md             # Contribution guidelines
├── SECURITY.md                # Security policy
├── CODE_OF_CONDUCT.md         # Code of conduct
└── LICENSE                    # MIT License
```

### CI / Testing

The project includes automated CI via GitHub Actions:

```bash
# Run locally before pushing:
bash tests/validators.sh    # Unit tests: validation, parsing, module aliases
bash tests/smoke.sh         # Integration: full runs, reports, install/uninstall
```

CI runs on every push and pull request on Ubuntu, validating:
- Bash syntax (`bash -n`) for all `.sh` files
- Validator unit tests
- Full smoke tests including report generation and installation

### Troubleshooting

| Problem | Solution |
|---|---|
| Module doesn't run | Check preconditions — run `--self-check` to verify tool availability |
| No subdomains found | Expected with `passive` profile on small targets — not a bug |
| HTML report empty | Ensure at least one module executed before `finalize` |
| Permission denied | Run `chmod +x bin/sp3ctrarecon` |
| Missing Python 3 | Required for JSON parsing and favicon hashing |
| Tool not found warning | Install the missing tool or let the framework skip it gracefully |

### Ethical Use

> **Sp3ctraRecon must only be used on targets you have explicit, written authorization to test.**

This project is built for:
- Education and self-guided learning
- Lab environments and CTF competitions
- Authorized penetration testing engagements
- Defensive security assessments

It is **not** designed for unauthorized access, exploitation, or intrusion of any kind.

---

## Español

### Que Es Sp3ctraRecon?

Sp3ctraRecon es un **framework modular de reconocimiento en bash** disenado para profesionales de ciberseguridad, estudiantes y competidores de CTF. Integra las mejores herramientas de reconocimiento pasivo y activo en un unico flujo guiado.

A diferencia de la automatizacion ciega, Sp3ctraRecon te **ensena** cuando usar cada herramienta, por que importa, y que investigar despues. Cada modulo incluye explicaciones contextuales que se adaptan al modo de ensenanza seleccionado.

### Caracteristicas

| | Caracteristica | Descripcion |
|---|---|---|
| **17** | Modulos de reconocimiento | Desde OSINT hasta deteccion cloud, cubriendo toda la superficie |
| **6** | Perfiles de operacion | Adapta ritmo, sigilo y alcance a tu contexto |
| **3** | Modos de ensenanza | Off / Normal / Deep — aprende mientras ejecutas |
| **2** | Idiomas | Interfaz completamente bilingue: Espanol + Ingles |
| **5** | Formatos de reporte | Markdown, HTML (tema oscuro), CSV, JSON, TSV |
| **30+** | Herramientas externas | Integradas y orquestadas — todas opcionales |

### Como Funciona

```
                      +-----------------+
                      |   CLI / Menu    |
                      | Objetivo + Args |
                      +--------+--------+
                               |
                      +--------v--------+
                      |   Validacion    |
                      | IP/Dominio/URL/ |
                      |  CIDR detecta   |
                      +--------+--------+
                               |
                 +-------------+-------------+
                 |                           |
        +--------v--------+        +--------v--------+
        |  Carga Perfil   |        | Selec. Modulos  |
        | threads/rate/   |        | auto o manual   |
        | sigilo/timeout  |        | 17 disponibles  |
        +--------+--------+        +--------+--------+
                 |                           |
                 +-------------+-------------+
                               |
                      +--------v--------+
                      |  Motor Modulos  |
                      |  ensena -> exec |
                      |  -> resume      |
                      +--------+--------+
                               |
                      +--------v--------+
                      |    Reportes     |
                      | MD + HTML + CSV |
                      | + JSON + TSV    |
                      +-----------------+
```

### Requisitos

| Requisito | Detalles |
|---|---|
| **Bash** | Version 4 o superior |
| **Python 3** | Para parsing JSON/CSV y hash de favicon |
| **Herramientas externas** | Todas opcionales — el framework detecta disponibilidad |

> **Consejo**: Ejecuta `--self-check` en cualquier momento para ver que herramientas tienes instaladas.

### Inicio Rapido

**Opcion A — Ejecutar directamente:**

```bash
# 1. Clonar el repositorio
git clone https://github.com/cascanudo/Sp3ctraRecon.git
cd sp3ctrarecon

# 2. Dar permisos de ejecucion
chmod +x bin/sp3ctrarecon

# 3. Ejecutar contra un objetivo
./bin/sp3ctrarecon -t example.com
```

**Opcion B — Instalar localmente:**

```bash
# Instalar en ~/.local/bin (modo copia)
chmod +x install.sh
./install.sh --copy

# Disponible globalmente
sp3ctrarecon -t example.com
```

**Opcion C — Instalacion por enlace simbolico (desarrollo):**

```bash
./install.sh --link
sp3ctrarecon -t example.com
```

**Modo no interactivo (CI/scripts):**

```bash
sp3ctrarecon -t example.com -p passive --non-interactive -y -q
```

### Desinstalar

```bash
# Si se instalo con --copy
./uninstall.sh

# Con prefijo personalizado
PREFIX=~/.local INSTALL_ROOT=~/.local/share/sp3ctrarecon ./uninstall.sh
```

### Referencia CLI

| Flag | Descripcion | Default |
|---|---|---|
| `-t, --target VALUE` | Objetivo: IP, dominio, URL o CIDR | *requerido* |
| `-l, --lang es\|en` | Idioma de interfaz | `es` |
| `-p, --profile NAME` | Perfil de operacion | `webapp` |
| `--teach MODE` | Modo ensenanza: `off`, `normal`, `deep` | `normal` |
| `-m, --modules LIST` | Modulos o aliases separados por coma | *todos del perfil* |
| `-o, --output-dir PATH` | Directorio base de salida | `./` |
| `-y, --yes` | Auto-confirmar ejecuciones | off |
| `-q, --quiet` | Suprimir salida visual | off |
| `--non-interactive` | Ejecutar sin menus interactivos | off |
| `--list-modules` | Imprimir modulos disponibles y salir | |
| `--list-profiles` | Imprimir perfiles disponibles y salir | |
| `--self-check` | Verificar herramientas y salir | |
| `--version` | Mostrar version y salir | |
| `-h, --help` | Mostrar ayuda y salir | |

### Tipos de Objetivo

Sp3ctraRecon detecta y clasifica automaticamente tu objetivo:

| Entrada | Detectado Como | Ejemplo |
|---|---|---|
| Dominio | `domain` | `example.com` |
| URL | `url` | `https://app.example.com:8443/login` |
| IPv4 | `ip` | `192.168.1.1` |
| IPv6 | `ip` | `2001:db8::1` |
| CIDR | `cidr` | `10.0.0.0/24` |

### Perfiles

Los perfiles controlan que tan agresivo, exhaustivo y ruidoso es el reconocimiento:

| Perfil | Intencion | Ritmo | Ideal Para |
|---|---|---|---|
| `learning` | Aprendizaje guiado con explicaciones | Conservador | Estudiantes, principiantes |
| `webapp` | Analisis completo de superficie web | Balanceado | Evaluaciones web |
| `bugbounty` | Pasivo primero, validacion activa cuidadosa | Cuidadoso | Programas de bug bounty |
| `internal` | Enfoque corporativo / Active Directory | Orientado a servicios | Pentests internos |
| `ctf` | Ejecucion rapida y segura para labs | Rapido | Competencias CTF |
| `passive` | Cero interaccion directa con el objetivo | Solo pasivo | Scoping inicial, OSINT |

### Modulos

Los 17 modulos estan organizados por fase de reconocimiento. Cada modulo soporta **aliases** para acceso rapido:

#### Reconocimiento

| Modulo | Aliases | Que Hace | Herramientas |
|---|---|---|---|
| `passive_osint` | `osint`, `passive`, `passive-osint` | Fuentes publicas, WHOIS, contexto inicial | theHarvester, whois, dig |
| `subdomains` | `subs`, `sub` | Enumeracion pasiva de subdominios | subfinder, assetfinder, amass |
| `dns` | — | Registros DNS, zona, resolucion | dig, dnsx |
| `emails` | `email`, `mail`, `correos` | Recoleccion de correos de datos existentes | grep, crosslinked |

#### Analisis Web

| Modulo | Aliases | Que Hace | Herramientas |
|---|---|---|---|
| `live_hosts` | `live`, `alive`, `hosts` | Validacion de hosts HTTP/HTTPS | httpx |
| `web_fingerprint` | `web`, `fingerprint` | Tecnologias, frameworks, servidores | whatweb, nuclei |
| `headers` | `header`, `security-headers` | Analisis de cabeceras HTTP de seguridad | curl |
| `cors` | `cors-check` | Deteccion de misconfiguracion CORS | curl |
| `favicon` | `fav`, `favicon-hash`, `favhash` | Identificacion por hash de favicon | curl, python3 |
| `content_discovery` | `content`, `dirs`, `fuzz` | Rutas y archivos ocultos | ffuf, feroxbuster |
| `params_js` | `params`, `js`, `endpoints` | URLs historicas, JS, parametros | waybackurls, gau, katana |
| `ssl` | `tls`, `certs` | Auditoria de certificados y configuracion TLS | openssl, sslscan |
| `cms` | `wordpress`, `wp` | Deteccion de CMS y revision de vulnerabilidades | wpscan, joomscan |

#### Infraestructura

| Modulo | Aliases | Que Hace | Herramientas |
|---|---|---|---|
| `network` | `ports`, `scan` | Escaneo de puertos y enumeracion de servicios | nmap, rustscan, naabu |
| `services` | `smb`, `snmp` | Servicios no web (SMB, SNMP, NFS) | enum4linux-ng, smbclient, snmpwalk |
| `screenshots` | `screen`, `visual` | Captura de evidencia visual | gowitness |
| `cloud` | `aws`, `azure` | Deteccion de infraestructura cloud | heuristicas basadas en grep |

### Modo de Ensenanza

Controla cuanto explica Sp3ctraRecon durante la ejecucion:

| Modo | Comportamiento | Recomendado Para |
|---|---|---|
| `off` | Ejecuta modulos sin explicaciones | Usuarios expertos, automatizacion |
| `normal` | Explicacion contextual breve por modulo | Uso diario, enfoque balanceado |
| `deep` | Contexto ampliado con consejos y lecturas | Aprendizaje, formacion, documentacion |

Cada caja de ensenanza incluye:
- **Que**: Que hace el modulo y por que
- **Cuando**: Cuando ejecutar este modulo
- **Evitar**: Errores comunes y cuando NO usarlo
- **Siguiente**: Paso logico siguiente

### Flujo Recomendado

```
 1. passive_osint + subdomains + dns    (Fase pasiva: entender el objetivo)
          |
 2. live_hosts                          (Validar: que hosts estan vivos?)
          |
 3. web_fingerprint + headers           (Fingerprint: que esta corriendo?)
    + cors + favicon
          |
 4. content_discovery + params_js       (Explorar: rutas ocultas, JS, parametros)
          |
 5. ssl + cms + network                 (Profundizar: TLS, CMS, puertos)
          |
 6. services + screenshots              (Evidencia: servicios, capturas)
    + cloud + emails
```

> **Regla de oro**: Solo avanza a la siguiente fase cuando la anterior te de suficiente senal. No ejecutes modulos activos a ciegas.

### Estructura de Salida

Cada sesion crea un directorio aislado con todos los resultados:

```
sp3ctrarecon_example.com_20260402_143022/
├── reports/
│   ├── RECON_REPORT.md        # Reporte principal (Markdown)
│   ├── RECON_REPORT.html      # Reporte visual (tema oscuro, autocontenido)
│   ├── FINDINGS.md            # Hallazgos priorizados
│   ├── ASSETS.csv             # Activos consolidados (tipo, valor, fuente, notas)
│   └── SUMMARY.json           # Resumen estructurado (objetivo, perfil, conteos)
├── logs/
│   └── COMMAND_HISTORY.tsv    # Historial completo con tiempos
├── raw/                       # Salida cruda por herramienta
│   ├── passive_osint/
│   ├── subdomains/
│   └── ...
└── summary/                   # Resumenes consolidados por modulo
    ├── passive_osint/
    └── ...
```

### Reportes HTML

Sp3ctraRecon genera un **reporte HTML autocontenido** con tema oscuro:

| Seccion | Contenido |
|---|---|
| **Dashboard Ejecutivo** | Metricas clave: subdominios, hosts vivos, puertos, hallazgos |
| **Hallazgos** | Lista priorizada con indicadores de severidad visual |
| **Tabla de Activos** | Todos los activos descubiertos con atribucion de fuente |
| **Distribucion de Puertos** | Grafico de barras CSS de puertos descubiertos |
| **Stack Tecnologico** | Desglose visual de tecnologias detectadas |
| **Historial de Comandos** | Log completo con codigos de retorno y tiempos |

El reporte es un unico archivo `.html` — sin dependencias externas, sin JavaScript, completamente imprimible.

### Estructura del Proyecto

```
sp3ctrarecon/
├── bin/
│   └── sp3ctrarecon           # Script de entrada
├── lib/
│   ├── app.sh                 # Estado global, constantes, version
│   ├── i18n.sh                # Sistema bilingue (ES/EN)
│   ├── ui.sh                  # Capa visual: banner, spinner, progreso, menus
│   ├── validators.sh          # Validacion, deteccion de objetivo, aliases
│   ├── core.sh                # Motor de ejecucion, deteccion de herramientas
│   ├── reporting.sh           # Generacion de reportes (MD, HTML, JSON, CSV)
│   └── cli.sh                 # Parseo CLI, menus interactivos
├── modules/
│   └── recon.sh               # Los 17 modulos de reconocimiento
├── profiles/                  # Perfiles de operacion (.conf)
├── tests/                     # Tests unitarios + integracion
├── install.sh / uninstall.sh  # Instalador / Desinstalador
└── README.md
```

### CI / Testing

El proyecto incluye CI automatizado via GitHub Actions:

```bash
# Ejecutar localmente antes de hacer push:
bash tests/validators.sh    # Tests unitarios: validacion, parsing, aliases
bash tests/smoke.sh         # Integracion: ejecuciones completas, reportes, instalacion
```

### Troubleshooting

| Problema | Solucion |
|---|---|
| Modulo no ejecuta | Revisa precondiciones — ejecuta `--self-check` |
| Sin subdominios | Esperado con perfil `passive` en objetivos pequenos |
| Reporte HTML vacio | Asegurate de que al menos un modulo ejecuto antes de `finalize` |
| Permission denied | Ejecuta `chmod +x bin/sp3ctrarecon` |
| Falta Python 3 | Requerido para parsing JSON y hash de favicon |
| Tool not found | Instala la herramienta o deja que el framework la omita |

### Uso Etico

> **Sp3ctraRecon debe usarse unicamente sobre objetivos para los que tengas autorizacion explicita y por escrito.**

Este proyecto esta disenado para:
- Educacion y aprendizaje autoguiado
- Entornos de laboratorio y competencias CTF
- Pruebas de penetracion autorizadas
- Evaluaciones de seguridad defensiva

**No** esta disenado para acceso no autorizado, explotacion ni intrusion de ninguna clase.

---

<div align="center">

### License

[MIT License](LICENSE) — Free to use, modify, and distribute.

---

```
  ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
```

**Crafted with discipline by [Cascanudo](https://github.com/cascanudo)**

*"Reconnaissance is not about noise — it's about signal."*

```
  ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
```

</div>
