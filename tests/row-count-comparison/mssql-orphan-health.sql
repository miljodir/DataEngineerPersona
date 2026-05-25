SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

WITH fk_metadata AS (
    SELECT
        child_schema.name + '.' + child_table.name AS child_table,
        parent_schema.name + '.' + parent_table.name AS parent_table,
        fk.name AS constraint_name,
        STRING_AGG(child_column.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS fk_columns,
        STRING_AGG(parent_column.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referenced_columns,
        STRING_AGG('child.' + QUOTENAME(child_column.name) + ' IS NOT NULL', ' AND ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS not_null_clause,
        STRING_AGG('child.' + QUOTENAME(child_column.name) + ' = parent.' + QUOTENAME(parent_column.name), ' AND ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS join_clause,
        QUOTENAME(child_schema.name) + '.' + QUOTENAME(child_table.name) AS child_table_sql,
        QUOTENAME(parent_schema.name) + '.' + QUOTENAME(parent_table.name) AS parent_table_sql
    FROM sys.foreign_keys AS fk
    JOIN sys.foreign_key_columns AS fkc
        ON fkc.constraint_object_id = fk.object_id
    JOIN sys.tables AS child_table
        ON child_table.object_id = fk.parent_object_id
    JOIN sys.schemas AS child_schema
        ON child_schema.schema_id = child_table.schema_id
    JOIN sys.columns AS child_column
        ON child_column.object_id = child_table.object_id
       AND child_column.column_id = fkc.parent_column_id
    JOIN sys.tables AS parent_table
        ON parent_table.object_id = fk.referenced_object_id
    JOIN sys.schemas AS parent_schema
        ON parent_schema.schema_id = parent_table.schema_id
    JOIN sys.columns AS parent_column
        ON parent_column.object_id = parent_table.object_id
       AND parent_column.column_id = fkc.referenced_column_id
    WHERE child_table.is_ms_shipped = 0
      AND parent_table.is_ms_shipped = 0
    GROUP BY
        child_schema.name,
        child_table.name,
        parent_schema.name,
        parent_table.name,
        fk.name
)
SELECT @sql = STRING_AGG(
    N'SELECT N''' + REPLACE(child_table, '''', '''''') + N''' AS child_table, '
    + N'N''' + REPLACE(parent_table, '''', '''''') + N''' AS parent_table, '
    + N'N''' + REPLACE(constraint_name, '''', '''''') + N''' AS constraint_name, '
    + N'N''' + REPLACE(fk_columns, '''', '''''') + N''' AS fk_columns, '
    + N'N''' + REPLACE(referenced_columns, '''', '''''') + N''' AS referenced_columns, '
    + N'COUNT_BIG(*) AS orphan_count FROM ' + child_table_sql + N' AS child '
    + N'WHERE ' + not_null_clause + N' AND NOT EXISTS (SELECT 1 FROM ' + parent_table_sql + N' AS parent WHERE ' + join_clause + N')',
    N' UNION ALL '
) WITHIN GROUP (ORDER BY child_table, constraint_name)
FROM fk_metadata;

IF @sql IS NULL
BEGIN
    SELECT
        CAST(NULL AS nvarchar(256)) AS child_table,
        CAST(NULL AS nvarchar(256)) AS parent_table,
        CAST(NULL AS nvarchar(256)) AS constraint_name,
        CAST(NULL AS nvarchar(4000)) AS fk_columns,
        CAST(NULL AS nvarchar(4000)) AS referenced_columns,
        CAST(NULL AS bigint) AS orphan_count
    WHERE 1 = 0;
END
ELSE
BEGIN
    SET @sql = N'SELECT child_table, parent_table, constraint_name, fk_columns, referenced_columns, orphan_count '
             + N'FROM (' + @sql + N') AS orphan_counts '
             + N'ORDER BY orphan_count DESC, child_table, constraint_name;';
    EXEC sp_executesql @sql;
END;
