---
name: tests-status
description: Audita el estado de cobertura de tests de un proyecto. Lanza el suite unitario, detecta huecos (cripto sin tests, Server Actions sin tests, RLS sin tests, componentes 'use client' criticos sin tests), reporta verde/amarillo/rojo. No modifica codigo. Usa esta skill cuando el usuario diga: comprueba el estado de tests, estado tests, audita tests, test status, test audit, salud del testing, cobertura del proyecto, que falta cubrir, o invoque /tests-status.
origin: personalizada (basada en convencion CLAUDE.md del workspace)
---

# Auditoria de estado de tests

Esta skill audita un proyecto para reportar el estado de su cobertura de tests.
**No modifica codigo. No anade tests. Solo reporta.**

## Pasos a ejecutar

### 1. Verificar que tdd-workflow esta instalada
```bash
ls "$HOME/.claude/skills/tdd-workflow/SKILL.md" 2>/dev/null
```
Si no existe, decir al usuario:
> tdd-workflow no esta instalada en `~/.claude/skills/`. Algunas recomendaciones de esta auditoria asumen su disponibilidad. Continua igualmente o instalala primero.

No bloquees el resto de la auditoria por esto.

### 2. Detectar el runner
Lee `package.json`:
- Si tiene `vitest` o `jest` en deps/devDeps y un script `test`, sigue.
- Si no hay runner, reporta el estado como **ROJO** con la causa y termina.

Anota tambien:
- Si existe `vitest.integration.config.ts` o similar.
- Si existe `playwright.config.*` (E2E).

### 3. Lanzar el suite unitario
```bash
npm test
```
Captura:
- numero de tests passed / total / skipped
- duracion total
- archivos de test (cuenta con glob `**/*.test.{ts,tsx,js,jsx}` excluyendo `node_modules` y `tests/integration/`).

Si `npm test` falla con codigo != 0:
- Lista los archivos que fallaron y el primer mensaje de error de cada uno.
- No diagnostiques en profundidad. Solo reporta.

### 4. Tests de integracion — NO lanzar
Si hay script `test:integration` (o equivalente):
- Lee la config (`vitest.integration.config.ts` o similar) y el `setup.ts` de la carpeta de integracion.
- Reporta que requisitos pide: env vars necesarias, si apunta a BD local o cloud, si crea/borra usuarios.
- **Avisa explicitamente** si las env vars de `.env.local` apuntan a un dominio de produccion en vez de `localhost`/`127.0.0.1`.
- **No ejecutes** `npm run test:integration` salvo que el usuario lo pida de forma explicita en su mensaje.

### 5. Auditoria de huecos por categoria

Aplica esta tabla. Silencia las categorias que no apliquen al stack (ej: si no hay carpeta `app/`, ignora Server Actions).

| Categoria | Ruta a escanear | Criterio "sin test" |
|---|---|---|
| **Cripto / Seguridad** | `lib/crypto/**/*.ts`, `lib/auth/**/*.ts`, `lib/security/**/*.ts` | falta `.test.ts` hermano |
| **Server Actions** | `app/**/actions.ts`, `app/**/actions/*.ts` | falta `.test.ts` hermano |
| **RLS (integracion)** | tablas declaradas en `supabase/migrations/*.sql` (CREATE TABLE) | falta cobertura en `tests/integration/rls*.test.ts` |
| **Componentes UI criticos** | `components/**/*.tsx` con `"use client"` que toquen forms, auth, crypto, pagos, o entrada de PII | falta `.test.tsx` hermano |
| **Calculos de dominio** | `lib/**/{calculo,facturacion,impuestos,verifactu,*-pricing}*.ts` | falta `.test.ts` hermano |

Para cada hueco, asigna prioridad:
- **Alto**: cripto, RLS, calculos fiscales/economicos, auth, pagos.
- **Medio**: Server Actions, UI con forms o entrada de PII.
- **Bajo**: UI puramente presentacional, helpers triviales.

### 6. Reporte final

Devuelve **un solo bloque** en este formato. Sin parrafos de relleno.

```
ESTADO: <VERDE | AMARILLO | ROJO>
Tests: <passed>/<total> (<skipped> skipped) · <duracion>s · <num_archivos> archivos

Integracion: <no aplica | presente · <pre-requisitos> | apunta a PRODUCCION (riesgo)>
E2E: <no aplica | playwright configurado: si/no>

Huecos priorizados:
  ALTO    · <categoria> · <N> ficheros sin test
            ejemplos: <hasta 3 paths relativos>
  MEDIO   · ...
  BAJO    · ...

Acciones siguientes (1-3):
  1. <accion concreta con la ruta o comando>
  2. ...
```

Criterios de color:
- **VERDE**: suite unitario pasa, no hay huecos en categoria Alto.
- **AMARILLO**: suite unitario pasa pero hay huecos Alto, o hay tests skipped sospechosos.
- **ROJO**: suite unitario falla, no hay runner, o env vars de integracion apuntan a produccion sin proteccion.

## Restricciones absolutas

- **No edites ningun fichero del proyecto.** Ni de tests, ni de codigo, ni de config.
- **No instales dependencias.**
- **No lances `test:integration`** salvo peticion explicita del usuario en el mensaje actual.
- **No expandas la auditoria** a otras dimensiones (lint, typecheck, build) salvo peticion explicita.
- **No sugieras instalar libs nuevas** dentro del reporte. Eso es decision del usuario tras leer el estado.

## Cuando NO usar esta skill

- El usuario quiere **escribir** tests nuevos -> usar `tdd-workflow`.
- El usuario quiere **arreglar** un test fallando -> trabajar directamente con `npm test` y debug.
- El usuario quiere auditar varios proyectos en paralelo -> sugerir spawnear un subagente por proyecto en vez de invocar esta skill 16 veces.
