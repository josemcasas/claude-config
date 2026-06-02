---
name: tdd-workflow
description: Usa esta skill al escribir funcionalidades nuevas, arreglar bugs o refactorizar codigo. Impone desarrollo dirigido por pruebas con cobertura del 80%+ entre tests unitarios, de integracion y E2E.
origin: ECC (traducido y adaptado a Vitest + Next.js)
---

# Flujo de trabajo TDD

Esta skill garantiza que todo el desarrollo siga principios TDD con cobertura amplia.

## Cuando activarla

- Al escribir funcionalidades nuevas
- Al arreglar bugs o incidencias
- Al refactorizar codigo existente
- Al anadir endpoints de API
- Al crear componentes nuevos

## Principios fundamentales

### 1. Tests ANTES que codigo
SIEMPRE escribir los tests primero y luego implementar el codigo para hacerlos pasar.

### 2. Requisitos de cobertura
- Cobertura minima del 80% (unit + integration + E2E)
- Todos los casos limite cubiertos
- Escenarios de error testeados
- Condiciones de frontera verificadas

### 3. Tipos de test

#### Tests unitarios
- Funciones y utilidades individuales
- Logica de componentes
- Funciones puras
- Helpers y utilidades

#### Tests de integracion
- Endpoints de API
- Operaciones de base de datos
- Interacciones entre servicios
- Llamadas a APIs externas

#### Tests E2E (Playwright)
- Flujos criticos de usuario
- Workflows completos
- Automatizacion de navegador
- Interacciones UI

### 4. Checkpoints de Git
- Si el repo esta bajo Git, crear un commit de checkpoint despues de cada etapa TDD
- No hacer squash ni reescribir esos commits hasta que el workflow termine
- El mensaje de cada checkpoint debe describir la etapa y la evidencia exacta capturada
- Contar solo commits creados en la rama activa actual para la tarea actual
- No tratar commits de otras ramas, trabajo anterior no relacionado, o historia lejana como evidencia valida
- Antes de dar un checkpoint por satisfecho, verificar que el commit es alcanzable desde el `HEAD` actual de la rama activa y pertenece a la secuencia de la tarea actual
- El workflow compacto preferido es:
  - un commit para el test fallando y RED validado
  - un commit para el fix minimo aplicado y GREEN validado
  - un commit opcional para refactor completado
- No hacen falta commits separados solo de evidencia si el commit del test corresponde claramente a RED y el commit del fix corresponde claramente a GREEN

## Pasos del flujo TDD

### Paso 1: Escribir user journeys
```
Como [rol], quiero [accion], para [beneficio]

Ejemplo:
Como autonomo, quiero buscar clientes por nombre o NIF de forma difusa,
para encontrarlos rapido aunque no recuerde la grafia exacta.
```

### Paso 2: Generar casos de test
Para cada user journey, crear casos de test exhaustivos:

```typescript
import { describe, it, expect } from 'vitest'

describe('Busqueda de clientes', () => {
  it('devuelve clientes que coinciden con la query', async () => {
    // Implementacion del test
  })

  it('maneja query vacia sin romper', async () => {
    // Caso limite
  })

  it('cae a busqueda por subcadena cuando el indice no esta disponible', async () => {
    // Comportamiento de fallback
  })

  it('ordena resultados por puntuacion de similitud', async () => {
    // Logica de ordenacion
  })
})
```

### Paso 3: Ejecutar los tests (deben fallar)
```bash
npm test
# Los tests deben fallar — todavia no hemos implementado
```

Este paso es obligatorio y es la puerta RED para todo cambio en codigo de produccion.

Antes de modificar logica de negocio u otro codigo de produccion, hay que verificar un estado RED valido por una de estas vias:
- RED en tiempo de ejecucion:
  - El target de test relevante compila correctamente
  - El test nuevo o modificado se ejecuta de verdad
  - El resultado es RED
- RED en tiempo de compilacion:
  - El test nuevo instancia, referencia o ejercita el camino de codigo con el bug
  - El fallo de compilacion en si es la senal RED intencionada
- En cualquier caso, el fallo lo causa el bug de logica de negocio intencionado, comportamiento indefinido o implementacion ausente
- El fallo NO lo causan solo errores de sintaxis no relacionados, setup de test roto, dependencias faltantes o regresiones no relacionadas

Un test que solo se escribio pero no se compilo y ejecuto no cuenta como RED.

No editar codigo de produccion hasta confirmar este estado RED.

