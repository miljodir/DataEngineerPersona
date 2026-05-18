```prompt
---
name: db-migrate
description: One-click SQL Server to PostgreSQL database migration. Works with WideWorldImporters demo OR any customer SQL Server endpoint. Multi-tool redundancy with 12 cross-validating tools.
agent: db-migration
argument-hint: "[sourcePath] e.g. samples/wide-world-importers OR leave blank to use SQLSERVER_* / PG_* from .env"
tools: ['read/readFile', 'search/codebase', 'search/fileSearch', 'search/textSearch', 'search/listDirectory', 'todo', 'agent', 'execute', 'edit', 'search']
---

# One-Click SQL Server to PostgreSQL Migration

Read the skill file `.github/skills/sql-to-postgres/SKILL.md` first - it is the single source of truth for orchestration.

## Mode Selection

If `sourcePath` is provided and matches a folder under `samples/` → run **Demo mode** against the local Docker WideWorldImporters lab using `wsl zsh -c "scripts/migrate-data.sh"`.

If `sourcePath` is empty (just `/db-migrate` with no argument) → run **BYO Endpoint mode** against the SQL Server and PostgreSQL defined in `.env` (`SQLSERVER_*` and `PG_*`) using `wsl zsh -c "scripts/migrate-endpoint.sh"`.

Source path argument: `${input:sourcePath:samples/wide-world-importers}`

## Required Outcome

Execute phases 1-3 end-to-end (phases 4-5 optional). Produce result docs in `docs/` only.

### Phase Workflow

1. **Phase 0: Precheck**
   - Verify all 12 tools are available.
   - Connect to source SQL Server via MSSQL extension.

2. **Phase 1: Source Assessment**
   - 3-tool schema discovery (MSSQL ext + ora2pg + DAB).
   - Extract all SP/trigger/view definitions.
   - Scan 24 T-SQL incompatible patterns.
   - Capture SSMS 22 performance baseline.
   - Run sec-check security baseline.
   - Generate `docs/01-source-assessment.md` and `docs/tsql-incompatibility-report.md`.

3. **Phase 2: Migration Execution**
   - pgLoader dry-run then actual transfer.
   - Translate SPs: Copilot + ora2pg merge best then sqlfluff lint then pgtap test.
   - Rewrite incompatible patterns (cursors to CTEs, MERGE to upsert, etc.).
   - Document reasoning in `docs/schema-optimization-logic.md`.
   - Generate `docs/02-migration-execution.md`.

4. **Phase 3: Validation (Iterate Until Consensus)**
   - Data integrity: row counts + checksums + DAB API regression.
   - Functional equivalence: pgtap + DAB REST + side-by-side queries.
   - Performance: 10 perf tests with timestamped JSON tracking.
   - Security: 10 sec tests with pass/fail.
   - Generate `docs/03-validation-report.md` and `tests/performance/results/trending.md`.

5. **Phase 4: Fabric Integration (Optional)**
   - SqlPackage to Fabric SQL DB.
   - DAB config to Fabric endpoint.
   - Generate `docs/04-fabric-integration.md`.

6. **Phase 5: Data Agent (Optional)**
   - DAB MCP Server on PostgreSQL.
   - Fabric Data Agent / AI Skill.
   - Generate `docs/05-data-agent-setup.md`.

## Guardrails

- Database-layer only - no application code.
- Always target Azure Database for PostgreSQL Flexible Server.
- Always use multi-tool cross-validation (no single tool decides).
- Always track results across iterations.
- Only write result docs to `docs/`.

## Final Response Format

1. Source schema summary (tables, SPs, triggers, sequences)
2. T-SQL incompatibility count (HIGH/MEDIUM/LOW)
3. ora2pg complexity score
4. Multi-tool consensus status per step
5. Performance metrics (before/after)
6. Security posture (before/after)
7. Migration readiness score (percent tests passing)
8. Risks and next action
```
