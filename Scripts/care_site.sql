INSERT INTO care_site (care_site_id, place_of_service_concept_id, location_id, care_site_source_value)
SELECT pracid, region, 8977 PlaceOfSvcConceptId, pracid FROM source.Practice