WITH vo AS (SELECT * FROM visit_occurance),
ss AS (SELECT * FROM source_to_standard),
clinical AS (
	SELECT
	*
	FROM clinical c
	JOIN vo ON vo.
	LEFT JOIN ss s ON s.source_code = c.medcode
)
INSERT INTO stem_table
(domain_id, person_id, visit_occurrence_id, provider_id, start_datetime, concept_id, source_concept_id, type_concept_id, operator_concept_id, unit_concept_id, unit_source_value, start_date, end_date, sig)
