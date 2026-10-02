# Tarea 3 — Infraestructura de Red de Defensa — Brain

## Rol y propósito

Sos el mantenedor de la base de conocimiento específica de la **Tarea 3** (Infraestructura
de Red de Defensa Completa). Acumulás el razonamiento, las decisiones de arquitectura y el
estado de avance de esta tarea — no reemplaza los entregables formales (`docs/*.md`,
Excel de `plantilla/mcu5/`), sino que guarda el *por qué* detrás de ellos para no
re-derivarlo cada sesión.

Este brain es autocontenido dentro del repo `TSI-2026-Infra` (uno de los integrantes
además tiene un brain general del curso en su máquina, fuera de este repo — no hace falta
para trabajar acá).

**Principio central:** un tema = un archivo. Nombres en kebab-case descriptivo.

## Mapa de directorios

```
TSI-2026-Infra/
├── CLAUDE.md        ← orientación corta para IA (se carga sola en Claude Code)
├── README.md        ← punto de entrada humano: estado, accesos, pendientes de seguridad
├── LETRA.md          ← fuente original, INTOCABLE
├── brain/
│   ├── CLAUDE.md      ← este archivo: reglas para mantener el brain
│   ├── MEMORY.md       ← FOTO del estado actual (se reescribe cuando cambia algo)
│   ├── decisions.md     ← log cronológico de decisiones, con fecha y motivo (append-only)
│   ├── LEARNINGS.md     ← errores ya pisados y su causa (append-only)
│   └── notes/            ← un archivo por tema puntual (ej. plan-recuperacion-atraso.md)
├── docs/                ← entregables formales (plantillas ISACA + MCU completadas)
├── infra/                ← despliegue Docker-first (ver infra/README.md)
└── vagrant/              ← copia portable en VirtualBox para el Red Team
```

- **Fuentes originales** (`LETRA.md`; plantillas ISACA/MCU del curso, que **no están en
  este repo**) NO se duplican acá — se referencian por nombre o sección (ej. "LETRA.md §6.3").
- `docs/` e `infra/` son entregables/código real, no brain — el brain los referencia pero
  no los reescribe.
- `MEMORY.md` = estado actual, se **reescribe** para que nunca contradiga a la realidad.
  `decisions.md` y `LEARNINGS.md` = historia, solo se **agrega** al final.

## Protocolo de lectura

Al empezar a trabajar en esta tarea:
1. Leer `../README.md` (visión general + estado resumido).
2. Leer `MEMORY.md` (hechos estables).
3. Si hace falta el estado real de avance, leer `../docs/README.md` e `../infra/README.md`
   directamente (son la fuente de verdad del avance, no se duplica acá).
4. Recién ahí, si hace falta detalle de un tema puntual, ir a `notes/`.

## Convenciones de escritura

Cada archivo de `notes/` lleva un frontmatter mínimo:

```markdown
---
title: <título corto>
tags: [tarea3, <tema>, ...]
updated: YYYY-MM-DD
---
```

- Enlazar temas relacionados con `[[nombre-del-archivo-sin-extension]]`.
- Un link a `[[algo]]` que todavía no existe es válido — marca algo pendiente de anotar.
- `decisions.md` es una lista cronológica: fecha, decisión, motivo, alternativas descartadas.
  No se reescribe el pasado; si una decisión cambia, se agrega una entrada nueva que
  referencia la anterior.

## Reglas duras

- Nunca editar `LETRA.md` ni las plantillas originales desde el brain.
- Nunca inventar fechas, cifras o estado de avance que no estén en una fuente citada
  (archivo + línea/sección, o "conversación DD/MM/AAAA"). Si falta información, se anota
  como pendiente de confirmar, no se completa a ciegas.
- Siempre citar de dónde sale un hecho.
- Mantener este `CLAUDE.md` corto (< 200 líneas).

## Nota sobre auto-carga

El `CLAUDE.md` de la **raíz** se carga solo al abrir Claude Code en el repo y manda a
leer `README.md` y `brain/MEMORY.md`. Este archivo (`brain/CLAUDE.md`) se carga cuando se
trabaja con archivos de `brain/`. Con otra IA (ChatGPT, Gemini, Copilot, etc.): pasarle
primero el `CLAUDE.md` de la raíz, el `README.md` y `brain/MEMORY.md`.
