#!/usr/bin/env bash

module_summary_init() {
  local summary="$1"
  ensure_dir "$(dirname "$summary")"
  : > "$summary"
}

module_summary_note() {
  local summary="$1" note="$2"
  printf -- '- %s\n' "$note" >> "$summary"
}

module_summary_skip() {
  local summary="$1" reason="$2"
  {
    echo "- $(pick_lang 'Estado' 'Status'): $(pick_lang 'omitido' 'skipped')"
    echo "- $(pick_lang 'Razon' 'Reason'): ${reason}"
  } > "$summary"
}

module_publish_summary() {
  local title="$1" summary="$2"
  if [[ -s "$summary" ]]; then
    append_report_section "$title" < "$summary"
  else
    append_report_section "$title" <<MD
- $(pick_lang 'Sin datos relevantes en esta ejecucion.' 'No relevant data collected in this run.')
MD
  fi
}

cms_candidates_from_whatweb() {
  local pattern="$1" outfile="$2" current=""
  local source="${OUTPUT_DIR}/raw/web/whatweb.txt"
  : > "$outfile"
  [[ -f "$source" ]] || return 1

  while IFS= read -r line; do
    if [[ "$line" == "### "* ]]; then
      current="${line#\#\#\# }"
      continue
    fi
    [[ -n "$current" ]] || continue
    if [[ "$line" =~ $pattern ]]; then
      printf '%s\n' "$current" >> "$outfile"
      current=""
    fi
  done < "$source"

  dedupe_file "$outfile"
  [[ -s "$outfile" ]]
}

mod_passive_osint() {
  local title summary
  title="$(pick_lang 'OSINT Pasivo' 'Passive OSINT')"
  summary="${OUTPUT_DIR}/summary/osint/passive_osint.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: OSINT PASIVO' 'MODULE: PASSIVE OSINT')" \
    "$(pick_lang 'Recolecta informacion publica con bajo ruido y amplia contexto antes de validar activos.' 'Collects public information with low noise and expands context before validating assets.')" \
    "$(pick_lang 'Usalo al inicio en dominios, bug bounty y reconocimiento externo.' 'Use it early for domains, bug bounty, and external reconnaissance.')" \
    "$(pick_lang 'Evitalo como unico modulo si ya necesitas confirmar exposicion real.' 'Avoid using it as the only module if you already need to confirm real exposure.')" \
    "$(pick_lang 'Luego valida con subdominios, DNS y hosts vivos.' 'Then validate with subdomains, DNS, and live hosts.')"

  if [[ -z "$DOMAIN" ]]; then
    module_summary_skip "$summary" "$(pick_lang 'Este modulo requiere un dominio base.' 'This module requires a base domain.')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0 out
  if have_tool theHarvester; then
    out="${OUTPUT_DIR}/raw/osint/theharvester.txt"
    run_cmd osint "theHarvester sobre ${DOMAIN}" "$out" theHarvester -d "$DOMAIN" -b all -l 200 || true
    module_summary_note "$summary" "theHarvester: \`${out}\`"
    ran_any=1
  fi
  if have_tool whois; then
    out="${OUTPUT_DIR}/raw/osint/whois.txt"
    run_cmd osint "WHOIS sobre ${DOMAIN}" "$out" whois "$DOMAIN" || true
    module_summary_note "$summary" "whois: \`${out}\`"
    ran_any=1
  fi
  if have_tool dig; then
    out="${OUTPUT_DIR}/raw/osint/dig_basic.txt"
    run_block osint "Registros basicos DIG sobre ${DOMAIN}" "$out" dig_basic_records "$DOMAIN" || true
    module_summary_note "$summary" "dig (A/AAAA/MX/TXT/NS/CNAME): \`${out}\`"
    ran_any=1
  fi
  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'No habia herramientas pasivas instaladas para este modulo.' 'No passive OSINT tools were installed for this module.')"

  append_asset domain "$DOMAIN" passive_osint base_domain
  module_publish_summary "$title" "$summary"
}

mod_subdomains() {
  local title summary
  title="$(pick_lang 'Subdominios Descubiertos' 'Discovered Subdomains')"
  summary="${OUTPUT_DIR}/summary/subdomains/subdomains.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: SUBDOMINIOS' 'MODULE: SUBDOMAINS')" \
    "$(pick_lang 'Descubre subdominios desde fuentes pasivas y consolida superficie.' 'Discovers subdomains from passive sources and consolidates surface area.')" \
    "$(pick_lang 'Usalo cuando el objetivo base sea un dominio o URL con host conocido.' 'Use it when the base target is a domain or URL with a known host.')" \
    "$(pick_lang 'Evitalo sobre IPs sueltas: ahi aporta poco.' 'Avoid it for standalone IPs: it adds little there.')" \
    "$(pick_lang 'Despues valida resolucion y actividad real con dnsx y httpx.' 'Then validate resolution and real activity with dnsx and httpx.')"

  if [[ -z "$DOMAIN" ]]; then
    module_summary_skip "$summary" "$(msg module_missing_domain)"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local all="${OUTPUT_DIR}/summary/subdomains/subdomains_all.txt"
  : > "$all"
  local ran_any=0 out

  if have_tool subfinder; then
    out="${OUTPUT_DIR}/raw/subdomains/subfinder.txt"
    run_cmd subdomains "Subfinder sobre ${DOMAIN}" "$out" subfinder -silent -all -d "$DOMAIN" || true
    cat "$out" >> "$all" 2>/dev/null || true
    module_summary_note "$summary" "subfinder: \`${out}\`"
    ran_any=1
  fi
  if have_tool assetfinder; then
    out="${OUTPUT_DIR}/raw/subdomains/assetfinder.txt"
    run_cmd subdomains "Assetfinder sobre ${DOMAIN}" "$out" assetfinder --subs-only "$DOMAIN" || true
    cat "$out" >> "$all" 2>/dev/null || true
    module_summary_note "$summary" "assetfinder: \`${out}\`"
    ran_any=1
  fi
  if have_tool amass; then
    out="${OUTPUT_DIR}/raw/subdomains/amass.txt"
    run_cmd subdomains "Amass pasivo sobre ${DOMAIN}" "$out" amass enum -passive -norecursive -noalts -d "$DOMAIN" || true
    cat "$out" >> "$all" 2>/dev/null || true
    module_summary_note "$summary" "amass: \`${out}\`"
    ran_any=1
  fi
  dedupe_file "$all"

  if [[ -s "$all" ]]; then
    record_lines_as_assets subdomain "$all" subdomains passive_discovery
    module_summary_note "$summary" "$(pick_lang 'Archivo consolidado' 'Consolidated file'): \`${all}\`"
    module_summary_note "$summary" "$(pick_lang 'Total' 'Total'): **$(wc -l < "$all")**"
  elif (( ran_any == 1 )); then
    module_summary_note "$summary" "$(pick_lang 'No se obtuvieron subdominios desde las herramientas instaladas.' 'No subdomains were obtained from the installed tools.')"
  else
    module_summary_note "$summary" "$(pick_lang 'No habia herramientas de subdominios instaladas.' 'No subdomain tools were installed.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_dns() {
  local title summary
  title="DNS"
  summary="${OUTPUT_DIR}/summary/dns/dns_summary.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: DNS' 'MODULE: DNS')" \
    "$(pick_lang 'Inspecciona registros y contexto de resolucion para entender infraestructura y dependencias.' 'Inspects records and resolution context to understand infrastructure and dependencies.')" \
    "$(pick_lang 'Usalo despues de subdominios o cuando necesites mapear registros y proveedores.' 'Use it after subdomains or when you need to map records and providers.')" \
    "$(pick_lang 'Evitalo si no tienes un dominio base o si solo trabajas una IP.' 'Avoid it if you do not have a base domain or if you only work with an IP.')" \
    "$(pick_lang 'Despues cruza resultados con dnsx, certificados y hosts vivos.' 'Then correlate results with dnsx, certificates, and live hosts.')"

  if [[ -z "$DOMAIN" ]]; then
    module_summary_skip "$summary" "$(msg module_missing_domain)"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0 out slog jout
  if have_tool dig; then
    out="${OUTPUT_DIR}/raw/dns/dig_full.txt"
    run_block dns "Registros DNS sobre ${DOMAIN}" "$out" dig_basic_records "$DOMAIN" || true
    module_summary_note "$summary" "dig: \`${out}\`"
    ran_any=1
  fi
  if have_tool dnsx && [[ -s "$(subdomains_file)" ]]; then
    slog="${OUTPUT_DIR}/raw/dns/dnsx.stdout.log"
    jout="${OUTPUT_DIR}/raw/dns/dnsx.jsonl"
    run_cmd dns "dnsx sobre subdominios consolidados" "$slog" dnsx -silent -l "$(subdomains_file)" -a -resp -j -o "$jout" || true
    module_summary_note "$summary" "dnsx: \`${jout}\`"
    ran_any=1
  fi
  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'No habia herramientas DNS instaladas o faltaban subdominios consolidados para dnsx.' 'No DNS tools were installed or consolidated subdomains were missing for dnsx.')"

  module_publish_summary "$title" "$summary"
}

