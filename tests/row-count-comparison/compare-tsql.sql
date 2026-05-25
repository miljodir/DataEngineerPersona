SET NOCOUNT ON;

DECLARE @sql nvarchar(max);

SELECT @sql = STRING_AGG(
    N'SELECT N''' + REPLACE(s.name + N'.' + t.name, '''', '''''') + N''' AS table_name, COUNT_BIG(*) AS row_count FROM '
    + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
    N' UNION ALL '
) WITHIN GROUP (ORDER BY s.name, t.name)
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0;

IF @sql IS NULL
BEGIN
    SELECT CAST(NULL AS nvarchar(256)) AS table_name, CAST(NULL AS bigint) AS row_count
    WHERE 1 = 0;
END
ELSE
BEGIN
    SET @sql = N'SELECT table_name, row_count FROM (' + @sql + N') AS counts ORDER BY table_name;';
    EXEC sp_executesql @sql;
END;
