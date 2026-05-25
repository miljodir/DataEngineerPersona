SELECT
    c.table_schema || '.' || c.table_name AS table_name,
    c.column_name,
    c.data_type,
    c.column_default AS default_expression
FROM information_schema.columns AS c
JOIN information_schema.tables AS t
    ON t.table_schema = c.table_schema
   AND t.table_name = c.table_name
WHERE c.column_default IS NOT NULL
  AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND t.table_type = 'BASE TABLE'
  AND COALESCE(c.is_identity, 'NO') <> 'YES'
  AND c.column_default NOT LIKE 'nextval(%'
ORDER BY table_name, column_name;
