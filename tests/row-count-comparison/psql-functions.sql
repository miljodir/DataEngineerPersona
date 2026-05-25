SELECT
    n.nspname || '.' || p.proname AS routine_name,
    COUNT(arg.arg_oid)::text AS parameter_count,
    COALESCE(
        string_agg(
            format_type(arg.arg_oid, NULL),
            ', '
            ORDER BY arg.ordinality
        ),
        ''
    ) AS parameter_types,
    pg_get_function_result(p.oid) AS return_type
FROM pg_proc AS p
JOIN pg_namespace AS n
    ON n.oid = p.pronamespace
LEFT JOIN LATERAL unnest(COALESCE(p.proargtypes::oid[], ARRAY[]::oid[])) WITH ORDINALITY AS arg(arg_oid, ordinality)
    ON true
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND p.prokind = 'f'
  AND NOT EXISTS (
      SELECT 1
      FROM pg_depend AS dep
      JOIN pg_extension AS ext
          ON ext.oid = dep.refobjid
      WHERE dep.classid = 'pg_proc'::regclass
        AND dep.objid = p.oid
        AND dep.deptype = 'e'
  )
GROUP BY n.nspname, p.proname, p.oid
ORDER BY routine_name, parameter_count;
