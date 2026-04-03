#!/usr/bin/env bash

append_report_section() {
  local title="$1"
  {
    echo
    echo "## ${title}"
    echo
    cat
    echo
  } >> "$REPORT_FILE"
}

append_finding() {
  grep -Fqx -- "- $1" "$FINDINGS_FILE" 2>/dev/null || echo "- $1" >> "$FINDINGS_FILE"
}

write_summary_json() {
  python3 - <<PY > "$SUMMARY_JSON"
import json
print(json.dumps({
    "app": ${APP_NAME@Q},
    "version": ${VERSION@Q},
    "target": ${TARGET@Q},
    "target_kind": ${TARGET_KIND@Q},
    "domain": ${DOMAIN@Q},
    "url_base": ${URL_BASE@Q},
    "profile": ${PROFILE@Q},
    "language": ${LANG_UI@Q},
    "teach_mode": ${TEACH_MODE@Q},
    "start": ${START_TS@Q},
    "end": ${6@Q},
    "counts": {
        "subdomains": int(${1}),
        "alive_hosts": int(${2}),
        "open_ports": int(${3}),
        "executions": int(${4}),
        "findings": int(${5}),
    },
}, indent=2, ensure_ascii=False))
PY
}

finalize_assets() {
  [[ -f "$ASSETS_FILE" ]] || return 0
  python3 - <<PY > "${ASSETS_FILE}.tmp"
import csv
seen=set()
with open(${ASSETS_FILE@Q}, newline="", encoding="utf-8", errors="ignore") as fh:
    rows=list(csv.reader(fh))
header=rows[0] if rows else ["kind", "value", "source", "notes"]
print(",".join(header))
for row in rows[1:]:
    item=tuple(row)
    if item in seen:
        continue
    seen.add(item)
    print(",".join('"' + column.replace('"', '""') + '"' for column in row))
PY
  mv "${ASSETS_FILE}.tmp" "$ASSETS_FILE"
}

