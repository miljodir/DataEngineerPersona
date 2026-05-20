# Copilot Instructions - SQL to PostgreSQL Migration

## What This Repo Is

A **language-agnostic SQL Server to PostgreSQL migration accelerator** using multi-tool redundancy. It targets Azure Database for PostgreSQL Flexible Server with optional Microsoft Fabric integration.

## Workspace Layout

```
.github/                        # Copilot orchestration (agent, skill, prompt, rules)
.devcontainer/                  # One-click Codespaces / VS Code dev container
dab/                            # Data API Builder configs (SQL Server, PostgreSQL, Fabric)
docs/                           # Generated phase result documents
tests/                          # Security, performance, pgtap, row-count tests
benchmarks/                     # HammerDB + pgbench configs and results
security/                       # Security baselines and hardening guides
scripts/                        # Bash automation scripts (canonical public path)
samples/wide-world-importers/   # WideWorldImporters demo database assets
reference/                      # T-SQL to PL/pgSQL cheatsheet, Azure best practices
templates/                      # Reusable pgLoader and Fabric config templates
```

## Critical Conventions

- **Language-agnostic.** This repo focuses on the database layer only. No application code.
- **Multi-tool redundancy.** Every critical step must be validated by 2-3 independent tools. No single tool decides.
- **Iterate to consensus.** If tools disagree, investigate, fix, re-run until they agree.
- **Target: Azure Database for PostgreSQL Flexible Server.** Always use Entra ID passwordless auth.
- **Document the why.** Every type, index, and SP translation must include reasoning.
- **Track results.** Every test run produces timestamped JSON. Trending is auto-generated.

## The 11 Tools

1. MSSQL Extension - source schema inspector
2. PostgreSQL Extension - target schema validator
3. pgLoader - bulk data migration with dry-run
4. DAB (Data API Builder) - API abstraction + MCP server
5. sqlfluff - PL/pgSQL linter
6. pgtap / pg_prove - PL/pgSQL unit tests
7. HammerDB - cross-platform TPC-C benchmarking
8. sec-check - security scanning
9. SSMS 22 - execution plan baseline
10. Azure Premigration Validation - connectivity/schema checks
11. Copilot Agent - orchestrates all tools

## Key Commands (canonical bash flow)

```bash
# One-click migration via Copilot Chat
# /db-migrate                           # BYO endpoint (uses .env)
# /db-migrate samples/wide-world-importers   # Local Docker demo

# Demo: WideWorldImporters local Docker
wsl zsh -c "scripts/setup-local-env.sh"         # Start containers + restore .bak
wsl zsh -c "scripts/migrate-data.sh"            # Schema + data + functions + row-count check

# BYO endpoint: any customer SQL Server -> any PostgreSQL
cp .env.example .env                    # Edit SQLSERVER_* and PG_* values
wsl zsh -c "scripts/migrate-endpoint.sh"        # pgloader-based generic transfer

# Manual phases
wsl zsh -c "scripts/run-assessment.sh --connection-string '...'"
wsl zsh -c "scripts/run-migration.sh"
wsl zsh -c "scripts/validate-migration.sh"

# DAB (Data API Builder)
dab start --config dab/dab-config-sqlserver.json
dab start --config dab/dab-config-postgres.json

# Tests
pg_prove -d test_db tests/pgtap/t/
bash tests/performance/run-performance-tests.sh
bash tests/security/run-security-tests.sh
```

> Bash is the canonical, public path. PowerShell variants exist locally for Windows-only personal use and are gitignored.

## When Editing Agent, Skill, or Prompt Files

- Agent definition (`.github/agents/db-migration.agent.md`) declares tool access - keep `tools:` in sync.
- Skill file (`.github/skills/sql-to-postgres/SKILL.md`) is the single source of truth for orchestration.
- Prompt file (`.github/prompts/db-migrate.prompt.md`) binds to `db-migration` agent.
- Rules (`.github/rules/database-rules.md`) govern all schema translations and testing requirements.
