WITH fk_columns AS (
    SELECT
        child_ns.nspname || '.' || child_table.relname AS table_name,
        con.conname AS constraint_name,
        parent_ns.nspname || '.' || parent_table.relname AS referenced_table,
        string_agg(child_att.attname, ', ' ORDER BY child_cols.ordinality) AS key_columns,
        string_agg(parent_att.attname, ', ' ORDER BY parent_cols.ordinality) AS referenced_columns
    FROM pg_constraint AS con
    JOIN pg_class AS child_table
        ON child_table.oid = con.conrelid
    JOIN pg_namespace AS child_ns
        ON child_ns.oid = child_table.relnamespace
    JOIN pg_class AS parent_table
        ON parent_table.oid = con.confrelid
    JOIN pg_namespace AS parent_ns
        ON parent_ns.oid = parent_table.relnamespace
    JOIN unnest(con.conkey) WITH ORDINALITY AS child_cols(attnum, ordinality)
        ON true
    JOIN unnest(con.confkey) WITH ORDINALITY AS parent_cols(attnum, ordinality)
        ON parent_cols.ordinality = child_cols.ordinality
    JOIN pg_attribute AS child_att
        ON child_att.attrelid = child_table.oid
       AND child_att.attnum = child_cols.attnum
    JOIN pg_attribute AS parent_att
        ON parent_att.attrelid = parent_table.oid
       AND parent_att.attnum = parent_cols.attnum
    WHERE con.contype = 'f'
      AND child_ns.nspname NOT IN ('pg_catalog', 'information_schema')
      AND parent_ns.nspname NOT IN ('pg_catalog', 'information_schema')
    GROUP BY child_ns.nspname, child_table.relname, con.conname, parent_ns.nspname, parent_table.relname
)
SELECT
    table_name,
    constraint_name,
    key_columns,
    referenced_table,
    referenced_columns
FROM fk_columns
ORDER BY table_name, constraint_name;
