# Installation Guide - CAR-bench AgentBeats Integration

This guide walks through the complete installation process for running the CAR-bench evaluation on the AgentBeats platform.

## Prerequisites

- **Python**: 3.11 or higher
- **uv package manager**: [Install uv](https://docs.astral.sh/uv/getting-started/installation/)
- **API Keys**:
  - Anthropic API key (for Claude - the agent being tested)
  - Azure OpenAI API key (for GPT-4o-mini - the user simulator)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/car-bench.git
cd car-bench
git checkout agentbeats-ready-car-bench
```

### 2. Install Dependencies

The following command will install all required packages including the CAR-bench benchmark from the `external/car-bench/` directory:

```bash
uv sync
```

**What gets installed:**
- AgentBeats framework (from `src/agentbeats/`)
- CAR-bench package (from `external/car-bench/` as editable install)
- All Python dependencies (LiteLLM, A2A SDK, Anthropic, etc.)

**Note**: This takes about 1-2 minutes and installs ~100 packages.

### 3. Configure API Keys

Create a `.env` file with your API credentials:

```bash
cp sample.env .env
```

Edit `.env` and add your keys:

```bash
# Required: For the purple agent (Claude Haiku)
ANTHROPIC_API_KEY=sk-ant-api03-...

# Required: For the user simulator (GPT-4o-mini)
AZURE_API_KEY=your-azure-key
AZURE_API_BASE=https://your-azure-endpoint.azure.com/api/providers/azure

# Optional: If you want to use Google models
GOOGLE_API_KEY=your-google-key
GOOGLE_GENAI_USE_VERTEXAI=FALSE
```

**Getting API Keys:**
- **Anthropic**: https://console.anthropic.com/
- **Azure OpenAI**: Contact your Azure administrator or use a personal Azure OpenAI resource

### 4. Verify Installation

Test that everything is installed correctly:

```bash
# Check that uv can find the packages
uv run python -c "from car_bench.envs import get_env; print('CAR-bench: OK')"
uv run python -c "from agentbeats import GreenExecutor; print('AgentBeats: OK')"
```

Expected output:
```
CAR-bench: OK
AgentBeats: OK
```

## Running Your First Evaluation

### Quick Test (3 tasks, ~30 seconds)

Edit `scenarios/car_bench/scenario.toml` and set:
```toml
[config]
num_tasks = 3
max_steps = 10
```

Then run:
```bash
uv run agentbeats-run scenarios/car_bench/scenario.toml --show-logs
```

### Full Evaluation (10 tasks, ~90 seconds)

```bash
uv run agentbeats-run scenarios/car_bench/scenario.toml --show-logs
```

**What you'll see:**
1. Both agents start on ports 8080 and 8081
2. CAR-bench data loads (locations, contacts, etc.)
3. Tasks execute with real-time logs
4. Results display: pass rate, task rewards, timing

**Expected Results:**
- Pass Rate: ~80% with Claude Haiku
- Time: ~8-9 seconds per task
- Logs show agent conversations and tool calls

### Stop the Evaluation

Press `Ctrl+C` to stop the agents.

## Troubleshooting

### Issue: `ModuleNotFoundError: No module named 'car_bench'`

**Solution**: Make sure you ran `uv sync` to install the local package.

### Issue: `litellm.APIError: AzureException APIError`

**Solution**: Check your `.env` file contains valid `AZURE_API_KEY` and `AZURE_API_BASE`.

### Issue: `anthropic.APIError: Authentication failed`

**Solution**: Verify your `ANTHROPIC_API_KEY` in `.env` is correct and has credits.

### Issue: Missing mock data warnings

```
Warning: File not found at .../pois.jsonl
Warning: File not found at .../routes_metadata.jsonl
```

**These are expected** - POIs and routes are only needed for specific navigation tasks. The base split tasks work without them.

### Issue: Agents don't stop after evaluation

**This is normal** - agents run as servers waiting for more requests. Press `Ctrl+C` to stop them.

## Advanced Configuration

### Change the Agent Model

Edit `scenarios/car_bench/scenario.toml`:

```toml
[[participants]]
cmd = "python scenarios/car_bench/car_bench_agent.py --model gpt-4 --provider openai"
```

Supported models:
- Claude: `claude-opus-4-20250514`, `claude-sonnet-4-20250514`, `claude-haiku-4-5-20251001`
- GPT: `gpt-4`, `gpt-4o`, `gpt-4-turbo`
- Others: Any LiteLLM-supported model

### Change Number of Tasks

Edit `scenarios/car_bench/scenario.toml`:

```toml
[config]
num_tasks = 50  # Run 50 tasks instead of 10
max_steps = 20  # Allow up to 20 conversation turns
```

### Run Specific Task IDs

Modify `car_bench_evaluator.py` line 80:

```python
def get_task_ids() -> list[int]:
    return [0, 5, 10, 15]  # Only run these specific tasks
```

### Change User Simulator

Edit `car_bench_evaluator.py` line 220-225:

```python
env = get_env(
    # ...
    user_model="gpt-4",  # Change from gpt-4o-mini to gpt-4
    user_provider="openai",  # Change provider
    # ...
)
```

## Docker Deployment

### Build Images

```bash
docker build -f scenarios/car_bench/Dockerfile.car-bench-evaluator -t car-bench-evaluator .
docker build -f scenarios/car_bench/Dockerfile.car-bench-agent -t car-bench-agent .
```

### Run with Docker

```bash
# Start purple agent
docker run -d -p 8080:8080 \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  car-bench-agent

# Start green agent  
docker run -d -p 8081:8081 \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -e AZURE_API_KEY=$AZURE_API_KEY \
  -e AZURE_API_BASE=$AZURE_API_BASE \
  car-bench-evaluator
```

## Next Steps

- Read the main [README.md](README.md) for architecture details
- Check [scenarios/car_bench/](scenarios/car_bench/) for implementation
- Explore [external/car-bench/README.md](external/car-bench/README.md) for CAR-bench documentation
- Try other scenarios: `scenarios/tau2/` and `scenarios/debate/`

## Support

For issues with:
- **CAR-bench benchmark**: See [external/car-bench/README.md](external/car-bench/README.md)
- **AgentBeats integration**: Open an issue on this repository
- **API keys/billing**: Contact your API provider

## Summary

The complete workflow is:
1. Clone repo + checkout branch
2. `uv sync` (installs everything)
3. Configure `.env` with API keys
4. `uv run agentbeats-run scenarios/car_bench/scenario.toml`
5. See results (80% pass rate expected)

That's it! 🎉
