# 🧠 CEO-Agents v2.0

![CI](https://github.com/dgr198213-ui/CEO-agents/actions/workflows/ci.yml/badge.svg)
![Security](https://github.com/dgr198213-ui/CEO-agents/actions/workflows/security.yml/badge.svg)
![Release](https://github.com/dgr198213-ui/CEO-agents/actions/workflows/release.yml/badge.svg)

**CEO-Agents** es un sistema avanzado de inteligencia artificial distribuida, escrito en **Nim** para máximo rendimiento, que orquesta un enjambre de agentes especializados a través de un "CEO Agent" central. Incluye algoritmos genéticos para evolución de agentes, ejecución segura en sandbox, y un panel de control moderno en **Next.js 15**.

## ✨ Características Principales

- 🚀 **Rendimiento Nativo:** Backend escrito en Nim, compilado a C, sin dependencias pesadas de runtime.
- 🧠 **Evolución Genética:** Los agentes mejoran su performance mediante algoritmos genéticos (mutación, crossover, selección por torneo).
- 🛡️ **Ejecución Segura:** Sandboxing integrado para ejecución de comandos shell con lista blanca y timeouts estrictos.
- 🤖 **Stack Especializado:** Agentes pre-configurados para Python, TypeScript, DevOps, Frontend, Backend, Seguridad y Testing.
- 📊 **Panel de Control:** Dashboard moderno en Next.js 15 + TailwindCSS + React Query para monitoreo en tiempo real.
- 🔌 **API REST:** API completa para integración con otros sistemas.
- 🗄️ **Base de Datos:** Soporte para PostgreSQL (producción) y SQLite (desarrollo local) via Prisma ORM.
- 🔄 **CI/CD Integrado:** Workflows de GitHub Actions para testing, análisis estático y despliegue automático.

## 🏗️ Arquitectura

El sistema se divide en tres capas principales:

1. **Capa Cognitiva (Backend Nim):**
   - `CEO Agent`: Enruta tareas, evalúa resultados y coordina el enjambre.
   - `Agent Execution Engine`: Motor de ejecución asíncrono y sandboxing.
   - `Evolution Core`: Algoritmos genéticos para mejora continua.
   - `Tool Registry`: Registro centralizado de herramientas (Shell, HTTP, FS).

2. **Capa de Persistencia (PostgreSQL / SQLite):**
   - Histórico de ejecuciones, métricas de agentes y artefactos generados.

3. **Capa de Presentación (Frontend Next.js):**
   - Panel de control interactivo para monitoreo y ejecución de tareas.

## 🚀 Instalación y Despliegue

### Requisitos Previos

- Docker y Docker Compose (recomendado)
- Node.js 22+ y pnpm (para desarrollo frontend)
- Nim 2.0.8+ (para desarrollo backend)

### Despliegue con Docker (Recomendado)

La forma más rápida de levantar todo el stack (Backend + Frontend + Base de Datos) es usando Docker Compose:

```bash
# 1. Clonar el repositorio
git clone https://github.com/dgr198213-ui/CEO-agents.git
cd CEO-agents

# 2. Configurar variables de entorno
cp .env.example .env
cp frontend/.env.example frontend/.env.local

# 3. Levantar el stack completo
docker-compose up -d

# 4. Aplicar migraciones de base de datos
docker-compose exec db psql -U ceo -d ceo_agents -f /docker-entrypoint-initdb.d/001_initial_schema.sql
docker-compose exec db psql -U ceo -d ceo_agents -f /docker-entrypoint-initdb.d/seed.sql
```

El panel de control estará disponible en `http://localhost:3000` y la API en `http://localhost:8080`.

### Desarrollo Local

Ver [INSTALL.md](INSTALL.md) para instrucciones detalladas de configuración del entorno de desarrollo local.

## 📖 Documentación de la API

El backend expone una API REST en el puerto `8080`.

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/v1/health` | `GET` | Estado del sistema, uptime y métricas básicas. |
| `/api/v1/agents` | `GET` | Lista de agentes disponibles y su performance. |
| `/api/v1/tasks/types` | `GET` | Tipos de tareas soportadas por el sistema. |
| `/api/v1/execute` | `POST` | Ejecuta una nueva tarea. |
| `/api/v1/stats` | `GET` | Estadísticas detalladas y snapshots del sistema. |

### Ejemplo de Ejecución de Tarea

```bash
curl -X POST http://localhost:8080/api/v1/execute \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Generar API\",
    \"description\": \"Crear un endpoint REST para usuarios\",
    \"taskType\": \"code_generation\",
    \"priority\": \"high\"
  }"
```

## 🧪 Testing

El proyecto incluye una suite completa de tests para el backend (Nim) y el frontend (TypeScript).

```bash
# Ejecutar todos los tests
./scripts/run_tests.sh

# Solo tests del backend Nim
./scripts/run_tests.sh --nim-only

# Solo tests del frontend
./scripts/run_tests.sh --frontend-only
```

## 📁 Estructura del Repositorio

```text
CEO-agents/
├── src/                # Código fuente del backend (Nim)
├── examples/           # Ejemplos ejecutables de uso de la API interna
├── tests/              # Tests unitarios y de integración (Nim)
├── frontend/           # Panel de control (Next.js 15 + TailwindCSS)
├── database/           # Esquemas Prisma, migraciones SQL y seeds
├── scripts/            # Scripts de utilidad (instalación, tests, build)
├── docs/               # Documentación adicional y logs históricos
├── .github/workflows/  # Pipelines de CI/CD (GitHub Actions)
├── build.sh            # Script de compilación del backend
├── Dockerfile          # Dockerfile del backend
└── docker-compose.yml  # Orquestación del stack completo
```

## 🤝 Contribuciones y Open Source

CEO-Agents es un proyecto **Open Source** y damos la bienvenida a cualquier persona que quiera colaborar. 

- 📜 **Licencia:** MIT (ver [LICENSE](LICENSE)).
- 🚀 **Guía de Contribución:** Revisa [CONTRIBUTING.md](CONTRIBUTING.md) para empezar.
- 🧬 **Comunidad:** Ayúdanos a evolucionar el enjambre de agentes.

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.
