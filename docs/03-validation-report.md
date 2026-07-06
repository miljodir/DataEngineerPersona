# Phase 3: Validation Report

Generated: 2026-05-26 08:03:06 UTC  
Iteration: run-20260526-100234  
Source database: `d-inkatdb` on `d-inkat-mssql.database.windows.net:1433`  
Target database: `indikatorkatalog` on `127.0.0.1:5432`

## Validation Summary

| Area | Status | Differences | Notes |
|---|---|---:|---|
| Row counts | ❌ | 4 | Exact `COUNT(*)` comparison across user tables |
| Primary keys | ✅ | 0 | Compares each table's ordered PK columns and ignores constraint-name drift |
| Foreign keys | ✅ | 0 | Compares FK relationship signatures and ignores constraint-name drift |
| Non-unique secondary indexes | ✅ | 0 | Highlights non-unique source indexes missing on PostgreSQL; unique indexes are compared in the separate unique-keys section |
| Unique keys | ✅ | 0 | Compares non-primary unique indexes/constraints by table and ordered key columns |
| Check constraints | N/A | 0 | Compares normalized check expressions and whether the target constraints are validated |
| Default expressions | ⚠️ | 24 | Hard mismatches: 0; review-only behavior changes: 24 |
| Views | N/A | 0 | Skipped as a strict parity gate when the PostgreSQL target has no views, which is expected after `data only` migration runs |
| Functions | N/A | 0 | Compares function name + parameter count and validates mapped parameter/return types |
| Columns/data types | ❌ | 2 | Validates base-table columns against the pgloader mappings in `scripts/migrate-endpoint.sh` |
| Sequence health | N/A | 0 | Checks that PostgreSQL identity/serial sequences are not behind the migrated data |
| Orphan foreign-key health | ❌ | 1 | Source orphan baseline query returned no rows, so introduced-vs-pre-existing attribution is unavailable |
| Duplicate key health | ❌ | 1 | Source duplicate baseline query returned no rows, so introduced-vs-pre-existing attribution is unavailable |

## Row counts

| Status | Table | SQL Server rows | PostgreSQL rows | Detail |
|---|---|---:|---:|---|
| ✅ | `dbo.EnvironmentTarget` | 117 | 117 | Exact COUNT(*) match |
| ✅ | `dbo.EnvironmentTargetVersion` | 1215 | 1215 | Exact COUNT(*) match |
| ✅ | `dbo.EnvironmentTargetVersionLanguage` | 1215 | 1215 | Exact COUNT(*) match |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention` | 1003 | 1003 | Exact COUNT(*) match |
| ✅ | `dbo.EnvironmentTargetVersionResource` | 3423 | 3423 | Exact COUNT(*) match |
| ✅ | `dbo.EnvironmentTargetVersionTheme` | 1388 | 1388 | Exact COUNT(*) match |
| ✅ | `dbo.Indicator` | 437 | 437 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersion` | 3303 | 3303 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionData` | 2955 | 2955 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionEea` | 48 | 48 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionIntRapport` | 60 | 60 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionLanguage` | 3303 | 3303 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionRelatedLink` | 4934 | 4934 | Exact COUNT(*) match |
| ✅ | `dbo.IndicatorVersionResource` | 4708 | 4708 | Exact COUNT(*) match |
| ❌ | `dbo.Language` | 1 | 2 | Row count mismatch |
| ❌ | `dbo.Member` | 59 | 60 | Row count mismatch |
| ✅ | `dbo.MemberRight` | 1528 | 1528 | Exact COUNT(*) match |
| ❌ | `dbo.Period` | 5 | 6 | Row count mismatch |
| ✅ | `dbo.Resource` | 130 | 130 | Exact COUNT(*) match |
| ✅ | `dbo.ResourceLanguage` | 130 | 130 | Exact COUNT(*) match |
| ✅ | `dbo.ResultArea` | 30 | 30 | Exact COUNT(*) match |
| ✅ | `dbo.ResultAreaLanguage` | 30 | 30 | Exact COUNT(*) match |
| ✅ | `dbo.Theme` | 79 | 79 | Exact COUNT(*) match |
| ❌ | `dbo.__EFMigrationsHistory` | 2 | 1 | Row count mismatch |

## Primary keys

| Status | Table | SQL Server PK | PostgreSQL PK | Detail |
|---|---|---|---|---|
| ✅ | `dbo.EnvironmentTarget` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.EnvironmentTargetVersion` | `EnvironmentTargetId, VersionNo` | `EnvironmentTargetId, VersionNo` | Ordered PK columns match |
| ✅ | `dbo.EnvironmentTargetVersionLanguage` | `EnvironmentTargetId, EnvironmentTargetVersionNo, LanguageId` | `EnvironmentTargetId, EnvironmentTargetVersionNo, LanguageId` | Ordered PK columns match |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.EnvironmentTargetVersionResource` | `EnvironmentTargetId, EnvironmentTargetVersionNo, ResourceId` | `EnvironmentTargetId, EnvironmentTargetVersionNo, ResourceId` | Ordered PK columns match |
| ✅ | `dbo.EnvironmentTargetVersionTheme` | `EnvironmentTargetId, EnvironmentTargetVersionNo, ThemeId` | `EnvironmentTargetId, EnvironmentTargetVersionNo, ThemeId` | Ordered PK columns match |
| ✅ | `dbo.Indicator` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersion` | `IndicatorId, VersionNo` | `IndicatorId, VersionNo` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionData` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionEea` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionIntRapport` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionLanguage` | `IndicatorId, IndicatorVersionNo, LanguageId` | `IndicatorId, IndicatorVersionNo, LanguageId` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionRelatedLink` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.IndicatorVersionResource` | `IndicatorId, IndicatorVersionNo, ResourceId` | `IndicatorId, IndicatorVersionNo, ResourceId` | Ordered PK columns match |
| ✅ | `dbo.Language` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.Member` | `UserId` | `UserId` | Ordered PK columns match |
| ✅ | `dbo.MemberRight` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.Period` | `Year` | `Year` | Ordered PK columns match |
| ✅ | `dbo.Resource` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.ResourceLanguage` | `ResourceId, LanguageId` | `ResourceId, LanguageId` | Ordered PK columns match |
| ✅ | `dbo.ResultArea` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.ResultAreaLanguage` | `ResultAreaId, LanguageId` | `ResultAreaId, LanguageId` | Ordered PK columns match |
| ✅ | `dbo.Theme` | `Id` | `Id` | Ordered PK columns match |
| ✅ | `dbo.__EFMigrationsHistory` | `MigrationId` | `MigrationId` | Ordered PK columns match |

