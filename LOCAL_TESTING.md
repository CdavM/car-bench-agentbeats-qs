# Local Testing Guide

This guide explains the two ways to test your AgentBeats scenarios locally before deploying to GitHub Actions.

## Overview

AgentBeats provides two local testing approaches:

### 🐍 Direct Python Execution (Fast Development)
- **Use case**: Rapid iteration, debugging with breakpoints, code changes
- **Speed**: Fastest - no Docker builds
- **Setup**: Run agents directly on your machine
- **Config**: `scenarios/scenario.toml`

### 🐳 Docker Compose (Pre-Production Testing)
- **Use case**: Testing before deployment, validating Docker setup
- **Speed**: Slower (Docker builds) but matches production exactly
- **Setup**: Automated with `generate_compose.py`
- **Config**: `scenarios/scenario-docker-local.toml`

**Recommendation**: Use Python for development, Docker for final validation before GitHub Actions.

---

## Method 1: Direct Python Execution

### Quick Start

```bash
# 1. Install dependencies
pip install -e .
pip install -e external/car_bench

# 2. Set up environment
cp .env.example .env
# Edit .env with your API keys:
#   ANTHROPIC_API_KEY=sk-ant-...
#   OPENAI_API_KEY=sk-...
#   GEMINI_API_KEY=...

# 3. In terminal 1: Start purple agent
python src/purple_car_bench_agent/server.py \
    --host 127.0.0.1 --port 8080 \
    --agent-llm anthropic/claude-haiku-4-5-20251001

# 4. In terminal 2: Start green evaluator
python src/green_car_bench_agent/server.py \
    --host 127.0.0.1 --port 8081

# 5. In terminal 3: Run evaluation
python src/agentbeats/run_scenario.py \
    --scenario scenarios/scenario.toml

# 6. View results
cat results.json
```

### Configuration

`scenarios/scenario.toml`:
```toml
[green_agent]
endpoint = "http://127.0.0.1:8081"
cmd = "python src/green_car_bench_agent/server.py --host 127.0.0.1 --port 8081"

[[participants]]
role = "agent"
endpoint = "http://127.0.0.1:8080"
cmd = "python src/purple_car_bench_agent/server.py --host 127.0.0.1 --port 8080 --agent-llm anthropic/claude-haiku-4-5-20251001"

[config]
num_trials = 2
tasks_base_start_index = 0
tasks_base_end_index = 3  # Small number for quick tests
max_steps = 20
```

### Benefits
- ✅ Fastest iteration cycle
- ✅ Easy debugging with breakpoints
- ✅ No Docker overhead
- ✅ Live code reloading

### Use This When
- Making code changes to agent logic
- Debugging issues with pdb/debugger
- Testing new features quickly
- Iterating on prompts or tool implementations

---

## Method 2: Docker Compose Testing

### Quick Start

```bash
# 1. Install script dependencies
pip install tomli tomli-w

# 2. Set up environment
cp .env.example .env
# Edit .env with your API keys

# 3. Generate docker-compose.yml
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml

# 4. Run evaluation (automatically builds images)
mkdir -p output
docker compose up --abort-on-container-exit

# 5. View results
cat output/results.json
```

### What This Does

The `generate_compose.py` tool:
- ✅ Reads `scenario-docker-local.toml` configuration
- ✅ Substitutes environment variables from `.env` file
- ✅ Generates `docker-compose.yml` with build contexts
- ✅ Sets up proper Docker networking between agents
- ✅ Includes agentbeats-client for orchestration
- ✅ Runs the full assessment in isolated containers
- ✅ Saves results to `output/results.json`

### Configuration

`scenarios/scenario-docker-local.toml`:
```toml
[green_agent]
# Builds from local Dockerfile
build = { context = ".", dockerfile = "src/green_car_bench_agent/Dockerfile.car-bench-evaluator" }
env = { GEMINI_API_KEY = "${GEMINI_API_KEY}", LOGURU_LEVEL = "${LOGURU_LEVEL}" }

[[participants]]
# Builds from local Dockerfile
build = { context = ".", dockerfile = "src/purple_car_bench_agent/Dockerfile.car-bench-agent" }
name = "agent"
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    OPENAI_API_KEY = "${OPENAI_API_KEY}",
    AGENT_LLM = "anthropic/claude-haiku-4-5-20251001"  # Model selection via env var
}

[config]
num_trials = 2
tasks_base_start_index = 0
tasks_base_end_index = 3  # Small number for quick tests
```

