INSERT INTO provider
	(provider_id, provider_name, npi, dea, specialty_concept_id, care_site_id, year_of_birth, gender_concept_id, 
	provider_source_value, specialty_source_value, specialty_source_concept_id, gender_source_value, gender_source_concept_id)
SELECT
staffid, NULL, NULL, NULL, m.source_concept_id, cast(Right(cast(staffid as varchar), 5) as integer) as CARE_SITE_ID, null, CASE when coalesce(gender, 0)::int when 1 then 8507 when 2 then 8532 else 0 end as gender_concept_id
staffid as PROVIDER_SOURCE_VALUE, l.text as SPECIALTY_SOURCE_VALUE,NULL, coalesce(gender, 0) as gender,null
from source.Staff s
JOIN source.lookup l ON s.role = l.code  AND lookup_type_id = 76
JOIN source_to_concept_map m ON m.source_code = s.role