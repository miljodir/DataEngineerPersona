SET NOCOUNT ON;

WITH fk_columns AS (
    SELECT
        fk.object_id,
        child_schema.name + '.' + child_table.name AS table_name,
        fk.name AS constraint_name,
        parent_schema.name + '.' + parent_table.name AS referenced_table,
        STRING_AGG(child_column.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS key_columns,
        STRING_AGG(parent_column.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referenced_columns
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
        fk.object_id,
        child_schema.name,
        child_table.name,
        fk.name,
        parent_schema.name,
        parent_table.name
)
SELECT
    table_name,
    constraint_name,
    key_columns,
    referenced_table,
    referenced_columns
FROM fk_columns
ORDER BY table_name, constraint_name;