mod_live_hosts() {
  local title summary
  title="$(pick_lang 'Hosts vivos' 'Live hosts')"
  summary="${OUTPUT_DIR}/summary/livehosts/live_hosts.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: HOSTS VIVOS' 'MODULE: LIVE HOSTS')" \
    "$(pick_lang 'Valida que objetivos responden y cuales tienen superficie HTTP/HTTPS.' 'Validates which targets respond and which have HTTP/HTTPS surface.')" \
    "$(pick_lang 'Usalo tras descubrir subdominios o cuando ya tienes URLs candidatas.' 'Use it after discovering subdomains or once you have candidate URLs.')" \
    "$(pick_lang 'Evitalo si estas en un perfil totalmente pasivo.' 'Avoid it if you are in a fully passive profile.')" \
    "$(pick_lang 'Despues prioriza titulos, codigos, tecnologias y capturas.' 'Then prioritize titles, status codes, technologies, and screenshots.')"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): perfil passive"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local in="${OUTPUT_DIR}/tmp/httpx_input.txt"
  ensure_targets_for_web "$in"
  if [[ ! -s "$in" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos HTTP' 'no HTTP targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  if have_tool httpx; then
    local slog="${OUTPUT_DIR}/raw/livehosts/httpx.stdout.log"
    local jout="${OUTPUT_DIR}/raw/livehosts/httpx.jsonl"
    run_cmd livehosts "httpx sobre objetivos web" "$slog" httpx -silent -l "$in" -title -tech-detect -status-code -follow-redirects -ip -cname -server -json -o "$jout" || true
    if [[ -s "$jout" ]]; then
      extract_alive_urls_from_httpx_json "$jout" "$(alive_urls_file)"
      extract_httpx_enrichment "$jout"
      extract_technologies_from_httpx_json "$jout" "$(technologies_file)"
      record_lines_as_assets url "$(alive_urls_file)" livehosts httpx_alive
    fi
    module_summary_note "$summary" "httpx jsonl: \`${jout}\`"
    module_summary_note "$summary" "$(pick_lang 'Archivo consolidado' 'Consolidated file'): \`$(alive_urls_file)\`"
    module_summary_note "$summary" "$(pick_lang 'Total' 'Total'): **$(wc -l < "$(alive_urls_file)" 2>/dev/null || echo 0)**"
  else
    module_summary_note "$summary" "$(pick_lang 'httpx no esta instalado.' 'httpx is not installed.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_network() {
  local title summary
  title="$(pick_lang 'Red y puertos' 'Network and ports')"
  summary="${OUTPUT_DIR}/summary/network/network.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: RED / PUERTOS' 'MODULE: NETWORK / PORTS')" \
    "$(pick_lang 'Enumera puertos y servicios abiertos para entender por donde continuar.' 'Enumerates open ports and services to understand where to continue.')" \
    "$(pick_lang 'Usalo con IPs, CIDR o hosts que quieras perfilar a nivel de red.' 'Use it with IPs, CIDR, or hosts you want to profile at network level.')" \
    "$(pick_lang 'Evitalo en perfiles estrictamente pasivos.' 'Avoid it in strictly passive profiles.')" \
    "$(pick_lang 'Luego prioriza SMB, SNMP, NFS, web y TLS segun puertos abiertos.' 'Then prioritize SMB, SNMP, NFS, web, and TLS based on open ports.')"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): perfil passive"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local target_for_scan="$TARGET"
  [[ -n "$TARGET_HOST" ]] && target_for_scan="$TARGET_HOST"
  local ran_any=0 out

  if have_tool nmap; then
    out="${OUTPUT_DIR}/raw/network/nmap_top.txt"
    run_cmd network "Nmap top ports sobre ${target_for_scan}" "$out" nmap -Pn -sV --top-ports 200 "$target_for_scan" || true
    extract_ports_from_scan_output "$out" "$(network_ports_file)"
    extract_services_from_scan_output "$out" "$(services_file)"
    module_summary_note "$summary" "nmap: \`${out}\`"
    ran_any=1
  elif have_tool rustscan; then
    out="${OUTPUT_DIR}/raw/network/rustscan.txt"
    run_cmd network "RustScan sobre ${target_for_scan}" "$out" rustscan -a "$target_for_scan" --ulimit 5000 -- -Pn -sV || true
    extract_ports_from_scan_output "$out" "$(network_ports_file)"
    module_summary_note "$summary" "rustscan: \`${out}\`"
    ran_any=1
  elif have_tool naabu; then
    out="${OUTPUT_DIR}/raw/network/naabu.txt"
    run_cmd network "Naabu sobre ${target_for_scan}" "$out" naabu -host "$target_for_scan" -top-ports 100 -silent || true
    awk -F: 'NF>=2{print $2"/tcp"}' "$out" | sort -u > "$(network_ports_file)" 2>/dev/null || true
    module_summary_note "$summary" "naabu: \`${out}\`"
    ran_any=1
  fi

  if (( ran_any == 1 )); then
    record_lines_as_assets port "$(network_ports_file)" network open_port
    module_summary_note "$summary" "$(pick_lang 'Archivo consolidado de puertos' 'Consolidated ports file'): \`$(network_ports_file)\`"
    module_summary_note "$summary" "$(pick_lang 'Total' 'Total'): **$(wc -l < "$(network_ports_file)" 2>/dev/null || echo 0)**"
  else
    module_summary_note "$summary" "$(pick_lang 'No hay nmap, rustscan ni naabu instalados.' 'nmap, rustscan, and naabu are not installed.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_web_fingerprint() {
  local title summary
  title="$(pick_lang 'Fingerprint Web' 'Web Fingerprint')"
  summary="${OUTPUT_DIR}/summary/web/fingerprint.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: FINGERPRINT WEB' 'MODULE: WEB FINGERPRINT')" \
    "$(pick_lang 'Identifica tecnologias, frameworks, CMS y servidores para priorizar el analisis.' 'Identifies technologies, frameworks, CMSs, and servers to prioritize analysis.')" \
    "$(pick_lang 'Usalo despues de validar hosts vivos y antes de fuzzing intenso.' 'Use it after validating live hosts and before heavy fuzzing.')" \
    "$(pick_lang 'Evitalo si todavia no confirmaste que URLs responden.' 'Avoid it if you have not yet confirmed which URLs respond.')" \
    "$(pick_lang 'Despues ejecuta content discovery, JS/parametros y CMS solo si aplica.' 'Then run content discovery, JS/parameters, and CMS only when relevant.')"

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay hosts vivos confirmados' 'no confirmed live hosts')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local targets_file="${OUTPUT_DIR}/tmp/web_targets.txt"
  local tech_file
  tech_file="$(technologies_file)"
  ensure_targets_for_web "$targets_file"
  if [[ ! -s "$targets_file" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos web validos' 'no valid web targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0
  if have_tool whatweb; then
    local out="${OUTPUT_DIR}/raw/web/whatweb.txt"
    run_block web "WhatWeb sobre objetivos web" "$out" run_whatweb_targets "$targets_file" "$out" || true
    extract_technologies_from_whatweb "$out" "$tech_file"
    module_summary_note "$summary" "whatweb: \`${out}\`"
    ran_any=1
  fi
  if have_tool nuclei && [[ "$PROFILE" != passive ]]; then
    local out="${OUTPUT_DIR}/raw/web/nuclei_tech.txt"
    run_cmd web "Nuclei con tags tech y exposure" "$out" nuclei -l "$targets_file" -tags tech,exposure -rl "$PROFILE_RATE" || true
    module_summary_note "$summary" "nuclei: \`${out}\`"
    ran_any=1
  fi

  if [[ -s "$tech_file" ]]; then
    tech_contains wordpress && append_finding "$(pick_lang 'Se detectaron indicios de WordPress en el fingerprint web.' 'WordPress indicators were detected in the web fingerprint.')"
    module_summary_note "$summary" "$(pick_lang 'Tecnologias consolidadas en' 'Technologies consolidated in'): \`${tech_file}\`"
    while IFS= read -r line; do
      module_summary_note "$summary" "$line"
    done < <(head -n 20 "$tech_file" | sed 's/^/- /')
  elif (( ran_any == 0 )); then
    module_summary_note "$summary" "$(pick_lang 'No habia herramientas de fingerprint instaladas.' 'No fingerprinting tools were installed.')"
  else
    module_summary_note "$summary" "$(pick_lang 'No se consolidaron tecnologias en esta ejecucion.' 'No technologies were consolidated in this run.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_content_discovery() {
  local title summary
  title="$(pick_lang 'Descubrimiento de contenido' 'Content discovery')"
  summary="${OUTPUT_DIR}/summary/content/content_discovery.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: CONTENT DISCOVERY' 'MODULE: CONTENT DISCOVERY')" \
    "$(pick_lang 'Busca rutas, archivos, backups y directorios interesantes en aplicaciones web.' 'Searches for paths, files, backups, and interesting directories in web applications.')" \
    "$(pick_lang 'Usalo solo cuando ya validaste que hosts merecen esfuerzo.' 'Use it only once you validated which hosts deserve effort.')" \
    "$(pick_lang 'Evitalo sobre todos los hosts a ciegas o en perfiles muy sigilosos.' 'Avoid running it blindly against all hosts or in very stealthy profiles.')" \
    "$(pick_lang 'Luego revisa 200/30x/401/403 y cruza con tecnologias detectadas.' 'Then review 200/30x/401/403 responses and correlate with detected technologies.')"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): perfil passive"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay hosts vivos' 'no live hosts')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local targets_file="${OUTPUT_DIR}/tmp/content_targets.txt"
  ensure_targets_for_web "$targets_file"
  if [[ ! -s "$targets_file" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos web validos' 'no valid web targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local wordlist
  wordlist="$(best_wordlist_web || true)"
  if [[ -z "$wordlist" ]]; then
    module_summary_skip "$summary" "$(msg no_standard_wordlist)"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0 url id slog jout out
  if have_tool ffuf; then
    while IFS= read -r url; do
      [[ -n "$url" ]] || continue
      id="$(safe_file_name "$url")"
      slog="${OUTPUT_DIR}/raw/content/ffuf_${id}.stdout.log"
      jout="${OUTPUT_DIR}/raw/content/ffuf_${id}.json"
      run_cmd content "FFUF sobre ${url}" "$slog" ffuf -u "${url%/}/FUZZ" -w "$wordlist" -t "$PROFILE_THREADS" -mc all -fc 404 -ac -o "$jout" -of json || true
    done < "$targets_file"
    collect_ffuf_findings
    [[ -s "$(interesting_paths_file)" ]] && append_finding "$(pick_lang 'Se encontraron rutas con palabras clave o estados interesantes. Revisa el TSV consolidado.' 'Interesting paths or keyword matches were found. Review the consolidated TSV.')"
    ran_any=1
  elif have_tool feroxbuster; then
    while IFS= read -r url; do
      [[ -n "$url" ]] || continue
      id="$(safe_file_name "$url")"
      out="${OUTPUT_DIR}/raw/content/ferox_${id}.txt"
      run_cmd content "Feroxbuster sobre ${url}" "$out" feroxbuster -u "$url" -w "$wordlist" -t "$PROFILE_THREADS" --silent || true
    done < "$targets_file"
    ran_any=1
  fi

  module_summary_note "$summary" "$(pick_lang 'Wordlist empleada' 'Wordlist used'): \`${wordlist}\`"
  module_summary_note "$summary" "TSV: \`$(interesting_paths_file)\`"
  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'No hay ffuf ni feroxbuster instalados.' 'Neither ffuf nor feroxbuster is installed.')"

  module_publish_summary "$title" "$summary"
}

mod_params_js() {
  local title summary
  title="$(pick_lang 'JS y parametros' 'JS and parameters')"
  summary="${OUTPUT_DIR}/summary/params/params.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: JS Y PARAMETROS' 'MODULE: JS AND PARAMETERS')" \
    "$(pick_lang 'Recupera URLs historicas, endpoints y JavaScript para analisis manual fino.' 'Retrieves historical URLs, endpoints, and JavaScript for fine-grained manual analysis.')" \
    "$(pick_lang 'Usalo cuando ya confirmaste una app o dominio interesante.' 'Use it once you have confirmed an interesting app or domain.')" \
    "$(pick_lang 'Evitalo si todavia no definiste bien el alcance o si solo trabajas una IP sin contexto web.' 'Avoid it if scope is not well defined yet or if you only have an IP with no web context.')" \
    "$(pick_lang 'Despues filtra ruido y prioriza auth, api, admin, debug, graphql y swagger.' 'Then filter noise and prioritize auth, api, admin, debug, graphql, and swagger.')"

  if [[ -z "$DOMAIN" ]]; then
    module_summary_skip "$summary" "$(msg module_missing_domain)"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local hist="${OUTPUT_DIR}/summary/params/historical_urls.txt"
  : > "$hist"
  local ran_any=0 out

  if have_tool waybackurls; then
    out="${OUTPUT_DIR}/raw/params/waybackurls.txt"
    run_cmd params "waybackurls sobre ${DOMAIN}" "$out" waybackurls "$DOMAIN" || true
    cat "$out" >> "$hist" 2>/dev/null || true
    module_summary_note "$summary" "waybackurls: \`${out}\`"
    ran_any=1
  fi
  if have_tool gau; then
    out="${OUTPUT_DIR}/raw/params/gau.txt"
    run_cmd params "gau sobre ${DOMAIN}" "$out" gau "$DOMAIN" || true
    cat "$out" >> "$hist" 2>/dev/null || true
    module_summary_note "$summary" "gau: \`${out}\`"
    ran_any=1
  fi
  dedupe_file "$hist"
  record_lines_as_assets url "$hist" historical_urls archive
  collect_param_keywords "$hist" "$(prioritized_endpoints_file)"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_note "$summary" "$(pick_lang 'Katana se omite en perfil passive para mantener el modulo estrictamente pasivo.' 'Katana is skipped in the passive profile to keep this module strictly passive.')"
  elif have_tool katana; then
    local targets_file="${OUTPUT_DIR}/tmp/katana_targets.txt"
    ensure_targets_for_web "$targets_file"
    if [[ -s "$targets_file" ]]; then
      out="${OUTPUT_DIR}/raw/params/katana.txt"
      run_cmd params "Katana sobre objetivos web" "$out" katana -silent -list "$targets_file" -jc -kf all -d 3 -fx || true
      module_summary_note "$summary" "katana: \`${out}\`"
      ran_any=1
    fi
  fi

  [[ -s "$(prioritized_endpoints_file)" ]] && append_finding "$(pick_lang 'Se detectaron endpoints historicos con palabras clave utiles para revision manual.' 'Historical endpoints with useful keywords were detected for manual review.')"
  module_summary_note "$summary" "$(pick_lang 'Historico consolidado' 'Consolidated history'): \`${hist}\`"
  module_summary_note "$summary" "$(pick_lang 'Total URLs historicas' 'Total historical URLs'): **$(wc -l < "$hist" 2>/dev/null || echo 0)**"
  module_summary_note "$summary" "$(pick_lang 'Priorizados' 'Prioritized'): \`$(prioritized_endpoints_file)\`"
  if (( ran_any == 0 )) && [[ "$PROFILE" != passive ]]; then
    module_summary_note "$summary" "$(pick_lang 'No habia herramientas de archivos historicos instaladas.' 'No historical URL tools were installed.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_ssl() {
  local title summary
  title="$(pick_lang 'SSL / TLS' 'SSL / TLS')"
  summary="${OUTPUT_DIR}/summary/ssl/ssl.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: SSL/TLS' 'MODULE: SSL/TLS')" \
    "$(pick_lang 'Inspecciona certificados, SAN, protocolos y configuracion basica del canal seguro.' 'Inspects certificates, SAN, protocols, and basic secure-channel configuration.')" \
    "$(pick_lang 'Usalo cuando detectas HTTPS o puertos tipicos de TLS.' 'Use it when you detect HTTPS or typical TLS ports.')" \
    "$(pick_lang 'Evitalo si no hay senales de 443/8443/9443 o URLs HTTPS.' 'Avoid it if there are no signs of 443/8443/9443 or HTTPS URLs.')" \
    "$(pick_lang 'Despues cruza CN/SAN con subdominios y vigencia del certificado.' 'Then correlate CN/SAN with subdomains and certificate validity.')"

  if [[ "$TARGET_KIND" == cidr ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'target CIDR sin contexto por host' 'CIDR target without per-host context')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local host="" port="" run_ssl=0
  if [[ "$TARGET_KIND" == url && "$DEFAULT_SCHEME" == https ]]; then
    host="$TARGET_HOST"
    port="${TARGET_PORT:-443}"
    run_ssl=1
  elif ensure_network_context && has_any_open_port 443 8443 9443; then
    host="${TARGET_HOST:-$DOMAIN}"
    if is_port_open 443; then
      port=443
    elif is_port_open 8443; then
      port=8443
    else
      port=9443
    fi
    [[ -n "$host" ]] && run_ssl=1
  fi

  if (( run_ssl == 0 )); then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay senales tecnicas suficientes de TLS' 'there is not enough technical TLS evidence')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0
  if have_tool openssl; then
    local out="${OUTPUT_DIR}/raw/ssl/openssl_cert.txt"
    run_block ssl "Certificado con openssl sobre ${host}:${port}" "$out" openssl_collect_cert "$host" "$port" || true
    module_summary_note "$summary" "openssl: \`${out}\`"
    ran_any=1
  fi
  if have_tool sslscan; then
    local out="${OUTPUT_DIR}/raw/ssl/sslscan.txt"
    run_cmd ssl "sslscan sobre ${host}:${port}" "$out" sslscan --show-certificate "${host}:${port}" || true
    module_summary_note "$summary" "sslscan: \`${out}\`"
    ran_any=1
  fi
  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'Ni openssl ni sslscan estan instalados.' 'Neither openssl nor sslscan is installed.')"

  module_publish_summary "$title" "$summary"
}

mod_cms() {
  local title summary
  title="CMS"
  summary="${OUTPUT_DIR}/summary/cms/cms.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: CMS' 'MODULE: CMS')" \
    "$(pick_lang 'Busca WordPress, Joomla u otros CMS y solo profundiza cuando hay evidencia previa.' 'Looks for WordPress, Joomla, or other CMSs and goes deeper only when there is prior evidence.')" \
    "$(pick_lang 'Usalo despues de WhatWeb o del fingerprint general.' 'Use it after WhatWeb or general fingerprinting.')" \
    "$(pick_lang 'Evitalo sobre todos los hosts sin una pista real de CMS.' 'Avoid running it against all hosts without a real CMS clue.')" \
    "$(pick_lang 'Despues interpreta versiones y plugins con cuidado; deteccion no equivale a impacto.' 'Then interpret versions and plugins carefully; detection does not equal impact.')"

  if [[ "$TARGET_KIND" == cidr ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'target CIDR sin contexto web por host' 'CIDR target without per-host web context')"
    module_publish_summary "$title" "$summary"
    return 0
  fi
  if ! ensure_alive_context; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay hosts vivos' 'no live hosts')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local wp_targets="${OUTPUT_DIR}/tmp/cms_wordpress_targets.txt"
  local jo_targets="${OUTPUT_DIR}/tmp/cms_joomla_targets.txt"
  local wp_count=0 jo_count=0
  cms_candidates_from_whatweb '(WordPress|wp-content|wp-json)' "$wp_targets" && wp_count="$(wc -l < "$wp_targets")"
  cms_candidates_from_whatweb '(Joomla|joomla)' "$jo_targets" && jo_count="$(wc -l < "$jo_targets")"

  if (( wp_count == 0 && jo_count == 0 )); then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay pistas claras de CMS por URL' 'there are no clear per-URL CMS clues')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0 url id out
  if (( wp_count > 0 )); then
    module_summary_note "$summary" "WordPress: **${wp_count}** $(pick_lang 'objetivos candidatos' 'candidate targets')"
    if have_tool wpscan; then
      while IFS= read -r url; do
        [[ -n "$url" ]] || continue
        id="$(safe_file_name "$url")"
        out="${OUTPUT_DIR}/raw/cms/wpscan_${id}.txt"
        run_cmd cms "WPScan sobre ${url}" "$out" wpscan --url "$url" --disable-tls-checks || true
      done < "$wp_targets"
      ran_any=1
    else
      module_summary_note "$summary" "$(pick_lang 'WPScan no esta instalado.' 'WPScan is not installed.')"
    fi
  fi
  if (( jo_count > 0 )); then
    module_summary_note "$summary" "Joomla: **${jo_count}** $(pick_lang 'objetivos candidatos' 'candidate targets')"
    if have_tool joomscan; then
      while IFS= read -r url; do
        [[ -n "$url" ]] || continue
        id="$(safe_file_name "$url")"
        out="${OUTPUT_DIR}/raw/cms/joomscan_${id}.txt"
        run_cmd cms "Joomscan sobre ${url}" "$out" joomscan -u "$url" || true
      done < "$jo_targets"
      ran_any=1
    else
      module_summary_note "$summary" "$(pick_lang 'Joomscan no esta instalado.' 'Joomscan is not installed.')"
    fi
  fi
  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'Se confirmaron candidatos, pero faltan herramientas CMS para profundizar.' 'Candidate URLs were confirmed, but CMS tools are missing.')"

  module_publish_summary "$title" "$summary"
}

mod_services() {
  local title summary
  title="$(pick_lang 'Servicios no web' 'Non-web services')"
  summary="${OUTPUT_DIR}/summary/services/services.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: SERVICIOS NO WEB' 'MODULE: NON-WEB SERVICES')" \
    "$(pick_lang 'Enumera servicios clasicos internos solo cuando hay puertos que lo justifiquen.' 'Enumerates classic internal services only when open ports justify it.')" \
    "$(pick_lang 'Usalo tras el escaneo de puertos.' 'Use it after the port scan.')" \
    "$(pick_lang 'Evitalo si aun no confirmaste puertos relevantes.' 'Avoid it if you have not confirmed relevant ports yet.')" \
    "$(pick_lang 'Luego interpreta shares, banners y permisos con calma.' 'Then interpret shares, banners, and permissions carefully.')"

  if [[ "$TARGET_KIND" == cidr ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'target CIDR sin contexto por host' 'CIDR target without per-host context')"
    module_publish_summary "$title" "$summary"
    return 0
  fi
  if ! ensure_network_context; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay puertos parseados' 'no parsed ports')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local host="$TARGET_HOST"
  if [[ -z "$host" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin host unico para servicios' 'no single host available for service checks')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local ran_any=0 out
  if has_any_open_port 139 445; then
    if have_tool enum4linux-ng; then
      out="${OUTPUT_DIR}/raw/services/enum4linux.txt"
      run_cmd services "Enum4linux-ng sobre ${host}" "$out" enum4linux-ng "$host" || true
      module_summary_note "$summary" "enum4linux-ng: \`${out}\`"
      ran_any=1
    fi
    if have_tool smbclient; then
      out="${OUTPUT_DIR}/raw/services/smbclient_anonymous.txt"
      run_cmd services "smbclient listado anonimo sobre ${host}" "$out" smbclient -N -L "//${host}" || true
      module_summary_note "$summary" "smbclient: \`${out}\`"
      if grep -Eqi 'Disk|IPC|Sharename' "$out" 2>/dev/null; then
        append_finding "$(pick_lang 'SMB permitio al menos enumeracion anonima parcial. Revisa shares y permisos expuestos.' 'SMB allowed at least partial anonymous enumeration. Review exposed shares and permissions.')"
      fi
      ran_any=1
    fi
  fi
  if is_port_open 111 && have_tool rpcinfo; then
    out="${OUTPUT_DIR}/raw/services/rpcinfo.txt"
    run_cmd services "rpcinfo sobre ${host}" "$out" rpcinfo -p "$host" || true
    module_summary_note "$summary" "rpcinfo: \`${out}\`"
    ran_any=1
  fi
  if is_port_open 161 && have_tool snmpwalk; then
    out="${OUTPUT_DIR}/raw/services/snmpwalk_public.txt"
    run_cmd services "SNMP walk community public sobre ${host}" "$out" snmpwalk -v2c -c public "$host" || true
    module_summary_note "$summary" "snmpwalk(public): \`${out}\`"
    if [[ -s "$out" ]] && ! grep -Eqi 'Timeout|No Response|Unknown host|Authentication failure' "$out"; then
      append_finding "$(pick_lang 'SNMP respondio con la comunidad public. Revisa la exposicion y el alcance de la informacion.' 'SNMP responded to the public community. Review exposure and the scope of the information.')"
    fi
    ran_any=1
  fi
  if is_port_open 2049 && have_tool showmount; then
    out="${OUTPUT_DIR}/raw/services/showmount.txt"
    run_cmd services "showmount sobre ${host}" "$out" showmount -e "$host" || true
    module_summary_note "$summary" "showmount: \`${out}\`"
    if grep -Eq '^/|Export list' "$out" 2>/dev/null; then
      append_finding "$(pick_lang 'Se observaron exportaciones NFS. Revisa el alcance y permisos de los recursos publicados.' 'NFS exports were observed. Review the scope and permissions of the published resources.')"
    fi
    ran_any=1
  fi

  (( ran_any == 1 )) || module_summary_note "$summary" "$(pick_lang 'No habia puertos relevantes abiertos o faltaban herramientas de servicios.' 'There were no relevant open ports or service tools were missing.')"
  module_publish_summary "$title" "$summary"
}

mod_screenshots() {
  local title summary
  title="Screenshots"
  summary="${OUTPUT_DIR}/summary/screenshots/screenshots.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: SCREENSHOTS' 'MODULE: SCREENSHOTS')" \
    "$(pick_lang 'Genera evidencia visual para priorizar portales, logins y paneles.' 'Generates visual evidence to prioritize portals, logins, and panels.')" \
    "$(pick_lang 'Usalo despues de validar hosts vivos.' 'Use it after validating live hosts.')" \
    "$(pick_lang 'Evitalo si no hay superficie HTTP o si buscas minimo ruido.' 'Avoid it if there is no HTTP surface or if you want minimal noise.')" \
    "$(pick_lang 'Luego cruza capturas con titulos, tecnologias y rutas interesantes.' 'Then correlate screenshots with titles, technologies, and interesting paths.')"

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay superficie web confirmada' 'there is no confirmed web surface')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  if have_tool gowitness; then
    local targets_file="${OUTPUT_DIR}/tmp/screenshot_targets.txt"
    local outdir="${OUTPUT_DIR}/raw/screenshots/gowitness"
    local out="${OUTPUT_DIR}/raw/screenshots/gowitness.log"
    ensure_targets_for_web "$targets_file"
    ensure_dir "$outdir"
    run_cmd screenshots "Gowitness sobre objetivos web" "$out" gowitness scan file -f "$targets_file" --write-db --screenshot-path "$outdir" || true
    module_summary_note "$summary" "$(pick_lang 'Capturas en' 'Screenshots in'): \`${outdir}\`"
  else
    module_summary_note "$summary" "$(pick_lang 'Gowitness no esta instalado.' 'Gowitness is not installed.')"
  fi

  module_publish_summary "$title" "$summary"
}

mod_cloud() {
  local title summary
  title="Cloud"
  summary="${OUTPUT_DIR}/summary/cloud/cloud_notes.md"
  module_summary_init "$summary"

  teach_box \
    "$(pick_lang 'MODULO: CLOUD' 'MODULE: CLOUD')" \
    "$(pick_lang 'Busca pistas basicas de proveedores cloud en DNS, CNAME y respuestas web.' 'Looks for basic cloud-provider clues in DNS, CNAMEs, and web responses.')" \
    "$(pick_lang 'Usalo despues de DNS y fingerprint.' 'Use it after DNS and fingerprint.')" \
    "$(pick_lang 'Evitalo como unica fuente de decision: es un modulo de pistas, no de certeza total.' 'Avoid using it as the sole decision source: it is a clue module, not absolute certainty.')" \
    "$(pick_lang 'Luego revisa manualmente buckets, storage y endpoints del proveedor detectado.' 'Then manually review buckets, storage, and provider endpoints.')"

  local clues=0 file
  for file in "${OUTPUT_DIR}/raw/livehosts/httpx.jsonl" "${OUTPUT_DIR}/raw/dns/dig_full.txt" "${OUTPUT_DIR}/raw/dns/dnsx.jsonl"; do
    [[ -f "$file" ]] || continue
    if grep -Eiq 'amazonaws|cloudfront|azure|blob.core.windows.net|googleapis|appspot|herokuapp|fastly|akamai' "$file"; then
      clues=1
      module_summary_note "$summary" "$(pick_lang 'Se detectaron pistas de proveedor cloud en' 'Cloud-provider clues were detected in'): \`${file}\`"
    fi
  done

  if (( clues == 1 )); then
    append_finding "$(pick_lang 'Hay indicios de infraestructura cloud. Revisa CNAME, buckets y storage asociados.' 'There are signs of cloud infrastructure. Review related CNAMEs, buckets, and storage.')"
  else
    module_summary_note "$summary" "$(pick_lang 'No se detectaron pistas claras de cloud en esta ejecucion.' 'No clear cloud clues were detected in this run.')"
  fi

  module_publish_summary "$title" "$summary"
}

_check_security_headers() {
  local targets_file="$1" url
  local -a check_headers=(
    "Content-Security-Policy"
    "Strict-Transport-Security"
    "X-Frame-Options"
    "X-Content-Type-Options"
    "Referrer-Policy"
    "Permissions-Policy"
    "X-XSS-Protection"
  )
  while IFS= read -r url; do
    [[ -n "$url" ]] || continue
    echo "=== ${url} ==="
    local headers_raw
    headers_raw="$(curl -sI -m 10 -L "$url" 2>/dev/null || true)"
    if [[ -z "$headers_raw" ]]; then
      echo "  $(pick_lang 'Sin respuesta' 'No response')"
      echo
      continue
    fi
    local h found
    for h in "${check_headers[@]}"; do
      if echo "$headers_raw" | grep -qi "^${h}:"; then
        found="$(echo "$headers_raw" | grep -i "^${h}:" | head -1 | sed 's/\r$//')"
        echo "  [PRESENT] ${found}"
      else
        echo "  [MISSING] ${h}"
      fi
    done
    echo
  done < "$targets_file"
}

mod_headers() {
  local title summary
  title="$(pick_lang 'Cabeceras HTTP de seguridad' 'HTTP Security Headers')"
  summary="${OUTPUT_DIR}/summary/headers/headers.md"
  module_summary_init "$summary"

  teach_box \
    "$(msg teach_headers_title)" \
    "$(msg teach_headers_what)" \
    "$(msg teach_headers_when)" \
    "$(msg teach_headers_avoid)" \
    "$(msg teach_headers_next)"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): perfil passive"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay hosts vivos confirmados' 'no confirmed live hosts')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local targets_file="${OUTPUT_DIR}/tmp/headers_targets.txt"
  ensure_targets_for_web "$targets_file"
  if [[ ! -s "$targets_file" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos web validos' 'no valid web targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local out="${OUTPUT_DIR}/raw/headers/security_headers.txt"
  run_block headers "$(pick_lang 'Analisis de cabeceras de seguridad' 'Security headers analysis')" "$out" _check_security_headers "$targets_file" || true

  if [[ -s "$out" ]]; then
    local missing_count
    missing_count="$(grep -c 'MISSING' "$out" 2>/dev/null || echo 0)"
    if (( missing_count > 0 )); then
      append_finding "$(pick_lang "Se detectaron ${missing_count} cabeceras de seguridad faltantes." "${missing_count} missing security headers were detected.")"
    fi
    module_summary_note "$summary" "$(pick_lang 'Analisis de cabeceras' 'Headers analysis'): \`${out}\`"
    module_summary_note "$summary" "$(pick_lang 'Cabeceras faltantes' 'Missing headers'): **${missing_count}**"
  fi

  module_publish_summary "$title" "$summary"
}

mod_emails() {
  local title summary
  title="$(pick_lang 'Correos electronicos' 'Email Harvesting')"
  summary="${OUTPUT_DIR}/summary/emails/emails.md"
  module_summary_init "$summary"

  teach_box \
    "$(msg teach_emails_title)" \
    "$(msg teach_emails_what)" \
    "$(msg teach_emails_when)" \
    "$(msg teach_emails_avoid)" \
    "$(msg teach_emails_next)"

  if [[ -z "$DOMAIN" ]]; then
    module_summary_skip "$summary" "$(msg module_missing_domain)"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local all
  all="$(emails_file)"
  : > "$all"
  local ran_any=0

  local email_regex='[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
  if [[ -d "${OUTPUT_DIR}/raw" ]]; then
    grep -rhoE "$email_regex" "${OUTPUT_DIR}/raw/" 2>/dev/null | sort -u >> "$all" || true
    if [[ -s "$all" ]]; then
      module_summary_note "$summary" "$(pick_lang 'Correos extraidos de datos crudos existentes' 'Emails extracted from existing raw data')"
      ran_any=1
    fi
  fi

  if have_tool crosslinked; then
    local out="${OUTPUT_DIR}/raw/emails/crosslinked.txt"
    run_cmd emails "crosslinked $(pick_lang 'sobre' 'on') ${DOMAIN}" "$out" crosslinked -f '{first}.{last}@${DOMAIN}' "$DOMAIN" || true
    if [[ -s "$out" ]]; then
      grep -hoE "$email_regex" "$out" >> "$all" 2>/dev/null || true
    fi
    module_summary_note "$summary" "crosslinked: \`${out}\`"
    ran_any=1
  fi

  dedupe_file "$all"

  if [[ -s "$all" ]]; then
    record_lines_as_assets email "$all" emails harvested
    module_summary_note "$summary" "$(pick_lang 'Archivo consolidado' 'Consolidated file'): \`${all}\`"
    module_summary_note "$summary" "$(pick_lang 'Total' 'Total'): **$(wc -l < "$all")**"
    append_finding "$(pick_lang 'Se recolectaron correos electronicos. Revisa exposicion y posibles vectores de phishing.' 'Email addresses were collected. Review exposure and potential phishing vectors.')"
  elif (( ran_any == 0 )); then
    module_summary_note "$summary" "$(pick_lang 'No habia datos crudos ni herramientas de harvesting disponibles.' 'No raw data or harvesting tools were available.')"
  else
    module_summary_note "$summary" "$(pick_lang 'No se encontraron correos en esta ejecucion.' 'No emails were found in this run.')"
  fi

  module_publish_summary "$title" "$summary"
}

_check_cors() {
  local targets_file="$1" url
  while IFS= read -r url; do
    [[ -n "$url" ]] || continue
    echo "=== ${url} ==="
    local resp acao acac

    resp="$(curl -sI -m 10 -H 'Origin: https://evil.example.com' "$url" 2>/dev/null || true)"
    if echo "$resp" | grep -qi 'Access-Control-Allow-Origin.*evil.example.com'; then
      echo "  [VULN] $(pick_lang 'Origen reflejado: https://evil.example.com' 'Reflected origin: https://evil.example.com')"
    else
      echo "  [OK] $(pick_lang 'Origen no reflejado' 'Origin not reflected')"
    fi

    resp="$(curl -sI -m 10 -H 'Origin: null' "$url" 2>/dev/null || true)"
    if echo "$resp" | grep -qi 'Access-Control-Allow-Origin.*null'; then
      echo "  [VULN] $(pick_lang 'Acepta origen null' 'Accepts null origin')"
    else
      echo "  [OK] $(pick_lang 'No acepta origen null' 'Does not accept null origin')"
    fi

    resp="$(curl -sI -m 10 -H 'Origin: https://evil.example.com' "$url" 2>/dev/null || true)"
    acao="$(echo "$resp" | grep -i 'Access-Control-Allow-Origin' | head -1 || true)"
    acac="$(echo "$resp" | grep -i 'Access-Control-Allow-Credentials.*true' | head -1 || true)"
    if [[ -n "$acao" && -n "$acac" ]]; then
      echo "  [VULN] $(pick_lang 'Allow-Credentials con origen permisivo' 'Allow-Credentials with permissive origin')"
    fi

    echo
  done < "$targets_file"
}

mod_cors() {
  local title summary
  title="$(pick_lang 'Verificacion CORS' 'CORS Misconfiguration Check')"
  summary="${OUTPUT_DIR}/summary/cors/cors.md"
  module_summary_init "$summary"

  teach_box \
    "$(msg teach_cors_title)" \
    "$(msg teach_cors_what)" \
    "$(msg teach_cors_when)" \
    "$(msg teach_cors_avoid)" \
    "$(msg teach_cors_next)"

  if [[ "$PROFILE" == passive ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): perfil passive"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay hosts vivos confirmados' 'no confirmed live hosts')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local targets_file="${OUTPUT_DIR}/tmp/cors_targets.txt"
  ensure_targets_for_web "$targets_file"
  if [[ ! -s "$targets_file" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos web validos' 'no valid web targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local out="${OUTPUT_DIR}/raw/cors/cors_check.txt"
  run_block cors "$(pick_lang 'Verificacion CORS' 'CORS misconfiguration check')" "$out" _check_cors "$targets_file" || true

  if [[ -s "$out" ]]; then
    local vuln_count
    vuln_count="$(grep -c '\[VULN\]' "$out" 2>/dev/null || echo 0)"
    if (( vuln_count > 0 )); then
      append_finding "$(pick_lang "Se detectaron ${vuln_count} posibles misconfiguraciones CORS." "${vuln_count} possible CORS misconfigurations were detected.")"
    fi
    module_summary_note "$summary" "$(pick_lang 'Analisis CORS' 'CORS analysis'): \`${out}\`"
    module_summary_note "$summary" "$(pick_lang 'Posibles vulnerabilidades' 'Possible vulnerabilities'): **${vuln_count}**"
  fi

  module_publish_summary "$title" "$summary"
}

_identify_favicons() {
  local targets_file="$1" url
  while IFS= read -r url; do
    [[ -n "$url" ]] || continue
    local favicon_url="${url%/}/favicon.ico"
    echo "=== ${favicon_url} ==="

    local hash_result
    hash_result="$(curl -sL -m 10 "$favicon_url" 2>/dev/null | python3 -c "
import sys, base64, struct
try:
    data = sys.stdin.buffer.read()
    if len(data) == 0:
        sys.exit(1)
    b64 = base64.encodebytes(data).decode()
    def mmh3_32(key, seed=0):
        key = key.encode('utf-8') if isinstance(key, str) else key
        length = len(key)
        nblocks = length // 4
        h1 = seed
        c1 = 0xcc9e2d51
        c2 = 0x1b873593
        for i in range(nblocks):
            k1 = struct.unpack('<I', key[i*4:(i+1)*4])[0]
            k1 = (k1 * c1) & 0xFFFFFFFF
            k1 = ((k1 << 15) | (k1 >> 17)) & 0xFFFFFFFF
            k1 = (k1 * c2) & 0xFFFFFFFF
            h1 ^= k1
            h1 = ((h1 << 13) | (h1 >> 19)) & 0xFFFFFFFF
            h1 = (h1 * 5 + 0xe6546b64) & 0xFFFFFFFF
        tail = key[nblocks * 4:]
        k1 = 0
        if len(tail) >= 3: k1 ^= tail[2] << 16
        if len(tail) >= 2: k1 ^= tail[1] << 8
        if len(tail) >= 1:
            k1 ^= tail[0]
            k1 = (k1 * c1) & 0xFFFFFFFF
            k1 = ((k1 << 15) | (k1 >> 17)) & 0xFFFFFFFF
            k1 = (k1 * c2) & 0xFFFFFFFF
            h1 ^= k1
        h1 ^= length
        h1 ^= (h1 >> 16)
        h1 = (h1 * 0x85ebca6b) & 0xFFFFFFFF
        h1 ^= (h1 >> 13)
        h1 = (h1 * 0xc2b2ae35) & 0xFFFFFFFF
        h1 ^= (h1 >> 16)
        if h1 >= 0x80000000: h1 -= 0x100000000
        return h1
    print(mmh3_32(b64))
except Exception:
    pass
" 2>/dev/null || true)"

    if [[ -n "$hash_result" && "$hash_result" != "0" ]]; then
      echo "  Hash: ${hash_result}"
      local match=""
      case "$hash_result" in
        116323821) match="Spring Boot" ;;
        -297069493) match="Jenkins" ;;
        81586312) match="Apache Tomcat" ;;
        -1028703177) match="Grafana" ;;
        -1293291457) match="GitLab" ;;
        1848946384) match="Confluence" ;;
        -305179312) match="Jira" ;;
        988422585) match="Nginx default" ;;
        -1507567067) match="Apache default" ;;
        -1138760707) match="IIS default" ;;
        1165519062) match="Kibana" ;;
        -335242539) match="SonarQube" ;;
        1485257654) match="Nextcloud" ;;
        1279688030) match="Plesk" ;;
        -1073754801) match="cPanel" ;;
        1182489835) match="WordPress default" ;;
        -1210440700) match="Drupal" ;;
        766315014) match="Joomla" ;;
        -428443830) match="phpMyAdmin" ;;
        -752046790) match="Webmin" ;;
        1820498498) match="Roundcube" ;;
        -466583080) match="Zimbra" ;;
        642660180) match="OWA/Exchange" ;;
        1774235098) match="Zabbix" ;;
        -609585995) match="Nagios" ;;
        1547956543) match="Elastic" ;;
        855273746) match="Portainer" ;;
        -1950415971) match="Prometheus" ;;
        -27518332) match="Traefik" ;;
        -1188298460) match="Moodle" ;;
      esac
      if [[ -n "$match" ]]; then
        echo "  [MATCH] ${match}"
      else
        echo "  [UNKNOWN] $(pick_lang 'Hash no reconocido' 'Unrecognized hash')"
      fi
    else
      echo "  $(pick_lang 'Sin favicon o sin respuesta' 'No favicon or no response')"
    fi
    echo
  done < "$targets_file"
}

