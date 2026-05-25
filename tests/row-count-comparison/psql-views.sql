SELECT
    n.nspname || '.' || c.relname AS view_name,
    COALESCE(
        string_agg(a.attname, ', ' ORDER BY a.attnum),
        ''
    ) AS view_columns
FROM pg_class AS c
JOIN pg_namespace AS n
    ON n.oid = c.relnamespace
LEFT JOIN pg_attribute AS a
    ON a.attrelid = c.oid
   AND a.attnum > 0
   AND NOT a.attisdropped
WHERE c.relkind = 'v'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
      SELECT 1
      FROM pg_depend AS dep
      JOIN pg_extension AS ext
          ON ext.oid = dep.refobjid
      WHERE dep.classid = 'pg_class'::regclass
        AND dep.objid = c.oid
        AND dep.deptype = 'e'
  )
GROUP BY n.nspname, c.relname
ORDER BY view_name;
