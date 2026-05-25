SET NOCOUNT ON;

SELECT
    s.name + '.' + t.name AS table_name,
    c.name AS column_name,
    info.DATA_TYPE AS data_type,
    dc.definition AS default_expression,
    dc.name AS constraint_name
FROM sys.default_constraints AS dc
JOIN sys.columns AS c
    ON c.object_id = dc.parent_object_id
   AND c.column_id = dc.parent_column_id
JOIN sys.tables AS t
    ON t.object_id = dc.parent_object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
JOIN INFORMATION_SCHEMA.COLUMNS AS info
    ON info.TABLE_SCHEMA = s.name
   AND info.TABLE_NAME = t.name
   AND info.COLUMN_NAME = c.name
WHERE t.is_ms_shipped = 0
ORDER BY table_name, column_name;
