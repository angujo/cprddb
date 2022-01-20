INSERT INTO observation_period
(person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id)
SELECT 
p.patid, max(p.frd,r.uts), min(p.tod,r.lcd, p.crd), 32880
FROM SOURCE.patient p, SOURCE.practice r WHERE RIGHT(p.patid,5)::numeric = r.pracid