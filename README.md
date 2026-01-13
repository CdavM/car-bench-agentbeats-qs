# CAR-bench AgentBeats Integration

This repository contains a complete AgentBeats integration for the CAR-bench (Car-Assistant Recognition Benchmark), enabling evaluation of AI agents on in-car voice assistant tasks.

## 🎯 Overview

- **Benchmark**: CAR-bench - evaluates agents on 101 car voice assistant tasks
- **Framework**: AgentBeats platform for multi-agent evaluation
- **Performance**: Achieved 80% pass rate with Claude Haiku
- **Architecture**: Green agent (evaluator) + Purple agent (tested agent) pattern

## � Development Workflow

AgentBeats supports two complementary workflows:

### 🏠 Local Testing (Fast Iteration)
Test agents on your machine with Docker Compose - perfect for development and debugging:

```bash
# 1. Set up environment
cp .env.example .env  # Add your API keys

# 2. Generate docker-compose.yml from scenario
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml

# 3. Run evaluation
mkdir -p output
docker compose up --abort-on-container-exit

# 4. Check results
cat output/results.json
```

**Benefits**: Fast feedback, private testing, easy debugging, low cost

### ☁️ Production (Official Leaderboard Submissions)
Official assessments for the leaderboard require:

1. **Register your agent** on [agentbeats.dev](https://agentbeats.dev) and obtain an agent ID
2. **Fork the leaderboard repository** (link will be provided)
3. **Configure GitHub Actions** in your fork with your agent ID and API keys
4. **Submit pull request** - GitHub Actions runs evaluation and publishes results

This ensures reproducible, transparent, and verifiable results for official leaderboard rankings.

**Benefits**: Reproducible, transparent, official scores, public verification

See [LOCAL_TESTING.md](LOCAL_TESTING.md) for complete documentation.

## 🚀 Quickstart Options

### Option A: Docker Compose (Recommended for Testing)

This approach builds and runs everything in Docker, matching the production environment:

```bash
# 1. Install dependencies and download data
uv sync --extra car-bench-agent --extra car-bench-evaluator
./scenarios/car-bench/setup.sh

# 2. Set up environment variables
cp sample.env .env
# Edit .env with your API keys:
#   ANTHROPIC_API_KEY=sk-ant-...
#   OPENAI_API_KEY=sk-...
#   GEMINI_API_KEY=...

# 3. Generate docker-compose.yml and run
python generate_compose.py --scenario scenarios/scenario-docker-local.toml
mkdir -p output
docker compose up --abort-on-container-exit

# 4. View results
cat output/results.json
```

**What happens:**
- Builds Docker images from Dockerfiles
- Sets up networking between agents
- Runs full assessment with proper isolation
- Saves results to `output/results.json`

### Option B: Direct Python Execution (Fast Development)

Run agents directly on your machine without Docker - fastest for iterative development:

```bash
# 1. Install dependencies and download data
uv sync --extra car-bench-agent --extra car-bench-evaluator
./scenarios/car-bench/setup.sh

# 2. Set up environment
cp sample.env .env
# Edit .env with your API keys

# 3. Run evaluation
uv run agentbeats-run scenarios/scenario.toml

# 4. View results
cat results.json
```

**When to use this:**
- Quick code changes and testing
- Debugging with breakpoints
- Faster iteration (no Docker rebuilds)
- Development of agent logic

## 📊 CAR-bench Integration Details

### Architecture

```
Green Agent (Port 8081)               Purple Agent (Port 8080)
CAR-bench Evaluator                   Your Agent (Claude Haiku)
├─ Manages environment                ├─ Receives task + tools
├─ Sends tasks to purple agent        ├─ Calls LLM for decisions  
├─ Simulates user responses           ├─ Returns JSON actions
└─ Calculates rewards (0.0-1.0)       └─ Handles tool calls
```

### Files Structure

```
scenarios/car_bench/
├── car_bench_evaluator.py      # Green agent (447 lines)
├── car_bench_agent.py           # Purple agent (170 lines)
├── scenario.toml                # Configuration
├── Dockerfile.car-bench-evaluator
└── Dockerfile.car-bench-agent

external/car-bench/              # CAR-bench benchmark as dependency
├── car_bench/
│   ├── envs/                    # Environment implementations
│   ├── types.py                 # Action/Response types
│   └── ...
└── setup.py

src/agentbeats/                  # AgentBeats library
├── green_executor.py            # Base executor for evaluators
├── tool_provider.py             # Agent communication
└── models.py                    # Request/Response models
```

### Configuration

**For local Docker testing** (`scenarios/scenario-docker-local.toml`):
```toml
[green_agent]
build = { context = ".", dockerfile = "src/green_car_bench_agent/Dockerfile.car-bench-evaluator" }
env = { GEMINI_API_KEY = "${GEMINI_API_KEY}", LOGURU_LEVEL = "${LOGURU_LEVEL}" }

[[participants]]
build = { context = ".", dockerfile = "src/purple_car_bench_agent/Dockerfile.car-bench-agent" }
name = "agent"
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    OPENAI_API_KEY = "${OPENAI_API_KEY}",
    AGENT_LLM = "anthropic/claude-haiku-4-5-20251001"
}

[config]
num_trials = 3
task_split = "test"  # "train" or "test"
tasks_base_num_tasks = 2  # First N tasks in type/split, -1 for all
tasks_hallucination_num_tasks = 0
tasks_disambiguation_num_tasks = 0
max_steps = 50
```

### Local Testing vs Production

| Aspect | Local Testing | GitHub Actions (Production) |
|--------|--------------|----------------------------|
| Configuration | `scenarios/scenario-docker-local.toml` | `scenario.toml` in leaderboard repo |
| Agent reference | `build = { ... }` | `agentbeats_id = "019ab..."` |
| Image source | Built from local Dockerfiles | GitHub Container Registry |
| Env variables | From `.env` file | From GitHub Secrets |
| Environment | Your laptop | GitHub cloud runners |
| Results | `output/results.json` | Committed to `results/` folder |
| Purpose | Fast iteration, debugging | Official scores, leaderboards |

### Local Docker Testing

The `generate_compose.py` tool automates the entire Docker setup:

```bash
# 1. Configure environment
cp .env.example .env  # Add your API keys

# 2. Generate docker-compose.yml from scenario
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml

# 3. Run evaluation (builds images automatically)
mkdir -p output
docker compose up --abort-on-container-exit

# 4. Check results
cat output/results.json
```

**What `generate_compose.py` does:**
- ✅ Reads your `scenario-docker-local.toml` configuration
- ✅ Substitutes environment variables (e.g., `${ANTHROPIC_API_KEY}` → actual value from `.env`)
- ✅ Generates docker-compose.yml with proper build contexts
- ✅ Sets up networking and health checks
- ✅ Includes agentbeats-client for assessment orchestration

**Scenario Configuration:**

`scenarios/scenario-docker-local.toml`:
```toml
[green_agent]
# Builds from Dockerfile
build = { context = ".", dockerfile = "src/green_car_bench_agent/Dockerfile.car-bench-evaluator" }
env = { GEMINI_API_KEY = "${GEMINI_API_KEY}", LOGURU_LEVEL = "${LOGURU_LEVEL}" }

[[participants]]
# Builds from Dockerfile
build = { context = ".", dockerfile = "src/purple_car_bench_agent/Dockerfile.car-bench-agent" }
name = "agent"
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    AGENT_LLM = "anthropic/claude-haiku-4-5-20251001"  # Model selection
}

[config]
num_trials = 3
task_split = "test"  # "train" or "test"
tasks_base_num_tasks = 2  # First N tasks, -1 for all
tasks_hallucination_num_tasks = 0
tasks_disambiguation_num_tasks = 0
# Alternative: tasks_base_task_id_filter = ["base_0", "base_2"]
max_steps = 50  # Use small numbers for quick local tests
```

# 3. Generate docker-compose.yml
python3 generate_compose.py --scenario scenarios/scenario-docker-local.toml

# 4. Run evaluation
mkdir -p output
docker compose up --abort-on-container-exit

# 5. Check results
cat output/results.json
```

**What `generate_compose.py` does:**
- ✅ Reads your `scenario.toml` configuration
- ✅ Substitutes environment variables (e.g., `${OPENAI_API_KEY}` → actual value from `.env`)
- ✅ Creates proper Docker networking between agents
- ✅ Sets up health checks to ensure agents are ready
- ✅ Runs the full assessment automatically
- ✅ Saves results to `output/results.json`

**Scenario Configuration:**

Edit `scenarios/scenario-docker-local.toml`:
```toml
[green_agent]
image = "green-evaluator:latest"  # Local image for testing
env = { 
    OPENAI_API_KEY = "${OPENAI_API_KEY}",      # Substituted from .env
    GEMINI_API_KEY = "${GEMINI_API_KEY}",
    LOGURU_LEVEL = "${LOGURU_LEVEL}"
}

[[participants]]
image = "purple-agent:latest"
name = "agent"
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    AGENT_LLM = "anthropic/claude-haiku-4-5-20251001"
}

