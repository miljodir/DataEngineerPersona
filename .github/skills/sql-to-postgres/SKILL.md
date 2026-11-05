---
name: sql-to-postgres
description: Language-agnostic SQL Server to PostgreSQL database migration skill using multi-tool redundancy. Covers assessment, migration, validation, Fabric integration, and data agent setup with 12 cross-validating tools.
version: 1.0.0
author: DB Transform Team
maturity: stable
requires:
  agents:
    - db-migration
  tools:
    - mssql_connect
    - mssql_list_tables
    - mssql_run_query
    - mssql_list_schemas
    - mssql_list_views
    - mssql_list_functions
    - mssql_dab
    - pgsql_migration_show_report
trigger_phrases:
  - "migrate sql server to postgresql"
  - "sql to postgres migration"
  - "database modernization"
  - "stored procedure migration"
  - "tsql to plpgsql"
  - "db transform"
  - "database upgrade to postgres"
---

# SQL Server to PostgreSQL Migration Skill

This is the **single source of truth** for running the end-to-end database migration.
All orchestration lives here. `docs/` only holds generated results.

---

## When to Use

- A team needs to migrate SQL Server to Azure Database for PostgreSQL Flexible Server.
- Migration must be language-stack agnostic (database layer only, no application code).
- Requires multi-tool redundancy - no single tool does the upgrade.
- Needs tracked security and performance test results with iteration trending.

## Core Philosophy

**Iterate to consensus.** For each step:
1. Run Tool A (primary)
2. Run Tool B (cross-check)
3. Run Tool C (sanity check)
4. Compare - all agree? Pass. Disagree? Investigate, fix, re-run.
5. Final result = merged best from all tools.

## Inputs

| Input | Required | Default |
|---|---|---|
| `sourcePath` | Yes | - |
| `sourceConnectionString` | Yes | - |
| `targetConnectionString` | No | auto-provisioned Azure PG |
| `demoDatabase` | No | `WideWorldImporters` |

---

## Phase-by-Phase Orchestration

### Phase 0: Precheck

1. Verify MSSQL extension is available (`mssql_connect`).
2. Verify PostgreSQL extension is available (`pgsql_*`).
3. Check for ora2pg, pgLoader, sqlfluff, pgtap, pg_prove, HammerDB availability.
4. Check for DAB CLI (`dab --version`).
5. Check for sec-check CLI (`agentsec --version`).

### Phase 1: Source Assessment

**Tools:** `mssql_connect`, `mssql_list_tables`, `mssql_run_query`, ora2pg, DAB, SSMS 22, sec-check
**Output:** `docs/01-source-assessment.md`, `docs/tsql-incompatibility-report.md`

**Step 1.1: Schema Discovery (3-tool cross-validation)**

| Tool | Action | Purpose |
|---|---|---|
| MSSQL ext | `mssql_connect` then `mssql_list_tables` then `mssql_run_query` on INFORMATION_SCHEMA | Ground truth schema inventory |
| ora2pg | `ora2pg -t SHOW_REPORT` | Independent complexity assessment (A/B/C score) |
| DAB | `dab init --database-type mssql` | Entity discovery / migration manifest |

Consensus gate: All 3 report same table count, column types, FK relationships.

**Step 1.2: SP/Trigger/View Extraction**

```sql
-- Run via mssql_run_query
SELECT
  o.name AS object_name,
  o.type_desc,
  m.definition,
  LEN(m.definition) AS definition_length
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
ORDER BY o.type_desc, o.name;
```

**Step 1.3: T-SQL Incompatibility Scan (24 patterns)**

Scan all extracted definitions for:
- **HIGH:** Cursors, MERGE, @@TRANCOUNT/nested transactions, HIERARCHYID, GEOGRAPHY/GEOMETRY, linked servers, OPENROWSET/OPENQUERY
- **MEDIUM:** @@ROWCOUNT, @@IDENTITY, CROSS APPLY, TRY/CATCH, #TempTables, table variables, sp_executesql, TRY_CAST
- **LOW:** ISNULL to COALESCE, NEWID to gen_random_uuid, GETDATE to NOW, TOP to LIMIT, NOLOCK to remove, RAISERROR to RAISE EXCEPTION, OUTPUT to RETURNING

Output: `docs/tsql-incompatibility-report.md` with every instance, location, severity, recommended fix.

**Step 1.4: Performance Baseline**

Capture SSMS 22 execution plans for key stored procedures. Record:
- Execution time (ms)
- Logical reads
- Plan cost
- Query hint recommendations

**Step 1.5: Security Baseline**

```sql
-- Run via mssql_run_query
SELECT name, type_desc, is_disabled FROM sys.sql_logins;
SELECT * FROM sys.server_permissions;
SELECT name, is_encrypted FROM sys.databases;
```

Also run: `agentsec scan` on any SQL scripts in the source path.

**Mermaid Diagrams:** Source ER diagram, SP dependency graph, incompatibility heatmap.

---

### Phase 2: Migration Execution

**Tools:** pgLoader v4 (Podman by default), ora2pg, Copilot, sqlfluff, pgtap, PostgreSQL ext
**Output:** `docs/02-migration-execution.md`, `docs/schema-optimization-logic.md`

**Step 2.1: pgLoader Dry Run**

```bash
scripts/run-migration.sh --dry-run
```

Validate type mappings. Cross-check with ora2pg schema conversion output.

**Step 2.2: Data Transfer**

```bash
scripts/run-migration.sh --execute
```

pgLoader CAST rules for WideWorldImporters:
- `NVARCHAR` to `TEXT`
- `BIT` to `BOOLEAN`
- `DECIMAL` to `NUMERIC`
- `DATETIME2` to `TIMESTAMPTZ`
- `UNIQUEIDENTIFIER` to `UUID`
- `MONEY` to `NUMERIC(19,4)`
- `HIERARCHYID` to `TEXT` (with ltree migration plan)
- `GEOGRAPHY` to PostGIS `geography`

