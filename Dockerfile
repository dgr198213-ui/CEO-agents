# ============================================================================
# CEO-Agents - Dockerfile (Backend Nim)
# ============================================================================
# Multi-stage build para imagen mínima de producción.
# Stage 1: Compilación con Nim
# Stage 2: Imagen runtime mínima (debian-slim)
# ============================================================================

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS builder

ARG NIM_VERSION=2.0.8
ARG BUILD_DATE
ARG GIT_SHA

LABEL org.opencontainers.image.title="CEO-Agents API"
LABEL org.opencontainers.image.description="Sistema de Agentes Evolutivos CEO - Backend"
LABEL org.opencontainers.image.version="${NIM_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${GIT_SHA}"

# Dependencias de compilación
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    libc6-dev \
    ca-certificates \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Instalar Nim via choosenim
RUN curl -sSf https://nim-lang.org/choosenim/init.sh | sh -s -- -y
ENV PATH="/root/.nimble/bin:/root/.choosenim/toolchains/nim-${NIM_VERSION}/bin:${PATH}"

# Verificar instalación
RUN nim --version && nimble --version

# Directorio de trabajo
WORKDIR /build

# Copiar código fuente
COPY src/ ./src/
COPY CEO.nimble ./

# Compilar el servidor API en modo release
RUN nim c \
    -d:release \
    --opt:speed \
    --hints:off \
    --warnings:off \
    --threads:off \
    -o:/build/ceo-api \
    src/api_wrapper.nim

# Verificar que el binario existe y es ejecutable
RUN ls -la /build/ceo-api && file /build/ceo-api

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

# Dependencias mínimas de runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Usuario no-root para seguridad
RUN groupadd -r ceo && useradd -r -g ceo -s /sbin/nologin ceo

WORKDIR /app

# Copiar binario compilado
COPY --from=builder /build/ceo-api /app/ceo-api
RUN chmod +x /app/ceo-api

# Cambiar a usuario no-root
USER ceo

# Variables de entorno por defecto
ENV CEO_PORT=8080
ENV CEO_HOST=0.0.0.0
ENV CEO_LLM_PROVIDER=ollama
ENV CEO_LLM_MODEL=llama3
ENV CEO_LOG_LEVEL=info

# Exponer puerto
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/api/v1/health || exit 1

# Punto de entrada
ENTRYPOINT ["/app/ceo-api"]
