# CEO-Agents - Base de Datos

## Stack

- **ORM**: Prisma (recomendado para el frontend Next.js)
- **Base de datos**: PostgreSQL (producción) / SQLite (desarrollo local)
- **Migraciones**: SQL puro (`migrations/`) + Prisma Migrate

## Configuración Rápida (PostgreSQL local con Docker)

```bash
# 1. Levantar PostgreSQL con Docker
docker run -d \
  --name ceo-agents-db \
  -e POSTGRES_DB=ceo_agents \
  -e POSTGRES_USER=ceo \
  -e POSTGRES_PASSWORD=ceo_secret \
  -p 5432:5432 \
  postgres:16-alpine

# 2. Configurar variable de entorno
echo 'DATABASE_URL="postgresql://ceo:ceo_secret@localhost:5432/ceo_agents"' > .env

# 3. Aplicar migración inicial
psql postgresql://ceo:ceo_secret@localhost:5432/ceo_agents -f database/migrations/001_initial_schema.sql

# 4. Aplicar seed inicial
psql postgresql://ceo:ceo_secret@localhost:5432/ceo_agents -f database/seed.sql
```

## Configuración con Prisma (frontend Next.js)

```bash
cd frontend

# Instalar Prisma
pnpm add -D prisma
pnpm add @prisma/client

# Copiar schema
cp ../database/schema.prisma prisma/schema.prisma

# Generar cliente
npx prisma generate

# Aplicar migraciones
npx prisma migrate dev --name init

# Seed
npx prisma db seed
```

## Configuración SQLite (desarrollo local sin Docker)

```bash
# .env
DATABASE_URL="file:./dev.db"

# Cambiar provider en schema.prisma:
# datasource db {
#   provider = "sqlite"
#   url      = env("DATABASE_URL")
# }

npx prisma migrate dev --name init
```

## Estructura de Tablas

| Tabla              | Descripción                                    |
|--------------------|------------------------------------------------|
| `agents`           | Agentes del stack CEO con sus especializaciones |
| `tasks`            | Tareas ejecutadas con resultados y métricas     |
| `artifacts`        | Artefactos generados por las tareas             |
| `agent_metrics`    | Histórico de performance por agente             |
| `system_snapshots` | Snapshots periódicos del estado del sistema     |
| `system_config`    | Configuración clave-valor del sistema           |

## Variables de Entorno Requeridas

```env
DATABASE_URL="postgresql://user:password@host:5432/dbname"
```

## Migraciones

Las migraciones se encuentran en `migrations/` en formato SQL puro para máxima compatibilidad:

```
migrations/
  001_initial_schema.sql   # Schema inicial completo
```

Para agregar una nueva migración:
1. Crea el archivo `migrations/00N_descripcion.sql`
2. Aplícalo con `psql $DATABASE_URL -f migrations/00N_descripcion.sql`
3. Si usas Prisma: `npx prisma migrate dev --name descripcion`