## Foreign keys

| Status | Child table | SQL Server relationship | PostgreSQL relationship | Detail |
|---|---|---|---|---|
| ✅ | `dbo.EnvironmentTarget` | `dbo.EnvironmentTarget (ResultAreaId) -> dbo.ResultArea (Id)` | `public.EnvironmentTarget (ResultAreaId) -> public.ResultArea (Id)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersion` | `dbo.EnvironmentTargetVersion (AssignedToUserId) -> dbo.Member (UserId)` | `public.EnvironmentTargetVersion (AssignedToUserId) -> public.Member (UserId)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersion` | `dbo.EnvironmentTargetVersion (EnvironmentTargetId) -> dbo.EnvironmentTarget (Id)` | `public.EnvironmentTargetVersion (EnvironmentTargetId) -> public.EnvironmentTarget (Id)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersion` | `dbo.EnvironmentTargetVersion (StateFromUserId) -> dbo.Member (UserId)` | `public.EnvironmentTargetVersion (StateFromUserId) -> public.Member (UserId)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionLanguage` | `dbo.EnvironmentTargetVersionLanguage (EnvironmentTargetId, EnvironmentTargetVersionNo) -> dbo.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | `public.EnvironmentTargetVersionLanguage (EnvironmentTargetId, EnvironmentTargetVersionNo) -> public.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionLanguage` | `dbo.EnvironmentTargetVersionLanguage (LanguageId) -> dbo.Language (Id)` | `public.EnvironmentTargetVersionLanguage (LanguageId) -> public.Language (Id)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention` | `dbo.EnvironmentTargetVersionRelConvention (EnvironmentTargetId, EnvironmentTargetVersionNo) -> dbo.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | `public.EnvironmentTargetVersionRelConvention (EnvironmentTargetId, EnvironmentTargetVersionNo) -> public.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionResource` | `dbo.EnvironmentTargetVersionResource (EnvironmentTargetId, EnvironmentTargetVersionNo) -> dbo.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | `public.EnvironmentTargetVersionResource (EnvironmentTargetId, EnvironmentTargetVersionNo) -> public.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionResource` | `dbo.EnvironmentTargetVersionResource (ResourceId) -> dbo.Resource (Id)` | `public.EnvironmentTargetVersionResource (ResourceId) -> public.Resource (Id)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionTheme` | `dbo.EnvironmentTargetVersionTheme (EnvironmentTargetId, EnvironmentTargetVersionNo) -> dbo.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | `public.EnvironmentTargetVersionTheme (EnvironmentTargetId, EnvironmentTargetVersionNo) -> public.EnvironmentTargetVersion (EnvironmentTargetId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.EnvironmentTargetVersionTheme` | `dbo.EnvironmentTargetVersionTheme (ThemeId) -> dbo.Theme (Id)` | `public.EnvironmentTargetVersionTheme (ThemeId) -> public.Theme (Id)` | Relationship signature matches |
| ✅ | `dbo.Indicator` | `dbo.Indicator (EnvironmentTargetId) -> dbo.EnvironmentTarget (Id)` | `public.Indicator (EnvironmentTargetId) -> public.EnvironmentTarget (Id)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersion` | `dbo.IndicatorVersion (AssignedToUserId) -> dbo.Member (UserId)` | `public.IndicatorVersion (AssignedToUserId) -> public.Member (UserId)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersion` | `dbo.IndicatorVersion (IndicatorId) -> dbo.Indicator (Id)` | `public.IndicatorVersion (IndicatorId) -> public.Indicator (Id)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersion` | `dbo.IndicatorVersion (StateFromUserId) -> dbo.Member (UserId)` | `public.IndicatorVersion (StateFromUserId) -> public.Member (UserId)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionData` | `dbo.IndicatorVersionData (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionData (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionEea` | `dbo.IndicatorVersionEea (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionEea (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionIntRapport` | `dbo.IndicatorVersionIntRapport (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionIntRapport (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionLanguage` | `dbo.IndicatorVersionLanguage (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionLanguage (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionLanguage` | `dbo.IndicatorVersionLanguage (LanguageId) -> dbo.Language (Id)` | `public.IndicatorVersionLanguage (LanguageId) -> public.Language (Id)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionRelatedLink` | `dbo.IndicatorVersionRelatedLink (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionRelatedLink (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionResource` | `dbo.IndicatorVersionResource (IndicatorId, IndicatorVersionNo) -> dbo.IndicatorVersion (IndicatorId, VersionNo)` | `public.IndicatorVersionResource (IndicatorId, IndicatorVersionNo) -> public.IndicatorVersion (IndicatorId, VersionNo)` | Relationship signature matches |
| ✅ | `dbo.IndicatorVersionResource` | `dbo.IndicatorVersionResource (ResourceId) -> dbo.Resource (Id)` | `public.IndicatorVersionResource (ResourceId) -> public.Resource (Id)` | Relationship signature matches |
| ✅ | `dbo.MemberRight` | `dbo.MemberRight (EnvironmentTargetId) -> dbo.EnvironmentTarget (Id)` | `public.MemberRight (EnvironmentTargetId) -> public.EnvironmentTarget (Id)` | Relationship signature matches |
| ✅ | `dbo.MemberRight` | `dbo.MemberRight (IndicatorId) -> dbo.Indicator (Id)` | `public.MemberRight (IndicatorId) -> public.Indicator (Id)` | Relationship signature matches |
| ✅ | `dbo.MemberRight` | `dbo.MemberRight (UserId) -> dbo.Member (UserId)` | `public.MemberRight (UserId) -> public.Member (UserId)` | Relationship signature matches |
| ✅ | `dbo.ResourceLanguage` | `dbo.ResourceLanguage (LanguageId) -> dbo.Language (Id)` | `public.ResourceLanguage (LanguageId) -> public.Language (Id)` | Relationship signature matches |
| ✅ | `dbo.ResourceLanguage` | `dbo.ResourceLanguage (ResourceId) -> dbo.Resource (Id)` | `public.ResourceLanguage (ResourceId) -> public.Resource (Id)` | Relationship signature matches |
| ✅ | `dbo.ResultArea` | `dbo.ResultArea (PeriodId) -> dbo.Period (Year)` | `public.ResultArea (PeriodId) -> public.Period (Year)` | Relationship signature matches |
| ✅ | `dbo.ResultAreaLanguage` | `dbo.ResultAreaLanguage (LanguageId) -> dbo.Language (Id)` | `public.ResultAreaLanguage (LanguageId) -> public.Language (Id)` | Relationship signature matches |
| ✅ | `dbo.ResultAreaLanguage` | `dbo.ResultAreaLanguage (ResultAreaId) -> dbo.ResultArea (Id)` | `public.ResultAreaLanguage (ResultAreaId) -> public.ResultArea (Id)` | Relationship signature matches |

