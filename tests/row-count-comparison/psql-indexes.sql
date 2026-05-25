SELECT
    n.nspname || '.' || t.relname AS table_name,
    i.relname AS index_name,
    COALESCE(substring(pg_get_indexdef(ix.indexrelid) FROM 'USING [^(]+ \(([^)]*)\)'), '') AS key_columns,
    COALESCE(substring(pg_get_indexdef(ix.indexrelid) FROM 'INCLUDE \(([^)]*)\)'), '') AS included_columns,
    CASE WHEN ix.indisunique THEN 'YES' ELSE 'NO' END AS is_unique,
    COALESCE(pg_get_expr(ix.indpred, ix.indrelid), '') AS filter_definition,
    am.amname AS index_type
FROM pg_index AS ix
JOIN pg_class AS t
    ON t.oid = ix.indrelid
JOIN pg_class AS i
    ON i.oid = ix.indexrelid
JOIN pg_namespace AS n
    ON n.oid = t.relnamespace
JOIN pg_am AS am
    ON am.oid = i.relam
WHERE NOT ix.indisprimary
  AND NOT ix.indisunique
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY table_name, index_name;
