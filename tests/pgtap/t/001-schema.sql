-- 001-schema: Verify the migrated application schema exists in PostgreSQL

BEGIN;
SELECT plan(14);

SELECT ok(
  EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'public'),
  'Schema public should exist'
);

SELECT ok(to_regclass('public."EnvironmentTarget"') IS NOT NULL, 'Table public.EnvironmentTarget should exist');
SELECT ok(to_regclass('public."EnvironmentTargetVersion"') IS NOT NULL, 'Table public.EnvironmentTargetVersion should exist');
SELECT ok(to_regclass('public."Indicator"') IS NOT NULL, 'Table public.Indicator should exist');
SELECT ok(to_regclass('public."IndicatorVersion"') IS NOT NULL, 'Table public.IndicatorVersion should exist');
SELECT ok(to_regclass('public."Language"') IS NOT NULL, 'Table public.Language should exist');
SELECT ok(to_regclass('public."Member"') IS NOT NULL, 'Table public.Member should exist');
SELECT ok(to_regclass('public."MemberRight"') IS NOT NULL, 'Table public.MemberRight should exist');
SELECT ok(to_regclass('public."ResultArea"') IS NOT NULL, 'Table public.ResultArea should exist');
SELECT ok(to_regclass('public."Period"') IS NOT NULL, 'Table public.Period should exist');

SELECT is(
  (
    SELECT string_agg(a.attname, ', ' ORDER BY cols.ordinality)
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ordinality) ON true
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = cols.attnum
    WHERE con.contype = 'p'
      AND n.nspname = 'public'
      AND c.relname = 'EnvironmentTargetVersion'
  ),
  'EnvironmentTargetId, VersionNo',
  'EnvironmentTargetVersion should keep its composite primary key'
);

SELECT is(
  (
    SELECT string_agg(a.attname, ', ' ORDER BY cols.ordinality)
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ordinality) ON true
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = cols.attnum
    WHERE con.contype = 'p'
      AND n.nspname = 'public'
      AND c.relname = 'IndicatorVersion'
  ),
  'IndicatorId, VersionNo',
  'IndicatorVersion should keep its composite primary key'
);

SELECT is(
  (
    SELECT string_agg(a.attname, ', ' ORDER BY cols.ordinality)
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ordinality) ON true
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = cols.attnum
    WHERE con.contype = 'p'
      AND n.nspname = 'public'
      AND c.relname = 'EnvironmentTargetVersionLanguage'
  ),
  'EnvironmentTargetId, EnvironmentTargetVersionNo, LanguageId',
  'EnvironmentTargetVersionLanguage should keep its composite primary key'
);

SELECT is(
  (
    SELECT string_agg(a.attname, ', ' ORDER BY cols.ordinality)
    FROM pg_constraint con
    JOIN pg_class c ON c.oid = con.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ordinality) ON true
    JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = cols.attnum
    WHERE con.contype = 'p'
      AND n.nspname = 'public'
      AND c.relname = 'IndicatorVersionLanguage'
  ),
  'IndicatorId, IndicatorVersionNo, LanguageId',
  'IndicatorVersionLanguage should keep its composite primary key'
);

SELECT * FROM finish();
ROLLBACK;