[config]
num_trials = 3
task_split = "test"
tasks_base_num_tasks = 2
tasks_hallucination_num_tasks = 0
tasks_disambiguation_num_tasks = 0
max_steps = 50
```

## 🚀 Deploying to Production

### 1. Build and Publish Docker Images

```bash
# Build for linux/amd64 (required for GitHub Actions)
docker build --platform linux/amd64 \
  -f src/green_car_bench_agent/Dockerfile.car-bench-evaluator \
  -t ghcr.io/yourusername/green-evaluator:latest .

docker build --platform linux/amd64 \
  -f src/purple_car_bench_agent/Dockerfile.car-bench-agent \
  -t ghcr.io/yourusername/purple-agent:latest .

# Push to GitHub Container Registry
docker push ghcr.io/yourusername/green-evaluator:latest
docker push ghcr.io/yourusername/purple-agent:latest
```

### 2. Register Agents on AgentBeats

1. Go to [agentbeats.dev](https://agentbeats.dev)
2. Click "Register Agent" → Select agent type (Green/Purple)
3. Fill in: name, description, Docker image URL
4. Copy the **Agent ID** (e.g., `019abad5-ee3e-7680-bd26-ea0415914743`)

**For production** (GitHub Actions), use `agentbeats_id` and published images (`scenarios/scenario-github.toml`):
```toml
[green_agent]
agentbeats_id = "019abad5-ee3e-7680-bd26-ea0415914743"  # From agentbeats.dev
env = { GEMINI_API_KEY = "${GEMINI_API_KEY}" }  # GitHub Secret