Si el repo esta bajo Git, crear un commit de checkpoint inmediatamente despues de validar esta etapa.
Formato recomendado del mensaje:
- `test: anade reproductor para <feature o bug>`
- Este commit puede servir tambien como checkpoint de validacion RED si el reproductor se compilo y ejecuto y fallo por el motivo intencionado
- Verifica que este commit esta en la rama activa actual antes de continuar

### Paso 4: Implementar codigo
Escribir el codigo minimo para que los tests pasen:

```typescript
// Implementacion guiada por los tests
export async function buscarClientes(query: string) {
  // Implementacion aqui
}
```

Si el repo esta bajo Git, deja el fix minimo en stage pero pospon el commit de checkpoint hasta validar GREEN en el Paso 5.

### Paso 5: Volver a ejecutar los tests
```bash
npm test
# Los tests ahora deben pasar
```

Re-ejecutar el mismo target de test relevante despues del fix y confirmar que el test que fallaba ahora esta GREEN.

Solo despues de un GREEN valido se puede proceder al refactor.

Si el repo esta bajo Git, crear un commit de checkpoint inmediatamente despues de validar GREEN.
Formato recomendado del mensaje:
- `fix: <feature o bug>`
- El commit del fix puede servir tambien como checkpoint GREEN si el mismo target de test se re-ejecuto y paso
- Verifica que este commit esta en la rama activa actual antes de continuar

### Paso 6: Refactor
Mejorar la calidad del codigo manteniendo los tests en verde:
- Eliminar duplicacion
- Mejorar nombres
- Optimizar rendimiento
- Mejorar legibilidad

Si el repo esta bajo Git, crear un commit de checkpoint inmediatamente despues de completar el refactor con los tests en verde.
Formato recomendado del mensaje:
- `refactor: limpieza tras la implementacion de <feature o bug>`
- Verifica que este commit esta en la rama activa actual antes de dar el ciclo TDD por completo

### Paso 7: Verificar cobertura
```bash
npm run test:coverage
# Verifica que se alcanza el 80%+ de cobertura
```

## Patrones de testing

### Patron de test unitario (Vitest)
```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Componente Button', () => {
  it('renderiza con el texto correcto', () => {
    render(<Button>Pulsa aqui</Button>)
    expect(screen.getByText('Pulsa aqui')).toBeInTheDocument()
  })

  it('llama a onClick al pulsar', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>Pulsa</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('esta deshabilitado cuando la prop disabled es true', () => {
    render(<Button disabled>Pulsa</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### Patron de test de integracion de API (Next.js App Router)
```typescript
import { describe, it, expect } from 'vitest'
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/clientes', () => {
  it('devuelve clientes correctamente', async () => {
    const request = new NextRequest('http://localhost/api/clientes')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('valida los query params', async () => {
    const request = new NextRequest('http://localhost/api/clientes?limit=invalido')
    const response = await GET(request)

    expect(response.status).toBe(400)
  })

  it('maneja errores de base de datos sin romper', async () => {
    // Simular fallo de Supabase
    const request = new NextRequest('http://localhost/api/clientes')
    // Probar manejo de error
  })
})
```

### Patron de test E2E (Playwright)
```typescript
import { test, expect } from '@playwright/test'

test('el usuario puede buscar y filtrar clientes', async ({ page }) => {
  await page.goto('/')
  await page.click('a[href="/clientes"]')

  await expect(page.locator('h1')).toContainText('Clientes')

  await page.fill('input[placeholder="Buscar clientes"]', 'acme')

  // Espera al debounce y a los resultados
  await page.waitForTimeout(600)

  const resultados = page.locator('[data-testid="cliente-card"]')
  await expect(resultados).toHaveCount(5, { timeout: 5000 })

  const primero = resultados.first()
  await expect(primero).toContainText('acme', { ignoreCase: true })

  await page.click('button:has-text("Activos")')
  await expect(resultados).toHaveCount(3)
})

test('el usuario puede crear un cliente nuevo', async ({ page }) => {
  await page.goto('/clientes/nuevo')

  await page.fill('input[name="nombre"]', 'Cliente de prueba')
  await page.fill('input[name="nif"]', 'B12345678')
  await page.fill('input[name="email"]', 'test@cliente.com')

  await page.click('button[type="submit"]')

  await expect(page.locator('text=Cliente creado correctamente')).toBeVisible()
  await expect(page).toHaveURL(/\/clientes\/[a-f0-9-]+$/)
})
```

## Organizacion de ficheros de test

```
app/
  (app)/
    clientes/
      page.tsx
      actions.ts
      actions.test.ts         # tests de Server Actions
