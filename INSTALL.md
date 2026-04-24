# Guía de Instalación — CEO-Agents

## Requisitos del Sistema

| Componente | Versión Mínima | Notas |
|---|---|---|
| **Nim** | 2.0.0+ | Lenguaje principal del proyecto |
| **GCC** | 9.0+ | Compilador C backend para Nim |
| **Sistema Operativo** | Linux, macOS, Windows | Probado en Ubuntu 22.04+ y macOS 13+ |
| **RAM** | 512 MB | Para compilación y ejecución de ejemplos |
| **Disco** | 200 MB | Incluyendo toolchain de Nim |

---

## Instalación Rápida (Recomendada)

El método más sencillo es usar el script de instalación automático:

```bash
git clone https://github.com/dgr198213-ui/CEO-agents.git
cd CEO-agents
chmod +x install.sh
./install.sh
```

El script realiza automáticamente:
1. Verifica e instala `gcc` si es necesario
2. Instala Nim via `choosenim` si no está presente
3. Compila todos los módulos y ejemplos
4. Genera ejecutables en el directorio `./bin/`

---

## Instalación Manual

### Paso 1: Instalar GCC

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y gcc g++ build-essential
```

**macOS:**
```bash
xcode-select --install
```

**Windows:** Instalar [MinGW-w64](https://www.mingw-w64.org/) o usar WSL2.

### Paso 2: Instalar Nim

**Método recomendado — choosenim:**
```bash
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```

Añadir al PATH (agregar a `~/.bashrc` o `~/.zshrc`):
```bash
export PATH="$HOME/.nimble/bin:$PATH"
```

**Verificar instalación:**
```bash
nim --version
# Nim Compiler Version 2.x.x
```

### Paso 3: Clonar el Repositorio

```bash
git clone https://github.com/dgr198213-ui/CEO-agents.git
cd CEO-agents
```

### Paso 4: Compilar el Proyecto

**Opción A — Script de build:**
```bash
chmod +x build.sh
./build.sh
```

**Opción B — Nimble:**
```bash
nimble build
```

**Opción C — Compilación manual de un ejemplo:**
```bash
nim c -r example_integrated_ceo_stack.nim
```

---

## Ejecutar los Ejemplos

Una vez compilado, los ejecutables se encuentran en `./bin/`:

```bash
# CEO + Stack Agents (ejemplo principal)
./bin/example_integrated_ceo_stack

# Swarm Intelligence
./bin/example_swarm

# Knowledge Agents con evolución
./bin/example_knowledge

# Co-evolución predador-presa
./bin/example_coevolution

# Foraging Behavior
./bin/example_foraging

# Sistema PWA Evolutivo
./bin/example_pwa_integrated
```

O compilar y ejecutar directamente:
```bash
nim c -r example_integrated_ceo_stack.nim
```

---

## Compilación en Modo Release

Para máximo rendimiento (recomendado para benchmarks):

```bash
./build.sh --release
# o
nim c -d:release --opt:speed example_integrated_ceo_stack.nim
```

---

## Estructura del Proyecto

```
CEO-agents/
├── agent_base.nim              # Clase base de todos los agentes
├── evolution_core.nim          # Motor evolutivo genérico
├── ceo_agent.nim               # Agente CEO principal
├── stack_agents.nim            # Stack de agentes especializados
├── neuro_agent.nim             # Agente con red neuronal
├── swarm_agent.nim             # Agente de enjambre
├── coevo_agent.nim             # Agente de co-evolución
├── knowledge_agent.nim         # Agente de gestión del conocimiento
├── cache_strategy_agent.nim    # Agente PWA: estrategias de caché
├── notification_agent.nim      # Agente PWA: notificaciones push
├── sync_agent.nim              # Agente PWA: sincronización offline
├── example_integrated_ceo_stack.nim  # Ejemplo: CEO completo
├── example_swarm.nim           # Ejemplo: Swarm
├── example_knowledge.nim       # Ejemplo: Knowledge
├── example_coevolution.nim     # Ejemplo: Co-evolución
├── example_foraging.nim        # Ejemplo: Foraging
├── example_pwa_integrated.nim  # Ejemplo: PWA completo
├── install.sh                  # Script de instalación
├── build.sh                    # Script de compilación
├── CEO.nimble                  # Configuración del paquete Nim
├── README.md                   # Documentación principal
├── START_HERE.md               # Guía de inicio rápido
└── INDEX.md                    # Índice del proyecto
```

---

## Solución de Problemas

### Error: `nim: command not found`

Asegúrate de que `~/.nimble/bin` está en tu PATH:
```bash
export PATH="$HOME/.nimble/bin:$PATH"
```

### Error: `gcc: command not found`

Instala las herramientas de compilación:
```bash
# Ubuntu/Debian
sudo apt-get install -y build-essential

# macOS
xcode-select --install
```

### Error de compilación en módulos

Verifica que tienes Nim 2.0.0 o superior:
```bash
nim --version
```

Si tienes una versión anterior, actualiza con choosenim:
```bash
choosenim update stable
```

### Ejemplo `example_knowledge` tarda mucho

Este ejemplo ejecuta evolución genética con muchas generaciones. Es normal que tome 1-5 minutos. Para una ejecución más rápida, compila en modo release:
```bash
nim c -d:release -r example_knowledge.nim
```

---

## Soporte

- Documentación completa: [README.md](README.md)
- Guía de inicio: [START_HERE.md](START_HERE.md)
- Índice de módulos: [INDEX.md](INDEX.md)
