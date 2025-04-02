.PHONY: fmt
fmt:
	uv run ruff format src
	uv run ruff check --select I --fix src
	uv run ruff check --fix src