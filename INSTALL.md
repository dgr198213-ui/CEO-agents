# CEO-Agents - Guia de Instalacion

Esta guia cubre la instalacion y configuracion del entorno de desarrollo local para CEO-Agents.

## Requisitos del Sistema

| Componente | Version Minima | Notas |
|------------|---------------|-------|
| Sistema Operativo | Linux (Ubuntu 22.04+) / macOS 13+ / Windows (WSL2) | |
| Nim | 2.0.8+ | Instalado via choosenim |
| GCC | 9.0+ | Para compilar el backend Nim |
| Node.js | 22+ | Para el frontend Next.js |
| pnpm | 10+ | Gestor de paquetes del frontend |
| Docker | 24+ | Para despliegue con contenedores |
| Docker Compose | 2.20+ | Para orquestacion del stack |
| PostgreSQL | 15+ | Base de datos (o via Docker) |

## Instalacion Rapida con Docker (Recomendada)

La forma mas sencilla de levantar el proyecto completo es con Docker Compose:

```bash
git clone https://github.com/dgr198213-ui/CEO-agents.git
cd CEO-agents
cp .env.example .env
cp frontend/.env.example frontend/.env.local
docker-compose up -d
```

El panel de control estara disponible en `http://localhost:3000` y la API en `http://localhost:8080`.

## Instalacion Manual

### 1. Instalar Nim

```bash
# Instalar choosenim (gestor de versiones de Nim)
curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y

# Anadir al PATH (anadir tambien a ~/.bashrc o ~/.zshrc)
export PATH="$HOME/.nimble/bin:$PATH"

# Verificar instalacion
nim --version
```

Alternativamente, usa el script incluido:

```bash
./scripts/install_nim.sh
```

### 2. Compilar el Backend

```bash
# Compilar todos los modulos y ejemplos
./build.sh

# Solo el servidor API
./build.sh api

# Modo release (optimizado)
./build.sh --release api

# Con soporte SQLite
./build.sh --sqlite api
```

El binario compilado se encontrara en `bin/api_wrapper`.

### 3. Instalar el Frontend

```bash
cd frontend
pnpm install
```

### 4. Configurar Variables de Entorno

```bash
# Backend
cp .env.example .env

# Frontend
cp frontend/.env.example frontend/.env.local
```

Edita los archivos `.env` y `frontend/.env.local` con tus configuraciones.

### 5. Configurar la Base de Datos

**Opcion A: PostgreSQL con Docker**

```bash
docker run -d \
  --name ceo-agents-db \
  -e POSTGRES_DB=ceo_agents \
  -e POSTGRES_USER=ceo \
  -e POSTGRES_PASSWORD=ceo_secret \
  -p 5432:5432 \
  postgres:16-alpine
```

Aplicar migraciones:

```bash
psql postgresql://ceo:ceo_secret@localhost:5432/ceo_agents \
  -f database/migrations/001_initial_schema.sql

psql postgresql://ceo:ceo_secret@localhost:5432/ceo_agents \
  -f database/seed.sql
```

**Opcion B: PostgreSQL local**

```bash
createdb ceo_agents
psql ceo_agents -f database/migrations/001_initial_schema.sql
psql ceo_agents -f database/seed.sql
```

### 6. Configurar el LLM

CEO-Agents soporta múltiples proveedores de LLM. Puedes configurarlos a través del panel de `Configuración` en el frontend.

**Proveedores Soportados:**

*   **Ollama (Local):** Ejecuta modelos LLM localmente. Ideal para desarrollo y privacidad.
    *   `ollama pull llama3`
    *   `CEO_LLM_PROVIDER=ollama`, `CEO_LLM_MODEL=llama3`, `CEO_LLM_BASE_URL=http://localhost:11434`
*   **OpenAI:** Acceso a GPT-4, GPT-3.5 y otros modelos de última generación.
    *   `CEO_LLM_PROVIDER=openai`, `CEO_LLM_MODEL=gpt-4o-mini`, `OPENAI_API_KEY=sk-...`
*   **Anthropic:** Acceso a Claude, un modelo de IA de última generación con excelente razonamiento.
    *   `CEO_LLM_PROVIDER=anthropic`, `CEO_LLM_MODEL=claude-3-haiku-20240307`, `ANTHROPIC_API_KEY=sk-ant-...`
*   **OpenRouter:** Acceso unificado a múltiples modelos (GPT-4, Claude, Llama, etc.) con una única API.
    *   `CEO_LLM_PROVIDER=openrouter`, `CEO_LLM_MODEL=openai/gpt-3.5-turbo`, `OPENROUTER_API_KEY=sk-or-...`
*   **Groq:** Inferencia ultra rápida con modelos de código abierto. Ideal para aplicaciones en tiempo real.
    *   `CEO_LLM_PROVIDER=groq`, `CEO_LLM_MODEL=mixtral-8x7b-32768`, `GROQ_API_KEY=gsk-...`
*   **DeepSeek:** Modelos económicos y eficientes con excelente relación calidad-precio.
    *   `CEO_LLM_PROVIDER=deepseek`, `CEO_LLM_MODEL=deepseek-chat`, `DEEPSEEK_API_KEY=sk-...`
*   **Mistral:** Modelos de IA de alto rendimiento con enfoque en privacidad y eficiencia.
    *   `CEO_LLM_PROVIDER=mistral`, `CEO_LLM_MODEL=mistral-small-latest`, `MISTRAL_API_KEY=sk-...`

## Ejecutar el Proyecto

### Modo Desarrollo

```bash
# Terminal 1: Backend API
./bin/api_wrapper

# Terminal 2: Frontend
cd frontend && pnpm dev
```

El panel de control estara disponible en `http://localhost:3000`.
La API REST estara disponible en `http://localhost:8080`.

### Modo Produccion (Docker)

```bash
docker-compose up -d
```

### Con Ollama (LLM Local)

```bash
docker-compose --profile ollama up -d
```

### Con Adminer (GUI de Base de Datos)

```bash
docker-compose --profile dev up -d
# Accede a http://localhost:8081
```

## Ejecutar Tests

```bash
# Todos los tests
./scripts/run_tests.sh

# Solo backend Nim
./scripts/run_tests.sh --nim-only

# Solo frontend
./scripts/run_tests.sh --frontend-only
```

## Verificar la Instalacion

```bash
# Verificar que la API responde
curl http://localhost:8080/api/v1/health

# Verificar agentes disponibles
curl http://localhost:8080/api/v1/agents

# Ejecutar una tarea de prueba
curl -X POST http://localhost:8080/api/v1/execute \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Hello world","taskType":"generic","priority":"low"}'
```

## Solucion de Problemas

**Error: `nim: command not found`**
Asegurate de que `~/.nimble/bin` esta en tu `PATH`. Anade `export PATH="$HOME/.nimble/bin:$PATH"` a tu `~/.bashrc` o `~/.zshrc`.

**Error de conexion a la base de datos**
Verifica que `DATABASE_URL` en `.env` es correcta y que PostgreSQL esta corriendo.

**Error de conexion al LLM**
Si usas Ollama, asegurate de que el servicio esta corriendo con `ollama serve`. Si usas OpenAI/Anthropic, verifica que la API key es valida.

**Puerto 8080 en uso**
Cambia `API_PORT` en `.env` y `NEXT_PUBLIC_API_URL` en `frontend/.env.local`.
