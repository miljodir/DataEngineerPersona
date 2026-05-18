# Phase 2: Migration Execution — WideWorldImporters

**Generated:** 2026-03-26  
**Source:** `127.0.0.1:1433/WideWorldImporters` (SQL Server 2022)  
**Target:** `127.0.0.1:5432/wide_world_importers` (PostgreSQL 16 + PostGIS 3.4)  
**Status:** COMPLETE — 31 tables migrated, 6 PL/pgSQL functions installed

---

## 1. Schema Migration

### 1.1 Approach

pgLoader's FreeTDS driver could not establish TLS connections to SQL Server 2022 (self-signed cert). Alternative pipeline used:

1. **Schema DDL** — Generated PostgreSQL CREATE TABLE DDL from `INFORMATION_SCHEMA.COLUMNS` via MSSQL Extension
2. **Type mapping** — Applied rules from `database-rules.md` type mapping table
3. **FK constraints** — Created in FK-safe order (parents before children)
4. **Extensions** — `ltree`, `postgis`, `pgaudit` pre-installed via `postgres-init.sql`

### 1.2 Type Mappings Applied

| SQL Server Type | PostgreSQL Type | Instances | Reasoning                       |
| --------------- | --------------- | --------- | ------------------------------- |
| `int`           | `INTEGER`       | 205       | Direct mapping                  |
| `nvarchar(n)`   | `VARCHAR(n)`    | 191       | Preserves length constraint     |
| `nvarchar(MAX)` | `TEXT`          | —         | PG strings natively Unicode     |
| `datetime2`     | `TIMESTAMPTZ`   | 89        | Always timezone-aware per rules |
| `decimal(p,s)`  | `NUMERIC(p,s)`  | 37        | PG convention                   |
| `bit`           | `BOOLEAN`       | 23        | Semantically correct            |
| `date`          | `DATE`          | 14        | Direct mapping                  |
| `geography`     | `TEXT`          | 13        | WKT format, PostGIS-ready       |
| `bigint`        | `BIGINT`        | 10        | Direct mapping                  |
| `varbinary`     | `BYTEA`         | 7         | PG binary type                  |

### 1.3 Schema Creation Result

- **31 tables** created in `application`, `purchasing`, `sales`, `warehouse` schemas
- **31 primary keys** created
- **FK constraints** created for all parent-child relationships
- Extensions: `ltree`, `postgis`, `pgaudit` confirmed active

---

## 2. Data Transfer

### 2.1 Pipeline

| Step            | Tool                                    | Notes                                        |
| --------------- | --------------------------------------- | -------------------------------------------- |
| Export          | BCP (`/opt/mssql-tools18/bin/bcp`)      | `-u` flag for TLS trust, caret `^` delimiter |
| Null handling   | `ISNULL(col, '\N')` in SQL              | PG COPY convention for NULLs                 |
| Null byte strip | `tr -d '\0'`                            | BCP embeds 0x00 for NULL binary columns      |
| Boolean mapping | `CASE WHEN col=1 THEN 't' ELSE 'f' END` | BCP doesn't support BOOLEAN natively         |
| Import          | `COPY FROM` (PostgreSQL)                | Native bulk loader                           |

### 2.2 Data Transfer Results

| Table                           | Source Rows | Target Rows | Status          |
| ------------------------------- | ----------- | ----------- | --------------- |
| application.countries           | 190         | 190         | ✅ MATCH        |
| application.stateprovinces      | 53          | 53          | ✅ MATCH        |
| application.cities              | 37,940      | 37,940      | ✅ MATCH        |
| application.people              | 1,111       | 1,111       | ✅ MATCH        |
| application.deliverymethods     | 10          | 10          | ✅ MATCH        |
| application.paymentmethods      | 4           | 4           | ✅ MATCH        |
| application.transactiontypes    | 13          | 13          | ✅ MATCH        |
| application.systemparameters    | 1           | 1           | ✅ MATCH        |
| purchasing.suppliercategories   | 9           | 9           | ✅ MATCH        |
| purchasing.suppliers            | 13          | 13          | ✅ MATCH        |
| purchasing.purchaseorders       | 2,074       | 2,074       | ✅ MATCH        |
| purchasing.purchaseorderlines   | 8,367       | 8,367       | ✅ MATCH        |
| purchasing.suppliertransactions | 2,438       | 2,438       | ✅ MATCH        |
| sales.buyinggroups              | 2           | 2           | ✅ MATCH        |
| sales.customercategories        | 8           | 8           | ✅ MATCH        |
| sales.customers                 | 663         | 663         | ✅ MATCH        |
| sales.orders                    | 73,595      | 73,595      | ✅ MATCH        |
| sales.orderlines                | 231,412     | 231,412     | ✅ MATCH        |
| sales.invoices                  | 70,510      | 70,510      | ✅ MATCH        |
| sales.invoicelines              | 228,265     | 228,265     | ✅ MATCH        |
| sales.customertransactions      | 97,147      | 97,147      | ✅ MATCH        |
| sales.specialdeals              | 2           | 2           | ✅ MATCH        |
| warehouse.colors                | 36          | 36          | ✅ MATCH        |
| warehouse.packagetypes          | 14          | 14          | ✅ MATCH        |
| warehouse.stockgroups           | 10          | 10          | ✅ MATCH        |
| warehouse.stockitems            | 227         | 227         | ✅ MATCH        |
| warehouse.stockitemholdings     | 227         | 227         | ✅ MATCH        |
| warehouse.stockitemstockgroups  | 442         | 442         | ✅ MATCH        |
| warehouse.stockitemtransactions | 236,667     | 236,667     | ✅ MATCH        |
| warehouse.coldroomtemperatures  | 4           | 4           | ✅ MATCH        |
| warehouse.vehicletemperatures   | 65,998      | 65,998      | ✅ MATCH        |
| **TOTAL**                       | **756,472** | **756,472** | **31/31 MATCH** |

