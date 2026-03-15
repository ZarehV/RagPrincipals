# CLAUDE.md — Python Development Standards

This file defines the coding standards, project conventions, and best practices that Claude must
follow when writing, editing, or reviewing Python code in this repository. All contributors and
AI assistants are expected to adhere to these guidelines consistently.

---

## Project Overview

**RagPrincipals** is an experimental sandbox repository for exploring Claude Code's
capabilities and potential. It serves as a playground for testing AI-assisted development
workflows, automation patterns, and Claude Code integrations — built with Python.

---

## 1. Python Version & Runtime

- **Target version:** Python 3.14+
- Embrace features available in 3.14: free-threaded mode (`--disable-gil`), improved `typing`
  ergonomics, `ExceptionGroup`, `tomllib`, `match` statements, `asyncio.TaskGroup`, and the
  `type` soft-keyword for aliases.
- Never write compatibility shims for Python < 3.12 — those versions are EOL or approaching it.
- Never use `from __future__ import annotations` — it is no longer needed in 3.14; PEP 563
  semantics are the default.
- If an API is deprecated in 3.14, do not use it, even if it still works.

```python
# GOOD — native 3.14 syntax
type Vector = list[float]

def scale(v: Vector, factor: float) -> Vector:
    return [x * factor for x in v]

# BAD — legacy typing imports, unnecessary future import
from __future__ import annotations
from typing import List
def scale(v: List[float], factor: float) -> List[float]: ...
```

---

## 2. Project Structure

Every project must follow this layout:

```
my_project/
├── src/
│   └── my_package/              # Importable source package (src layout)
│       ├── __init__.py
│       ├── core.py
│       └── utils.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # Shared pytest fixtures
│   ├── unit/
│   │   └── test_core.py
│   └── integration/
│       └── test_pipeline.py
├── docs/                        # Project documentation (optional)
├── scripts/                     # One-off helper scripts (not importable)
├── .env.example                 # Documents required environment variables
├── pyproject.toml               # Single source of truth for all config
├── requirements.txt             # Pinned runtime deps (exported from uv.lock)
├── requirements-dev.txt         # Pinned dev deps (exported from uv.lock)
├── CLAUDE.md                    # This file
└── README.md
```

**This repository's current structure:**

```
RagPrincipals/
├── CLAUDE.md                        # This file — AI assistant guidance
├── README.md                        # Project introduction
├── pyproject.toml                   # Project metadata, dependencies, and tool config
├── .gitignore
├── src/
│   └── rag_principals/         # Main package
│       └── __init__.py
└── tests/                           # Pytest test suite
    └── __init__.py
```

Add new modules under `src/rag_principals/` and their corresponding tests under `tests/`.

**Rules:**

- Always use the **src layout** — it prevents accidental imports of the local working directory
  and forces the package to be properly installed before use.
- Keep `scripts/` separate from the importable package; scripts are not tested.
- Do **not** create `setup.py` or `setup.cfg`; use `pyproject.toml` exclusively.
- The `tests/` directory mirrors the `src/` structure where practical.
- Split tests into `unit/` (no I/O, no network) and `integration/` (external systems, mocked or
  real) sub-directories.

---

## 3. Dependency & Environment Management

### Primary workflow: `uv`

`uv` is the preferred tool for all new projects and CI pipelines. It is significantly faster than
pip and provides deterministic lock files.

```bash
# Bootstrap a new project
uv init my_project
cd my_project

# Create / sync the virtual environment from pyproject.toml
uv sync

# Add a runtime dependency
uv add httpx

# Add a development-only dependency
uv add --dev pytest pytest-cov

# Export pinned requirements for environments that only have pip
uv export --no-hashes > requirements.txt
uv export --no-hashes --only-group dev > requirements-dev.txt

# Run any command inside the managed environment
uv run pytest
uv run python -m my_package
```

### Fallback workflow: `pip` + `venv`

When `uv` is unavailable (e.g., restricted CI images, customer environments), use standard
`pip` + `venv`. Always install from the pinned `requirements.txt` produced by `uv export`.

```bash
# Create and activate the environment
python3.14 -m venv .venv
source .venv/bin/activate          # Linux / macOS
.venv\Scripts\activate             # Windows

# Install from locked requirements
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install the package itself in editable mode
pip install -e .
```

**Rules:**

- `uv.lock` must be committed to version control — it is the authoritative lock.
- `requirements.txt` and `requirements-dev.txt` are derived from the lock and must be
  re-exported whenever `uv.lock` changes (automate this in CI).
- Never manually edit `requirements.txt`; it is always generated by `uv export`.
- Pin minimum versions (`>=`) in `pyproject.toml`; avoid hard upper bounds unless a known
  incompatibility exists.
- Separate dependency groups cleanly: runtime in `[project.dependencies]`, optional features in
  `[project.optional-dependencies]`, dev tooling in `[dependency-groups]`.
- Activate the virtual environment before running any command manually.
- Never install packages into the system Python.
- Never add dependencies to `pyproject.toml` without explicit user approval.

---

## 4. `pyproject.toml` Reference

All project metadata and tool configuration lives here. Never create separate `pytest.ini`,
`mypy.ini`, `.isort.cfg`, `.flake8`, or `tox.ini` files.

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-package"
version = "0.1.0"
description = "Short description of the project."
readme = "README.md"
license = { text = "MIT" }
requires-python = ">=3.14"
dependencies = [
    "httpx>=0.27",
]

[project.optional-dependencies]
# Installable extras for end users:  pip install my-package[async]
async = ["anyio>=4"]

[dependency-groups]
# Dev-only tooling — never shipped to end users
dev = [
    "pytest>=8",
    "pytest-cov>=5",
    "pytest-asyncio>=0.23",
    "mypy>=1.11",
]

