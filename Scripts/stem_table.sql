WITH voccur AS (SELECT person_id, visit_start_date, visit_occurrence_id FROM visit_occurance),
	ssource AS (SELECT source_concept_id, source_code FROM source_to_source WHERE source_vocabulary_id in ('Read','gemscript','Gemscript')),
	sstandard AS (SELECT source_concept_id, source_code, source_vocabulary_id FROM source_to_standard WHERE source_vocabulary_id in ('Read', 'JNJ_CPRD_TEST_ENT', 'JNJ_CPRD_ADD_ENTTYPE','gemscript','Gemscript', 'LOINC') AND target_standard_concept = 'S' and target_invalid_reason is NULL),
	concs AS (SELECT concept_id, domain_id, concept_name FROM concept WHERE standard_concept = 'S' and invalid_reason is NULL and (domain_id IN ('Meas Value','Meas Value Operator') OR vocabulary_id IN ('UCUM')) GROUP BY concept_code),
	meds AS (SELECT medcode, read_code FROM medical),
	
	clinicals AS (
		SELECT
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id, 
		c.patid person_id, vo.visit_occurrence_id, c.staffid provider_id, c.eventdate::timestamp start_datetime, 
		st.source_concept_id concept_id, m.read_code source_value, ss.source_concept_id, 32827 type_concept_id, c.eventdate start_date,
		NULL operator_concept_id,NULL unit_concept_id,NULL unit_source_value, null end_date, NULL sig, 
		NULL range_high, NULL range_low, NULL value_as_number, null value_as_concept_id, null value_source_value, NULL value_as_string
		FROM clinical c
		JOIN meds m AS c.medcode = m.medcode
		JOIN vo ON vo.person_id = c.patid AND vo.visit_start_date = c.eventdate
		LEFT JOIN concept cn ON cn.concept_code = m.read_code
		LEFT JOIN ssource ss ON ss.source_code = m.read_code
		LEFT JOIN sstandard st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read'
	),
	
	referrals AS (
		SELECT
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id, 
		r.patid person_id, vo.visit_occurrence_id, r.staffid provider_id, r.eventdate::timestamp start_datetime, 
		st.source_concept_id concept_id, m.read_code source_value, ss.source_concept_id, 32842 type_concept_id, r.eventdate start_date,
		NULL operator_concept_id,NULL unit_concept_id,NULL unit_source_value, null end_date, NULL sig, 
		NULL range_high, NULL range_low, NULL value_as_number, null value_as_concept_id, null value_source_value, NULL value_as_string
		FROM referral r
		JOIN meds m AS r.medcode = m.medcode
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN concept cn ON cn.concept_code = m.read_code
		LEFT JOIN ssource ss ON ss.source_code = m.read_code
		LEFT JOIN sstandard st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read'
	),
	
	immunes AS (
		SELECT
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id,  
		r.patid person_id, vo.visit_occurrence_id, r.staffid provider_id, r.eventdate::timestamp start_datetime, 
		st.source_concept_id concept_id, m.read_code source_value, ss.source_concept_id, 32827 type_concept_id, r.eventdate start_date,
		NULL operator_concept_id,NULL unit_concept_id,NULL unit_source_value, null end_date, NULL sig, 
		NULL range_high, NULL range_low, NULL value_as_number, null value_as_concept_id, null value_source_value, NULL value_as_string
		FROM immunisation r
		JOIN meds m AS r.medcode = m.medcode
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		LEFT JOIN concept cn ON cn.concept_code = m.read_code
		LEFT JOIN ssource ss ON ss.source_code = m.read_code
		LEFT JOIN sstandard st ON st.source_code = m.read_code AND st.source_vocabulary_id = 'Read'
	),
	
	tests AS (
		SELECT
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id, 
		ti.patid person_id, vo.visit_occurrence_id, ti.staffid provider_id, ti.eventdate::timestamp AS start_datetime, 
		st.source_concept_id concept_id, ti.read_code source_value, ss.source_concept_id, 32856 type_concept_id, ti.eventdate start_date, 
		CASE cop.concept_id IS NULL THEN 0 ELSE cop.concept_id end operator_concept_id,	cu.concept_id unit_concept_id,ti.unit unit_source_value,
		null end_date, NULL sig, ti.range_high, ti.range_low, ti.value_as_number, cv.concept_id value_as_concept_id, ti.value_as_concept_id value_source_value, NULL value_as_string
		FROM test_int ti
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = ti.eventdate
		LEFT JOIN concept cn ON cn.concept_code = ti.read_code
		LEFT JOIN concs cop ON cop.ti.operator = cop.concept_name AND cop.domain_id IN ('Meas Value Operator')
		LEFT JOIN ssource ss ON ss.source_code = ti.read_code
		LEFT JOIN sstandard st ON st.source_code = ti.read_code AND st.source_vocabulary_id = 'JNJ_CPRD_TEST_ENT'
		LEFT JOIN concs cu ON cu.concept_code = ti.unit AND cu.vocabulary_id = 'UCUM'
		LEFT JOIN concs cv ON cv.concept_name = ti.value_as_concept_id AND cc.domain_id IN ('Meas Value')		
	),
	
	addins AS (
		SELECT 
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id, 
		ad.patid person_id,
	    vo.visit_occurrence_id,
	    ad.staffid provider_id,
	    ad.eventdate::timestamp start_datetime,
	    st.source_concept_id AS concept_id, 
	    ad.source_value,
	    0 source_concept_id,
	    32851 AS type_concept_id, 
	    ad.eventdate start_date,
	    NULL operator_concept_id,
	    cu.concept_id unit_concept_id,
	    ad.unit_source_value,
	    ad.eventdate end_date,
	    NULL sig, NULL range_high, NULL range_low,
	    ad.value_as_number,
	    CASE 
	    	when ad."data" = 'Read code for condition' THEN (SELECT source_concept_id FROM sstandard WHERE source_code = ad.value_as_string AND source_vocabulary_id = 'Read' LIMIT 1)
	    	when ad."data" = 'Drug code' THEN (SELECT source_concept_id FROM sstandard WHERE source_code = ad.value_as_string AND source_vocabulary_id = 'Gemscript' LIMIT 1)
	    	when ad.qualifier_source_value IS not null THEN (SELECT source_concept_id FROM sstandard WHERE source_code = ad.qualifier_source_value AND domain_id = 'Meas Value' AND source_vocabulary_id = 'LOINC' LIMIT 1)
	    END value_as_concept_id,
	    ad.qualifier_source_value value_source_value,
	    ad.value_as_string
	    FROM add_in ad
		JOIN voccur vo ON vo.person_id = ad.patid AND vo.visit_start_date = ad.eventdate
		LEFT JOIN concept cn ON cn.concept_code = ad.source_value
		LEFT JOIN sstandard st ON st.source_code = ad.source_value AND st.source_vocabulary_id = 'JNJ_CPRD_ADD_ENTTYPE'
		LEFT JOIN concs cu ON cu.concept_code = ad.unit_source_value AND cu.vocabulary_id = 'UCUM'
	),
	
	therapies AS (
		SELECT
		CASE WHEN cn.concept_id IS NULL OR 0 = cn.concept_id THEN 'Observation' else cn.domain_id END AS domain_id,  
		r.patid person_id, vo.visit_occurrence_id, r.staffid provider_id, r.eventdate::timestamp start_datetime, 
		st.source_concept_id concept_id, m.gemscriptcode source_value, ss.source_concept_id, 32838 type_concept_id, r.eventdate start_date,
		NULL operator_concept_id,NULL unit_concept_id,NULL unit_source_value, 
		r.eventdate::date + coalesce(case when a.numdays = 0 or a.numdays > 365 then null else a.numdays end, dd.numdays, dm.numdays, 1) end_date, cd.dosage_text sig, 
		NULL range_high, NULL range_low, NULL value_as_number, null value_as_concept_id, null value_source_value, NULL value_as_string
		FROM therapy r
		JOIN product m AS r.prodcode = m.prodcode
		JOIN voccur vo ON vo.person_id = c.patid AND vo.visit_start_date = r.eventdate
		JOIN SOURCE.commondosages cd ON cd.dosageid = r.dosageid
		LEFT JOIN concept cn ON cn.concept_code = m.gemscriptcode
		LEFT JOIN ssource ss ON ss.source_code = m.gemscriptcode AND ss.source_vocabulary_id = 'gemscript' AND r.eventdate between (ss.source_valid_start_date, ss.source_valid_end_date)
		LEFT JOIN sstandard st ON st.source_code = m.gemscriptcode AND st.source_vocabulary_id = 'gemscript' AND r.eventdate between (st.source_valid_start_date, st.source_valid_end_date)
	    LEFT join source.daysupply_decodes dd on r.prodcode = dd.prodcode and dd.daily_dose = coalesce(cd.daily_dose, 0) and dd.qty = coalesce(case when r.qty < 0 then null else r.qty end, 0) and dd.numpacks = coalesce(r.numpacks, 0)
	    left join source.daysupply_modes dm on r.prodcode = dm.prodcode
	),
	
	stem_table AS (
		SELECT row_number() over(ORDER BY t.person_id) AS id, t.* FROM 
			(SELECT * FROM clinicals
			UNION
			SELECT * FROM referrals
			UNION
			SELECT * FROM immunes
			UNION
			SELECT * FROM tests
			UNION
			SELECT * FROM addins
			UNION
			SELECT * FROM therapies) t
	)
	
	ins_condition_occurrence AS (
		INSERT INTO target.condition_occurrence 
			(condition_status_source_value, provider_id, visit_occurrence_id, visit_detail_id, condition_status_concept_id, condition_occurrence_id, 
			condition_source_value, person_id, condition_concept_id, condition_start_date, condition_source_concept_id, 
			condition_start_datetime, condition_end_date, condition_end_datetime, condition_type_concept_id, stop_reason) 
			SELECT 
			(NULL condition_status_source_value, provider_id, visit_occurrence_id, null visit_detail_id, NULL condition_status_concept_id, id condition_occurrence_id, 
			source_value condition_source_value, person_id, concept_id condition_concept_id, condition_start_date start_date, source_concept_id condition_source_concept_id, 
			start_datetime condition_start_datetime, end_date condition_end_date, condition_end_datetime, type_concept_id condition_type_concept_id, NULL stop_reason)  
			FROM stem_table WHERE domain_id IN 
			('Condition','Condition Status')
	),

	ins_device_exposure AS (
		INSERT INTO target.device_exposure 
			(device_type_concept_id, device_exposure_id, person_id, device_concept_id, device_exposure_start_date, 
			device_exposure_start_datetime, device_exposure_end_date, device_exposure_end_datetime, unique_device_id, 
			quantity, provider_id, visit_occurrence_id, visit_detail_id, device_source_concept_id, device_source_value) 
			SELECT 
			(type_concept_id device_type_concept_id, id device_exposure_id, person_id, concept_id device_concept_id, start_date device_exposure_start_date, 
			start_datetime device_exposure_start_datetime, end_date device_exposure_end_date, end_date::timestamp device_exposure_end_datetime, NULL unique_device_id, 
			NULL quantity, provider_id, visit_occurrence_id, NULL visit_detail_id, source_concept_id device_source_concept_id, source_value device_source_value)  
			FROM stem_table WHERE domain_id IN 
			('Device')
	),

	ins_measurement AS (
		INSERT INTO target.measurement 
			(measurement_id, measurement_source_value, unit_source_value, value_source_value, measurement_time, person_id, measurement_concept_id, 
			measurement_date, measurement_datetime, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, 
			unit_concept_id, range_low, range_high, provider_id, visit_occurrence_id, visit_detail_id, measurement_source_concept_id) 
			SELECT 
			(id measurement_id, null measurement_source_value, unit_source_value, value_source_value, null measurement_time, person_id, concept_id measurement_concept_id, 
			start_date measurement_date, start_datetime measurement_datetime, type_concept_id measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, 
			unit_concept_id, range_low, range_high, provider_id, visit_occurrence_id, null visit_detail_id, source_concept_id measurement_source_concept_id)  
			FROM stem_table WHERE domain_id IN 
			('Measurement')
	),

	ins_drug_exposure AS (
		INSERT INTO target.drug_exposure 
			(sig, drug_exposure_start_date, drug_exposure_start_datetime, drug_exposure_end_date, drug_exposure_end_datetime, 
			visit_occurrence_id, visit_detail_id, drug_source_concept_id, stop_reason, provider_id, route_concept_id, days_supply, quantity, 
			dose_unit_source_value, route_source_value, drug_source_value, refills, drug_type_concept_id, verbatim_end_date, lot_number, 
			drug_concept_id, drug_exposure_id, person_id) 
			SELECT 
			(sig, start_date drug_exposure_start_date, start_datetime drug_exposure_start_datetime, end_date drug_exposure_end_date, end_date::timestamp drug_exposure_end_datetime, 
			visit_occurrence_id, null visit_detail_id, source_concept_id drug_source_concept_id, null stop_reason, provider_id,null route_concept_id, null days_supply, NULL quantity, 
			NULL dose_unit_source_value, route_source_value, source_value drug_source_value, NULL refills, type_concept_id drug_type_concept_id, null verbatim_end_date, NULL lot_number, 
			concept_id drug_concept_id, id drug_exposure_id, person_id)  
			FROM stem_table WHERE domain_id IN 
			('Drug')
	),

	ins_procedure_occurrence AS (
		INSERT INTO target.procedure_occurrence 
			(procedure_source_value, procedure_occurrence_id, person_id, procedure_concept_id, procedure_date, procedure_datetime, 
			procedure_type_concept_id, modifier_concept_id, quantity, provider_id, visit_occurrence_id, visit_detail_id, 
			procedure_source_concept_id, modifier_source_value) 
			SELECT 
			(source_value procedure_source_value,id procedure_occurrence_id, person_id, concept_id procedure_concept_id, start_date procedure_date, start_datetime procedure_datetime, 
			type_concept_id procedure_type_concept_id, null modifier_concept_id, null quantity, provider_id, visit_occurrence_id, null visit_detail_id, 
			source_concept_id procedure_source_concept_id, null modifier_source_value)  
			FROM stem_table WHERE domain_id IN 
			('Procedure')
	),

	ins_observation AS (
		INSERT INTO target.observation 
			(observation_date, observation_datetime, observation_type_concept_id, unit_source_value, qualifier_source_value, value_as_string, 
			observation_source_concept_id, visit_detail_id, visit_occurrence_id, provider_id, observation_source_value, unit_concept_id, qualifier_concept_id, 
			value_as_concept_id, value_as_number, observation_id, person_id, observation_concept_id) 
			SELECT 
			(start_date observation_date, start_datetime observation_datetime, type_concept_id observation_type_concept_id, unit_source_value,  NULL qualifier_source_value, value_as_string, 
			source_concept_id observation_source_concept_id, NULL visit_detail_id, visit_occurrence_id, provider_id, source_value observation_source_value, unit_concept_id, NULL qualifier_concept_id, 
			value_as_concept_id, value_as_number, id observation_id, person_id, concept_id observation_concept_id)  
			FROM stem_table WHERE domain_id IN 
			('Observation')
	)
INSERT INTO target.specimen 
	(disease_status_source_value, unit_source_value, disease_status_concept_id, specimen_source_value, anatomic_site_concept_id, unit_concept_id, quantity, 
	specimen_datetime, specimen_date, specimen_type_concept_id, specimen_concept_id, specimen_source_id, person_id, specimen_id, 
	anatomic_site_source_value) 
	SELECT 
	(NULL disease_status_source_value, unit_source_value, NULL disease_status_concept_id, source_value specimen_source_value, NULL anatomic_site_concept_id, unit_concept_id, NULL quantity, 
	start_datetime specimen_datetime, start_date specimen_date, type_concept_id specimen_type_concept_id, concept_id specimen_concept_id, NULL specimen_source_id, person_id,id  specimen_id, 
	NULL anatomic_site_source_value)  
	FROM stem_table WHERE domain_id IN 
	('Specimen')

	
	