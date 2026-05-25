SELECT
    n.nspname || '.' || t.relname AS table_name,
    i.relname AS object_name,
    COALESCE(substring(pg_get_indexdef(ix.indexrelid) FROM 'USING [^(]+ \(([^)]*)\)'), '') AS key_columns,
    COALESCE(pg_get_expr(ix.indpred, ix.indrelid), '') AS filter_definition,
    CASE
        WHEN con.contype = 'u' THEN 'UNIQUE_CONSTRAINT'
        ELSE 'UNIQUE_INDEX'
    END AS object_type
FROM pg_index AS ix
JOIN pg_class AS t
    ON t.oid = ix.indrelid
JOIN pg_class AS i
    ON i.oid = ix.indexrelid
JOIN pg_namespace AS n
    ON n.oid = t.relnamespace
LEFT JOIN pg_constraint AS con
    ON con.conindid = ix.indexrelid
   AND con.contype = 'u'
WHERE ix.indisunique
  AND NOT ix.indisprimary
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY table_name, object_name;
