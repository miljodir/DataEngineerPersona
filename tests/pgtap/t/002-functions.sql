-- 002-application-objects: Verify migrated application objects and expected absence of app routines

BEGIN;
SELECT plan(9);

SELECT is(
  (
    SELECT COUNT(*)
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND p.prokind = 'f'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend dep
        JOIN pg_extension ext ON ext.oid = dep.refobjid
        WHERE dep.classid = 'pg_proc'::regclass
          AND dep.objid = p.oid
          AND dep.deptype = 'e'
      )
  ),
  0::bigint,
  'No user-defined non-extension functions should be present for this migrated application schema'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'v'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend dep
        JOIN pg_extension ext ON ext.oid = dep.refobjid
        WHERE dep.classid = 'pg_class'::regclass
          AND dep.objid = c.oid
          AND dep.deptype = 'e'
      )
  ),
  0::bigint,
  'No user-defined non-extension views should be present for this migrated application schema'
);

SELECT ok(to_regclass('public."IX_Language_Lang_Country"') IS NOT NULL, 'Unique index IX_Language_Lang_Country should exist');
SELECT ok(to_regclass('public."IX_Resource_Name_Group"') IS NOT NULL, 'Unique index IX_Resource_Name_Group should exist');
SELECT ok(to_regclass('public."IX_MemberRight_UserId_EnvironmentTargetId"') IS NOT NULL, 'Unique index IX_MemberRight_UserId_EnvironmentTargetId should exist');
SELECT ok(to_regclass('public."IX_MemberRight_UserId_IndicatorId"') IS NOT NULL, 'Unique index IX_MemberRight_UserId_IndicatorId should exist');

SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_constraint con
    JOIN pg_class child ON child.oid = con.conrelid
    JOIN pg_namespace child_ns ON child_ns.oid = child.relnamespace
    JOIN pg_class parent ON parent.oid = con.confrelid
    JOIN pg_namespace parent_ns ON parent_ns.oid = parent.relnamespace
    WHERE con.contype = 'f'
      AND child_ns.nspname = 'public'
      AND parent_ns.nspname = 'public'
      AND child.relname = 'EnvironmentTarget'
      AND parent.relname = 'ResultArea'
  ),
  'EnvironmentTarget should keep its FK to ResultArea'
);

SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_constraint con
    JOIN pg_class child ON child.oid = con.conrelid
    JOIN pg_namespace child_ns ON child_ns.oid = child.relnamespace
    JOIN pg_class parent ON parent.oid = con.confrelid
    JOIN pg_namespace parent_ns ON parent_ns.oid = parent.relnamespace
    WHERE con.contype = 'f'
      AND child_ns.nspname = 'public'
      AND parent_ns.nspname = 'public'
      AND child.relname = 'Indicator'
      AND parent.relname = 'EnvironmentTarget'
  ),
  'Indicator should keep its FK to EnvironmentTarget'
);

SELECT ok(
  EXISTS (
    SELECT 1
    FROM pg_constraint con
    JOIN pg_class child ON child.oid = con.conrelid
    JOIN pg_namespace child_ns ON child_ns.oid = child.relnamespace
    JOIN pg_class parent ON parent.oid = con.confrelid
    JOIN pg_namespace parent_ns ON parent_ns.oid = parent.relnamespace
    WHERE con.contype = 'f'
      AND child_ns.nspname = 'public'
      AND parent_ns.nspname = 'public'
      AND child.relname = 'MemberRight'
      AND parent.relname = 'Member'
  ),
  'MemberRight should keep its FK to Member'
);

SELECT * FROM finish();
ROLLBACK;