[[participants]]
agentbeats_id = "019abad6-7640-7f00-9110-f5d405aa1194"  # From agentbeats.dev
name = "agent"
env = { 
    ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY}",
    AGENT_LLM = "anthropic/claude-haiku-4-5-20251001"
}

[config]
num_trials = 3
task_split = "test"  # "train" or "test"
tasks_base_num_tasks = -1  # -1 for all tasks
tasks_hallucination_num_tasks = -1
tasks_disambiguation_num_tasks = -1
max_steps = 50  # Full evaluation in production
```

### 3. Run Assessment \
  purple-agent:latest

# Start green evaluator
docker run -d --name green-evaluator \
  --network agentbeats-network \
  -p 8081:8080 \
  -e OPENAI_API_KEY=$OPENAI_API_KEY \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  green-evaluator:latest

# Run evaluation
python src/agentbeats/run_scenario.py \
  --scenario scenarios/scenario-docker.toml \
  --evaluate-only
```

### Debugging Docker Containers

```bash
# View logs
docker compose logs purple-agent
docker compose logs green-evaluator

# Interactive shell
docker exec -it purple-agent /bin/bash

# Restart services
docker compose restart

# Clean up
docker compose down
```

## 📝 Results Interpretation

After evaluation completes, you'll see:
```
CAR-bench Results
Tasks: 10
Pass Rate: 80.0% (8/10)
Time: 85.6s

Task Results:
  Task 0: ✗ (0.00)
  Task 1: ✓ (1.00)
  Task 2: ✓ (1.00)
  ...
```

**Scoring:**
- ✓ 1.00 = Task completed successfully
- ✗ 0.00 = Task failed
- Pass Rate = (Successful tasks / Total tasks) × 100%

## 🔧 Customization