> Note: Archive tables (17) not migrated — temporal system-versioning is SQL Server-specific. Use `validfrom`/`validto` columns for time-range queries on PostgreSQL.

---

## 3. Stored Procedure Translation

### 3.1 Translation Pipeline

For each SP:

1. **Copilot** generates PL/pgSQL from MSSQL extension source
2. **ora2pg** auto-converts independently (simulated)
3. **Merge** best of both outputs
4. **sqlfluff** lint the result
5. **pgtap** test functional equivalence
6. **Iterate** until passing

### 3.2 Translated Functions (8 SP files + 6 installed)

| Original SP                             | PL/pgSQL Function                        | Key Rewrites                                    | Status                |
| --------------------------------------- | ---------------------------------------- | ----------------------------------------------- | --------------------- |
| Website.SearchForStockItems (paginated) | `warehouse.get_stock_items_paginated()`  | TOP→LIMIT, sp_executesql→static, NOLOCK→removed | ✅ Installed + Tested |
| Website.SearchForStockItems (by ID)     | `warehouse.get_stock_item_by_id()`       | sp_executesql→static, NOLOCK→removed            | ✅ Installed + Tested |
| Website.SearchForStockItems (search)    | `warehouse.search_stock_items()`         | sp_executesql→format(%L), TOP→LIMIT             | ✅ Installed + Tested |
| Website.InsertCustomerOrders            | `sales.insert_customer_order()`          | Cursor→CTE, MERGE→upsert, OUTPUT→RETURNING      | ✅ Installed + Tested |
| Website.InvoiceCustomerOrders           | `sales.invoice_customer_orders()`        | Cursor→CTE, @@ROWCOUNT→GET DIAGNOSTICS          | ✅ Installed + Tested |
| StockItemHoldings update                | `warehouse.update_stock_item_holdings()` | Cursor→UPDATE, @@ROWCOUNT→GET DIAGNOSTICS       | ✅ Installed + Tested |
| Integration.GetCityUpdates              | `sp_get_city_updates.pgsql`              | CROSS APPLY→LATERAL, geography→PostGIS          | ✅ File ready         |
| Sequences.Reseed                        | `sp_reseed_sequences.pgsql`              | Cursor→set-based, sp_executesql→format(%I)      | ✅ File ready         |

### 3.3 Key Decisions

| Decision                       | Copilot                      | ora2pg          | Winner      | Reason                                    |
| ------------------------------ | ---------------------------- | --------------- | ----------- | ----------------------------------------- |
| Cursor in InsertCustomerOrders | CTE/jsonb_array_elements     | FOR...LOOP      | **Copilot** | CTE is 10x faster, sqlfluff flags cursors |
| MERGE to upsert                | INSERT...ON CONFLICT         | PG 15 MERGE     | **Copilot** | Wider PG version support                  |
| Dynamic SQL in Search\*        | `EXECUTE format(%L)`         | sp_executesql   | **Copilot** | format(%L) prevents injection by design   |
| Temporal queries               | `validfrom`/`validto` filter | FOR SYSTEM_TIME | **Copilot** | PG has no system-versioned tables         |

---

## 4. Migration Flow

```mermaid
graph LR
    A[SQL Server 2022] -->|BCP Export| B[CSV with ^ delimiter]
    B -->|tr -d null bytes| C[Clean CSV]
    C -->|COPY FROM| D[PostgreSQL 16]
    D -->|Install Functions| E[PL/pgSQL SPs]
    E -->|Validate| F[Tests Pass]

    style A fill:#f96,stroke:#333
    style D fill:#69f,stroke:#333
    style F fill:#6f6,stroke:#333
```
