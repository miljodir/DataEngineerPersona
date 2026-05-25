SELECT
    n.nspname || '.' || c.relname AS table_name,
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid, true) AS check_expression,
    CASE WHEN con.convalidated THEN 'NO' ELSE 'YES' END AS is_disabled
FROM pg_constraint AS con
JOIN pg_class AS c
    ON c.oid = con.conrelid
JOIN pg_namespace AS n
    ON n.oid = c.relnamespace
WHERE con.contype = 'c'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_name, constraint_name;
