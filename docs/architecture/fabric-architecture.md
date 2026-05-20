# Fabric Integration Architecture

Optional Phase 4-5: Integrating the migrated PostgreSQL database with Microsoft Fabric.

## Fabric Topology

```mermaid
flowchart TB
    subgraph Source["Source (Migrated)"]
        PG[(Azure PG\nFlexible Server)]
    end

    subgraph Bridge["Data API Builder"]
        DAB[DAB MCP Server\nREST + GraphQL + MCP]
    end

    subgraph Fabric["Microsoft Fabric"]
        SQLDB[(Fabric SQL DB)]
        OL[OneLake\nDelta/Parquet]
        AE[SQL Analytics\nEndpoint]
        DA[Data Agent\nAI Skill]
        GQL[GraphQL API]
        PBI[Power BI\nSemantic Model]
    end

    PG --> |SqlPackage .bacpac| SQLDB
    PG --> |Data Pipeline| OL
    SQLDB --> |Auto-replicate| OL
    OL --> AE
    SQLDB --> DA
    SQLDB --> GQL
    AE --> PBI
    DAB --> PG
    DAB --> SQLDB

    style PG fill:#336791,color:#fff
    style SQLDB fill:#0078d4,color:#fff
    style OL fill:#f39c12,color:#fff
```

## MSSQL Extension to Fabric

The same MSSQL extension that inspects the source SQL Server can connect to Fabric SQL DB:

```
Source: mssql_connect -> 127.0.0.1 SQL Server
Target: mssql_connect -> your-server.database.fabric.microsoft.com
```

Same tool, new connection string. Zero new tooling for the DBA.

## DAB on Fabric

DAB config points at Fabric SQL DB endpoint:

- Same REST/GraphQL/MCP surface
- Same entity definitions
- Same RBAC policies
- Different `database-type` and `connection-string`

See `dab/dab-config-fabric.json` for the template.
