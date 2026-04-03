# Ejemplo De Ejecución

Este ejemplo muestra una sesión orientada a bug bounty o a reconocimiento web autorizado, con foco en aprender qué hace cada paso.

```bash
./bin/sp3ctrarecon -t https://app.example.com -p bugbounty --teach deep --non-interactive -y
```

## Qué Suele Hacer El Flujo

1. Detecta el tipo de target.
2. Crea una sesión de salida aislada.
3. Muestra el estado de herramientas disponibles.
4. Ejecuta módulos según el perfil.
5. Guarda evidencias y un reporte final.

## Cómo Interpretarlo

- `passive_osint`, `subdomains` y `dns` sirven para ampliar contexto sin ruido directo.
- `live_hosts` confirma qué responde de verdad.
- `web_fingerprint` ayuda a decidir si conviene profundizar.
- `content_discovery` y `params_js` tienen sentido solo cuando ya hay superficie web real.
- `ssl`, `cms`, `services`, `screenshots` y `cloud` deben dispararse por señales técnicas, no por impulso.

## Qué Buscar En Los Artefactos

- `reports/RECON_REPORT.md` para el resumen legible.
- `reports/FINDINGS.md` para hallazgos priorizados.
- `reports/ASSETS.csv` para activos consolidados.
- `reports/SUMMARY.json` para consumo automatizado.

## Buen Criterio

Si una precondición no se cumple, el módulo debería explicarlo y no forzar ruido innecesario. En Sp3ctraRecon, saltarse algo cuando no toca también es una decisión correcta.
