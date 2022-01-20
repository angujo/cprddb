WITH vo AS (SELECT * FROM visit_occurance),
ss AS (SELECT * FROM source_to_source),
st AS (SELECT * FROM source_to_standard),
clinical AS (
	SELECT
	c.patid, c.eventdate, c.medcode, c.staffid, c.consid
	FROM clinical c
	JOIN vo ON vo.person_id = c.patid AND vo.visit_start_date = c.eventdate
	LEFT JOIN ss s ON s.source_code = c.medcode AND source_vocabulary_id = 'Read'
	LEFT JOIN st t ON t.source_code = c.medcode AND t.source_vocabulary_id = 'Read' AND t.Target_standard_concept = 'S' and t.target_invalid_reason is NULL
)
INSERT INTO stem_table
(domain_id, person_id, visit_occurrence_id, provider_id, start_datetime, concept_id, source_concept_id, type_concept_id, operator_concept_id, unit_concept_id, unit_source_value, start_date, end_date, sig)