## Non-unique secondary indexes

| Status | Table | Key columns | SQL Server index | PostgreSQL index | Detail |
|---|---|---|---|---|---|
| ✅ | `public.EnvironmentTarget` | `ResultAreaId` | `n/a` | `IX_EnvironmentTarget_ResultAreaId` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersion` | `AssignedToUserId` | `n/a` | `IX_EnvironmentTargetVersion_AssignedToUserId` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersion` | `StateFromUserId` | `n/a` | `IX_EnvironmentTargetVersion_StateFromUserId` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersionLanguage` | `LanguageId` | `n/a` | `IX_EnvironmentTargetVersionLanguage_LanguageId` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersionRelConvention` | `EnvironmentTargetId,EnvironmentTargetVersionNo` | `n/a` | `IX_EnvironmentTargetVersionRelConvention_EnvironmentTargetId_E~` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersionResource` | `ResourceId` | `n/a` | `IX_EnvironmentTargetVersionResource_ResourceId` | Additional PostgreSQL-only index |
| ✅ | `public.EnvironmentTargetVersionTheme` | `ThemeId` | `n/a` | `IX_EnvironmentTargetVersionTheme_ThemeId` | Additional PostgreSQL-only index |
| ✅ | `public.Indicator` | `EnvironmentTargetId` | `n/a` | `IX_Indicator_EnvironmentTargetId` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersion` | `AssignedToUserId` | `n/a` | `IX_IndicatorVersion_AssignedToUserId` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersion` | `StateFromUserId` | `n/a` | `IX_IndicatorVersion_StateFromUserId` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionData` | `IndicatorId,IndicatorVersionNo` | `n/a` | `IX_IndicatorVersionData_IndicatorId_IndicatorVersionNo` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionEea` | `IndicatorId,IndicatorVersionNo` | `n/a` | `IX_IndicatorVersionEea_IndicatorId_IndicatorVersionNo` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionIntRapport` | `IndicatorId,IndicatorVersionNo` | `n/a` | `IX_IndicatorVersionIntRapport_IndicatorId_IndicatorVersionNo` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionLanguage` | `LanguageId` | `n/a` | `IX_IndicatorVersionLanguage_LanguageId` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionRelatedLink` | `IndicatorId,IndicatorVersionNo` | `n/a` | `IX_IndicatorVersionRelatedLink_IndicatorId_IndicatorVersionNo` | Additional PostgreSQL-only index |
| ✅ | `public.IndicatorVersionResource` | `ResourceId` | `n/a` | `IX_IndicatorVersionResource_ResourceId` | Additional PostgreSQL-only index |
| ✅ | `public.MemberRight` | `EnvironmentTargetId` | `n/a` | `IX_MemberRight_EnvironmentTargetId` | Additional PostgreSQL-only index |
| ✅ | `public.MemberRight` | `IndicatorId` | `n/a` | `IX_MemberRight_IndicatorId` | Additional PostgreSQL-only index |
| ✅ | `public.MemberRight` | `UserId` | `n/a` | `IX_MemberRight_UserId` | Additional PostgreSQL-only index |
| ✅ | `public.ResourceLanguage` | `LanguageId` | `n/a` | `IX_ResourceLanguage_LanguageId` | Additional PostgreSQL-only index |
| ✅ | `public.ResultArea` | `PeriodId` | `n/a` | `IX_ResultArea_PeriodId` | Additional PostgreSQL-only index |
| ✅ | `public.ResultAreaLanguage` | `LanguageId` | `n/a` | `IX_ResultAreaLanguage_LanguageId` | Additional PostgreSQL-only index |

