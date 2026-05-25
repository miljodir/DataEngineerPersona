SELECT
    r.routine_schema || '.' || r.routine_name AS routine_name,
    COUNT(p.parameter_name) FILTER (WHERE p.ordinal_position > 0)::text AS parameter_count,
    COALESCE(
        string_agg(
            COALESCE(NULLIF(p.data_type, 'USER-DEFINED'), p.udt_name),
            ', '
            ORDER BY p.ordinal_position
        ) FILTER (WHERE p.ordinal_position > 0),
        ''
    ) AS parameter_types,
    COALESCE(NULLIF(r.data_type, 'USER-DEFINED'), r.type_udt_name, '') AS return_type
FROM information_schema.routines AS r
LEFT JOIN information_schema.parameters AS p
    ON p.specific_schema = r.specific_schema
   AND p.specific_name = r.specific_name
WHERE r.routine_schema NOT IN ('pg_catalog', 'information_schema')
  AND r.routine_type = 'FUNCTION'
GROUP BY r.routine_schema, r.routine_name, r.specific_name, r.data_type, r.type_udt_name
ORDER BY routine_name, parameter_count;
