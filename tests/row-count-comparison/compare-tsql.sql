SELECT
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
    JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY SCHEMA_NAME(t.schema_id), t.name
ORDER BY table_name;