### Benefits
- ✅ Matches production environment exactly
- ✅ Tests Docker builds before deployment
- ✅ Validates networking and health checks
- ✅ Catches environment-specific issues

### Use This When
- Final validation before GitHub Actions deployment
- Testing Docker configurations
- Verifying multi-container setup
- Ensuring production compatibility

---

## Comparison

| Feature | Direct Python | Docker Compose |
|---------|--------------|----------------|
| **Speed** | Fast (seconds) | Slower (builds images) |
| **Setup** | Manual (3 terminals) | Automated (1 command) |
| **Debugging** | Easy (breakpoints) | Harder (logs only) |
| **Isolation** | Shared environment | Full container isolation |
| **Production match** | Approximate | Exact |
| **When to use** | Development | Pre-deployment |

---

## Workflow Recommendations

### Development Cycle
```bash
# 1. Make code changes
vim src/purple_car_bench_agent/car_bench_agent.py

# 2. Test with Python (fast)
python src/purple_car_bench_agent/server.py --host 127.0.0.1 --port 8080 &
python src/green_car_bench_agent/server.py --host 127.0.0.1 --port 8081 &
python src/agentbeats/run_scenario.py --scenario scenarios/scenario.toml

# 3. Iterate quickly
# Kill servers, make changes, restart
```

### Pre-Deployment Validation
```bash
# 1. Final validation with Docker
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml
docker compose up --abort-on-container-exit

# 2. If tests pass, deploy
git add .
git commit -m "Update agent"
git push
```

---

## Environment Variable Substitution

Both methods use environment variables from `.env`:

```bash
# .env file
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-key-here
GEMINI_API_KEY=your-gemini-key
AGENT_LLM=anthropic/claude-haiku-4-5-20251001
LOGURU_LEVEL=INFO
```

In your scenario files, use `${VAR_NAME}`:

```toml
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    AGENT_LLM = "${AGENT_LLM}"
}
```

The tool/framework will:
1. Look for `ANTHROPIC_API_KEY` in your `.env` file
2. Replace `${ANTHROPIC_API_KEY}` with the actual value
3. Pass it to the container/process

This is **exactly** how GitHub Actions works - it injects secrets as environment variables.

---

## Docker Compose Details

The generated `docker-compose.yml` creates:

```
┌─────────────────────────────────────┐
│   agentbeats-network (bridge)       │
│                                     │
│  ┌──────────────┐  ┌──────────────┐│
│  │    agent     │  │ green-agent  ││
│  │   :9009      │◄─┤    :9009     ││
│  └──────────────┘  └──────────────┘│
│         ▲                ▲          │
│         │                │          │
│  ┌─────────────────────────┐       │
│  │   agentbeats-client     │       │
│  │  (runs assessment)      │       │
│  └─────────────────────────┘       │
└─────────────────────────────────────┘
```

1. **agent**: Your purple agent under test (port 9009)
2. **green-agent**: The CAR-bench evaluator (port 9009)
3. **agentbeats-client**: Official client that orchestrates the assessment

### Differences from Production

| Aspect | Local (Docker Compose) | GitHub Actions |
|--------|----------------------|----------------|
| Scenario config | `scenarios/scenario-docker-local.toml` | `scenario.toml` in leaderboard repo |
| Agent reference | `build = { context = ".", dockerfile = "..." }` | `agentbeats_id = "019ab..."` |
| Image source | Built from local Dockerfiles | GitHub Container Registry |
| Env vars | From `.env` file | From GitHub Secrets |
| Environment | Your laptop | GitHub cloud runners |
| Results | Saved to `output/` | Committed to `results/` folder |

---

## Common Workflows

### Testing Code Changes

**With Direct Python (Fastest):**
```bash
# 1. Make code changes
vim src/purple_car_bench_agent/car_bench_agent.py

# 2. Restart agent server
# Kill and restart python processes
python src/purple_car_bench_agent/server.py --host 127.0.0.1 --port 8080 --agent-llm anthropic/claude-haiku-4-5-20251001 &

# 3. Run evaluation
python src/agentbeats/run_scenario.py --scenario scenarios/scenario.toml
```