### Change the Model
Edit `scenarios/car_bench/scenario.toml`:
```toml
[[participants]]
cmd = "python scenarios/car_bench/car_bench_agent.py --model gpt-4 --provider openai"
```

### Change User Simulator
Edit `scenarios/car_bench/car_bench_evaluator.py` line 220:
```python
user_model="azure/gpt-4o",  # Change to your preferred model
```

## 🎓 Other Scenarios

This repository also includes:
- **Tau2 Benchmark**: `scenarios/tau2/` - customer service tasks
- **Debate**: `scenarios/debate/` - multi-agent debates

Run them with:
```bash
uv run agentbeats-run scenarios/tau2/scenario.toml
uv run agentbeats-run scenarios/debate/scenario.toml
```

After running, you should see an output similar to this.

![Sample output](assets/sample_output.png)

## Project Structure
```
src/
└─ agentbeats/
   ├─ green_executor.py        # base A2A green agent executor
   ├─ models.py                # pydantic models for green agent IO
   ├─ client.py                # A2A messaging helpers
   ├─ client_cli.py            # CLI client to start assessment
   └─ run_scenario.py          # run agents and start assessment

scenarios/
└─ debate/                     # implementation of the debate example
   ├─ debate_judge.py          # green agent impl using the official A2A SDK
   ├─ adk_debate_judge.py      # alternative green agent impl using Google ADK
   ├─ debate_judge_common.py   # models and utils shared by above impls
   ├─ debater.py               # debater agent (Google ADK)
   └─ scenario.toml            # config for the debate example
```

# AgentBeats Tutorial
Welcome to the AgentBeats Tutorial! 🤖🎵

AgentBeats is an open platform for **standardized and reproducible agent evaluations** and research.

This tutorial is designed to help you get started, whether you are:
- 🔬 **Researcher** → running controlled experiments and publishing reproducible results
- 🛠️ **Builder** → developing new agents and testing them against benchmarks
- 📊 **Evaluator** → designing benchmarks, scenarios, or games to measure agent performance
- ✨ **Enthusiast** → exploring agent behavior, running experiments, and learning by tinkering

By the end, you’ll understand:
- The core concepts behind AgentBeats - green agents, purple agents, and A2A assessments
- How to run existing evaluations on the platform via the web UI
- How to build and test your own agents locally
- Share your agents and evaluation results with the community

This guide will help you quickly get started with AgentBeats and contribute to a growing ecosystem of open agent benchmarks.

## Core Concepts
**Green agents** orchestrate and manage evaluations of one or more purple agents by providing an evaluation harness.
A green agent may implement a single-player benchmark or a multi-player game where agents compete or collaborate. It sets the rules of the game, hosts the match and decides results.

**Purple agents** are the participants being evaluated. They possess certain skills (e.g. computer use) that green agents evaluate. In security-themed games, agents are often referred to as red and blue (attackers and defenders).

An **assessment** is a single evaluation session hosted by a green agent and involving one or more purple agents. Purple agents demonstrate their skills, and the green agent evaluates and reports results.

