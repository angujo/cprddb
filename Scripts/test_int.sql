-- drop any existence
DROP TABLE IF EXISTS test_int;

-- create the table
CREATE TABLE test_int AS (
WITH 
	test_t AS (SELECT patid, eventdate, constype, consid, staffid, enttype, medcode, data1, data2, data3, data4, data5, data6 FROM SOURCE.test),
	meds AS (SELECT read_code, description, medcode FROM SOURCE.medical),
	entities AS (SELECT code, description, data_fields FROM SOURCE.entity WHERE data_fields in (7,8,4)),
	lookups AS (SELECT code, lookup_type_id, text FROM SOURCE.lookup WHERE lookup_type_id IN (56,83,85)) 
SELECT 
       tt.patid,
       tt.eventdate,
       tt.constype,
       tt.consid,
       tt.staffid,
       mc.read_code,
       mc.description as read_description,
       CAST(e.code as varchar)||'-'||e.description as map_value,       
       et.code as enttype,
       et.description as enttype_desc,
       et.data_fields,
       case when tt.data1 <> 0 --In this case 0 means 'data not entered' so it is set to blank
        then lp.text else '' end as operator, --Data1 is the coded operator (<,>,=,>=,<=). The join on line 29 looks up the text value and stores that here. 
       tt.data2 as value_as_number,
       case when tt.data3 <> 0 then lp2.text --Here the number 0 means 'data not entered' so it is set to blank
         when et.code = 284 and (t.data2 is not null and tt.data2 <> 0) then 'week' --Enttype (code) 284 refers to gestational age in weeks so the unit is hard coded
         else '' end as unit, --Data3 is the coded unit of the laboratory test. The join on line 32 looks up the text value and stores that here.
       case when tt.data4 <> 0 then lp3.text else '' end as value_as_concept_id, --In this case 0 means 'data not entered' so it is set to blank. Data4 is the coded qualifier (high,low). The join on line 35 looks up the text value and stores that value here.
       tt.data5 as range_low,
       tt.data6 as range_high     
FROM test_t tt
JOIN entities et ON tt.enttype = et.code
JOIN meds mc ON tt.medcode = mc.medcode
JOIN lookups lp ON tt.data1 = lp.code AND lp.lookup_type_id = 56 /*OPR - Operator*/
JOIN lookups lp2 ON tt.data3 = lp2.code AND lp2.lookup_type_id = 83 /*SUM - Specimen Unit of Measure*/
JOIN lookups lp3 ON tt.data4 = lp3.code AND lp3.lookup_type_id = 85 /*TQU - Test Qualifier*/ 
WHERE et.data_fields in (7,8) --When data_fields equals 7 or 8 then both operators and units may be present. 

UNION

SELECT tt.patid,
       tt.eventdate,
       tt.constype,
       tt.consid,
       tt.staffid,
       mc.read_code,
       mc.description as read_description,
       CAST(e.code as varchar)||'-'||e.description as map_value,
       et.code as enttype,
       et.description as enttype_desc,
       et.data_fields,
       '' as operator,
       NULL as value_as_number,
       '' as unit,
       case when tt.data1 <> 0 then lp.text else '' end as value_as_concept_id, --In this case 0 means 'data not entered' so it is set to blank. Data1 is the coded value for the qualifier (high,low) so the join on line 64 looks up the value and stores the text here.
       tt.data2 as range_low,
       tt.data3 as range_high     
FROM test_t tt
JOIN entities et ON tt.enttype = et.code
JOIN meds mc ON tt.medcode = mc.medcode
JOIN lookups lp ON tt.data1 = lp.code AND lp.lookup_type_id = 85 /*TQU - Test Qualifier*/ 
WHERE et.data_fields = 4 --When data_fields equals 4 then only the value of the text and qualifier is available.