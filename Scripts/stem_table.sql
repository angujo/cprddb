WITH voccur AS (SELECT * FROM visit_occurance),
	ssource AS (SELECT * FROM source_to_source),
	sstandard AS (SELECT * FROM source_to_standard),
	clinicals AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		c.patid, vo.visit_occurrence_id, c.staffid, c.eventdate::timestamp, st.source_concept_id, c.medcode, ss.source_concept_id, 32827,NULL,NULL,NULL,c.eventdate, null
		FROM clinical c
		JOIN vo ON vo.person_id = c.patid AND vo.visit_start_date = c.eventdate
		LEFT JOIN ss ss ON ss.source_code = c.medcode AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN st st ON st.source_code = c.medcode AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	referrals AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		r.patid, vo.visit_occurrence_id, r.staffid, r.eventdate::timestamp, st.source_concept_id, r.medcode, ss.source_concept_id, 32842,NULL,NULL,NULL,r.eventdate, null
		FROM referral r
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN ssource ss ON ss.source_code = r.medcode AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = r.medcode AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	immunes AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		r.patid, vo.visit_occurrence_id, r.staffid, r.eventdate::timestamp, st.source_concept_id, r.medcode, ss.source_concept_id, 32827,NULL,NULL,NULL,r.eventdate, null
		FROM immunisation r
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN ssource ss ON ss.source_code = r.medcode AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = r.medcode AND st.source_vocabulary_id = 'Read' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	),
	tests AS (
		SELECT
		CASE WHEN st.source_concept_id IS NULL OR 0 = st.source_concept_id THEN 'Observation' else st.source_domain_id end, 
		r.patid, vo.visit_occurrence_id, r.staffid, r.eventdate::timestamp, st.source_concept_id, r.medcode, ss.source_concept_id, 32856,NULL,NULL,NULL,r.eventdate, null
		FROM test r
		JOIN test_int ti ON ti.enttype = r.enttype
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = ti.eventdate
		LEFT JOIN ssource ss ON ss.source_code = r.medcode AND ss.source_vocabulary_id = 'Read'
		LEFT JOIN sstandard st ON st.source_code = r.medcode AND st.source_vocabulary_id = 'JNJ_CPRD_TEST_ENT' AND st.Target_standard_concept = 'S' and st.target_invalid_reason is NULL
	)
INSERT INTO stem_table
(domain_id, person_id, visit_occurrence_id, provider_id, start_datetime, concept_id, source_concept_id, type_concept_id, operator_concept_id, unit_concept_id, unit_source_value, start_date, end_date, sig)
