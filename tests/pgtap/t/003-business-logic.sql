-- 003-business-logic: Verify core migrated data integrity rules for the application schema

BEGIN;
SELECT plan(9);

SELECT is(
  (
    SELECT COUNT(*)
    FROM public."EnvironmentTargetVersion" child
    LEFT JOIN public."EnvironmentTarget" parent
      ON parent."Id" = child."EnvironmentTargetId"
    WHERE parent."Id" IS NULL
  ),
  0::bigint,
  'Every EnvironmentTargetVersion should reference an EnvironmentTarget'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM public."IndicatorVersion" child
    LEFT JOIN public."Indicator" parent
      ON parent."Id" = child."IndicatorId"
    WHERE parent."Id" IS NULL
  ),
  0::bigint,
  'Every IndicatorVersion should reference an Indicator'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM public."MemberRight" child
    LEFT JOIN public."Member" parent
      ON parent."UserId" = child."UserId"
    WHERE parent."UserId" IS NULL
  ),
  0::bigint,
  'Every MemberRight should reference an existing Member'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM (
      SELECT "Lang", "Country"
      FROM public."Language"
      GROUP BY "Lang", "Country"
      HAVING COUNT(*) > 1
    ) duplicates
  ),
  0::bigint,
  'Language should not contain duplicate (Lang, Country) combinations'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM (
      SELECT "Name", "Group"
      FROM public."Resource"
      WHERE "Name" IS NOT NULL
        AND "Group" IS NOT NULL
      GROUP BY "Name", "Group"
      HAVING COUNT(*) > 1
    ) duplicates
  ),
  0::bigint,
  'Resource should not contain duplicate (Name, Group) combinations'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM (
      SELECT "UserId", "EnvironmentTargetId"
      FROM public."MemberRight"
      WHERE "UserId" IS NOT NULL
        AND "EnvironmentTargetId" IS NOT NULL
      GROUP BY "UserId", "EnvironmentTargetId"
      HAVING COUNT(*) > 1
    ) duplicates
  ),
  0::bigint,
  'MemberRight should not contain duplicate (UserId, EnvironmentTargetId) pairs'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM (
      SELECT "UserId", "IndicatorId"
      FROM public."MemberRight"
      WHERE "UserId" IS NOT NULL
        AND "IndicatorId" IS NOT NULL
      GROUP BY "UserId", "IndicatorId"
      HAVING COUNT(*) > 1
    ) duplicates
  ),
  0::bigint,
  'MemberRight should not contain duplicate (UserId, IndicatorId) pairs'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM public."EnvironmentTarget" parent
    LEFT JOIN public."EnvironmentTargetVersion" child
      ON child."EnvironmentTargetId" = parent."Id"
    WHERE child."EnvironmentTargetId" IS NULL
  ),
  0::bigint,
  'Every EnvironmentTarget should have at least one EnvironmentTargetVersion'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM public."Indicator" parent
    LEFT JOIN public."IndicatorVersion" child
      ON child."IndicatorId" = parent."Id"
    WHERE child."IndicatorId" IS NULL
  ),
  0::bigint,
  'Every Indicator should have at least one IndicatorVersion'
);

SELECT * FROM finish();
ROLLBACK;