[tool.hatch.build.targets.wheel]
packages = ["src/my_package"]

[tool.mypy]
python_version = "3.14"
strict = true
ignore_missing_imports = false

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers --tb=short -q"
markers = [
    "slow: marks tests as slow (deselect with '-m not slow')",
    "integration: marks tests that require external services",
]
asyncio_mode = "auto"   # required by pytest-asyncio

[tool.coverage.run]
source = ["src"]
branch = true
omit = ["*/conftest.py"]

[tool.coverage.report]
fail_under = 80
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
```

Do not modify `tool.mypy` or `tool.ruff` config unless asked.

---

## 5. Code Style & Formatting

**Formatter / linter:** [Ruff](https://docs.astral.sh/ruff/)

The following rules are **non-negotiable** regardless of which formatter is in use:

| Rule             | Value                                                               |
|------------------|---------------------------------------------------------------------|
| Line length      | **100 characters**                                                  |
| String quotes    | **Double quotes** (`"`) everywhere                                  |
| Import order     | stdlib → third-party → first-party, blank line between each group  |
| Wildcard imports | **Never** (`from module import *`)                                  |
| Trailing commas  | **Required** in all multi-line collections and call signatures      |
| f-strings        | **Preferred** for interpolation; avoid `%` or `.format()` in new code |
| Mutable defaults | **Forbidden** — use `None` and assign in the function body          |

```python
# GOOD — double quotes, f-string, safe default
def greet(name: str, tags: list[str] | None = None) -> str:
    if tags is None:
        tags = []
    label = ", ".join(tags)
    return f"Hello, {name} [{label}]"


# BAD — single quotes, %-format, mutable default
def greet(name, tags=[]):
    return 'Hello, %s [%s]' % (name, ', '.join(tags))
```

**Import ordering example:**

```python
# 1. Standard library
import json
from pathlib import Path

# 2. Third-party
import httpx
from pydantic import BaseModel

# 3. First-party (shared common modules first, then package-local)
from common.ecs_logging import get_logger
from my_package.config import settings
from my_package.utils import normalize

logger = get_logger(__name__)
```

Always run `ruff check .` and `ruff format .` before committing.

---

## 6. Type Annotations

- **All** public functions, methods, and module-level variables must be fully annotated.
- Run `mypy` in strict mode. No `# type: ignore` without an inline explanation.
- Use **built-in generics** everywhere — `list[str]`, `dict[str, int]`, `tuple[int, ...]`.
  Never import `List`, `Dict`, `Tuple`, `Optional`, or `Union` from `typing` (deprecated since
  3.9, removed in future versions).
- Use `X | Y` union syntax — never `Optional[X]` or `Union[X, Y]`.
- Use the `type` statement for aliases (3.12+).
- Use `typing.Protocol` for structural subtyping instead of ABCs where practical.
- Use `typing.TypeVar` and `typing.ParamSpec` for generics; use `typing.overload` to express
  type-level branching instead of `Any`.

```python
# GOOD
type JsonObject = dict[str, object]
type Callback[T] = Callable[[T], None]

def fetch(url: str, timeout: float | None = None) -> JsonObject:
    ...


# BAD
from typing import Dict, Optional, Union
def fetch(url: str, timeout: Optional[float] = None) -> Dict[str, object]:
    ...
```

---

## 7. Documentation & Docstrings

- Use **Google-style** docstrings for all public modules, classes, and functions.
- Every **module** must begin with a one-line module docstring.
- Every **public class** and **public function** must have a docstring.
- Private helpers (`_name`) should have docstrings when non-obvious.
- One-liners are acceptable for trivial functions; use the full format when arguments, return
  values, exceptions, or examples add value.
- Docstring examples must be valid `doctest`-runnable snippets.

```python
"""Utility helpers for numeric data transformation."""

import math


def normalize(values: list[float], *, clip: bool = False) -> list[float]:
    """Normalize a list of floats to the [0, 1] range.

    Applies min-max scaling so that the minimum input maps to 0.0 and the
    maximum input maps to 1.0. All other values are scaled linearly.

    Args:
        values: The raw numeric values to normalize. Must be non-empty and
            contain at least two distinct values.
        clip: If True, output values are clamped to [0, 1] after scaling.
            Useful when the input may contain outliers beyond the expected
            range.

    Returns:
        A new list of floats in [0, 1] (or exactly [0, 1] if ``clip=True``).

    Raises:
        ValueError: If ``values`` is empty.
        ValueError: If all values in ``values`` are identical (zero range).

    Example:
        >>> normalize([0.0, 5.0, 10.0])
        [0.0, 0.5, 1.0]
        >>> normalize([-1.0, 0.0, 1.0], clip=True)
        [0.0, 0.5, 1.0]
    """
    if not values:
        raise ValueError("values must not be empty")
    lo, hi = min(values), max(values)
    if math.isclose(lo, hi):
        raise ValueError("values must have a non-zero range")
    result = [(v - lo) / (hi - lo) for v in values]
    if clip:
        result = [max(0.0, min(1.0, v)) for v in result]
    return result
```

---

## 8. Testing

**Framework:** `pytest` with `pytest-cov` for coverage and `pytest-asyncio` for async tests.

```bash
# Activate the environment first (uv or venv)
source .venv/bin/activate

# Run all tests with branch coverage
pytest --cov --cov-report=term-missing

# Run only fast unit tests
pytest tests/unit/ -v

# Run integration tests (opt-in)
pytest tests/integration/ -v -m integration

# Run a specific test by keyword
pytest -k "normalize" -v

# Stop on first failure
pytest -x
```

### Coverage

