SET NOCOUNT ON;

SELECT
    s.name + '.' + t.name AS table_name,
    kc.name AS constraint_name,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.key_constraints AS kc
JOIN sys.tables AS t
    ON t.object_id = kc.parent_object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN sys.index_columns AS ic
    ON ic.object_id = t.object_id
   AND ic.index_id = kc.unique_index_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
   AND c.column_id = ic.column_id
WHERE kc.type = 'PK'
  AND t.is_ms_shipped = 0
GROUP BY s.name, t.name, kc.name
ORDER BY table_name;