## Unique keys

| Status | Table | Unique columns | SQL Server object | PostgreSQL object | Detail |
|---|---|---|---|---|---|
| ✅ | `dbo.Language` | `Lang,Country` | `IX_Language_Lang_Country` | `IX_Language_Lang_Country` | Unique key coverage matches |
| ✅ | `dbo.MemberRight` | `UserId,EnvironmentTargetId` | `IX_MemberRight_UserId_EnvironmentTargetId` | `IX_MemberRight_UserId_EnvironmentTargetId` | Unique key coverage matches |
| ✅ | `dbo.MemberRight` | `UserId,IndicatorId` | `IX_MemberRight_UserId_IndicatorId` | `IX_MemberRight_UserId_IndicatorId` | Unique key coverage matches |
| ✅ | `dbo.Resource` | `Name,Group` | `IX_Resource_Name_Group` | `IX_Resource_Name_Group` | Unique key coverage matches |

## Check constraints

| Status | Table | SQL Server constraint | PostgreSQL constraint | Detail |
|---|---|---|---|---|
| N/A | n/a | n/a | n/a | No check constraints returned by either query |

## Default expressions

Only insert-time behavior changes are treated as review items here. Explicit `DEFAULT NULL` and no default are treated as equivalent.

| Status | Column | SQL Server default | PostgreSQL default | Detail |
|---|---|---|---|---|
| ⚠️ | `dbo.EnvironmentTarget.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.EnvironmentTargetVersion.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.EnvironmentTargetVersionLanguage.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.EnvironmentTargetVersionRelConvention.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.EnvironmentTargetVersionResource.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.EnvironmentTargetVersionTheme.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Indicator.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersion.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersionData.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ✅ | `dbo.IndicatorVersionData.Zone` | `NULL` | `n/a` | Explicit NULL default and no default are behaviorally equivalent |
| ⚠️ | `dbo.IndicatorVersionEea.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersionIntRapport.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersionLanguage.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersionRelatedLink.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.IndicatorVersionResource.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Language.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Language.IsDeleted` | `NULL` | `false` | Target now supplies a zero/false default where the source defaulted NULL; fix only if omitted inserts should continue storing NULL |
| ⚠️ | `dbo.Member.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.MemberRight.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Period.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Resource.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.ResourceLanguage.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.ResultArea.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.ResultAreaLanguage.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |
| ⚠️ | `dbo.Theme.Created` | `NULL` | `CURRENT_TIMESTAMP` | Target now auto-populates CURRENT_TIMESTAMP where the source defaulted NULL; fix only if that insert-time behavior was not intentional in the PostgreSQL model |

