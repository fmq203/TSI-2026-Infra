# Tarea 3 — Infraestructura de Red de Defensa — Brain

## Rol y propósito

Sos el mantenedor de la base de conocimiento específica de la **Tarea 3** (Infraestructura
de Red de Defensa Completa). Acumulás el razonamiento, las decisiones de arquitectura y el
estado de avance de esta tarea — no reemplaza los entregables formales (`docs/*.md`,
Excel de `plantilla/mcu5/`), sino que guarda el *por qué* detrás de ellos para no
re-derivarlo cada sesión.

Este brain es independiente del brain general del curso (`../../../brain/`, es decir
`Seguridad/brain/`). Vive dentro de la carpeta de la tarea porque el volumen de detalle
(17 RF, 10 RNF, 6 hitos, 9 stacks Docker, auditoría MCU 5.0 Avanzado) lo justifica. El
brain general solo debe tener un resumen corto que apunte acá — no duplicar el detalle.

**Principio central:** un tema = un archivo. Nombres en kebab-case descriptivo.

## Mapa de directorios

```
tarea3-infra-red-segura/
├── README.md        ← punto de entrada humano + del brain (leer primero)
├── LETRA.md          ← fuente original, INTOCABLE desde el brain
├── brain/
│   ├── CLAUDE.md      ← este archivo: mapa y reglas
│   ├── MEMORY.md       ← hechos estables (fechas, equipo, RF/RNF, arquitectura decidida)
│   ├── decisions.md     ← log de decisiones de arquitectura/alcance, con fecha y motivo
│   ├── LEARNINGS.md     ← lecciones aprendidas (qué funcionó, qué no, por qué)
│   └── notes/            ← un archivo por tema puntual, se crea bajo demanda
├── docs/                ← entregables formales (plantillas ISACA + MCU completadas)
└── infra/                ← despliegue Docker-first (ver infra/README.md)
```

- **Fuentes originales** (`LETRA.md`, plantillas en `../plantilla/`) NO se duplican acá —
  se referencian con ruta relativa o cita de sección (ej. "LETRA.md §6.3").
- `docs/` e `infra/` son entregables/código real, no brain — el brain los referencia pero
  no los reescribe.
- `MEMORY.md` y `decisions.md` son principalmente append-only (se agrega, rara vez se borra).

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

Este `CLAUDE.md` vive en `brain/`, no en la raíz de la tarea, así que **no se carga
automáticamente** al abrir Claude Code en `tarea3-infra-red-segura/`. El archivo que sí
se lee naturalmente al abrir la carpeta es `../README.md` — por eso el README fue
actualizado para funcionar como base/puerta de entrada del brain y resumir lo esencial.
Para reglas completas, pedir explícitamente "leé brain/CLAUDE.md" o referenciarlo con
`@brain/CLAUDE.md`.
