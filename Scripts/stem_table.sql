WITH voccur AS (SELECT * FROM visit_occurance),
	ssource AS (SELECT * FROM source_to_source),
	sstandard AS (SELECT * FROM source_to_standard),
	concs AS (SELECT concept_id, domain_id, concept_name FROM concept WHERE standard_concept = 'S' and invalid_reason is NULL and (domain_id IN ('Meas Value','Meas Value Operator') OR vocabulary_id IN ('UCUM')) GROUP BY concept_code),
	meds AS (SELECT * FROM medical),
	clinicals AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		c.patid, vo.visit_occurrence_id, c.staffid, c.eventdate::timestamp start_datetime, m.read_code source_value, st.source_concept_id, c.medcode, ss.source_concept_id, 32827,NULL,NULL,NULL,c.eventdate, null
		FROM clinical c
		JOIN meds m AS c.medcode = m.medcode
		JOIN vo ON vo.person_id = c.patid AND vo.visit_start_date = c.eventdate
		LEFT JOIN ss ss ON ss.source_code = m.read_code AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN st st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	referrals AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		r.patid, vo.visit_occurrence_id, r.staffid, r.eventdate::timestamp start_datetime, m.read_code source_value, st.source_concept_id, r.medcode, ss.source_concept_id, 32842,NULL,NULL,NULL,r.eventdate, null
		FROM referral r
		JOIN meds m AS r.medcode = m.medcode
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN ssource ss ON ss.source_code = m.read_code AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	immunes AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		r.patid, vo.visit_occurrence_id, r.staffid, r.eventdate::timestamp start_datetime, m.read_code source_value, st.source_concept_id, r.medcode, ss.source_concept_id, 32827,NULL,NULL,NULL,r.eventdate, null
		FROM immunisation r
		JOIN meds m AS r.medcode = m.medcode
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN ssource ss ON ss.source_code = m.read_code AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	tests AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id END AS domain_id, 
		ti.patid AS person_id, vo.visit_occurrence_id, ti.staffid AS provider_id, ti.eventdate::timestamp AS start_datetime, ti.read_code source_value, st.source_concept_id AS concept_id, 
		ss.source_concept_id, 32856 AS type_concept_id, 
		CASE cop.concept_id IS NULL THEN 0 ELSE cop.concept_id end operator_concept_id,
		cu.concept_id unit_concept_id,ti.unit unit_source_value,ti.eventdate start_date, 
		null end_date, NULL AS sig, ti.range_high, ti.range_low, ti.value_as_number, cv.concept_id value_as_concept_id, ti.value_as_concept_id
		FROM test_int ti
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = ti.eventdate
		LEFT JOIN concs cop ON cop.ti.operator = cop.concept_name AND cop.domain_id IN ('Meas Value Operator')
		LEFT JOIN ssource ss ON ss.source_code = ti.read_code AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = ti.read_code AND st.source_vocabulary_id = 'JNJ_CPRD_TEST_ENT' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
		LEFT JOIN concs cu ON cu.concept_code = ti.unit AND cu.vocabulary_id = 'UCUM'
		LEFT JOIN concept cv ON cv.concept_name = ti.value_as_concept_id AND cc.domain_id IN ('Meas Value')
	)
INSERT INTO stem_table
(domain_id, person_id, visit_occurrence_id, provider_id, start_datetime, concept_id, source_concept_id, type_concept_id, operator_concept_id, unit_concept_id, unit_source_value,
start_date, end_date, sig, range_high, range_low, value_as_number, value_as_concept_id, value_source_value)
