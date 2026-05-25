SET NOCOUNT ON;

SELECT
    s.name + '.' + t.name AS table_name,
    cc.name AS constraint_name,
    cc.definition AS check_expression,
    CASE WHEN cc.is_disabled = 1 THEN 'YES' ELSE 'NO' END AS is_disabled
FROM sys.check_constraints AS cc
JOIN sys.tables AS t
    ON t.object_id = cc.parent_object_id
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY table_name, constraint_name;