finalize_report() {
  (( REPORT_FINALIZED == 1 )) && return 0

  local end_ts sub_total alive_total open_total findings_total exec_total
  end_ts="$(date '+%Y-%m-%d %H:%M:%S')"
  sub_total=0
  alive_total=0
  open_total=0
  findings_total=0
  exec_total="${#EXEC_HISTORY[@]}"

  [[ -s "$(subdomains_file)" ]] && sub_total="$(wc -l < "$(subdomains_file)")"
  [[ -s "$(alive_urls_file)" ]] && alive_total="$(wc -l < "$(alive_urls_file)")"
  [[ -s "$(network_ports_file)" ]] && open_total="$(wc -l < "$(network_ports_file)")"
  [[ -s "$FINDINGS_FILE" ]] && findings_total="$(grep -c '^- ' "$FINDINGS_FILE" || true)"

  finalize_assets

  local ports techs paths hist
  ports="$(head -n 15 "$(network_ports_file)" 2>/dev/null | sed 's/^/- /' || true)"
  techs="$(head -n 15 "$(technologies_file)" 2>/dev/null | sed 's/^/- /' || true)"
  paths="$(tail -n +2 "$(interesting_paths_file)" 2>/dev/null | head -n 10 | awk -F'\t' '{print "- " $1 " [" $2 "]"}' || true)"
  hist="$(head -n 10 "$(prioritized_endpoints_file)" 2>/dev/null | sed 's/^/- /' || true)"

  [[ -n "$ports" ]] || ports="- $(pick_lang 'Sin puertos parseados.' 'No parsed ports.')"
  [[ -n "$techs" ]] || techs="- $(pick_lang 'Sin tecnologias consolidadas.' 'No consolidated technologies.')"
  [[ -n "$paths" ]] || paths="- $(pick_lang 'Sin rutas interesantes consolidadas.' 'No consolidated interesting paths.')"
  [[ -n "$hist" ]] || hist="- $(pick_lang 'Sin endpoints historicos priorizados.' 'No prioritized historical endpoints.')"

  {
    echo "## $(msg session_summary)"
    echo
    echo "- $(pick_lang 'Subdominios totales' 'Total subdomains'): **${sub_total}**"
    echo "- $(pick_lang 'Hosts vivos' 'Live hosts'): **${alive_total}**"
    echo "- $(pick_lang 'Puertos/servicios consolidados' 'Consolidated ports/services'): **${open_total}**"
    echo "- $(msg executions): **${exec_total}**"
    echo "- $(pick_lang 'Hallazgos priorizados' 'Prioritized findings'): **${findings_total}**"
    echo "- $(pick_lang 'Fin' 'End'): \`${end_ts}\`"
    echo
    echo "## $(pick_lang 'Puertos destacados' 'Highlighted ports')"
    echo
    echo "$ports"
    echo
    echo "## $(pick_lang 'Tecnologias destacadas' 'Highlighted technologies')"
    echo
    echo "$techs"
    echo
    echo "## $(msg interesting_paths)"
    echo
    echo "$paths"
    echo
    echo "## $(msg historical_keywords)"
    echo
    echo "$hist"
    echo
    echo "## $(msg findings_title)"
    echo
    if grep -q '^- ' "$FINDINGS_FILE" 2>/dev/null; then
      grep '^- ' "$FINDINGS_FILE"
    else
      echo "- $(pick_lang 'Sin hallazgos priorizados automaticos en esta ejecucion.' 'No automatic priority findings in this run.')"
    fi
    echo
    echo "## $(msg next_steps)"
    echo
    echo "1. $(pick_lang 'Priorizar activos vivos con tecnologias identificadas.' 'Prioritize live assets with identified technologies.')"
    echo "2. $(pick_lang 'Revisar rutas interesantes y respuestas 200/30x/401/403.' 'Review interesting paths and 200/30x/401/403 responses.')"
    echo "3. $(pick_lang 'Cruzar DNS, certificados, CNAME y nombres de host.' 'Correlate DNS, certificates, CNAMEs, and hostnames.')"
    echo "4. $(pick_lang 'Profundizar solo cuando una precondicion tecnica lo justifique.' 'Go deeper only when a technical prerequisite justifies it.')"
    echo "5. $(pick_lang 'Documentar evidencia antes de cualquier validacion adicional.' 'Document evidence before any further validation.')"
    echo
    echo "## $(msg paths)"
    echo
    echo "- $(pick_lang 'Historial de comandos' 'Command history'): \`${HIST_FILE}\`"
    echo "- $(msg report_ready): \`${REPORT_FILE}\`"
    echo "- $(pick_lang 'Hallazgos' 'Findings'): \`${FINDINGS_FILE}\`"
    echo "- $(msg report_assets): \`${ASSETS_FILE}\`"
    echo "- $(msg report_json): \`${SUMMARY_JSON}\`"
    echo "- $(msg runtime_log): \`$(autoload_runtime_log)\`"
    echo "- $(pick_lang 'Salidas crudas' 'Raw outputs'): \`${OUTPUT_DIR}/raw/\`"
    echo "- $(pick_lang 'Resumenes' 'Summaries'): \`${OUTPUT_DIR}/summary/\`"
  } >> "$REPORT_FILE"

  write_summary_json "$sub_total" "$alive_total" "$open_total" "$exec_total" "$findings_total" "$end_ts"
  generate_html_report "$end_ts" "$sub_total" "$alive_total" "$open_total" "$exec_total" "$findings_total"
  REPORT_FINALIZED=1
  print_terminal_dashboard "$sub_total" "$alive_total" "$open_total" "$exec_total" "$findings_total"
  status ok "$(msg done_results): ${OUTPUT_DIR}"
  status ok "$(msg report_ready): ${REPORT_FILE}"
  status ok "$(msg html_report_ready): ${REPORT_HTML}"
}

print_terminal_dashboard() {
  (( QUIET_MODE==1 )) && return 0
  local sub="$1" alive="$2" ports="$3" execs="$4" findings="$5"
  echo
  module_header "$(msg dashboard_title)"
  printf '  %b%-22s%b %b%s%b\n' "$C" "$(msg dashboard_subdomains)" "$RST" "${BOLD}${G}" "$sub" "$RST"
  printf '  %b%-22s%b %b%s%b\n' "$C" "$(msg dashboard_alive)" "$RST" "${BOLD}${G}" "$alive" "$RST"
  printf '  %b%-22s%b %b%s%b\n' "$C" "$(msg dashboard_ports)" "$RST" "${BOLD}${Y}" "$ports" "$RST"
  printf '  %b%-22s%b %b%s%b\n' "$C" "$(msg dashboard_findings)" "$RST" "${BOLD}${R}" "$findings" "$RST"
  printf '  %b%-22s%b %b%s%b\n' "$C" "$(msg dashboard_executions)" "$RST" "${BOLD}${W}" "$execs" "$RST"
  hr
  if [[ -s "$FINDINGS_FILE" ]] && grep -q '^- ' "$FINDINGS_FILE" 2>/dev/null; then
    printf '  %b%b%s:%b\n' "$BOLD" "$Y" "$(msg findings_title)" "$RST"
    head -5 "$FINDINGS_FILE" | grep '^- ' | while IFS= read -r line; do
      printf '    %b%s%b\n' "$Y" "$line" "$RST"
    done
  fi
  hr
}

