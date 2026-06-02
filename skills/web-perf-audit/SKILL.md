---
name: web-perf-audit
description: Audita el rendimiento real de una web Next.js / React. Mide Core Web Vitals via Lighthouse, analiza el bundle JS, detecta antipatrones Next (force-dynamic innecesarios, imagenes sin optimizar, RSC con libs cliente pesadas), y reporta bottlenecks priorizados. No modifica codigo, no instala deps globales. Usa esta skill cuando el usuario diga: la web va lenta, mi web es lenta, audita rendimiento, performance audit, core web vitals, lighthouse audit, optimizar velocidad, LCP malo, INP alto, bundle grande, primera carga lenta, o invoque /web-perf-audit.
origin: personalizada
---

# Auditoria de rendimiento web

Esta skill audita el rendimiento de una aplicacion Next.js / React.
**No modifica codigo. No instala deps globales. Solo mide y reporta.**

## Inputs esperados

Antes de empezar, confirma con el usuario:
- **URL a auditar** (puede ser local `http://localhost:3000`, preview de Vercel, o produccion).
- **Rutas concretas** a probar (al menos 1, recomendado 3: home, ruta autenticada, ruta con mucho contenido).
- **Si la web esta detras de auth**: pide cookie/token o que la lance autenticada en su navegador y use `--collect.url` con la sesion suya. Si no es viable, audita solo rutas publicas y deja constancia.

Si la URL es localhost y `npm run dev` no esta arriba, avisa y para.

## Pasos a ejecutar

### 1. Detectar el stack
Lee `package.json`:
- Framework: Next.js (version), Vite, Remix, otro. Si no es React/Next, avisa que la skill esta optimizada para esos pero igualmente puede correr Lighthouse y descartar el resto.
- Si hay `@next/bundle-analyzer` ya instalado, anotalo.
- Lee `next.config.{js,ts,mjs}` para detectar: `images.domains`, `experimental.*`, `compress`, `output: "standalone"`, `swcMinify`.

### 2. Lighthouse — Core Web Vitals
Para cada URL, ejecuta:
```bash
npx -y lighthouse <URL> \
  --only-categories=performance \
  --form-factor=mobile \
  --throttling-method=simulate \
  --output=json \
  --output-path=/tmp/lh-<slug>.json \
  --chrome-flags="--headless=new --no-sandbox"
```

Extrae del JSON:
- LCP (objetivo < 2.5s)
- INP / TBT (objetivo INP < 200ms, TBT < 200ms)
- CLS (objetivo < 0.1)
- TTFB (objetivo < 800ms en mobile)
- Score de performance (0-100)
- Top 5 "opportunities" por `wastedMs`
- Top 3 "diagnostics" relevantes (unused-javascript, render-blocking-resources, third-party-summary)

Si lighthouse falla por Chrome no encontrado, avisa: el usuario tiene que instalar Chrome o Chromium. No intentes instalarlo.

Repite para **desktop** (`--form-factor=desktop --throttling-method=provided`) solo si el usuario lo pide explicitamente. Por defecto mobile only — es el peor caso.

### 3. Bundle analysis (Next.js)
Si el stack es Next.js:

- Si `.next/` existe y es reciente (< 1h), reusa el output. Si no, **NO** lances `next build` por ti mismo — pide al usuario que lo lance (puede tardar minutos).
- Lee `.next/build-manifest.json` y `.next/app-build-manifest.json` para mapear rutas → chunks.
- Identifica las 5 rutas con mayor "First Load JS" (sumando chunks compartidos + chunk especifico).
- Si no hay `.next/` reciente, sugiere lanzar:
  ```bash
  ANALYZE=true npm run build
  ```
  Pero **solo si** `@next/bundle-analyzer` ya esta integrado en `next.config.{js,ts,mjs}`. Si no, indicalo como recomendacion en el reporte, no como accion automatica.

### 4. Antipatrones Next (grep estatico, rapido)

Busca con grep en `app/` y `pages/`:

| Patron | Que busca | Por que importa |
|---|---|---|
| `export const dynamic = "force-dynamic"` | rutas que desactivan cache RSC | mata el ISR y la cache estatica |
| `export const revalidate = 0` | idem | idem |
| `cookies()` o `headers()` en `app/page.tsx` raiz | trigger de force-dynamic implicito | TTFB sube en cada hit |
| `<img src=` (no `next/image`) en `.tsx` | imagenes sin optimizar | LCP malo, no AVIF/WebP, sin lazy |
| `"use client"` en ficheros que importan `recharts`, `chart.js`, `pdfjs`, `mapbox-gl`, `leaflet`, `@react-pdf/renderer`, `monaco-editor`, `framer-motion` (top) | libs pesadas en bundle cliente | inflan First Load JS |
| `import * as X` desde paquetes grandes (lodash, date-fns, lucide-react) | imports no tree-shakeables | bundle bloat |
| Falta de `loading.tsx` en rutas con data fetching | sin streaming UI | usuario ve pantalla en blanco hasta que termina el RSC |
| Server Components que importan modulos con `"use client"` en cascada | RSC inflados | aumenta payload del stream |

