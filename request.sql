WITH params AS (
  SELECT
    '2024-01-01' AS date_from,         -- начало периода (включительно)
    '2025-01-01' AS date_to,           -- конец периода (исключая)
    NULL AS branch_id,                 -- фильтр по филиалу, например 1, либо NULL
    NULL AS reg_act_type_id,           -- фильтр по типу акта, например 1, либо NULL
    NULL AS process_id,                -- фильтр по процессу, например 2, либо NULL
    NULL AS consequence_id             -- фильтр по последствию, например 1, либо NULL
)
SELECT
  r.requirement_id,
  r.requirement_code,
  r.requirement_title,
  rat.type_name AS reg_act_type,
  ra.act_title  AS reg_act_title,
  COUNT(DISTINCT ve.violation_event_id) AS violations_count,
  GROUP_CONCAT(DISTINCT c.consequence_name) AS possible_consequences
FROM violation_event ve
JOIN requirement r
  ON r.requirement_id = ve.requirement_id
JOIN reg_act ra
  ON ra.reg_act_id = r.reg_act_id
JOIN reg_act_type rat
  ON rat.reg_act_type_id = ra.reg_act_type_id
LEFT JOIN requirement_consequence rc
  ON rc.requirement_id = r.requirement_id
LEFT JOIN consequence c
  ON c.consequence_id = rc.consequence_id
CROSS JOIN params p
WHERE ve.event_datetime >= p.date_from
  AND ve.event_datetime <  p.date_to
  AND (p.branch_id IS NULL OR ve.branch_id = p.branch_id)
  AND (p.reg_act_type_id IS NULL OR rat.reg_act_type_id = p.reg_act_type_id)
  AND (p.process_id IS NULL OR ve.process_id = p.process_id)
  AND (
    p.consequence_id IS NULL OR EXISTS (
      SELECT 1
      FROM requirement_consequence rc2
      WHERE rc2.requirement_id = r.requirement_id
        AND rc2.consequence_id = p.consequence_id
    )
  )
GROUP BY
  r.requirement_id,
  r.requirement_code,
  r.requirement_title,
  rat.type_name,
  ra.act_title
ORDER BY
  violations_count DESC,
  r.requirement_id ASC;