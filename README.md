## <!--

page_type: sample
languages:

- sql
- tsql
- plpgsql
- bash
  products:
- azure
- azure-database-postgresql
- azure-sql-database
- github-copilot
- microsoft-fabric
- vs-code
  name: SQL Server to PostgreSQL Migration Accelerator
  description: Reusable, one-click migration accelerator from SQL Server to Azure Database for PostgreSQL Flexible Server, orchestrated by a Copilot agent with multi-tool cross-validation.
  urlFragment: sql-to-postgres-migration

---

-->

# SQL Server to PostgreSQL Migration Accelerator

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/kfolkes/sql-to-postgres-migration?quickstart=1)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Container&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/kfolkes/sql-to-postgres-migration)
[![Smoke test](https://github.com/kfolkes/sql-to-postgres-migration/actions/workflows/smoke-test.yml/badge.svg)](https://github.com/kfolkes/sql-to-postgres-migration/actions/workflows/smoke-test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **reusable, one-click** migration accelerator that moves SQL Server databases to Azure Database for PostgreSQL Flexible Server. Built for database teams. Orchestrated by a GitHub Copilot agent. Validated by 12 cross-checking tools.

> **Live demo:** open the badge above to launch a fully configured Codespace with SQL Server 2022 + PostgreSQL 16 + WideWorldImporters pre-loaded — then ask Copilot Chat: `/db-migrate`.

```mermaid
flowchart LR
    subgraph Source["Source: any SQL Server"]
        SS[(Azure SQL / on-prem<br/>SQL 2016+)]
    end
    subgraph Agent["Copilot Agent (12 tools, 5 phases)"]
        T1[Assess]
        T2[Translate]
        T3[Migrate]
        T4[Validate]
        T5[Optimize]
    end
    subgraph Target["Target: Azure PostgreSQL"]
        PG[(Flex Server<br/>Entra ID auth)]
    end
    SS --> Agent --> PG
    style SS fill:#cc2927,color:#fff
    style PG fill:#336791,color:#fff
```

---

## Two ways to use it

| Mode                                                         | When to use                       | What you run                                                         |
| ------------------------------------------------------------ | --------------------------------- | -------------------------------------------------------------------- |
| **Demo** — WideWorldImporters local Docker                   | First time, workshops, live demos | `/db-migrate samples/wide-world-importers` (or just click the badge) |
| **BYO Endpoint** — your own SQL Server → your own PostgreSQL | Real customer migrations          | Edit [.env](.env.example) → `/db-migrate` (no argument)              |

Both modes use the **same agent, same skill, same validation gates** — only the connection strings change.

---

## Quickstart (5 minutes, zero local install)

1. Click **[Open in GitHub Codespaces](https://codespaces.new/kfolkes/sql-to-postgres-migration?quickstart=1)** above.
2. Wait ~3 minutes — the dev container installs `psql`, `sqlcmd`, starts SQL Server 2022 + PostgreSQL 16, and restores WideWorldImporters automatically.
3. Open Copilot Chat and run:
   ```
   /db-migrate samples/wide-world-importers
   ```
4. Watch the agent execute Phases 1–3 and produce result docs in [docs/](docs/).

That's the live-demo path. For real customer migrations, follow [Bring your own endpoint](#bring-your-own-endpoint) below.

---

## Local quickstart (Docker required)

Open a bash shell in the repo (Codespace, dev container, WSL, macOS, or Linux):

```bash
cp .env.example .env                   # defaults are safe for local demo
wsl zsh -c "scripts/setup-local-env.sh"        # starts containers + restores WideWorldImporters (~3 min first run)
wsl zsh -c "scripts/migrate-data.sh"           # schema + 31 tables + 6 functions + row-count validation
```

Successful output ends with:

```
[5/5] Validating row counts...
  Row count validation: 31 matched, 0 mismatched out of 31 tables
  Migration Complete!
```

| Service                 | Host        | Port | User       | Password                         | Database               |
| ----------------------- | ----------- | ---- | ---------- | -------------------------------- | ---------------------- |
| SQL Server 2022         | `127.0.0.1` | 1433 | `sa`       | see [.env.example](.env.example) | `WideWorldImporters`   |
| PostgreSQL 16 (PostGIS) | `127.0.0.1` | 5432 | `wwi_user` | see [.env.example](.env.example) | `wide_world_importers` |

```bash
docker compose down       # stop containers (data persists)
docker compose down -v    # full reset (deletes volumes)
```

---

## Bring your own endpoint

To migrate any customer SQL Server to any PostgreSQL — Azure Flex Server, AWS RDS, Cloud SQL, on-prem — set the connection variables in [.env](.env.example) and run a single script:

```bash
cp .env.example .env
# Edit .env:
#   SQLSERVER_HOST='mycorp-sql.database.windows.net'
#   SQLSERVER_DB='ProductionDb'
#   SQLSERVER_USER='migrate_user'
#   SQLSERVER_PASSWORD='...'
#   PGHOST='mycorp-pg.postgres.database.azure.com'
#   PGDATABASE='production_db'
#   PGUSER='migrate_user'
#   PGPASSWORD='...'

wsl zsh -c "scripts/migrate-endpoint.sh --dry-run"    # validate connectivity + type mappings
wsl zsh -c "scripts/migrate-endpoint.sh"              # perform migration via pgloader
wsl zsh -c "scripts/migrate-endpoint.sh --with-foreign-keys"  # opt in to pgloader FK DDL
```

The same Copilot agent works on the customer endpoint:

```
/db-migrate
```

(no argument → BYO mode → reads `.env`).

`migrate-endpoint.sh` skips pgloader-managed foreign keys by default. This avoids a common pgloader failure mode where SQL Server alternate/composite key relationships are emitted as invalid PostgreSQL FK DDL such as `ERROR 42830: there is no unique constraint matching given keys`. Only use `--with-foreign-keys` after confirming the referenced columns will exist in PostgreSQL as `PRIMARY KEY` or `UNIQUE` constraints, not just indexes.

The default pgloader runtime requires Podman; `migrate-endpoint.sh` also uses `psql` for target operations. SQL-authenticated source validation uses `tsql`. See below for running pgloader locally with an Azure CLI login.

### Azure SQL with a personal Azure CLI login

pgloader v4 is a development release distributed as a self-contained JAR. Install Java 21 or later in the environment running the scripts, then download the [official v4 JAR](https://github.com/dimitri/pgloader/releases/tag/v4-dev):

```bash
mkdir -p "$HOME/.local/share/pgloader4"
curl -fL https://github.com/dimitri/pgloader/releases/download/v4-dev/pgloader.jar \
  -o "$HOME/.local/share/pgloader4/pgloader.jar"
java -jar "$HOME/.local/share/pgloader4/pgloader.jar" --version
```

In your local, uncommitted `.env`, set `SQLSERVER_AUTH_MODE='aad'`, `PGLOADER_RUNTIME='local'`, and `PGLOADER_JAR="${HOME}/.local/share/pgloader4/pgloader.jar"`. An existing `pgloader4` executable on `PATH` can be used instead by leaving `PGLOADER_JAR` empty. Set the source host and database, and ensure the signed-in identity can read the Azure SQL database and its metadata. SQL username and password are not used in `aad` mode.

Sign in with `az login` inside WSL (the environment running the script) before migrating. pgloader uses `ActiveDirectoryDefault`: other configured Azure credentials can take precedence over the Azure CLI login.

`validate-migration.sh` currently uses `tsql` and does not support Azure CLI authentication; it exits with an explanation if `SQLSERVER_AUTH_MODE='aad'`.

### Nais Postgres personal-access proxy

For a Nais target, start the proxy and keep it running for the full migration and validation:

```bash
nais postgres proxy <POSTGRES-NAME> --team <TEAM> --environment <ENVIRONMENT> \
  --access-level admin --reason "Migrating database schema and data"
```

Personal access defaults to read-only; `admin` is needed to create or alter schema objects. Set the target variables in your **local, uncommitted** `.env` from the proxy output: `PGHOST` to its TLS server name, `PGHOSTADDR` to its loopback listen address, `PGPORT`, `PGUSER`, `PGDATABASE` (usually `app`), and `PGSSLROOTCERT` to its CA certificate path. Set `PGSSLMODE=verify-full`. If the client needs a password, start the proxy with `--print-password` and set `PGPASSWORD` to the printed value; otherwise leave `PGPASSWORD` empty. Do not commit generated credentials, connection details, or local certificate paths.

`PGHOSTADDR`, `PGSSLMODE`, and `PGSSLROOTCERT` are also used by `validate-migration.sh`; the default `PGSSLMODE=disable` keeps the existing local/Clock SQL proxy flow unchanged.

For local pgloader on Linux or WSL, install `libnss-wrapper` (for example, `sudo apt-get install libnss-wrapper` on Debian/Ubuntu). The script uses it only for pgloader to map the proxy's TLS name to `PGHOSTADDR`, without changing system DNS or disabling hostname verification. If the library is installed in a nonstandard location, set `PGLOADER_NSS_WRAPPER` to its full path. The proxy address and certificate path must be reachable from the environment running the scripts.

---

## Architecture

```mermaid
flowchart TB
    subgraph Phase1["Phase 1: Assessment"]
        M1[MSSQL Extension] --> |schema| C1{Consensus?}
        O1[ora2pg] --> |complexity| C1
        D1[DAB init] --> |entities| C1
        C1 --> |YES| P1[docs/01-source-assessment.md]
    end
    subgraph Phase2["Phase 2: Migration"]
        PG2[pgLoader dry-run] --> C2{Consensus?}
        O2[ora2pg convert] --> C2
        CP2[Copilot translate PL/pgSQL] --> C2
        C2 --> |YES| P2[docs/02-migration-execution.md]
    end
    subgraph Phase3["Phase 3: Validation"]
        PT3[pgtap tests] --> C3{Consensus?}
        DA3[DAB API regression] --> C3
        RC3[Row-count compare] --> C3
        HM3[HammerDB TPC-C] --> C3
        SC3[sec-check delta] --> C3
        C3 --> |YES| P3[docs/03-validation-report.md]
    end
    Phase1 --> Phase2 --> Phase3
    style C1 fill:#2ecc71,color:#fff
    style C2 fill:#2ecc71,color:#fff
    style C3 fill:#2ecc71,color:#fff
```

Every critical step is validated by 2–3 independent tools — no single tool decides:

| Step             | Tool 1     | Tool 2             | Tool 3           |
| ---------------- | ---------- | ------------------ | ---------------- |
| Schema discovery | MSSQL ext  | ora2pg             | DAB              |
| SP translation   | Copilot    | ora2pg             | sqlfluff + pgtap |
| Data migration   | pgLoader   | DAB API regression | row counts       |
| Performance      | SSMS plans | HammerDB TPC-C     | pgbench          |
| Security         | sec-check  | Defender for DBs   | CodeQL           |

---

## What's in the box

```
sql-to-postgres-migration/
├── .devcontainer/                # One-click Codespaces / dev container
├── .github/
│   ├── agents/db-migration.agent.md       # The reusable migration agent
│   ├── prompts/db-migrate.prompt.md       # /db-migrate one-click prompt
│   ├── skills/sql-to-postgres/SKILL.md    # Single source of truth for orchestration
│   ├── workflows/                         # CI: smoke test + migration validation
│   └── ISSUE_TEMPLATE/                    # Bug / feature templates
├── scripts/
│   ├── setup-local-env.sh        # Demo: start containers + restore .bak
│   ├── migrate-data.sh           # Demo: WideWorldImporters → PostgreSQL
│   ├── migrate-endpoint.sh       # BYO: any SQL Server → any PostgreSQL (pgloader)
│   ├── run-assessment.sh         # Phase 1 helper
│   ├── run-migration.sh          # Phase 2 helper
│   └── validate-migration.sh     # Phase 3 helper
├── samples/wide-world-importers/ # Microsoft demo DB assets + pre-translated PL/pgSQL
├── dab/                          # Data API Builder configs (SQL, PG, Fabric)
├── tests/
│   ├── pgtap/                    # PL/pgSQL functional equivalence tests
│   ├── security/                 # 10 security tests (sec-001..010)
│   ├── performance/              # 10 perf tests (perf-001..010)
│   └── row-count-comparison/     # Source ↔ target validation queries and metadata checks
├── benchmarks/hammerdb/          # TPC-C scripts (both SQL and PG)
├── benchmarks/pgbench/           # pgbench load test
├── reference/
│   ├── tsql-to-plpgsql-cheatsheet.md
│   └── azure-architecture-center.md
├── docs/                         # Generated phase result docs
├── docker-compose.yml
├── .env.example                  # Two-mode env template (demo + BYO)
└── .gitattributes                # Enforces LF line endings (cross-platform)
```

---

## Optional CLI tools (for advanced workflows)

| Tool     | Install                                           | Purpose                                  |
| -------- | ------------------------------------------------- | ---------------------------------------- |
| .NET 8+  | <https://get.dot.net>                             | DAB CLI                                  |
| DAB CLI  | `dotnet tool install microsoft.dataapibuilder -g` | API layer + MCP                          |
| pgLoader | `apt install pgloader` / `brew install pgloader`  | BYO endpoint migrations                  |
| ora2pg   | <https://ora2pg.darold.net>                       | Independent assessment + auto-conversion |
| HammerDB | <https://hammerdb.com>                            | Cross-platform TPC-C benchmarking        |
| sqlfluff | `pip install sqlfluff`                            | PL/pgSQL linting                         |
| pgTAP    | `apt install pgtap`                               | PostgreSQL unit testing                  |
| SSMS 22  | <https://learn.microsoft.com/ssms>                | Source execution-plan baseline           |

All of these are **pre-installed in the dev container** so workshop attendees never have to set up tooling.

---

## Demo database: WideWorldImporters

Microsoft's official SQL Server sample database. Ideal for showing migration risk because it contains:

- **31 tables** across `Application`, `Purchasing`, `Sales`, `Warehouse`, `Website`
- **6 stored procedures** (translated to PL/pgSQL functions in [samples/wide-world-importers/migration-scripts/tsql-to-plpgsql/](samples/wide-world-importers/migration-scripts/tsql-to-plpgsql/))
- **Temporal tables** (system-versioned)
- **JSON columns**, **HIERARCHYID**, **GEOGRAPHY** types
- **~1.06 million rows** end-to-end
- Source backup: <https://aka.ms/WideWorldImporters>

Validated migration result (current `main`):

```
Tables created:    31
Data transferred:  31/31 tables
Functions:         6 PL/pgSQL functions
Row validation:    31/31 matched
```

---

## Roadmap / phases

| Phase                           | Status      | Output                                                           |
| ------------------------------- | ----------- | ---------------------------------------------------------------- |
| 1. Source assessment            | ✅ stable   | [docs/01-source-assessment.md](docs/01-source-assessment.md)     |
| 2. Migration execution          | ✅ stable   | [docs/02-migration-execution.md](docs/02-migration-execution.md) |
| 3. Validation & testing         | ✅ stable   | [docs/03-validation-report.md](docs/03-validation-report.md)     |
| 4. Microsoft Fabric integration | 🟡 optional | [docs/04-fabric-integration.md](docs/04-fabric-integration.md)   |
| 5. Data agent + GraphQL         | 🟡 optional | [docs/05-data-agent-setup.md](docs/05-data-agent-setup.md)       |

---

## Resources

- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [Azure Database Migration guide: SQL Server → PostgreSQL](https://learn.microsoft.com/data-migration/sql-server/postgresql/)
- [pgLoader documentation](https://pgloader.io/)
- [ora2pg documentation](https://ora2pg.darold.net/)
- [Data API Builder](https://learn.microsoft.com/azure/data-api-builder/)
- [GitHub Copilot agents & skills](https://docs.github.com/copilot)

---

## Contributing & support

- See [CONTRIBUTING.md](CONTRIBUTING.md) for the dev workflow.
- Report bugs via [Issues](../../issues/new/choose).
- Security disclosures: please use [MSRC](https://msrc.microsoft.com/create-report) (see [SECURITY.md](SECURITY.md)).
- This project follows the [Microsoft Open Source Code of Conduct](CODE_OF_CONDUCT.md).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos is subject to those third parties' policies.

## License

[MIT](LICENSE)

## Customizations

### pgloader v4 container

Both `scripts/migrate-endpoint.sh` and `scripts/run-migration.sh` use the official pgloader v4 container through Podman by default. The endpoint script shares its temporary load configuration with the container and uses host networking; when `PGHOSTADDR` is set, Podman maps that address to `PGHOST` so PostgreSQL TLS verification uses the proxy's server name. Set `PGLOADER_RUNTIME=local` to use a pgloader v4 JAR or an installed `pgloader4` executable instead. `SQLSERVER_AUTH_MODE=aad` requires the local runtime, as described above.

### Support for target GCP Cloud SQL for PostgreSQL:

```bash
# presumes gcloud is installed and authenticated
connectionName=`gcloud sql instances describe <myinstance> --format="value(connectionName)"`
# presumes cloud-sql-proxy is installed
cloud-sql-proxy $connectionName
```

cloud-sql-proxy removes the need for explicit ssl settings. It is also possible to connect directly to the public IP without cloud-sql-proxy, but this complicates the setup a bit as you need to configure certificates: in case you need that, set these options and make sure the ssl connection is 'required'

```
-v $PWD/server-ca.pem:/certs/server-ca.pem:ro -v $PWD/client-cert.pem:/root/.postgresql/postgresql.crt:ro \
-v $PWD/client-key.pem:/root/.postgresql/postgresql.key:ro -e SSL_CERT_FILE=/certs/server-ca.pem
```

### Custom usage

./scripts/migrate-endpoint.sh
./scripts/validate-migration.sh --database xx --connection-string "hostaddr=127.0.0.1 port=5432 user=... password=... dbname=..."

`validate-migration.sh` now compares source SQL Server metadata and target PostgreSQL metadata for row counts, keys, indexes, check/default constraints, views, functions, and column type mappings, plus PostgreSQL sequence/orphan/duplicate health checks, then regenerates `docs/03-validation-report.md`.
