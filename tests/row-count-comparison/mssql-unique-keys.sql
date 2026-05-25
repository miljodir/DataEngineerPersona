SET NOCOUNT ON;

SELECT
    s.name + '.' + t.name AS table_name,
    i.name AS object_name,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 THEN c.name END,
        ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal, ic.index_column_id) AS key_columns,
    REPLACE(REPLACE(COALESCE(i.filter_definition, ''), '[', ''), ']', '') AS filter_definition,
    CASE
        WHEN i.is_unique_constraint = 1 THEN 'UNIQUE_CONSTRAINT'
        ELSE 'UNIQUE_INDEX'
    END AS object_type
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
  AND i.is_primary_key = 0
  AND i.is_unique = 1
  AND t.is_ms_shipped = 0
GROUP BY s.name, t.name, i.name, i.filter_definition, i.is_unique_constraint
ORDER BY table_name, object_name;