**Step 2.3: SP Translation (T-SQL to PL/pgSQL)**

For each stored procedure:
1. Copilot generates PL/pgSQL translation from MSSQL ext source
2. ora2pg auto-converts independently
3. Compare outputs - merge best of both
4. sqlfluff lint the result
5. Write pgtap test for functional equivalence
6. Iterate until sqlfluff AND pgtap pass

**Step 2.4: Incompatible Pattern Rewrites**

For each HIGH/MEDIUM pattern from Phase 1.3:
- Cursors to Set-based CTEs / window functions
- MERGE to INSERT ... ON CONFLICT DO UPDATE
- @@TRANCOUNT to SAVEPOINT / ROLLBACK TO SAVEPOINT
- CROSS APPLY to LATERAL JOIN
- TRY/CATCH to BEGIN...EXCEPTION WHEN
- #TempTables to CREATE TEMP TABLE
- sp_executesql to EXECUTE format(...) with %I/%L

Document the reasoning for each optimization in `docs/schema-optimization-logic.md`.

**Mermaid Diagrams:** Migration flow, type mapping table, SP transformation pipeline, schema optimization decision tree.

---

### Phase 3: Validation and Testing (Iterate Until Consensus)

**Tools:** MSSQL ext + PG ext (side-by-side), pgtap, DAB, HammerDB, pgbench, sec-check
**Output:** `docs/03-validation-report.md`, `tests/performance/results/trending.md`

**Step 3.1: Data Integrity (3-tool validation)**

| Tool | Method | Pass Criteria |
|---|---|---|
| MSSQL ext + PG ext | Row counts per table, side-by-side | All tables match |
| Checksum queries | Hash-based comparison on key columns | Checksums match |
| DAB API regression | Same REST endpoints on both DBs then diff responses | 100% match |

**Step 3.2: Functional Equivalence (3-tool validation)**

| Tool | Method | Pass Criteria |
|---|---|---|
| pgtap | Unit tests for each migrated PL/pgSQL function | All pass |
| DAB REST | Same API calls, compare results | Identical output |
| Side-by-side queries | Same business question on both DBs | Same result set |

**Step 3.3: Performance (before/after)**

Run perf-001 through perf-010 test suite. Store results as timestamped JSON.

| Test | What It Measures |
|---|---|
| perf-001 | Paginated query |
| perf-002 | Point lookup |
| perf-003 | Insert with sequence |
| perf-004 | Update |
| perf-005 | Business-rule-heavy update (SP5 equiv) |
| perf-006 | Delete |
| perf-007 | Aggregation report |
| perf-008 | 50 concurrent connections (HammerDB) |
| perf-009 | Index hit vs seq scan ratio |
| perf-010 | Connection pooling throughput (PgBouncer) |

Iterate: Baseline then add indexes then rewrite cursors then enable PgBouncer then track improvement.

**Step 3.4: Security (before/after)**

Run sec-001 through sec-010 test suite:
- sec-001: No plaintext credentials
- sec-002: SSL enforced
- sec-003: pgAudit enabled
- sec-004: Least-privilege roles
- sec-005: Row-level security on PII tables
- sec-006: PUBLIC schema locked
- sec-007: Parameterized queries only
- sec-008: Encryption at rest
- sec-009: Firewall rules (no 0.0.0.0/0)
- sec-010: Defender for Open-Source DBs enabled

**Mermaid Diagrams:** Validation flow, performance trending, security progression, migration readiness dashboard.

---

### Phase 4: Fabric Integration (Optional)

**Tools:** SqlPackage, MSSQL ext (to Fabric SQL DB), DAB, trivy
**Output:** `docs/04-fabric-integration.md`

1. SqlPackage export .bacpac from source SQL Server.
2. SqlPackage import to Fabric SQL DB.
3. MSSQL extension connects to Fabric SQL DB endpoint (same tool, new target).
4. Fabric SQL DB auto-replicates to OneLake (Delta/Parquet).
5. DAB config pointing at Fabric SQL DB - same API surface.
6. trivy scan on deployment configs.

---

### Phase 5: Data Agent + GraphQL (Optional)

**Tools:** MSSQL ext (Copilot Agent Mode to Fabric), DAB MCP, Fabric Portal
**Output:** `docs/05-data-agent-setup.md`

1. DAB MCP Server on migrated PostgreSQL database.
2. Copilot Agent Mode via MSSQL ext on Fabric SQL DB.
3. Fabric Data Agent / AI Skill for conversational analytics.
4. GraphQL API from Fabric portal.
5. Power BI dashboard with before/after metrics.

---

## GitHub Actions CI Pipeline

`.github/workflows/migration-ci.yml` runs on every PR:

1. ora2pg assess - complexity report
2. MSSQL schema extract - source inventory
3. sqlfluff lint PL/pgSQL - syntax errors
4. sec-check scan - injection/secrets
5. pgLoader --dry-run - validate type mappings
6. pgtap tests - functional equivalence
7. Row-count comparison - data integrity
8. DAB API regression - application-level validation
9. Generate merged consensus report artifact

All 8 pass = migration validated. Any fail = investigate and iterate.

---

## Guardrails

- This is **database-layer only** - no application code assumptions.
- Always target **Azure Database for PostgreSQL Flexible Server**.
- Always document the **reasoning** behind every schema/type/index optimization.
- Always track test results across iterations with timestamped JSON.
- Always produce before/after metrics for performance AND security.
- Only write result evidence to `docs/`. No orchestration content in `docs/`.