Cada hallazgo lo marcas con:
- **ruta exacta** y **linea** (file_path:line)
- **impacto estimado**: ALTO si afecta LCP/INP, MEDIO si afecta TBT, BAJO si solo es codigo limpio.

### 5. Imagenes — auditoria especifica

Para cada `<img>` o `next/image` encontrado en rutas auditadas:
- ¿Tiene `priority` la imagen del LCP probable (hero)?
- ¿Tiene `sizes` apropiado en imagenes responsive?
- ¿Hay imagenes externas sin `images.domains` configurado (rompe optimizacion)?
- ¿Hay PNG/JPG > 200 KB que podrian ser AVIF/WebP?

Si el repo tiene carpeta `public/`, lista las 5 imagenes mas pesadas:
```bash
find public -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -size +100k -exec du -h {} \; | sort -rh | head -5
```

### 6. Backend latency (si aplica)

Si detectas Supabase / Postgres en `package.json`:
- Avisa que el usuario puede revisar **Supabase Studio > Reports > Slow queries** para queries > 500ms.
- **NO** te conectes a la BD ni ejecutes EXPLAIN. Solo apunta el destino.
- Si hay Sentry instalado, sugiere filtrar transactions por p95 duration en el dashboard.

### 7. Reporte final

Devuelve **un solo bloque** estructurado:

```
ESTADO: <VERDE | AMARILLO | ROJO>
Web: <URL>  ·  Rutas: <N>  ·  Stack: <Next 16 | Vite | ...>

Core Web Vitals (mobile, throttling 4G simulado):
  /              LCP <X.Xs>   INP <Xms>   CLS <X.XX>   TTFB <Xms>   score <NN>
  /dashboard     ...
  /clientes/[id] ...

Bundle (First Load JS):
  ruta peor: <ruta> -> <KB> kB
  chunk culpable: <nombre> (<KB> kB)
  o "no auditado: falta build reciente"

Antipatrones detectados: <N>
  ALTO  · <patron> · <fichero:linea>  (impacto: ...)
  MEDIO · ...

Imagenes:
  hero LCP sin priority: si/no
  imagenes > 200KB en public/: <N>
  candidatos a AVIF/WebP: <N>

Acciones priorizadas (top 5):
  1. <accion concreta, ruta y resultado esperado en LCP/INP/bundle>
  2. ...

Bottlenecks no auditables aqui:
  - Supabase slow queries -> Supabase Studio > Reports > Slow queries
  - Sentry p95 transactions -> Sentry > Performance
  - CDN / edge -> verificar en panel de Vercel
```

Criterios de color:
- **VERDE**: LCP < 2.5s y INP < 200ms y CLS < 0.1 en TODAS las rutas auditadas, sin antipatrones ALTO.
- **AMARILLO**: 1-2 metricas fuera de objetivo o antipatrones ALTO presentes pero arreglables sin refactor mayor.
- **ROJO**: >= 3 metricas fuera o LCP > 4s o antipatrones criticos (RSC inflado, force-dynamic en home).

## Restricciones absolutas

- **No edites ningun fichero del proyecto.**
- **No instales deps globales** (`npm i -g`). Lighthouse via `npx -y` esta bien (efimero).
- **No lances `next build`** por iniciativa propia. Pide al usuario.
- **No te conectes a la BD ni a servicios externos** (Supabase, Sentry, Vercel API). Solo dirige al usuario al panel correspondiente.
- **No hagas peticiones HTTP** a la URL salvo via Lighthouse.
- Si Lighthouse falla, reporta el resto sin abortar — los antipatrones y el bundle se pueden auditar sin Lighthouse.

## Cuando NO usar esta skill

- El usuario quiere **arreglar** los bottlenecks -> trabajar directamente con cada uno, no esta skill.
- El usuario quiere optimizar **percepcion** / animaciones / micro-interacciones -> usar `impeccable` o `gsap-react`.
- El usuario quiere optimizar **diseno visual** -> usar `ui-ux-pro-max` o `redesign-existing-projects`.
- El usuario quiere medir **SEO o accesibilidad** -> Lighthouse aparte con `--only-categories=seo,accessibility`. Esta skill solo cubre performance.
