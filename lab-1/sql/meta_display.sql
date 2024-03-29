DROP VIEW IF EXISTS meta_display_constraint_check CASCADE;
CREATE VIEW meta_display_constraint_check AS 
  SELECT 
    meta_constraint_check.id                         AS id,
    meta_constraint_check.name                       AS name,
    meta_constraint_check.namespace_id               AS namespace_id,
    meta_constraint_check.constrained_table_id       AS constrained_table_id,
    meta_constraint_check.constrained_column_numbers AS constrained_column_numbers,
    meta_constraint_check.clause                     AS clause
  FROM meta_constraint_check;

DROP VIEW IF EXISTS meta_display_constraint_check_single CASCADE;
CREATE VIEW meta_display_constraint_check_single AS 
  SELECT
    meta_display_constraint_check.id                            AS id,
    meta_display_constraint_check.name                          AS name,
    meta_display_constraint_check.namespace_id                  AS namespace_id,
    meta_display_constraint_check.constrained_table_id          AS constrained_table_id,
    meta_display_constraint_check.constrained_column_numbers[1] AS constrained_column_number,
    meta_display_constraint_check.clause                        AS clause
  FROM meta_display_constraint_check
  WHERE cardinality(meta_display_constraint_check.constrained_column_numbers) = 1;

DROP VIEW IF EXISTS meta_display_constraint_check_multiple CASCADE;
CREATE VIEW meta_display_constraint_check_multiple AS 
  SELECT 
    meta_display_constraint_check.id                         AS id,
    meta_display_constraint_check.name                       AS name,
    meta_display_constraint_check.namespace_id               AS namespace_id,
    meta_display_constraint_check.constrained_table_id       AS constrained_table_id,
    meta_display_constraint_check.constrained_column_numbers AS constrained_column_numbers,
    meta_display_constraint_check.clause                     AS clause
  FROM meta_display_constraint_check
  WHERE cardinality(meta_display_constraint_check.constrained_column_numbers) != 1;

DROP VIEW IF EXISTS meta_display_constraint_foreign_key_single CASCADE;
CREATE VIEW meta_display_constraint_foreign_key_single AS 
  SELECT 
    meta_constraint_foreign_key.id                            AS id,
    meta_constraint_foreign_key.name                          AS name,
    meta_constraint_foreign_key.namespace_id                  AS namespace_id,
    meta_constraint_foreign_key.constrained_table_id          AS constrained_table_id,
    meta_constraint_foreign_key.constrained_column_numbers[1] AS constrained_column_number,
    ('REFERENCES ' || meta_table_column.name::text)           AS clause
  FROM meta_constraint_foreign_key
  JOIN meta_table        ON meta_table.id = meta_constraint_foreign_key.referenced_table_id
  JOIN meta_table_column ON (
    meta_table_column.table_id = meta_table.id AND 
    meta_table_column.number = meta_constraint_foreign_key.referenced_column_numbers[1]
  )
  WHERE (
   cardinality(meta_constraint_foreign_key.constrained_column_numbers) = 1 AND
   cardinality(meta_constraint_foreign_key.referenced_column_numbers) = 1
  );

DROP FUNCTION IF EXISTS meta_display_column_name CASCADE;
CREATE FUNCTION meta_display_column_name(
  table_id      oid,
  column_number integer
) RETURNS text AS $$
DECLARE 
  column_name text;
BEGIN
  SELECT meta_table_column.name INTO column_name
  FROM meta_table 
  JOIN meta_table_column ON meta_table_column.table_id = meta_table.id
  WHERE meta_table.id = meta_display_column_name.table_id 
    AND meta_table_column.number = meta_display_column_name.column_number;

  RETURN column_name;
END; 
$$ LANGUAGE plpgsql;

DROP VIEW IF EXISTS meta_display_constraint_foreign_key_multiple CASCADE;
CREATE VIEW meta_display_constraint_foreign_key_multiple AS 
  SELECT 
    meta_constraint_foreign_key.id                         AS id,
    meta_constraint_foreign_key.name                       AS name,
    meta_constraint_foreign_key.namespace_id               AS namespace_id,
    meta_constraint_foreign_key.constrained_table_id       AS constrained_table_id,
    meta_constraint_foreign_key.constrained_column_numbers AS constrained_column_numbers,
    meta_constraint_foreign_key.referenced_table_id        AS referenced_table_id,
    meta_constraint_foreign_key.referenced_column_numbers  AS referenced_column_numbers,
    (
      (
        SELECT string_agg(meta_display_column_name(constrained_table_id, constrained_column_number), ', ') 
        FROM unnest(meta_constraint_foreign_key.constrained_column_numbers) 
        AS constrained_column_number
      ) || ' REFERENCES ' || (
        SELECT string_agg(meta_display_column_name(referenced_table_id, referenced_column_number), ', ')          
        FROM unnest(meta_constraint_foreign_key.referenced_column_numbers) 
        AS referenced_column_number
      )
    )                                                      AS clause
  FROM meta_constraint_foreign_key
  WHERE (
   cardinality(meta_constraint_foreign_key.constrained_column_numbers) != 1 AND
   cardinality(meta_constraint_foreign_key.referenced_column_numbers) != 1
  );