components/
  clientes/
    ClienteCard.tsx
    ClienteCard.test.tsx       # tests unitarios
lib/
  crypto/
    vault.ts
    vault.test.ts              # tests unitarios criticos
e2e/
  clientes.spec.ts             # E2E
  boveda.spec.ts
  auth.spec.ts
```

## Mockear servicios externos

### Mock de Supabase
```typescript
import { vi } from 'vitest'

vi.mock('@/lib/supabase/server', () => ({
  createClient: vi.fn(() => ({
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => Promise.resolve({
          data: [{ id: '1', nombre: 'Cliente prueba' }],
          error: null
        }))
      }))
    }))
  }))
}))
```

### Mock de Anthropic (cuando el codigo usa el SDK)
```typescript
import { vi } from 'vitest'

vi.mock('@anthropic-ai/sdk', () => ({
  default: vi.fn(() => ({
    messages: {
      create: vi.fn(() => Promise.resolve({
        content: [{ type: 'text', text: 'respuesta mockeada' }]
      }))
    }
  }))
}))
```

### Mock de Web Crypto (boveda)
```typescript
// Vitest expone crypto.subtle en el entorno jsdom o node:18+.
// Si hace falta, polyfill explicito:
import { webcrypto } from 'node:crypto'
vi.stubGlobal('crypto', webcrypto)
```

## Verificacion de cobertura

### Ejecutar reporte de cobertura
```bash
npm run test:coverage
```

### Umbrales de cobertura (Vitest)
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80
      }
    }
  }
})
```

## Errores comunes a evitar

### MAL: Testear detalles de implementacion
```typescript
// No testear estado interno
expect(componente.state.contador).toBe(5)
```

### BIEN: Testear comportamiento visible al usuario
```typescript
// Testear lo que el usuario ve
expect(screen.getByText('Contador: 5')).toBeInTheDocument()
```

### MAL: Selectores fragiles
```typescript
// Se rompe a la minima
await page.click('.css-class-xyz')
```

### BIEN: Selectores semanticos
```typescript
// Resiliente a cambios
await page.click('button:has-text("Enviar")')
await page.click('[data-testid="submit-button"]')
```

### MAL: Tests sin aislamiento
```typescript
// Los tests dependen unos de otros
test('crea usuario', () => { /* ... */ })
test('actualiza el mismo usuario', () => { /* depende del anterior */ })
```

### BIEN: Tests independientes
```typescript
// Cada test crea sus propios datos
test('crea usuario', () => {
  const usuario = crearUsuarioPrueba()
  // Logica
})

test('actualiza usuario', () => {
  const usuario = crearUsuarioPrueba()
  // Logica de actualizacion
})
```

## Testing continuo

### Modo watch durante el desarrollo
```bash
npm test -- --watch
# Los tests se ejecutan automaticamente al cambiar ficheros
```

### Hook pre-commit
```bash
# Antes de cada commit
npm test && npm run lint
```

### Integracion CI/CD
```yaml
# GitHub Actions
- name: Ejecutar tests
  run: npm test -- --coverage
- name: Subir cobertura
  uses: codecov/codecov-action@v3
```

## Buenas practicas

1. **Tests primero** — siempre TDD
2. **Una assertion por test** — foco en un solo comportamiento
3. **Nombres descriptivos** — explican que se prueba
4. **Arrange-Act-Assert** — estructura clara
5. **Mockear dependencias externas** — aislar tests unitarios
6. **Probar casos limite** — null, undefined, vacios, grandes
7. **Probar rutas de error** — no solo el camino feliz
8. **Mantener tests rapidos** — unitarios < 50 ms cada uno
9. **Limpiar despues de cada test** — sin efectos secundarios
10. **Revisar reportes de cobertura** — identificar huecos

## Metricas de exito

- 80%+ de cobertura alcanzado
- Todos los tests pasando (verde)
- Sin tests saltados ni desactivados
- Ejecucion rapida (< 30s para unitarios)
- E2E cubre flujos criticos
- Los tests cazan bugs antes de produccion

---

**Recuerda**: los tests no son opcionales. Son la red de seguridad que permite refactorizar con confianza, desarrollar rapido y mantener fiabilidad en produccion.