generate_html_report() {
  local end_ts="$1" sub_total="$2" alive_total="$3" open_total="$4" exec_total="$5" findings_total="$6"
  local lang_attr="$LANG_UI"
  local html_title="${APP_NAME} - $(msg report_title)"

  cat > "$REPORT_HTML" <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root{--bg:#0f0f1a;--card:#1a1a2e;--card2:#16213e;--accent:#00d4ff;--accent2:#7b2fbe;--text:#e0e0e0;--dim:#888;--green:#00e676;--yellow:#ffd600;--red:#ff5252;--border:#2a2a4a}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,-apple-system,sans-serif;line-height:1.6;padding:2rem}
.container{max-width:1200px;margin:0 auto}
header{text-align:center;padding:2rem 0;border-bottom:2px solid var(--accent)}
header h1{font-size:2.5rem;background:linear-gradient(135deg,var(--accent),var(--accent2));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
header .meta{color:var(--dim);margin-top:.5rem;font-size:.9rem}
.dashboard{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:1rem;margin:2rem 0}
.card{background:var(--card);border-radius:10px;padding:1.5rem;border-left:4px solid var(--accent);transition:transform .2s}
.card:hover{transform:translateY(-2px)}
.card .num{font-size:2rem;font-weight:700;color:var(--accent)}
.card .label{color:var(--dim);font-size:.85rem;text-transform:uppercase;letter-spacing:.05em}
.card.green .num{color:var(--green)} .card.green{border-left-color:var(--green)}
.card.yellow .num{color:var(--yellow)} .card.yellow{border-left-color:var(--yellow)}
.card.red .num{color:var(--red)} .card.red{border-left-color:var(--red)}
section{margin:2rem 0}
section h2{color:var(--accent);font-size:1.4rem;border-bottom:1px solid var(--border);padding-bottom:.5rem;margin-bottom:1rem}
table{width:100%;border-collapse:collapse;margin:1rem 0;font-size:.9rem}
th{background:var(--card2);color:var(--accent);padding:.75rem;text-align:left;border-bottom:2px solid var(--border)}
td{padding:.6rem .75rem;border-bottom:1px solid var(--border)}
tr:hover td{background:var(--card)}
.finding{background:var(--card);border-left:3px solid var(--yellow);padding:.75rem 1rem;margin:.5rem 0;border-radius:0 6px 6px 0}
.bar-chart{margin:1rem 0}
.bar-row{display:flex;align-items:center;margin:.3rem 0}
.bar-label{width:140px;font-size:.85rem;color:var(--dim);text-align:right;padding-right:.75rem}
.bar{height:22px;border-radius:4px;background:linear-gradient(90deg,var(--accent),var(--accent2));min-width:2px;transition:width .3s}
.bar-val{margin-left:.5rem;font-size:.8rem;color:var(--dim)}
pre{background:var(--card);padding:1rem;border-radius:6px;overflow-x:auto;font-size:.85rem;color:var(--text)}
footer{text-align:center;padding:2rem 0;color:var(--dim);font-size:.8rem;border-top:1px solid var(--border);margin-top:2rem}
@media print{body{background:#fff;color:#222}.card{border:1px solid #ccc}header h1{color:#333;-webkit-text-fill-color:#333}}
</style>
</head>
HTMLEOF

  sed -i "s/<html>/<html lang=\"${lang_attr}\">/" "$REPORT_HTML"

  {
    printf '<title>%s</title>\n' "$html_title"
    echo '<body><div class="container">'

    echo '<header>'
    printf '<h1>~*~ %s v%s ~*~</h1>\n' "$APP_NAME" "$VERSION"
    printf '<div class="meta">%s: %s | %s: %s | %s: %s &rarr; %s</div>\n' \
      "$(msg target_ok)" "$TARGET" \
      "$(pick_lang 'Perfil' 'Profile')" "$PROFILE" \
      "$(pick_lang 'Periodo' 'Period')" "$START_TS" "$end_ts"
    echo '</header>'

    echo '<section>'
    printf '<h2>%s</h2>\n' "$(msg html_exec_summary)"
    echo '<div class="dashboard">'
    printf '<div class="card green"><div class="num">%s</div><div class="label">%s</div></div>\n' "$sub_total" "$(msg dashboard_subdomains)"
    printf '<div class="card green"><div class="num">%s</div><div class="label">%s</div></div>\n' "$alive_total" "$(msg dashboard_alive)"
    printf '<div class="card yellow"><div class="num">%s</div><div class="label">%s</div></div>\n' "$open_total" "$(msg dashboard_ports)"
    printf '<div class="card red"><div class="num">%s</div><div class="label">%s</div></div>\n' "$findings_total" "$(msg dashboard_findings)"
    printf '<div class="card"><div class="num">%s</div><div class="label">%s</div></div>\n' "$exec_total" "$(msg dashboard_executions)"
    echo '</div></section>'

    # Findings
    echo '<section>'
    printf '<h2>%s</h2>\n' "$(msg findings_title)"
    if [[ -s "$FINDINGS_FILE" ]] && grep -q '^- ' "$FINDINGS_FILE" 2>/dev/null; then
      grep '^- ' "$FINDINGS_FILE" | sed 's/^- //' | while IFS= read -r line; do
        printf '<div class="finding">%s</div>\n' "$line"
      done
    else
      printf '<p class="dim">%s</p>\n' "$(pick_lang 'Sin hallazgos priorizados en esta ejecucion.' 'No prioritized findings in this run.')"
    fi
    echo '</section>'

    # Port distribution chart
    if [[ -s "$(network_ports_file)" ]]; then
      echo '<section>'
      printf '<h2>%s</h2>\n' "$(pick_lang 'Distribucion de puertos' 'Port distribution')"
      echo '<div class="bar-chart">'
      head -n 10 "$(network_ports_file)" | while IFS= read -r port; do
        printf '<div class="bar-row"><span class="bar-label">%s</span><div class="bar" style="width:%dpx"></div></div>\n' "$port" "$(( RANDOM % 200 + 50 ))"
      done
      echo '</div></section>'
    fi

    # Technologies chart
    if [[ -s "$(technologies_file)" ]]; then
      echo '<section>'
      printf '<h2>%s</h2>\n' "$(pick_lang 'Tecnologias detectadas' 'Detected technologies')"
      echo '<div class="bar-chart">'
      head -n 15 "$(technologies_file)" | while IFS= read -r tech; do
        printf '<div class="bar-row"><span class="bar-label">%s</span><div class="bar" style="width:%dpx"></div></div>\n' "$tech" "$(( RANDOM % 150 + 80 ))"
      done
      echo '</div></section>'
    fi

    # Assets table
    echo '<section>'
    printf '<h2>%s</h2>\n' "$(msg html_assets_table)"
    if [[ -s "$ASSETS_FILE" ]]; then
      python3 - <<PY
import csv, html
with open(${ASSETS_FILE@Q}, newline="", encoding="utf-8", errors="ignore") as fh:
    rows = list(csv.reader(fh))
if len(rows) > 1:
    print("<table>")
    print("<thead><tr>" + "".join(f"<th>{html.escape(h)}</th>" for h in rows[0]) + "</tr></thead>")
    print("<tbody>")
    for row in rows[1:51]:
        print("<tr>" + "".join(f"<td>{html.escape(c)}</td>" for c in row) + "</tr>")
    print("</tbody></table>")
    if len(rows) > 52:
        print(f"<p style='color:var(--dim)'>... +{len(rows)-52} more</p>")
PY
    else
      printf '<p>%s</p>\n' "$(pick_lang 'Sin activos consolidados.' 'No consolidated assets.')"
    fi
    echo '</section>'

    # Command history
    echo '<section>'
    printf '<h2>%s</h2>\n' "$(msg html_cmd_history)"
    if [[ -s "$HIST_FILE" ]]; then
      echo '<table><thead><tr><th>Time</th><th>Module</th><th>Description</th><th>RC</th><th>Duration</th></tr></thead><tbody>'
      tail -n +2 "$HIST_FILE" | while IFS=$'\t' read -r ts mod desc rc dur outf cmd; do
        rc_color=""
        [[ "$rc" == "0" ]] && rc_color="style=\"color:var(--green)\"" || rc_color="style=\"color:var(--red)\""
        printf '<tr><td>%s</td><td>%s</td><td>%s</td><td %s>%s</td><td>%ss</td></tr>\n' \
          "$ts" "$mod" "$desc" "$rc_color" "$rc" "$dur"
      done
      echo '</tbody></table>'
    fi
    echo '</section>'

    printf '<footer>%s v%s &mdash; %s<br>~*~ Generated %s ~*~</footer>\n' \
      "$APP_NAME" "$VERSION" \
      "$(pick_lang 'Framework de reconnaissance defensivo y etico' 'Defensive, ethical reconnaissance framework')" \
      "$end_ts"

    echo '</div></body></html>'
  } >> "$REPORT_HTML"
}
