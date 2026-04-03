# Contributing to Sp3ctraRecon / Contribuir a Sp3ctraRecon

[English](#english) | [Espanol](#español)

---

## English

Thanks for wanting to improve Sp3ctraRecon. The priority is keeping a useful, educational, and stable tool — not turning it into a black box or an opaque command launcher.

### Before Submitting Changes

- Maintain the educational focus.
- Avoid `eval` and fragile quoting.
- If you add a dependency, document why it's needed and what happens if it's missing.
- Do not add new offensive capabilities.
- Keep consistency across code, flags, installation, tests, reporting, and documentation.

### Recommended Flow

1. Review the architecture and locate the affected flow.
2. Implement the minimum necessary change.
3. Add or update verifiable validation.
4. Update user-facing documentation.
5. Verify the experience works in both English and Spanish.

### Validation

Before opening a PR, verify at least:

```bash
bash tests/validators.sh
bash tests/smoke.sh
```

If you change installation, also test `--copy` and `--link` behavior.

### Best Practices

- Use coherent module names and aliases.
- Prefer arrays and explicit paths.
- Reduce noise and maintain clear preconditions.
- If a module doesn't apply, explain why with a useful reason.

### Style

Sp3ctraRecon aims to be serious, maintainable, and didactic. The best contributions improve stability, clarity, or evidence without adding unnecessary complexity.

---

## Español

Gracias por querer mejorar Sp3ctraRecon. La prioridad es mantener una herramienta util, pedagogica y estable, sin convertirla en una caja negra ni en un lanzador opaco de comandos.

### Antes de Enviar Cambios

- Manten el enfoque educativo.
- Evita `eval` y quoting fragil.
- Si agregas una dependencia, documenta por que hace falta y que pasa si falta.
- No anadas capacidades ofensivas nuevas.
- Conserva la coherencia entre codigo, flags, instalacion, tests, reporting y documentacion.

### Flujo Recomendado

1. Revisa la arquitectura y localiza el flujo afectado.
2. Implementa el cambio minimo necesario.
3. Anade o actualiza validacion verificable.
4. Actualiza la documentacion visible al usuario.
5. Comprueba que la experiencia funcione en espanol e ingles.

### Validacion

Antes de abrir un PR, verifica al menos:

```bash
bash tests/validators.sh
bash tests/smoke.sh
```

Si cambias la instalacion, tambien revisa el comportamiento de `--copy` y `--link`.

### Buenas Practicas

- Usa nombres de modulo y aliases coherentes.
- Prefiere arrays y rutas explicitas.
- Reduce ruido y conserva precondiciones claras.
- Si un modulo no aplica, explicalo con una razon util.

### Estilo

Sp3ctraRecon busca ser serio, mantenible y didactico. Los cambios que mejor encajan son los que mejoran estabilidad, claridad o evidencia sin anadir complejidad innecesaria.