- Minimum threshold: **80%** (enforced in CI via `[tool.coverage.report] fail_under`).
- Branch coverage is enabled — partial branches count against the threshold.
- Do not use `# pragma: no cover` to game the metric; use it only for genuinely unreachable
  defensive branches (e.g., `raise NotImplementedError` in abstract-like methods).

### Naming conventions

| Item          | Convention                          | Example                             |
|---------------|-------------------------------------|-------------------------------------|
| Test file     | `test_<module>.py`                  | `test_utils.py`                     |
| Test function | `test_<what>_<condition>_<outcome>` | `test_normalize_empty_input_raises` |
| Fixture       | descriptive noun                    | `mock_http_client`, `sample_config` |

### Rules

- Use **fixtures** for all shared setup — never `setUp`/`tearDown` or module-level globals.
- Define fixtures in `conftest.py` at the closest scope that makes sense (test file, directory,
  or root).
- Use `pytest.raises` for exception assertions — never a bare `try/except` block in a test.
- Use `pytest.mark.parametrize` for data-driven cases instead of loops inside tests.
- Never write tests that depend on real external services without mocking them
  (`unittest.mock.patch`, `respx` for HTTPX, etc.).
- Avoid `unittest.TestCase` unless forced by inheritance.
- Async test functions are supported via `pytest-asyncio` with `asyncio_mode = "auto"`.
- Write tests for every new public function or class.

```python
# tests/unit/test_utils.py
import pytest
from my_package.utils import normalize


def test_normalize_standard_range_returns_unit_values() -> None:
    assert normalize([0.0, 5.0, 10.0]) == [0.0, 0.5, 1.0]


@pytest.mark.parametrize("bad_input", [[], [3.0, 3.0]])
def test_normalize_degenerate_input_raises_value_error(bad_input: list[float]) -> None:
    with pytest.raises(ValueError):
        normalize(bad_input)


@pytest.fixture
def sample_values() -> list[float]:
    return [2.0, 4.0, 6.0, 8.0, 10.0]


def test_normalize_with_clip_clamps_to_unit(sample_values: list[float]) -> None:
    result = normalize(sample_values, clip=True)
    assert all(0.0 <= v <= 1.0 for v in result)
```

---

## 9. Error Handling

- Catch the **most specific** exception possible. Never use a bare `except:` or
  `except Exception:` unless you are re-raising or logging at an application boundary.
- Always include context in error messages — what failed and why.
- Define a project-level base exception class; all domain errors inherit from it.
- Use `raise X from Y` to preserve exception chains; use `raise X from None` only when the
  original exception is irrelevant noise.
- Use `contextlib.suppress` sparingly; always document why an exception is intentionally ignored.
- Use `ExceptionGroup` (Python 3.11+) when multiple independent operations can fail concurrently.

```python
# src/my_package/exceptions.py
class AppError(Exception):
    """Base exception for all application-level errors."""


class ConfigurationError(AppError):
    """Raised when the application configuration is invalid or missing."""


class ExternalServiceError(AppError):
    """Raised when a call to an external service fails."""


# src/my_package/config.py
import json
from pathlib import Path
from my_package.exceptions import ConfigurationError


def load_config(path: str | Path) -> dict[str, object]:
    """Load and parse a JSON configuration file.

    Args:
        path: Path to the configuration file.

    Returns:
        Parsed configuration as a dictionary.

    Raises:
        ConfigurationError: If the file is missing or contains invalid JSON.
    """
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        raise ConfigurationError(f"Config file not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise ConfigurationError(
            f"Invalid JSON in config file '{path}': {exc}"
        ) from exc
```

---

## 10. Logging

**All logging must use Elasticsearch Common Schema (ECS) format.** The shared ECS logging
setup lives in `common/ecs-logging` and is the only approved way to initialise and obtain
loggers in this codebase. Never configure logging directly with `logging.basicConfig` or the
`ecs-logging` PyPI package in application code — always go through the shared module.

### Why ECS?

ECS-formatted logs are structured JSON that Elasticsearch can index and query without
additional parsing pipelines. Every log record carries a standard set of fields
(`@timestamp`, `log.level`, `log.logger`, `service.name`, `error.*`, etc.) that Kibana
dashboards and alerting rules depend on.

### Obtaining a logger

```python
# Every module — always use get_logger from the shared helper
from common.ecs_logging import get_logger

logger = get_logger(__name__)
```

`get_logger` is a thin wrapper around `logging.getLogger` that guarantees the ECS handler
is attached and the service metadata fields are injected. Never call `logging.getLogger`
directly in application code.

### Application entry point setup

Call `configure_logging` exactly once at startup, before any other imports that log:

```python
# src/my_package/__main__.py  (or wherever the app starts)
from common.ecs_logging import configure_logging

configure_logging(
    level="INFO",          # or read from Settings.log_level
    service_name="my-package",
    service_version="1.2.0",
)
```

Libraries (anything under `src/` that is not the entry point) must **never** call
`configure_logging`. They only call `get_logger(__name__)`.

### Log levels

| Level      | When to use                                                         |
|------------|---------------------------------------------------------------------|
| `DEBUG`    | Internal state, loop iterations, verbose diagnostics                |
| `INFO`     | Normal milestones: service start/stop, key operations completed     |
| `WARNING`  | Recoverable issues, deprecated usage, unexpected-but-handled states |
| `ERROR`    | Failures that prevent an operation from completing                  |
| `CRITICAL` | Failures that require immediate human intervention                  |

### Adding structured ECS fields

Pass extra ECS fields as keyword arguments to the log call. The shared module maps them
into the correct ECS dot-notation keys in the JSON output.

