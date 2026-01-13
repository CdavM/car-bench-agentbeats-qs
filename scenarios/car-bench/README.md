# CAR-bench Scenario

This scenario evaluates agents on the [CAR-bench](https://github.com/CAR-bench/car-bench) (Car-Assistant Recognition Benchmark), which tests AI agents on 101 in-car voice assistant tasks.

## Setup

### 1. Install dependencies

```bash
uv sync --extra car-bench-agent --extra car-bench-evaluator
```

This installs:
- **car-bench-agent** extras: LLM dependencies for the purple agent (google-adk, google-genai, litellm)
- **car-bench-evaluator** extras: car-bench package from GitHub for the green evaluator

### 2. Download car-bench data

Run the setup script to clone the car-bench repository and download large data files:

```bash
./scenarios/car-bench/setup.sh
```

This will:
- Clone the car-bench repository to `scenarios/car-bench/car-bench/`
- Download large mock_data files from GitHub releases
- Extract them into the correct location

The data will be automatically used via the `CAR_BENCH_DATA_DIR` environment variable.

### 3. Set your API keys

Create a `.env` file with your API keys:

```bash
cp sample.env .env
```

Edit `.env` and add:
```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

## Running the Benchmark

### Local Python Execution

```bash
uv run agentbeats-run scenarios/scenario.toml
```

### Docker Compose (for production-like testing)

```bash
# Generate docker-compose.yml
python generate_compose.py --scenario scenarios/scenario-docker-local.toml

# Run
mkdir -p output
docker compose up --abort-on-container-exit

# View results
cat output/results.json
```

## Configuration

The benchmark is configured via `scenarios/scenario.toml` and `scenarios/scenario-docker-local.toml`:

- **num_trials**: Number of times to run each task (for pass@k metrics)
- **tasks_base_start_index** / **tasks_base_end_index**: Range of base tasks to run
- **tasks_hallucination_start_index** / **tasks_hallucination_end_index**: Range of hallucination tasks
- **tasks_disambiguation_start_index** / **tasks_disambiguation_end_index**: Range of disambiguation tasks
- **max_steps**: Maximum conversation turns per task

## Data Directory Override

By default, the setup script places data at `scenarios/car-bench/car-bench/mock_data/` and this is automatically used. 

To use a different data directory, set the `CAR_BENCH_DATA_DIR` environment variable:

```bash
export CAR_BENCH_DATA_DIR=/path/to/custom/mock_data
uv run agentbeats-run scenarios/scenario.toml
```

## Troubleshooting

**Missing data files**: Ensure you ran `./scenarios/car-bench/setup.sh` and the download completed successfully.

**Import errors**: Make sure you installed the extras: `uv sync --extra car-bench-agent --extra car-bench-evaluator`

**Wrong data location**: Check that `CAR_BENCH_DATA_DIR` points to the correct directory or leave it unset to use the default.