mod_favicon() {
  local title summary
  title="$(pick_lang 'Favicon Hash' 'Favicon Hash')"
  summary="${OUTPUT_DIR}/summary/favicon/favicon.md"
  module_summary_init "$summary"

  teach_box \
    "$(msg teach_favicon_title)" \
    "$(msg teach_favicon_what)" \
    "$(msg teach_favicon_when)" \
    "$(msg teach_favicon_avoid)" \
    "$(msg teach_favicon_next)"

  if ! ensure_alive_context && [[ "$TARGET_KIND" != url ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'no hay superficie web confirmada' 'there is no confirmed web surface')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local targets_file="${OUTPUT_DIR}/tmp/favicon_targets.txt"
  ensure_targets_for_web "$targets_file"
  if [[ ! -s "$targets_file" ]]; then
    module_summary_skip "$summary" "$(msg skipped_condition): $(pick_lang 'sin objetivos web validos' 'no valid web targets')"
    module_publish_summary "$title" "$summary"
    return 0
  fi

  local out="${OUTPUT_DIR}/raw/favicon/favicon_hashes.txt"
  run_block favicon "$(pick_lang 'Identificacion de favicon hash' 'Favicon hash identification')" "$out" _identify_favicons "$targets_file" || true

  if [[ -s "$out" ]]; then
    local match_count
    match_count="$(grep -c '\[MATCH\]' "$out" 2>/dev/null || echo 0)"
    if (( match_count > 0 )); then
      grep '\[MATCH\]' "$out" | sed 's/.*\[MATCH\] //' | sort -u >> "$(technologies_file)" 2>/dev/null || true
      dedupe_file "$(technologies_file)"
      append_finding "$(pick_lang "Se identificaron ${match_count} tecnologias por favicon hash." "Identified ${match_count} technologies by favicon hash.")"
    fi
    module_summary_note "$summary" "$(pick_lang 'Analisis de favicon' 'Favicon analysis'): \`${out}\`"
    module_summary_note "$summary" "$(pick_lang 'Tecnologias identificadas' 'Technologies identified'): **${match_count}**"
  fi

  module_publish_summary "$title" "$summary"
}

run_modules_sequence() {
  local module
  for module in "$@"; do
    case "$module" in
      passive_osint) run_selected_module "$module" mod_passive_osint ;;
      subdomains) run_selected_module "$module" mod_subdomains ;;
      dns) run_selected_module "$module" mod_dns ;;
      live_hosts) run_selected_module "$module" mod_live_hosts ;;
      network) run_selected_module "$module" mod_network ;;
      web_fingerprint) run_selected_module "$module" mod_web_fingerprint ;;
      content_discovery) run_selected_module "$module" mod_content_discovery ;;
      params_js) run_selected_module "$module" mod_params_js ;;
      ssl) run_selected_module "$module" mod_ssl ;;
      cms) run_selected_module "$module" mod_cms ;;
      services) run_selected_module "$module" mod_services ;;
      screenshots) run_selected_module "$module" mod_screenshots ;;
      cloud) run_selected_module "$module" mod_cloud ;;
      headers) run_selected_module "$module" mod_headers ;;
      emails) run_selected_module "$module" mod_emails ;;
      cors) run_selected_module "$module" mod_cors ;;
      favicon) run_selected_module "$module" mod_favicon ;;
    esac
  done
}

auto_recon() {
  status info "$(msg flow_start): ${PROFILE}"
  case "$PROFILE" in
    passive)
      run_modules_sequence passive_osint subdomains dns params_js emails
      ;;
    learning|webapp|bugbounty)
      run_modules_sequence passive_osint subdomains dns live_hosts web_fingerprint headers cors favicon content_discovery params_js ssl cms screenshots cloud emails
      ;;
    internal)
      run_modules_sequence network services ssl
      ;;
    ctf)
      run_modules_sequence network live_hosts web_fingerprint headers cors content_discovery services ssl
      ;;
    *)
      run_modules_sequence passive_osint subdomains live_hosts web_fingerprint headers
      ;;
  esac
}