```python
from common.ecs_logging import get_logger

logger = get_logger(__name__)


def process_batch(records: list[dict[str, object]]) -> int:
    """Process a batch of records and return the success count."""
    logger.info(
        "Batch started",
        extra={"labels": {"batch_size": len(records)}},
    )
    success = 0
    for i, record in enumerate(records):
        try:
            _process_one(record)
            success += 1
        except AppError as exc:
            logger.warning(
                "Record skipped due to processing error",
                extra={
                    "labels": {"record_index": i},
                    "error": {"message": str(exc), "type": type(exc).__name__},
                },
            )
    logger.info(
        "Batch complete",
        extra={"labels": {"success_count": success, "total_count": len(records)}},
    )
    return success
```

### Logging exceptions

Use `logger.exception` inside `except` blocks — it automatically attaches the traceback
to the `error.stack_trace` ECS field:

```python
try:
    result = call_external_api()
except ExternalServiceError as exc:
    logger.exception(
        "External API call failed",
        extra={"url": {"full": exc.url}, "http": {"response": {"status_code": exc.status}}},
    )
    raise
```

### Rules

- **Never** use `print()` for operational output.
- **Never** call `logging.getLogger` directly — always use `common.ecs_logging.get_logger`.
- **Never** call `logging.basicConfig` or add handlers manually anywhere except
  `common/ecs-logging` itself.