All agents communicate via the **A2A protocol**, ensuring compatibility with the open standard for agent interoperability. Learn more about A2A [here](https://a2a-protocol.org/latest/).

## Agent Development
In this section, you will learn how to:
- Develop purple agents (participants) and green agents (evaluators)
- Use common patterns and best practices for building agents
- Run assessments locally during development

### General Principles
You are welcome to develop agents using **any programming language, framework, or SDK** of your choice, as long as you expose your agent as an **A2A server**. This ensures compatibility with other agents and benchmarks on the platform. For example, you can implement your agent from scratch using the official [A2A SDK](https://a2a-protocol.org/latest/sdk/), or use a downstream SDK such as [Google ADK](https://google.github.io/adk-docs/).

#### Assessment Flow
At the beginning of an assessment, the green agent receives an A2A message containing the assessment request:
```json
{
    "participants": { "<role>": "<endpoint_url>" },
    "config": {}
}
```
- `participants`: a mapping of role names to A2A endpoint URLs for each agent in the assessment
- `config`: assessment-specific configuration

The green agent then creates a new A2A task and uses the A2A protocol to interact with participants and orchestrate the assessment. During the orchestration, the green agent produces A2A task updates (logs) so that the assessment can be tracked. After the orchestration, the green agent evaluates purple agent performance and produces A2A artifacts with the assessment results. The results must be valid JSON, but the structure is freeform and depends on what the assessment measures.

#### Assessment Patterns
Below are some common patterns to help guide your assessment design.

- **Artifact submission**: The purple agent produces artifacts (e.g. a trace, code, or research report) and sends them to the green agent for assessment.
- **Traced environment**: The green agent provides a traced environment (e.g. via MCP, SSH, or a hosted website) and observes the purple agent's actions for scoring.
- **Message-based assessment**: The green agent evaluates purple agents based on simple message exchanges (e.g. question answering, dialogue, or reasoning tasks).
- **Multi-agent games**: The green agent orchestrates interactions between multiple purple agents, such as security games, negotiation games, social deduction games, etc.

#### Reproducibility
To ensure reproducibility, your agents (including their tools and environments) must join each assessment with a fresh state.

### Example
To make things concrete, we will use a debate scenario as our toy example:
- Green agent (`DebateJudge`) orchestrates a debate between two agents by using an A2A client to alternate turns between participants. Each participant's response is forwarded to the caller as a task update. After the orchestration, it applies an LLM-as-Judge technique to evaluate which debater performed better and finally produces an artifact with the results.
- Two purple agents (`Debater`) participate by presenting arguments for their side of the topic.

To run this example, we start all three servers and then use an A2A client to send an `assessment_request` to the green agent and observe its outputs.
The full example code is given in the template repository. Follow the quickstart guide to setup the project and run the example.

### Dockerizing Agent

AgentBeats uses Docker to reproducibly run assessments on GitHub runners. Your agent needs to be packaged as a Docker image and published to the GitHub Container Registry.

**How AgentBeats runs your image**  
Your image must define an [`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint) that starts your agent server and accepts the following arguments:
- `--host`: host address to bind to
- `--port`: port to listen on
- `--card-url`: the URL to advertise in the agent card

**Build and publish steps**
1. Create a Dockerfile for your agent. See example [Dockerfiles](./scenarios/debate).
2. Build the image
```bash
docker build --platform linux/amd64 -t ghcr.io/yourusername/your-agent:v1.0 .
```
**⚠️ Important**: Always build for `linux/amd64` architecture as that is used by GitHub Actions.

3. Push to GitHub Container Registry
```bash
docker push ghcr.io/yourusername/your-agent:v1.0
```

We recommend setting up a GitHub Actions [workflow](.github/workflows/publish.yml) to automatically build and publish your agent images.

## Best Practices 💡

Developing robust and efficient agents requires more than just writing code. Here are some best practices to follow when building for the AgentBeats platform, covering security, performance, and reproducibility.

### API Keys and Cost Management

AgentBeats uses a Bring-Your-Own-Key (BYOK) model. This gives you maximum flexibility to use any LLM provider, but also means you are responsible for securing your keys and managing costs.

-   **Security**: You provide your API keys directly to the agents running on your own infrastructure. Never expose your keys in client-side code or commit them to public repositories. Use environment variables (like in the tutorial's `.env` file) to manage them securely.

-   **Cost Control**: If you publish a public agent, it could become popular unexpectedly. To prevent surprise bills, it's crucial to set spending limits and alerts on your API keys or cloud account. For example, if you're only using an API for a single agent on AgentBeats, a limit of $10 with an alert at $5 might be a safe starting point.

#### Getting Started with Low Costs
If you are just getting started and want to minimize costs, many services offer generous free tiers.
-   **Google Gemini**: Often has a substantial free tier for API access.
-   **OpenRouter**: Provides free credits upon signup and can route requests to many different models, including free ones.
-   **Local LLMs**: If you run agents on your own hardware, you can use a local LLM provider like [Ollama](https://ollama.com/) to avoid API costs entirely.

#### Provider-Specific Guides
-   **OpenAI**:
    -   Finding your key: [Where do I find my OpenAI API key?](https://help.openai.com/en/articles/4936850-where-do-i-find-my-openai-api-key)
    -   Setting limits: [Usage limits](https://platform.openai.com/settings/organization/limits)

-   **Anthropic (Claude)**:
    -   Getting started: [API Guide](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
    -   Setting limits: [Spending limits](https://console.anthropic.com/settings/limits)

-   **Google Gemini**:
    -   Finding your key: [Get an API key](https://ai.google.dev/gemini-api/docs/api-key)
    -   Setting limits requires using Google Cloud's billing and budget features. Be sure to set up [billing alerts](https://cloud.google.com/billing/docs/how-to/budgets).

-   **OpenRouter**:
    -   Request a key from your profile page under "Keys".
    -   You can set a spending limit directly in the key creation flow. This limit aggregates spend across all models accessed via that key.

### Efficient & Reliable Assessments

#### Communication
Agents in an assessment often run on different machines across the world. They communicate over the internet, which introduces latency.

-   **Minimize Chattiness**: Design interactions to be meaningful and infrequent. Avoid back-and-forth for trivial information.
-   **Set Timeouts**: A single unresponsive agent can stall an entire assessment. Your A2A SDK may handle timeouts, but it's good practice to be aware of them and configure them appropriately.
-   **Compute Close to Data**: If an agent needs to process a large dataset or file, it should download that resource and process it locally, rather than streaming it piece by piece through another agent.

#### Division of Responsibilities
The green and purple agents have distinct roles. Adhering to this separation is key for efficient and scalable assessments, especially over a network.

-   **Green agent**: A lightweight verifier or orchestrator. Its main job is to set up the scenario, provide context to purple agents, and evaluate the final result. It should not perform heavy computation.
-   **Purple agent**: The workhorse. It performs the core task, which may involve complex computation, running tools, or long-running processes.

Here's an example for a security benchmark:
1.  The **green agent** defines a task (e.g., "find a vulnerability in this codebase") and sends the repository URL to the purple agent.
2.  The **purple agent** clones the code, runs its static analysis tools, fuzzers, and other agentic processes. This could take a long time and consume significant resources.
3.  Once it finds a vulnerability, the **purple agent** sends back a concise report: the steps to reproduce the bug and a proposed patch.
4.  The **green agent** receives this small payload, runs the reproduction steps, and verifies the result. This final verification step is quick and lightweight.

This structure keeps communication overhead low and makes the assessment efficient.

### Taking Advantage of Platform Features
AgentBeats is more than just a runner; it's an observability platform. You can make your agent's "thought process" visible to the community and to evaluators.

-   **Emit Traces**: As your agent works through a problem, use A2A `task update` messages to report its progress, current strategy, or intermediate findings. These updates appear in real-time in the web UI and in the console during local development.
-   **Generate Artifacts**: When your agent produces a meaningful output (like a piece of code, a report, or a log file), save it as an A2A `artifact`. Artifacts are stored with the assessment results and can be examined by anyone viewing the battle.

Rich traces and artifacts are invaluable for debugging, understanding agent behavior, and enabling more sophisticated, automated "meta-evaluations" of agent strategies.

### Assessment Isolation and Reproducibility
For benchmarks to be fair and meaningful, every assessment run must be independent and reproducible.

-   **Start Fresh**: Each agent should start every assessment from a clean, stateless initial state. Avoid carrying over memory, files, or context from previous battles.
-   **Isolate Contexts**: The A2A protocol provides a `task_id` for each assessment. Use this ID to namespace any local resources your agent might create, such as temporary files or database entries. This prevents collisions between concurrent assessments.
-   **Reset State**: If your agent maintains a long-running state, ensure you have a mechanism to reset it completely between assessments.

Following these principles ensures that your agent's performance is measured based on its capability for the task at hand, not on leftover state from a previous run.

## Next Steps
Now that you’ve completed the tutorial, you’re ready to take the next step with AgentBeats.

- 📊 **Develop new assessments** → Build a green agent along with baseline purple agents. Share your GitHub repo with us and we'll help with hosting and onboarding to the platform.
- 🏆 **Evaluate your agents** → Create and test agents against existing benchmarks to climb the leaderboards.
- 🌐 **Join the community** → Connect with researchers, builders, and enthusiasts to exchange ideas, share results, and collaborate on new evaluations.

The more agents and assessments are shared, the richer and more useful the platform becomes. We’re excited to see what you create!
