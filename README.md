# Tarea 3 — Infraestructura de Red de Defensa Completa

Este README es la **puerta de entrada** de la tarea: para personas y también el punto
que resume el estado y el razonamiento acumulado (el "brain") para no tener que
re-derivarlo cada vez.

## Contenido

- **`LETRA.md`** — La letra completa de la tarea: marco teórico, glosario, requerimientos funcionales/no funcionales, arquitectura sugerida, Partes Blue Team y Red Team, matriz de documentación, hitos, KPIs y criterios de evaluación. Fuente original, no se edita.
- **`docs/`** — Carpeta de trabajo del equipo para la documentación de la solución (ver `docs/README.md` para el checklist de entregables).
- **`infra/`** — Despliegue Docker-first de la infraestructura de defensa (ver `infra/README.md` para arquitectura, stacks y cómo levantarla).
- **`brain/`** — Base de conocimiento específica de esta tarea: decisiones de arquitectura, hechos estables y lecciones aprendidas que no viven en la letra ni en las plantillas. Ver "Brain de la Tarea 3" abajo.

## Brain de la Tarea 3

Es un brain **propio de esta tarea**, separado del brain general del curso
(`../../brain/`), porque el volumen de detalle (17 RF, 10 RNF, 6 hitos, 9 stacks Docker,
auditoría MCU 5.0 Avanzado) lo justifica. El brain general del curso solo debería tener
un resumen corto que apunte acá.

```
tarea3-infra-red-segura/
├── README.md        ← este archivo: entrada humana + base del brain
├── LETRA.md          ← fuente original, intocable desde el brain
├── brain/
│   ├── CLAUDE.md      ← mapa y reglas completas del brain
│   ├── MEMORY.md       ← hechos estables: fechas, equipo, RF/RNF, arquitectura decidida
│   ├── decisions.md     ← log de decisiones de arquitectura/alcance, con fecha y motivo
│   ├── LEARNINGS.md     ← lecciones aprendidas (se completa con el avance)
│   └── notes/            ← notas puntuales por tema (se crea bajo demanda)
├── docs/                ← entregables formales (plantillas ISACA + MCU completadas)
└── infra/                ← despliegue Docker-first (ver infra/README.md)
```

**Protocolo de lectura sugerido:**
1. Este README — visión general y estado.
2. `brain/MEMORY.md` — hechos estables, para no releer toda la letra cada sesión.
3. `docs/README.md` e `infra/README.md` — estado real de avance (son la fuente de verdad, el brain no los duplica).
4. `brain/notes/<tema>.md` — si hace falta profundizar en un tema puntual.
5. `brain/CLAUDE.md` — reglas completas, solo si vas a escribir/actualizar el brain.

## Estado actual (resumen al 2026-10-01 — detalle y fuentes en `brain/MEMORY.md`)

- **infra/**: tienen `docker-compose.yml` listo → `identity/`, `mail/`, `targets/`,
  `honeypot/`. Todavía vacíos: `nids/`, `router-vm/`, `siem-hids/`, `wazo/`,
  `alerting/`, `soar-thehive-optional/`.
- **docs/**: ningún entregable de la matriz tiene contenido todavía (todo `☐` en
  `docs/README.md`), incluyendo la consigna propia y el diagrama de arquitectura.
- ⚠️ Los hitos sugeridos por la letra H1 (21/09) y H2 (28/09) ya vencieron sin evidencia
  de avance en el filesystem — a confirmar con el equipo si hay un cronograma interno
  distinto.

## Cómo empezar

1. Lea `LETRA.md` completo.
2. En la **Semana 1** el equipo genera su **consigna propia** (escenario empresarial ficticio + diagrama de red + casos de uso). Se aprueba con el docente antes de avanzar.
3. Revise la matriz de documentación (sección 8) para saber qué plantilla llenar en cada semana.
4. Copie de `../plantilla/isaca/` las plantillas indicadas a su carpeta `docs/`.
5. Trabaje en su repositorio GIT y congele la entrega con `git tag v1.0` en el hito H4.

## Documentación que debe entregar (resumen)

| Fecha | Documento |
|---|---|
| Semana 1 (14-18/09) | Consigna propia + diagrama de red (vistas física/C4) + política, inventario |
| Semana 2 (21-25/09) | Análisis de riesgos, Excel controles MCU (Avanzado) |
| Semana 3-4 (28/09-02/10) | Gestión de accesos, monitoreo/logs/SIEM, bitácora |
| Semana 5 (05-07/10) | Vulnerabilidades, continuidad, incidentes, SoA + brecha MCU, notificaciones |
| **Miércoles 07/10/2026** | **Pre-entrega congelada** (`git tag v1.0`) + Excel/bitácora completos |
| **Miércoles 14/10/2026** | **Auditoría formal por función MCU 5.0 (defensa)** + demo de detección→respuesta |
| **Miércoles 28/10/2026** | **Pre-entrega Red Team** (informe preliminar ≥ 70%) |
| **Lunes 09/11/2026** | **Entrega final Red Team** (informe `plantilla/informe-red-team.md` + presentación) |

- **Equipo A (Blue Team):** construye la infraestructura de defensa y rinde la auditoría (semana del 14/09 al 14/10).
- **Equipo B (Red Team):** ataca la infraestructura entregada (28/10 → 09/11) y emite informe.