- **Never** log secrets, PII, or credentials at any level.
- Use `%`-style lazy formatting for the message string itself; structured data goes in `extra`.
- Do not construct the `extra` dict with f-strings containing sensitive values.
- All ECS field names must follow the official
  [ECS field reference](https://www.elastic.co/guide/en/ecs/current/ecs-field-reference.html).

---

## 11. Configuration & Secrets

- All secrets and environment-specific values go in environment variables — never in source code.
- Load and validate configuration at startup using `pydantic-settings`; fail fast on missing or
  malformed values.
- Provide a `.env.example` with every required key and a dummy value; this file is committed.
- `.env` files are in `.gitignore` and are **never committed**.
- Never log secrets, even at DEBUG level.

```python
# src/my_package/config.py
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    database_url: str = Field(..., description="PostgreSQL connection string")
    secret_key: str = Field(..., min_length=32)
    debug: bool = False
    max_retries: int = Field(default=3, ge=1, le=10)
    request_timeout: float = Field(default=30.0, gt=0)


# Singleton — import this throughout the application
settings = Settings()
```

```dotenv
# .env.example  (committed)
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
SECRET_KEY=change-me-to-a-long-random-string-at-least-32-chars
DEBUG=false
MAX_RETRIES=3
REQUEST_TIMEOUT=30.0
```

---

## 12. Concurrency Guidelines

- Use `asyncio` + `async`/`await` for all I/O-bound work (HTTP, databases, file I/O).
- Use `asyncio.TaskGroup` for structured concurrency — it guarantees all child tasks are
  awaited and surfaces exceptions cleanly via `ExceptionGroup`.
- Use `concurrent.futures.ProcessPoolExecutor` for CPU-bound parallelism; with Python 3.14's
  free-threaded mode, `ThreadPoolExecutor` may also be appropriate for CPU work — benchmark first.
- Always set explicit timeouts on network operations; never make unbounded blocking calls.
- Do not mix `asyncio` with `threading` unless wrapping a legacy blocking library
  (`asyncio.to_thread` is the safe bridge).

```python
import asyncio
import httpx


async def fetch_all(urls: list[str], timeout: float = 10.0) -> list[bytes]:
    """Fetch multiple URLs concurrently and return their response bodies."""
    async with httpx.AsyncClient(timeout=timeout) as client:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(client.get(url)) for url in urls]
    # All tasks are guaranteed complete here; exceptions surface as ExceptionGroup
    return [t.result().content for t in tasks]
```

---

## 13. Elasticsearch APM Instrumentation

**All applications must be instrumented with the Elastic APM Python agent.** APM traces,
transactions, and spans are the primary observability signal for performance, latency, and
error tracking. ECS logs (Section 10) and APM traces are correlated automatically via the
`transaction.id` and `trace.id` fields injected into every log record by the shared
`common/ecs-logging` module — this correlation only works when APM is active.

### Agent initialisation

The APM agent must be started **before any application code runs**, including before framework
setup. Initialise it at the very top of the application entry point, immediately after the
standard library imports:

```python
# src/my_package/__main__.py
import elasticapm  # must be first non-stdlib import

from common.ecs_logging import configure_logging

# Initialise APM — configuration is read from environment variables (see .env.example)
apm_client = elasticapm.Client()
elasticapm.instrument()          # activates all available auto-instrumentation patches

configure_logging(
    level="INFO",
    service_name="my-package",
    service_version="1.2.0",
)

# rest of application startup...
```

Add `elastic-apm` to the project's runtime dependencies:

```toml
# pyproject.toml
[project]
dependencies = [
    "elastic-apm>=6.22",
    "httpx>=0.27",
]
```

Required environment variables (add to `.env.example`):

```dotenv
# Elasticsearch APM
ELASTIC_APM_SERVICE_NAME=my-package
ELASTIC_APM_SERVER_URL=https://apm-server.example.com
ELASTIC_APM_SECRET_TOKEN=your-apm-secret-token
ELASTIC_APM_ENVIRONMENT=production
ELASTIC_APM_LOG_CORRELATION=true
```

### Auto-instrumentation vs manual instrumentation

`elasticapm.instrument()` patches supported frameworks and libraries (Django, Flask, FastAPI,
SQLAlchemy, httpx, redis, etc.) automatically. **Always call it.** Even for applications that
benefit from auto-instrumentation, manual transactions and spans are still required for
business-logic code paths that the agent cannot detect automatically.

If the application does **not** use a supported framework (e.g. a CLI tool, a background
worker, a pure data pipeline), **every logical unit of work must be wrapped in a manually
created transaction** — the agent will not create one on its own.

### Transactions — manual creation

A transaction represents one top-level unit of work (an incoming request, a job, a scheduled
task, a CLI command). Create one at the outermost entry point of each work item:

```python
import elasticapm
from common.ecs_logging import get_logger

logger = get_logger(__name__)
apm = elasticapm.get_client()


def run_pipeline(job_id: str, records: list[dict[str, object]]) -> None:
    """Entry point for a background processing job."""
    apm.begin_transaction("pipeline")
    elasticapm.label(job_id=job_id, record_count=len(records))
    try:
        _execute_pipeline(job_id, records)
        apm.end_transaction("pipeline.run", "success")
    except Exception:
        apm.capture_exception()
        apm.end_transaction("pipeline.run", "failure")
        raise
```

**Rules for transactions:**

- Every independently schedulable or invokable unit of work must have exactly one transaction.
- Set the transaction `result` to `"success"` or `"failure"` before ending it.
- Use `elasticapm.label(...)` to attach searchable metadata (key-value pairs) to the
  transaction. Labels must be strings, booleans, or numbers — never nested objects.
- Never create a transaction inside another transaction — use a span instead.

### Spans — `@elasticapm.capture_span` decorator

Every public function and method that represents a meaningful unit of work within a transaction
**must** be decorated with `@elasticapm.capture_span`. This is the standard and preferred way
to create spans — do not create spans manually with `begin_span` / `end_span` unless the
function boundary does not map cleanly to a span (e.g. iterating a generator).

```python
import elasticapm
from common.ecs_logging import get_logger

logger = get_logger(__name__)


class RecordProcessor:
    """Processes individual records in the pipeline."""

    @elasticapm.capture_span("process_batch", span_type="app")
    def process_batch(self, records: list[dict[str, object]]) -> int:
        """Process a batch of records and return the success count."""
        logger.info("Batch started", extra={"labels": {"batch_size": len(records)}})
        return sum(self._process_one(r) for r in records)

    @elasticapm.capture_span("process_one", span_type="app")
    def _process_one(self, record: dict[str, object]) -> int:
        """Process a single record. Returns 1 on success, 0 on handled failure."""
        ...


@elasticapm.capture_span("load_config", span_type="app.io")
def load_config(path: str) -> dict[str, object]:
    """Load configuration from disk."""
    ...


@elasticapm.capture_span("fetch_remote_data", span_type="external.http")
async def fetch_remote_data(url: str) -> bytes:
    """Fetch data from a remote endpoint."""
    ...
```

**Span naming and type conventions:**

| `span_type`     | When to use                                                 |
|-----------------|-------------------------------------------------------------|
| `app`           | General business logic, in-process computation              |
| `app.io`        | File or local I/O not covered by auto-instrumentation       |
| `db`            | Database operations not covered by auto-instrumentation     |
| `external.http` | Outbound HTTP calls not covered by auto-instrumentation     |
| `messaging`     | Queue producers/consumers (Kafka, RabbitMQ, SQS, etc.)      |
| `cache`         | Cache reads/writes (Redis, Memcached) not auto-instrumented |

**Rules for spans:**

- Decorate every public function and every public method with `@elasticapm.capture_span`.
- Decorate private helpers (`_name`) when they represent a distinct, measurable sub-operation.
- Always provide a descriptive `span_type`; never leave it as the default `"code"`.
- The span name (first argument) must be a **static string** — never an f-string or a value
  derived from runtime data. Runtime context belongs in labels, not the span name.
- Do not nest `capture_span` on a function that is itself already a transaction entry point.

### Exception capture

All exceptions that propagate beyond a transaction or span boundary **must** be captured with
the APM client so they appear in the Elastic APM Errors view. Use
`apm.capture_exception()` inside every `except` block that handles or re-raises an exception:

```python
import elasticapm
from common.ecs_logging import get_logger
from my_package.exceptions import AppError, ExternalServiceError

logger = get_logger(__name__)
apm = elasticapm.get_client()


@elasticapm.capture_span("call_external_api", span_type="external.http")
def call_external_api(url: str) -> dict[str, object]:
    """Call an external API and return the parsed JSON response."""
    try:
        return _do_http_request(url)
    except ExternalServiceError as exc:
        apm.capture_exception()                  # report to APM Errors
        logger.exception(
            "External API call failed",
            extra={"url": {"full": url}, "error": {"message": str(exc)}},
        )
        raise                                    # always re-raise unless intentionally absorbed


def run_job(job_id: str) -> None:
    """Top-level job runner — owns the transaction."""
    apm = elasticapm.get_client()
    apm.begin_transaction("job")
    try:
        _execute(job_id)
        apm.end_transaction("job.run", "success")
    except AppError:
        apm.capture_exception()              # report to APM Errors
        apm.end_transaction("job.run", "failure")
        raise
    except Exception:
        apm.capture_exception()              # catch-all at transaction boundary
        apm.end_transaction("job.run", "failure")
        raise
```

**Rules for exception capture:**

- Call `apm.capture_exception()` inside **every** `except` block, without exception.
  This applies to both re-raising and absorbing handlers.
- `apm.capture_exception()` must be called **before** `logger.exception(...)` so the APM
  error and the log record share the same active span context.
- Never swallow an exception at a transaction boundary without calling `capture_exception`
  first and setting the transaction result to `"failure"`.
- Do not pass the exception object to `capture_exception()` — it reads from `sys.exc_info()`
  automatically when called from inside an `except` block.

### Full annotated example

```python
# src/my_package/worker.py
"""Background worker that processes queued jobs."""

import elasticapm
from common.ecs_logging import get_logger
from my_package.exceptions import AppError, ExternalServiceError
from my_package.repository import JobRepository
from my_package.api_client import ApiClient

logger = get_logger(__name__)
apm = elasticapm.get_client()


class JobWorker:
    """Consumes jobs from the queue and processes them."""

    def __init__(self, repo: JobRepository, client: ApiClient) -> None:
        self._repo = repo
        self._client = client

    def run(self, job_id: str) -> None:
        """Process a single job. Creates the APM transaction."""
        apm.begin_transaction("job")
        elasticapm.label(job_id=job_id)
        try:
            payload = self._fetch_payload(job_id)
            result = self._transform(payload)
            self._persist(job_id, result)
            apm.end_transaction("job.run", "success")
            logger.info("Job completed", extra={"labels": {"job_id": job_id}})
        except AppError:
            apm.capture_exception()
            apm.end_transaction("job.run", "failure")
            raise

    @elasticapm.capture_span("fetch_payload", span_type="external.http")
    def _fetch_payload(self, job_id: str) -> dict[str, object]:
        """Fetch the job payload from the external API."""
        try:
            return self._client.get(f"/jobs/{job_id}/payload")
        except ExternalServiceError:
            apm.capture_exception()
            logger.exception("Failed to fetch payload", extra={"labels": {"job_id": job_id}})
            raise

    @elasticapm.capture_span("transform_payload", span_type="app")
    def _transform(self, payload: dict[str, object]) -> dict[str, object]:
        """Apply business-logic transformation to the raw payload."""
        try:
            return _apply_rules(payload)
        except ValueError:
            apm.capture_exception()
            logger.exception("Payload transformation failed")
            raise AppError("Invalid payload structure") from None

    @elasticapm.capture_span("persist_result", span_type="db")
    def _persist(self, job_id: str, result: dict[str, object]) -> None:
        """Write the processed result to the database."""
        try:
            self._repo.save(job_id, result)
        except Exception:
            apm.capture_exception()
            logger.exception("Failed to persist result", extra={"labels": {"job_id": job_id}})
            raise
```

---

## 15. Git & Commit Conventions

Commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <short imperative description>

[optional body — wrap at 72 chars]

[optional footer: BREAKING CHANGE, Closes #issue]
```

| Type       | When to use                                 |
|------------|---------------------------------------------|
| `feat`     | New user-visible feature                    |
| `fix`      | Bug fix                                     |
| `refactor` | Code restructuring with no behaviour change |
| `test`     | Adding or updating tests only               |
| `docs`     | Documentation only                          |
| `chore`    | Build scripts, dependency bumps, CI config  |
| `perf`     | Performance improvement                     |
| `revert`   | Reverts a previous commit                   |

**Rules:**

- Subject line: imperative mood, ≤ 72 characters, no trailing period.
- Never commit directly to `main` or `master`; always use a short-lived feature branch and a
  pull request.
- Squash or fixup WIP / checkpoint commits before merging.
- Reference the relevant issue in the footer: `Closes #42`.
- Include a link to the Claude session at the end of each commit message (automatically
  appended by Claude Code).
- Feature branches follow the pattern: `claude/<description>-<session-id>`
- Always push with: `git push -u origin <branch-name>`
- Branch names must start with `claude/` and end with the matching session ID, or the push
  will fail with a 403.
- On network failure, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s).

---

## 16. CI Checks (definition of done)

All of the following must pass before any branch can be merged:

```bash
# 1. Type checking
mypy src/

# 2. Tests with branch coverage
pytest --cov --cov-report=term-missing

# 3. Verify requirements files are up to date with the lock
uv export --no-hashes | diff - requirements.txt
uv export --no-hashes --only-group dev | diff - requirements-dev.txt

# 4. Lint and format checks
ruff format --check .
ruff check .
```

---

## 17. Security Standards

Security is a first-class concern in every code change. Apply the rules in this section
whenever writing, editing, or reviewing code that handles input, data, credentials, or external
systems.

### Dependency security

- **Never** introduce a dependency without checking it on [OSV.dev](https://osv.dev) or
  running `pip audit` / `uv audit` first.
- Add `pip-audit` to the dev dependency group and run it in CI.
- Prefer well-maintained packages with a clear security disclosure policy.
- Never depend on a package by its GitHub URL — only use PyPI releases.

### Input validation and injection

- **Never** construct SQL, shell commands, XML, or HTML by string concatenation or f-string
  formatting. Always use parameterised queries, `subprocess` with a list argument (never
  `shell=True`), or a proper templating library.

```python
# GOOD — parameterised query
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# BAD — SQL injection risk
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")


# GOOD — subprocess without shell
result = subprocess.run(["git", "log", "--oneline", "-n", "10"], capture_output=True)

# BAD — shell injection risk
result = subprocess.run(f"git log --oneline -n {count}", shell=True)
```

- All data crossing a trust boundary must be validated through a Pydantic model before use.
- Never call `eval()`, `exec()`, or `compile()` on user-supplied input.
- Never deserialise untrusted data with `pickle`, `marshal`, or `shelve`.

### Secrets and credentials

- All secrets live in environment variables and are loaded through `Settings` (Section 11).
- Never log a secret, even at `DEBUG` level, even partially.
- When comparing secrets, always use `hmac.compare_digest` — never `==`.

```python
import hmac

def verify_webhook(payload: bytes, signature: str, secret: str) -> bool:
    """Verify an HMAC-SHA256 webhook signature in constant time."""
    expected = hmac.new(secret.encode(), payload, "sha256").hexdigest()
    return hmac.compare_digest(expected, signature)
```

### File and path handling

- Never construct file paths by string concatenation. Always use `pathlib.Path` operators.
- Validate that resolved paths remain within the expected directory (path traversal prevention):

```python
from pathlib import Path


def safe_open(base_dir: Path, filename: str) -> Path:
    """Resolve a user-supplied filename within a base directory.

    Raises:
        ValueError: If the resolved path escapes the base directory.
    """
    target = (base_dir / filename).resolve()
    if not target.is_relative_to(base_dir.resolve()):
        raise ValueError(f"Path traversal detected: {filename!r}")
    return target
```

### Cryptography

- Never implement cryptographic primitives from scratch.
- Never use MD5 or SHA-1 for security purposes. Use SHA-256 or stronger.
- Never use `random` for security-sensitive values. Use `secrets`.

```python
import secrets

# GOOD — cryptographically secure
token = secrets.token_urlsafe(32)

# BAD — predictable, not cryptographically secure
import random
token = "".join(random.choices("abcdefghijklmnopqrstuvwxyz", k=32))
```

---

## 18. Data Validation Standard

**Pydantic v2 is the single approved library for data validation across all trust boundaries.**

### What counts as a trust boundary

- HTTP request bodies, query parameters, and headers
- Database rows read from any external store
- Queue and event-stream messages
- Responses from external HTTP APIs
- Files read from disk written by another process or user
- Environment variables (handled by `pydantic-settings` — see Section 11)
- CLI arguments passed by a user

### Defining models

```python
# src/my_package/models/job.py
"""Pydantic models for job lifecycle data."""

from datetime import datetime
from enum import StrEnum
from pydantic import BaseModel, Field, field_validator, model_validator


class JobStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILURE = "failure"


class Job(BaseModel):
    """Represents a single processing job."""

    model_config = {"frozen": True, "strict": True}

    job_id: str = Field(..., min_length=1, max_length=64, pattern=r"^[a-z0-9\-]+$")
    status: JobStatus = JobStatus.PENDING
    priority: int = Field(default=0, ge=0, le=10)
    payload: dict[str, object]
    created_at: datetime
    tags: list[str] = Field(default_factory=list, max_length=20)

    @field_validator("tags")
    @classmethod
    def tags_must_be_lowercase(cls, v: list[str]) -> list[str]:
        return [tag.lower() for tag in v]
```

### Model configuration rules

| Setting  | Required value                | Reason                                                          |
|----------|-------------------------------|-----------------------------------------------------------------|
| `frozen` | `True` for value objects      | Prevents accidental mutation; enables hashing                   |
| `strict` | `True`                        | Disables silent coercion; makes bugs visible                    |
| `extra`  | `"forbid"` for external input | Rejects unknown fields from untrusted sources                   |
| `extra`  | `"ignore"` for API responses  | Tolerates additive changes from external APIs                   |

### Serialisation

- Use `model.model_dump()` to serialise to a `dict`; use `model.model_dump_json()` for JSON.
- Never use `json.dumps(model.dict())` — `.dict()` is a Pydantic v1 alias and is deprecated.
- Use `model_dump(mode="json")` when the output must be JSON-safe.

---

## 19. API & Interface Design

### Module public surface (`__all__`)

Every module intended to be imported by other modules must define `__all__`.

### Naming conventions

| Kind              | Convention                       | Example                          |
|-------------------|----------------------------------|----------------------------------|
| Module            | `snake_case`, singular noun      | `job.py`, `payment.py`           |
| Package           | `snake_case`, singular noun      | `my_package/`                    |
| Class             | `PascalCase`                     | `JobWorker`, `PaymentProcessor`  |
| Exception         | `PascalCase` + `Error` suffix    | `ConfigurationError`             |
| Function / method | `snake_case`, verb phrase        | `fetch_payload`, `normalize`     |
| Constant          | `UPPER_SNAKE_CASE`               | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Private           | leading underscore               | `_internal_helper`, `_validate`  |
| Type alias        | `PascalCase` via `type` statement| `type Vector = list[float]`      |

### Function and method design

- Functions must do **one thing**.
- Maximum function length: **40 lines** of executable code.
- Maximum number of parameters: **5**. Group excess parameters into a Pydantic model.
- Prefer **keyword-only arguments** for boolean flags and non-obvious parameters.
- Prefer **return values over output parameters**.

```python
# GOOD — keyword-only flag; call site is self-documenting
def normalize(values: list[float], *, clip: bool = False) -> list[float]: ...

normalize([1.0, 2.0, 3.0], clip=True)   # intent is clear
```

### Class design

- Apply the **single-responsibility principle**.
- Maximum class length: **200 lines** of executable code.
- Prefer **composition over inheritance**.
- Do not define `__init__` methods that perform I/O, network calls, or significant computation.
  Use a `@classmethod` factory instead.

```python
# GOOD — lightweight __init__; factory handles I/O
class ApiClient:
    """HTTP client for the external job API."""

    def __init__(self, base_url: str, timeout: float, secret: str) -> None:
        self._client = httpx.Client(base_url=base_url, timeout=timeout)
        self._secret = secret

    @classmethod
    def from_settings(cls, settings: Settings) -> "ApiClient":
        """Construct an ApiClient from application settings."""
        return cls(
            base_url=settings.api_base_url,
            timeout=settings.request_timeout,
            secret=settings.api_secret,
        )
```

---

## 20. README Standard

Every repository must contain a `README.md` satisfying the following structure. Generate or
update the README whenever creating a new project or significantly changing the project's
interface, dependencies, or setup steps.

### Required sections (in order)

```markdown
# <Project Name>

One or two sentences describing what the project does and who it is for.

## Requirements
## Installation
## Environment Variables
## Running the Application
## Running Tests
## Architecture
## Contributing
```

### Rules

- Every environment variable in `.env.example` must appear in the README table, and vice versa.
- Keep the README under **150 lines**. Detailed documentation belongs in `docs/`.

---

## 21. Module & Class Design Guidelines

### When to split a module into a sub-package

Convert a single module file (`feature.py`) into a sub-package (`feature/`) when any of the
following is true:

- The file exceeds **300 lines** of executable code.
- The file contains more than **3 public classes**.
- Two distinct groups of functions have no imports from each other.
- A second module needs to import only a subset of the file's symbols.

### Avoiding circular imports

Circular imports are always a design smell. Never resolve a circular import with a local
(inside-function) import unless it is a temporary measure with a `# TODO(#issue)` tracking
its removal.

### Dependency direction rule

Dependencies must always flow in one direction:

```
entry points  (scripts/, __main__.py)
   ↓
services      (orchestration, use-case logic)
   ↓
domain        (models/, core business logic)
   ↓
infrastructure  (repository, API clients, queue adapters)
   ↓
common        (shared utilities, config, logging)
```

### File length hard limits

| File type              | Soft limit | Hard limit | Action when exceeded    |
|------------------------|------------|------------|-------------------------|
| Module (`.py`)         | 200 lines  | 300 lines  | Split into sub-package  |
| Class body             | 100 lines  | 200 lines  | Split by responsibility |
| Function / method body | 20 lines   | 40 lines   | Extract named helpers   |
| Test file              | 200 lines  | 400 lines  | Split by test category  |

---

## 22. What Claude Must NOT Do

**Code quality:**

- Do not add `# type: ignore` without an inline comment explaining the suppression.
- Do not use `Any` as a type unless there is genuinely no alternative — document it when used.
- Do not use `typing.List`, `typing.Dict`, `typing.Optional`, or `typing.Union`.
- Do not use `from __future__ import annotations` — unnecessary in Python 3.14.
- Do not use wildcard imports (`from module import *`).
- Do not use f-strings inside `logger.*()` calls — use `%`-style lazy formatting.

**Logging (ECS):**

- Do not call `logging.getLogger` directly — always use `common.ecs_logging.get_logger`.
- Do not call `logging.basicConfig` or add handlers manually.
- Do not use `print()` for operational output under any circumstance.
- Do not include secrets, PII, or credentials in any log message or `extra` field.
- Do not invent ECS field names — use only fields defined in the official ECS field reference.

**Project hygiene:**

- Do not introduce new dependencies without updating `pyproject.toml` **and** regenerating
  the lock file and requirements exports, and without explicit user approval.
- Do not leave `TODO` comments without an issue reference: `# TODO(#42): description`.
- Do not hard-code file paths, magic numbers, or unexplained constants.
- Do not commit `.env` files or any file containing real credentials.

**Testing:**

- Do not write tests that call real external services without mocking them.
- Do not use bare `try/except` in test bodies — use `pytest.raises`.
- Do not use `# pragma: no cover` to artificially inflate coverage metrics.

**Error handling:**

- Do not silently swallow exceptions with a bare `except: pass`.
- Do not catch `BaseException`, `KeyboardInterrupt`, or `SystemExit` without re-raising.

**APM instrumentation:**

- Do not write a public function or method without a `@elasticapm.capture_span` decorator,
  unless it is the transaction entry point itself.
- Do not use a runtime value or f-string as the span name — span names must be static strings.
- Do not create a transaction inside an existing transaction — use a span instead.
- Do not call `apm.end_transaction(...)` without setting the result to `"success"` or `"failure"`.
- Do not catch an exception without calling `apm.capture_exception()` inside the `except` block.

**Security:**

- Do not construct SQL, shell commands, or markup by string concatenation or f-strings.
- Do not call `eval()`, `exec()`, or `compile()` on any externally supplied input.
- Do not deserialise untrusted data with `pickle`, `marshal`, or `shelve`.
- Do not use `==` to compare secrets or HMAC signatures — use `hmac.compare_digest`.
- Do not use `random` for security-sensitive values — use `secrets`.
- Do not use MD5 or SHA-1 for any security purpose.
- Do not open files at paths constructed from user input without path traversal validation.
- Do not introduce a new dependency without running `pip-audit` against it first.

**Data validation:**

- Do not pass raw `dict`, `str`, or untyped data from an external source into business logic.
- Do not use `.dict()` (Pydantic v1 alias) — use `.model_dump()`.
- Do not use `dataclass` for external-data models that require validation — use Pydantic.
- Do not set `extra = "allow"` on any Pydantic model.
- Do not define a Pydantic model without an explicit `model_config` block.

**API & interface design:**

- Do not write a public module without defining `__all__`.
- Do not write a function longer than 40 lines of executable code without extracting helpers.
- Do not write a function with more than 5 parameters.
- Do not perform I/O, network calls, or significant computation in `__init__`.
- Do not use positional boolean parameters — make them keyword-only (after `*`).
- Do not import from a higher architectural layer — dependencies flow downward only.

**Module & class structure:**

- Do not allow a module to exceed 300 lines of executable code.
- Do not allow a class to exceed 200 lines of executable code.
- Do not resolve a circular import with a local import — fix the dependency direction.
- Do not scatter constants throughout a file — group them at the top, after imports.

---

## Working with Claude Code

- **Claude Code docs**: https://docs.anthropic.com/en/docs/claude-code
- **Model in use**: `claude-sonnet-4-6` (default); switch to `claude-opus-4-6` for complex
  tasks or `claude-haiku-4-5` for fast/cheap tasks.
- **Hooks**: Claude Code supports `SessionStart` and other lifecycle hooks — add them under
  `.claude/hooks/` as experiments are built.
- **Skills / Slash commands**: Project-specific skills can be defined and invoked with
  `/skill-name`.

## Adding New Experiments

1. Create a module under `src/rag_principals/<experiment_name>.py`.
2. Add tests in `tests/test_<experiment_name>.py`.
3. Update the **Repository Structure** section above.
4. Commit and push to the active development branch.

## Current Status

- **Phase**: Python project scaffolding complete
- **Active branch**: `claude/update-claude-python-standards-iPJNH`
- **Last updated**: 2026-03-15