**With Direct Python:**
```bash
# Use Python debugger
import pdb; pdb.set_trace()

# Or use your IDE's debugger
# Set breakpoints and run in debug mode
```

**With Docker:**
```bash
# Generate compose file
python generate_compose.py --scenario scenarios/scenario-docker-local.toml

# Run with logs visible
docker compose up

# In another terminal, inspect running containers
docker ps
docker logs agent
docker logs green-agent
docker exec -it 
```

### Debugging Agent Issues

```bash
# Generate compose file
python generate_compose.py --scenario scenarios/scenario-docker-local.toml

# Run with logs visible
docker compose up

# In another terminal, inspect running containers
doEdit configuration
vim scenarios/scenario-docker-local.toml
# Change: tasks_base_end_index = 10

# Regenerate and test
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml
docker compose up --abort-on-container-exit
```

---

## Troubleshooting

### Direct Python Execution

**"Module not found" errors:**
```bash
# Install dependencies
pip install -e .
pip install -e external/car_bench
```

**"Port already in use":**
```bash
# Kill existing processes
lsof -ti:8080 | xargs kill
lsof -ti:8081 | xargs kill
```

**"API key not found":**
```bash
# Check environment variables are loaded
python -c "import os; print(os.getenv('ANTHROPIC_API_KEY'))"
```

### Docker Compose

**"Error: tomli or tomllib required":**

Install dependencies:
```bash
pip install tomli tomli-w python-dotenv
```

### "Environment variable XXX not found"

Make sure your `.env` file has the variable:
```bash
# Check what's in .env
cat .env

# Add missing variable
echo "MISSING_VAR=value" >> .env
```

**Docker build failures:**
```bash
# Clean rebuild
docker compose down
docker system prune -f
python generate_compose.py --scenario scenarios/scenario-docker-local.toml
docker compose up --build --abort-on-container-exit
```

---

## Recommended Development Flow

```
┌─────────────────────────────────────────┐
│ 1. Development Phase                    │
│    - Use Direct Python Execution        │
│    - Fast iteration                     │
│    - Easy debugging                     │
│    - File: scenarios/scenario.toml      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 2. Pre-Deployment Validation            │
│    - Use Docker Compose                 │
│    - Test containerization              │
│    - Verify networking                  │
│    - File: scenarios/scenario-docker-local.toml│
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 3. Official Leaderboard Submission      │
│    - Register agent on agentbeats.dev   │
│    - Fork leaderboard repository        │
│    - Configure with your agent ID       │
│    - GitHub Actions runs evaluation     │
└─────────────────────────────────────────┘
```

## Summary

**Use Direct Python when:**
- 🚀 Developing new features
- 🐛 Debugging issues
- ⚡ Need fast iteration
- 🔍 Want to use breakpoints

**Use Docker Compose when:**
- ✅ Validating before deployment
- 🐳 Testing Docker configuration
- 🌐 Ensuring production compatibility
- 📦 Final integration testing

**For Official Leaderboard Submissions:**
- 🏆 Register your agent on [agentbeats.dev](https://agentbeats.dev)
- 📋 Fork the official leaderboard repository (link provided separately)
- ⚙️ Configure GitHub Actions with your agent ID
- 📊 Automated evaluation and public results

Both local methods ensure your agents work correctly before submitting to the leaderboard!API_KEY ...
docker run -d --name green-evaluator -e OPENAI_API_KEY=$OPENAI_API_KEY ...

# Run evaluation manually
python src/agentbeats/run_scenario.py --scenario scenarios/scenario-docker.toml --evaluate-only
```

### After (Docker Compose)

```bash
# Everything in one command
python generate_compose.py --scenario scenarios/scenario-docker-local.toml
docker compose up --abort-on-container-exit
```

Benefits:
- ✅ Less manual work
- ✅ Consistent with GitHub Actions workflow
- ✅ Environment variables managed in one place
- ✅ Easy to tear down and restart

## See Also

- [AgentBeats Tutorial](https://docs.agentbeats.dev/tutorial/)
- [scenario.toml Reference](https://github.com/RDI-Foundation/agentbeats-leaderboard-template)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