## Views

| Status | View | SQL Server columns | PostgreSQL columns | Detail |
|---|---|---|---|---|
| N/A | n/a | n/a | n/a | No user views returned by either query |

## Functions

| Status | Function | SQL Server signature | PostgreSQL signature | Detail |
|---|---|---|---|---|
| N/A | n/a | n/a | n/a | No user-defined functions returned by either query |

## Columns and data types

| Status | Column | SQL Server type | PostgreSQL type | Detail |
|---|---|---|---|---|
| ✅ | `dbo.EnvironmentTarget.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTarget.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTarget.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTarget.LastVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTarget.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTarget.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTarget.Number` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTarget.ResultAreaId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersion.AssignedToUserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersion.Comment` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersion.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersion.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersion.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersion.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersion.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersion.Progress` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersion.PublishDate` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersion.State` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersion.StateFromUserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersion.StateReason` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersion.Verdi` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersion.VersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Aarsaker` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.EnvironmentTargetVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Forutsetninger` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Ingress` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Kontakt` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.KvalitetOgVurdering` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.LanguageId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.NaarViMaalet` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Name` | `nvarchar` | `character varying` | Expected pgloader cast nvarchar(256) -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionLanguage.Tema` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Description` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.EnvironmentTargetVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Link` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionRelConvention.Order` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionResource.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionResource.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionResource.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionResource.EnvironmentTargetVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionResource.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionResource.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionResource.ResourceId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionTheme.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionTheme.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionTheme.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionTheme.EnvironmentTargetVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.EnvironmentTargetVersionTheme.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.EnvironmentTargetVersionTheme.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.EnvironmentTargetVersionTheme.ThemeId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Indicator.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Indicator.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Indicator.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Indicator.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Indicator.LastVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Indicator.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Indicator.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Indicator.Number` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.AssignedToUserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersion.Comment` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersion.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersion.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersion.IframeLink` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersion.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersion.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersion.NextDataUpdateMonth` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.NextDataUpdateYear` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.Progress` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.PublishDate` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersion.State` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.StateFromUserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersion.StateReason` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersion.Status` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.TypeIndikator` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.UpdateFrequence` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.UpdateFrequenceOther` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersion.Vekting` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersion.VersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.ChartType` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionData.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionData.DataSetId` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionData.DataType` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Image` | `varbinary` | `bytea` | Expected varbinary -> bytea |
| ✅ | `dbo.IndicatorVersionData.ImageType` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionData.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Lines` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionData.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionData.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionData.Name` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionData.Order` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Stacked` | `bit` | `boolean` | Expected pgloader cast bit -> boolean |
| ✅ | `dbo.IndicatorVersionData.Type` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionData.Zone` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionEea.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionEea.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionEea.Description` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionEea.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionEea.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionEea.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionEea.Link` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionEea.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionEea.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionEea.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionEea.Order` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionIntRapport.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionIntRapport.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionIntRapport.Description` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionIntRapport.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionIntRapport.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionIntRapport.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionIntRapport.Link` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionIntRapport.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionIntRapport.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionIntRapport.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionIntRapport.Order` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionLanguage.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionLanguage.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionLanguage.Formaal` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.GrunnlagVekting` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.GrunnlagVerdi` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionLanguage.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionLanguage.Kontakt` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.KvalitetUsikkerhet` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.KvalitetVurdering` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.LanguageId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionLanguage.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionLanguage.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionLanguage.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionLanguage.Omtale` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionLanguage.OmtaleTittel` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.IndicatorVersionRelatedLink.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionRelatedLink.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionRelatedLink.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionRelatedLink.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionRelatedLink.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionRelatedLink.Link` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionRelatedLink.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionRelatedLink.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionRelatedLink.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionRelatedLink.Order` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionResource.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionResource.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionResource.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionResource.IndicatorVersionNo` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.IndicatorVersionResource.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.IndicatorVersionResource.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.IndicatorVersionResource.ResourceId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Language.Country` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Language.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Language.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Language.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Language.IsDefault` | `bit` | `boolean` | Expected pgloader cast bit -> boolean |
| ✅ | `dbo.Language.IsDeleted` | `bit` | `boolean` | Expected pgloader cast bit -> boolean |
| ✅ | `dbo.Language.Lang` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Language.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Language.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Language.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Member.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Member.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Member.IsDeleted` | `bit` | `boolean` | Expected pgloader cast bit -> boolean |
| ✅ | `dbo.Member.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Member.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Member.UserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.MemberRight.Allow` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.MemberRight.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.MemberRight.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.MemberRight.EnvironmentTargetId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.MemberRight.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.MemberRight.IndicatorId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.MemberRight.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.MemberRight.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.MemberRight.Type` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.MemberRight.UserId` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.Period.ArchiveDate` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Period.CopiedFrom` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Period.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Period.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Period.IsDeleted` | `bit` | `boolean` | Expected pgloader cast bit -> boolean |
| ✅ | `dbo.Period.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Period.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Period.PublishDate` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Period.Year` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Resource.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Resource.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Resource.Group` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Resource.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Resource.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Resource.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Resource.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResourceLanguage.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResourceLanguage.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResourceLanguage.LanguageId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResourceLanguage.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResourceLanguage.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResourceLanguage.ResourceId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResourceLanguage.Value` | `nvarchar` | `text` | Expected pgloader cast nvarchar -> text |
| ✅ | `dbo.ResultArea.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResultArea.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResultArea.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResultArea.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResultArea.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResultArea.Number` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResultArea.PeriodId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResultAreaLanguage.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResultAreaLanguage.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResultAreaLanguage.LanguageId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.ResultAreaLanguage.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.ResultAreaLanguage.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResultAreaLanguage.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.ResultAreaLanguage.ResultAreaId` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Theme.Created` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Theme.CreatedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Theme.Id` | `int` | `integer` | Expected int -> integer |
| ✅ | `dbo.Theme.Modified` | `datetime2` | `timestamp with time zone` | Expected pgloader cast datetime2 -> timestamp with time zone |
| ✅ | `dbo.Theme.ModifiedBy` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Theme.Name` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ✅ | `dbo.Theme.Uri` | `varchar` | `character varying` | Expected pgloader cast varchar -> character varying |
| ❌ | `dbo.__EFMigrationsHistory.MigrationId` | `nvarchar` | `character varying` | Expected pgloader cast nvarchar -> text |
| ❌ | `dbo.__EFMigrationsHistory.ProductVersion` | `nvarchar` | `character varying` | Expected pgloader cast nvarchar -> text |

## Sequence health

| Status | Column | Sequence | Table max | Sequence last value | Detail |
|---|---|---|---:|---:|---|
| N/A | n/a | n/a | n/a | n/a | No PostgreSQL sequences were associated with user tables |

## Orphan foreign-key health

| Status | Endpoint | Detail |
|---|---|---|
| ❌ | SQL Server | Source orphan baseline query returned no rows, so introduced-vs-pre-existing attribution is unavailable |

## Duplicate key health

| Status | Endpoint | Detail |
|---|---|---|
| ❌ | SQL Server | Source duplicate baseline query returned no rows, so introduced-vs-pre-existing attribution is unavailable |

