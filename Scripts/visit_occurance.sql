WITH vdetails AS (
	SELECT v.person_id, v.visit_detail_start_date, max(provider_id) provider_id, max(care_site_id) care_site_id, max(visit_detail_source_value) visit_detail_source_value 
	FROM visit_detail v GROUP BY v.person_id, v.visit_detail_start_date
	)
INSERT INTO visit_occurrence
	(person_id, visit_concept_id, visit_start_date, visit_start_datetime, visit_end_date, visit_end_datetime, visit_type_concept_id, provider_id, care_site_id, visit_source_value, 
	visit_source_concept_id, admitted_from_concept_id, admitted_from_source_value, discharged_to_concept_id, discharged_to_source_value, preceding_visit_occurrence_id)
	SELECT 
	person_id, null, visit_detail_start_date, visit_detail_start_date::timestamp, visit_detail_start_date, visit_detail_start_date::timestamp, 32827, provider_id, care_site_id, visit_detail_source_value, 
	0, null, null, null, null, null
	FROM vdetails;


-- populate the preceding entries
WITH vodetails AS (SELECT visit_occurrence_id, lag(visit_occurrence_id, 1) over(patition BY person_id ORDER BY visit_start_date) AS prev_id FROM visit_detail ORDER BY person_id, visit_start_date asc)
UPDATE visit_occurrence v SET preceding_visit_occurrence_id = d.prev_id FROM vodetails d WHERE v.visit_occurrence_id=d.visit_occurrence_id;
	