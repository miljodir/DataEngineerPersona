SELECT
    n.nspname || '.' || c.relname AS table_name,
    con.conname AS constraint_name,
    string_agg(a.attname, ', ' ORDER BY cols.ordinality) AS key_columns
FROM pg_constraint AS con
JOIN pg_class AS c
    ON c.oid = con.conrelid
JOIN pg_namespace AS n
    ON n.oid = c.relnamespace
JOIN unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ordinality)
    ON true
JOIN pg_attribute AS a
    ON a.attrelid = c.oid
   AND a.attnum = cols.attnum
WHERE con.contype = 'p'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY n.nspname, c.relname, con.conname
ORDER BY table_name;
