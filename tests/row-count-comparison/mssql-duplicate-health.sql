SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

WITH unique_objects AS (
    SELECT
        s.name + '.' + t.name AS table_name,
        i.name AS object_name,
        CASE
            WHEN i.is_primary_key = 1 THEN 'PRIMARY_KEY'
            WHEN i.is_unique_constraint = 1 THEN 'UNIQUE_CONSTRAINT'
            ELSE 'UNIQUE_INDEX'
        END AS object_type,
        STRING_AGG(
            CASE WHEN ic.is_included_column = 0 THEN c.name END,
            ', '
        ) WITHIN GROUP (ORDER BY ic.key_ordinal, ic.index_column_id) AS key_columns,
        STRING_AGG(
            CASE WHEN ic.is_included_column = 0 THEN QUOTENAME(c.name) END,
            ', '
        ) WITHIN GROUP (ORDER BY ic.key_ordinal, ic.index_column_id) AS key_columns_sql,
        STRING_AGG(
            CASE WHEN ic.is_included_column = 0 THEN 'src.' + QUOTENAME(c.name) + ' IS NOT NULL' END,
            ' AND '
        ) WITHIN GROUP (ORDER BY ic.key_ordinal, ic.index_column_id) AS not_null_clause,
        COALESCE(i.filter_definition, '') AS filter_definition,
        QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS table_sql
    FROM sys.indexes AS i
    JOIN sys.tables AS t
        ON t.object_id = i.object_id
    JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id
    JOIN sys.columns AS c
        ON c.object_id = i.object_id
       AND c.column_id = ic.column_id
    WHERE i.type > 0
      AND (i.is_primary_key = 1 OR i.is_unique = 1)
      AND t.is_ms_shipped = 0
    GROUP BY
        s.name,
        t.name,
        i.name,
        i.is_primary_key,
        i.is_unique_constraint,
        i.filter_definition
)
SELECT @sql = STRING_AGG(
    N'SELECT N''' + REPLACE(table_name, '''', '''''') + N''' AS table_name, '
    + N'N''' + REPLACE(object_name, '''', '''''') + N''' AS object_name, '
    + N'N''' + REPLACE(object_type, '''', '''''') + N''' AS object_type, '
    + N'N''' + REPLACE(key_columns, '''', '''''') + N''' AS key_columns, '
    + N'COUNT(*) AS duplicate_group_count, COALESCE(SUM(duplicate_count - 1), 0) AS duplicate_row_count '
    + N'FROM (SELECT ' + key_columns_sql + N', COUNT_BIG(*) AS duplicate_count FROM ' + table_sql + N' AS src '
    + N'WHERE ' + CASE
                      WHEN filter_definition = '' THEN not_null_clause
                      ELSE not_null_clause + N' AND (' + filter_definition + N')'
                  END
    + N' GROUP BY ' + key_columns_sql + N' HAVING COUNT_BIG(*) > 1) AS duplicates',
    N' UNION ALL '
) WITHIN GROUP (ORDER BY table_name, object_name)
FROM unique_objects;

IF @sql IS NULL
BEGIN
    SELECT
        CAST(NULL AS nvarchar(256)) AS table_name,
        CAST(NULL AS nvarchar(256)) AS object_name,
        CAST(NULL AS nvarchar(64)) AS object_type,
        CAST(NULL AS nvarchar(4000)) AS key_columns,
        CAST(NULL AS bigint) AS duplicate_group_count,
        CAST(NULL AS bigint) AS duplicate_row_count
    WHERE 1 = 0;
END
ELSE
BEGIN
    SET @sql = N'SELECT table_name, object_name, object_type, key_columns, duplicate_group_count, duplicate_row_count '
             + N'FROM (' + @sql + N') AS duplicate_counts '
             + N'ORDER BY duplicate_group_count DESC, duplicate_row_count DESC, table_name, object_name;';
    EXEC sp_executesql @sql;
END;