DROP VIEW IF EXISTS meta_display_constraint_primary_key_single CASCADE;
CREATE VIEW meta_display_constraint_primary_key_single AS
  SELECT
    meta_constraint_primary_key.id                            AS id,
    meta_constraint_primary_key.name                          AS name,
    meta_constraint_primary_key.namespace_id                  AS namespace_id,
    meta_constraint_primary_key.constrained_table_id          AS constrained_table_id,
    meta_constraint_primary_key.constrained_column_numbers[1] AS constrained_column_number,
    'PRIMARY KEY'                                             AS clause
  FROM meta_constraint_primary_key
  WHERE cardinality(meta_constraint_primary_key.constrained_column_numbers) = 1;

DROP VIEW IF EXISTS meta_display_constraint_primary_key_multiple CASCADE;
CREATE VIEW meta_display_constraint_primary_key_multiple AS
  SELECT
    meta_constraint_primary_key.id                          AS id,
    meta_constraint_primary_key.name                        AS name,
    meta_constraint_primary_key.namespace_id                AS namespace_id,
    meta_constraint_primary_key.constrained_table_id        AS constrained_table_id,
    meta_constraint_primary_key.constrained_column_numbers  AS constrained_column_numbers,
    (
      'PRIMARY KEY ' || (
        SELECT string_agg(meta_display_column_name(constrained_table_id, constrained_column_number), ', ') 
        FROM unnest(meta_constraint_primary_key.constrained_column_numbers) 
        AS constrained_column_number
      )
    )                                                       AS clause
  FROM meta_constraint_primary_key
  WHERE cardinality(meta_constraint_primary_key.constrained_column_numbers) != 1;

DROP VIEW IF EXISTS meta_display_constraint_unique_single CASCADE;
CREATE VIEW meta_display_constraint_unique_single AS
  SELECT
    meta_constraint_unique.id                            AS id,
    meta_constraint_unique.name                          AS name,
    meta_constraint_unique.namespace_id                  AS namespace_id,
    meta_constraint_unique.constrained_table_id          AS constrained_table_id,
    meta_constraint_unique.constrained_column_numbers[1] AS constrained_column_number,
    'UNIQUE'                                             AS clause
  FROM meta_constraint_unique
  WHERE cardinality(meta_constraint_unique.constrained_column_numbers) = 1;

DROP VIEW IF EXISTS meta_display_constraint_unique_multiple CASCADE;
CREATE VIEW meta_display_constraint_unique_multiple AS
  SELECT
    meta_constraint_unique.id                          AS id,
    meta_constraint_unique.name                        AS name,
    meta_constraint_unique.namespace_id                AS namespace_id,
    meta_constraint_unique.constrained_table_id        AS constrained_table_id,
    meta_constraint_unique.constrained_column_numbers  AS constrained_column_numbers,
    (
      'UNIQUE ' || (
        SELECT string_agg(meta_display_column_name(constrained_table_id, constrained_column_number), ', ') 
        FROM unnest(meta_constraint_unique.constrained_column_numbers) 
        AS constrained_column_number
      )
    )                                                  AS clause
  FROM meta_constraint_unique
  WHERE cardinality(meta_constraint_unique.constrained_column_numbers) != 1;

DROP VIEW IF EXISTS meta_display_constraint_exclusion CASCADE;
CREATE VIEW meta_display_constraint_exclusion_multiple AS 
  SELECT
    meta_constraint_exclusion.id                         AS id,
    meta_constraint_exclusion.name                       AS name,
    meta_constraint_exclusion.namespace_id               AS namespace_id,
    meta_constraint_exclusion.constrained_table_id       AS constrained_table_id,
    meta_constraint_exclusion.constrained_column_numbers AS constrained_column_numbers,
    (
      'EXCLUDE ' || (
        SELECT 
          string_agg((
            '(' 
            || meta_display_column_name(constrained_table_id, column_number)
            || ' WITH ' 
            || meta_operator.name || 
            ')'
          ), ', ') 
        FROM unnest(
          meta_constraint_exclusion.constrained_column_numbers,
          meta_constraint_exclusion.per_column_operator_ids
        ) WITH ORDINALITY AS column_operator(column_number, operator_id)
        JOIN meta_operator ON meta_operator.id = column_operator.operator_id
      )
    )                                                 AS clause
  FROM meta_constraint_exclusion;

DROP VIEW IF EXISTS meta_display_contraint_single CASCADE;
CREATE VIEW meta_display_contraint_single AS
  (
    SELECT id, name, namespace_id, constrained_table_id, constrained_column_number, clause 
    FROM meta_display_constraint_check_single
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, constrained_column_number, clause
    FROM meta_display_constraint_foreign_key_single
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, constrained_column_number, clause
    FROM meta_display_constraint_primary_key_single
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, constrained_column_number, clause
    FROM meta_display_constraint_unique_single
  );

DROP VIEW IF EXISTS meta_display_contraint_multiple CASCADE;
CREATE VIEW meta_display_contraint_multiple AS
  (
    SELECT id, name, namespace_id, constrained_table_id, clause
    FROM meta_display_constraint_check_multiple
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, clause 
    FROM meta_display_constraint_foreign_key_multiple
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, clause 
    FROM meta_display_constraint_primary_key_multiple
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, clause 
    FROM meta_display_constraint_unique_multiple
  ) UNION ALL (
    SELECT id, name, namespace_id, constrained_table_id, clause 
    FROM meta_display_constraint_exclusion_multiple
  );