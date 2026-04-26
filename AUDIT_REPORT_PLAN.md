# Auditoría Completa y Plan de Acción: CEO-Agents

## 1. Auditoría Completa del Repositorio

### Estado Actual
El proyecto es un sistema de orquestación de agentes evolutivos escrito en Nim. Cuenta con múltiples módulos de simulación (Swarm, Coevolución, Foraging) y un orquestador principal (`ceo_agent.nim`) que delega tareas a agentes especializados (`stack_agents.nim`). También incluye un motor de ejecución (`agent_execution_engine.nim`) y un wrapper de API REST (`api_wrapper.nim`).

### Problemas Identificados
1. **Errores y Dependencias Rotas:**
   - La compilación falla si no se tiene instalado el paquete `db_connector` (específicamente `db_sqlite`), requerido por `tool_registry.nim`.
   - `example_ceo_functional.nim` contiene TODOs sin implementar (línea 177: `TODO: Implement task logic`).
   - Dependencia circular o mal diseño en `agent_base.nim` y `tool_registry.nim` donde se comparte el enum `ToolCapability`. Aunque compila, el diseño de importaciones es frágil.

2. **Módulos Incompletos y TODOs:**
   - En `example_ceo_functional.nim`: La generación de código es simulada mediante strings quemados (línea 165+).
   - En `tool_registry.nim`: La herramienta `DatabaseQuery` asume que SQLite está disponible pero puede fallar si no está configurado correctamente.
   - Faltan implementaciones reales para muchas de las herramientas del sistema (actualmente la mayoría son mocks que devuelven strings estáticos o ejecutan comandos muy básicos).
   - El sistema de memoria de los agentes (`AgentMemory` en `agent_execution_engine.nim`) no persiste a largo plazo (solo en memoria RAM).

3. **Arquitectura y Estructura:**
   - **Monolítico:** Todos los archivos `.nim` están en la raíz del proyecto. No hay estructura de carpetas `src/`, `tests/`, `docs/`, etc.
   - **Inconsistencia de Nombres:** Algunos archivos usan camelCase y otros snake_case.
   - **Falta de Frontend:** No existe ninguna interfaz de usuario; todo se ejecuta por consola o mediante la API REST básica.
   - **Falta de Base de Datos Real:** Todo el estado se mantiene en memoria durante la ejecución, perdiéndose al finalizar.

## 2. Mapa del Proyecto

### Arquitectura Actual
```text
CEO-Agents/
├── agent_base.nim              (Interfaces base, Vectores, Genomas)
├── evolution_core.nim          (Algoritmos genéticos, Poblaciones)
├── llm_integration.nim         (Conexión con OpenAI, Anthropic, Ollama)
├── tool_registry.nim           (Herramientas de sistema, red, DB, código)
├── agent_execution_engine.nim  (Motor de ejecución de tareas, dependencias)
├── ceo_agent.nim               (Orquestador principal, ruteo evolutivo)
├── stack_agents.nim            (10 agentes especializados)
├── api_wrapper.nim             (API REST básica con asynchttpserver)
└── Ejemplos (example_*.nim)    (Simulaciones y demos funcionales)
```

### Cuellos de Botella y Puntos Críticos
- **Estado Efímero:** Al no haber base de datos, el aprendizaje evolutivo del CEO Agent se pierde tras cada ejecución.
- **Gestión de Errores en LLMs:** Si la API del LLM falla o devuelve JSON malformado, el motor de ejecución puede fallar silenciosamente o encolar la tarea indefinidamente.
- **Seguridad (Sandboxing):** Las herramientas de shell (`executeShell`) se ejecutan directamente en el host, lo cual es extremadamente peligroso para un sistema autónomo.

## 3. Plan de Acción (Roadmap)

### Fase 1: Reestructuración y Correcciones (Backend Nim)
- Mover todo el código fuente a `src/`.
- Mover ejemplos a `examples/`.
- Resolver el TODO en `example_ceo_functional.nim` implementando lógica real.
- Aislar y proteger la ejecución de comandos shell.

### Fase 2: Base de Datos y Persistencia
- Configurar PostgreSQL para persistir el genoma del CEO Agent, historial de tareas y memoria a largo plazo de los agentes.
- Crear un módulo `db_models.nim` o integrar Prisma a través de un servicio Node.js secundario. (Dado que es Nim, implementaremos persistencia directa con PostgreSQL).

### Fase 3: API y Frontend (Next.js 15 + Tailwind)
- Ampliar `api_wrapper.nim` para soportar CORS, WebSockets (para logs en tiempo real) y CRUD de agentes.
- Inicializar un proyecto Next.js 15 en la carpeta `frontend/`.
- Crear un dashboard para visualizar el grafo de agentes, estado de tareas y métricas de evolución.

### Fase 4: Testing y Documentación
- Crear carpeta `tests/` e implementar tests unitarios con `unittest` de Nim.
- Actualizar el README con la nueva estructura y generar documentación Swagger/OpenAPI para la API.

### Fase 5: CI/CD y Despliegue
- Crear Dockerfile multi-stage para compilar Nim y servir la API.
- Crear Dockerfile para el frontend Next.js.
- Configurar `docker-compose.yml` para levantar DB, API y Frontend.
- Crear GitHub Actions para test, build y lint.

## 4. Implementation Plan (Por Archivos)

1. **Reestructuración de Carpetas:**
   - Crear `src/`, `examples/`, `tests/`.
   - Modificar `build.sh` y `CEO.nimble` para apuntar a `src/`.

2. **`src/example_ceo_functional.nim`:**
   - Reemplazar el string estático de generación de código por una llamada real al LLM usando `llm_integration.nim`.

3. **`src/tool_registry.nim`:**
   - Añadir validación estricta y sandboxing básico (o advertencias) en `registerShellTools`.

4. **`src/api_wrapper.nim`:**
   - Añadir headers CORS.
   - Añadir endpoints: `GET /api/v1/agents`, `GET /api/v1/tasks`.

5. **`frontend/` (Nuevo):**
   - Inicializar Next.js 15 App Router.
   - Instalar TailwindCSS, Lucide Icons, Recharts (para métricas evolutivas).
   - Crear componentes: `AgentNetworkGraph`, `TaskQueue`, `EvolutionMetrics`.

6. **`docker-compose.yml` (Nuevo):**
   - Servicios: `postgres`, `nim-backend`, `next-frontend`.

7. **`.github/workflows/ci.yml` (Nuevo):**
   - Setup Nim, compilar core, ejecutar tests.

---
**ESPERANDO APROBACIÓN**
¿Apruebas este plan de acción? Si es así, procederé inmediatamente con la Fase 1 (Reestructuración y correcciones del código Nim) y la inicialización del Frontend.
