# Python Rules

Stack-specific rules. Load **alongside** `../general-rules.md` when working in a Python project.

---

## Runtime & tooling

- Python 3.11+ for new projects. Pin in `pyproject.toml` `requires-python`.
- Dependency management: **one** of `uv` / `poetry` / `pip-tools` per project. Don't mix.
- Lockfile committed; environments reproducible.
- `ruff` for linting **and** formatting (replaces flake8 + black + isort + pyupgrade).
- `mypy` or `pyright` for type checking, configured in `pyproject.toml` with `strict = true` for new modules.
- `pytest` for testing.

---

## File layout

- **src-layout**: source under `src/<package_name>/`, not flat.
- Tests under `tests/`, mirroring source structure.
- Entry points exposed via `pyproject.toml` `[project.scripts]`, not loose `main.py` scripts.
- Settings via `pydantic-settings` (or Django settings) — never bare `os.environ` reads scattered across modules.

---

## Typing

- Type hints on every public function/method signature.
- `from __future__ import annotations` at the top of modules using forward refs (PEP 563).
- No `Any` without a `# reason: <one line>` comment.
- No `# type: ignore` without a code (`# type: ignore[arg-type]`) and a reason.
- Prefer `dataclasses` / `pydantic` models / `attrs` over loose dicts for structured data.
- `TypedDict` for dict-shaped responses you can't model otherwise.

---

## Patterns

- Early returns over nested `if`.
- Comprehensions for simple transforms; explicit loops when there's logic or side effects.
- Context managers (`with`) for all file/connection/lock acquisition.
- **Mutable default arguments are a defect**: `def f(x=[]):` is forbidden — use `def f(x: list[int] | None = None): x = x or []`.
- `pathlib.Path` over `os.path` strings.
- F-strings over `%` or `.format()`.
- `enum.Enum` (or `StrEnum`) for closed sets of values; not string literals scattered through the code.

---

## Web frameworks

### FastAPI
- Pydantic models for every request/response body. Don't accept `dict`.
- Dependency injection (`Depends`) for auth, DB session, current user.
- Routers per feature, mounted in a single `main.py`.
- Background work goes to a real queue (Celery / RQ / Arq), not `BackgroundTasks` for anything serious.

### Django
- Fat models, thin views, business logic in `services.py` modules per app.
- `select_related` / `prefetch_related` to avoid N+1 queries — verify with `django-debug-toolbar` in dev.
- Forms / DRF serializers for input validation.
- Migrations checked in; never `--fake` outside of recovery scenarios.

### Flask
- Blueprints organized by feature, not by file type.
- Application factory pattern (`create_app()`).
- Marshmallow / pydantic for request validation; don't trust `request.json` directly.

---

## Async

- Don't mix sync and async carelessly. Calling sync blocking I/O from inside an async coroutine kills throughput — wrap with `asyncio.to_thread()`.
- `httpx` async client over `requests` in async paths.
- One event loop per process; don't `asyncio.run()` from inside another loop.

---

## Pre-PR checklist

```bash
ruff check .                # lint
ruff format --check .       # format
mypy .                      # or pyright
pytest                      # tests (with --cov for coverage)
```

---

## Security

- Parameterized queries / ORM only; never string-format SQL.
- `secrets.token_urlsafe()` for tokens — not `random` (predictable).
- Pin and audit dependencies (`pip-audit`, `safety`).
- **Avoid `pickle` for untrusted input** — RCE risk. Use JSON / msgpack / protobuf.
- `subprocess` calls: pass args as a list (`["cmd", "arg"]`), never `shell=True` with user input.
- `yaml.safe_load`, never `yaml.load`.
- Django: `DEBUG=False` in prod, `ALLOWED_HOSTS` set, CSRF middleware on, `SECURE_*` settings enabled.
