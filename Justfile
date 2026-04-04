# Honcho local development recipes

default:
    just --list

# Start postgres (pgvector) and redis containers
infra-up:
    docker compose up -d

# Stop infrastructure containers
infra-down:
    docker compose down

# Stop infrastructure and wipe all data volumes
infra-reset:
    docker compose down -v

# Run database migrations
migrate:
    uv run alembic upgrade head

# Start the API server on port 28000
api:
    uv run fastapi dev src/main.py --port 28000

# Start the deriver background worker
deriver:
    uv run python -m src.deriver

# Start everything (infra + migrate + api + deriver in background)
up: infra-up migrate
    uv run python -m src.deriver &
    uv run fastapi dev src/main.py --port 28000

# Stop all processes and infrastructure
down:
    -pkill -f "fastapi dev src/main.py"
    -pkill -f "src.deriver"
    docker compose down

# Check health of all services
status:
    @echo "--- Docker ---"
    @docker compose ps
    @echo ""
    @echo "--- API (port 28000) ---"
    @curl -s http://localhost:28000/docs -o /dev/null -w "HTTP %{http_code}\n" 2>/dev/null || echo "not running"
    @echo ""
    @echo "--- Deriver ---"
    @pgrep -f "src.deriver" > /dev/null && echo "running" || echo "not running"

# Run tests
test *args:
    uv run pytest tests/ {{ args }}

# Lint and typecheck
check:
    uv run ruff check src/
    uv run basedpyright

# Format code
fmt:
    uv run ruff format src/

# Install/sync dependencies
sync:
    uv sync

# Full setup from scratch (first time)
setup: sync infra-up
    @echo "Waiting for postgres..."
    @sleep 3
    just migrate
    @echo "Ready! Run 'just up' to start."
