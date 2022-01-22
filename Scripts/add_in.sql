WITH 
	adds AS (
		SELECT patid, adid, a.enttype, a.data1, a.data2, a.data3, a.data4, a.data5, a.data6, a.data7 FROM SOURCE.additional a
		),
	clinic AS (
		SELECT c.eventdate,c.constype,c.consid,c.staffid,c.adid,c.patid FROM SOURCE.clinical c JOIN adds a ON a.adid = c.adid
		),
	entities AS (
		SELECT e.enttype, e.data_fields, e.category, e.description, e.data1, e.data2, e.data3, e.data4, e.data5, e.data6, e.data7, e.data1_lkup, e.data2_lkup, e.data3_lkup, e.data4_lkup, e.data5_lkup, e.data6_lkup, e.data7_lkup
		FROM SOURCE.entity e JOIN adds a ON a.enttype = e.enttype
		),
	looktype AS (
		SELECT lt.name, lt.lookup_type_id FROM SOURCE.lookuptype lt 
		JOIN SOURCE.entities e ON lt.name IN (e.data1_lkup, e.data2_lkup, e.data3_lkup, e.data4_lkup, e.data5_lkup, e.data6_lkup, e.data7_lkup)
		),
	looks AS (
		SELECT lu.lookup_type_id, lu.text, lu.code FROM SOURCE.lookup lu 
		JOIN looktype lt on lt.lookup_type_id = lu.lookup_type_id 
		JOIN adds a ON lu.code::text IN (a.data1, a.data2, a.data3, a.data4, a.data5, a.data6, a.data7)
		),
	meds AS (
		SELECT m.medcode, m.read_code, m.desc FROM SOURCE.medical m 
		JOIN adds a on m.medcode::text IN (a.data1, a.data2, a.data3, a.data4, a.data5, a.data6, a.data7) 
		JOIN entities e on a.enttype = e.enttype AND 'Medical Dictionary' IN (e.data1_lkup, e.data2_lkup, e.data3_lkup, e.data4_lkup, e.data5_lkup, e.data6_lkup, e.data7_lkup)
		),
	products AS (
		SELECT p.prodcode, p.gemscriptcode, p.productname FROM SOURCE.product p
		JOIN adds a on p.prodcode::text IN (a.data1, a.data2, a.data3, a.data4, a.data5, a.data6, a.data7) 
		JOIN entities e on a.enttype = e.enttype AND 'Product Dictionary' IN (e.data1_lkup, e.data2_lkup, e.data3_lkup, e.data4_lkup, e.data5_lkup, e.data6_lkup, e.data7_lkup)
	)
select a.patid,
       c.eventdate, --Join on line 32 to the Clinical table to get this information
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data1 as data,       
       case when e.data1_lkup in ('Medical Dictionary', 'Product Dictionary') then null else a.data1 end as value_as_number, 
       case when e.data1_lkup = 'Medical Dictionary' then m.read_code when e.data1_lkup = 'Product Dictionary' then p.gemscriptcode else lu.text end as value_as_string,
       case when e.data1_lkup = 'dd/mm/yyyy' then a.data1 end as value_as_date,
       case when a.enttype in (13,488) then 'kg' --enttype 13 is weight, enttype 488 is weight loss
        when a.enttype = 476 then 'cm' --enttype 476 is waist circumference
        when a.enttype in (119,61,60,120) then 'week' --These enttypes relate to weeks gestation of fetus
        when a.enttype = 14 then 'm' --enttype 14 is height
        else '' --These units have to be hard coded as they do not have a unit lookup
       end as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c on c.adid = a.adid and c.patid = a.patid
  join entities e on a.enttype = e.enttype
  left join looktype lt on e.data1_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data1
  left join meds m
  on m.medcode::text = a.data1
  and e.data1_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data1
  and e.data1_lkup = 'Product Dictionary'
where e.data_fields > 0 and a.enttype not in (72,116,372,78) --These are enttypes where data1 is the value and data2 is the unit

UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data2 as data,       
       case when e.data2_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data2 
       end as value_as_number, 
       case when e.data2_lkup = 'Medical Dictionary' then m.read_code 
        when e.data2_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data2_lkup = 'dd/mm/yyyy' then a.data2
       end as value_as_date,
       case when a.enttype = 52 then 'hour' --enttype 52 is sleep pattern and this is asking average hours of sleep
        when a.enttype = 69 then 'week' --enttype 69 is weeks post-natal
        when a.enttype = 150 then 'day' --enttype 150 is days post-natal
        else '' 
       end as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data2_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data2
  left join meds m
  on m.medcode::text = a.data2
  and e.data2_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data2
  and e.data2_lkup = 'Product Dictionary'
where e.data_fields > 1 and a.enttype not in (72,116,78,60,119,120) 
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data3 as data,       
       case when e.data3_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data3 
       end as value_as_number, 
       case when e.data3_lkup = 'Medical Dictionary' then m.read_code 
        when e.data3_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data3_lkup = 'dd/mm/yyyy' then a.data3
       end as value_as_date,
       '' as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data3_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data3
  left join meds m
  on m.medcode::text = a.data3
  and e.data3_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data3
  and e.data3_lkup = 'Product Dictionary'
where e.data_fields > 2 and a.enttype not in (372,78,126) --For these enttypes data3 and data4 are coupled and handled farther down in the query

UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data4 as data,       
       case when e.data4_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data4 
       end as value_as_number, 
       case when e.data4_lkup = 'Medical Dictionary' then m.read_code 
        when e.data4_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data4_lkup = 'dd/mm/yyyy' then a.data4
       end as value_as_date,
       '' as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data4_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data4
  left join meds m
  on m.medcode::text = a.data4
  and e.data4_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data4
  and e.data4_lkup = 'Product Dictionary'
where e.data_fields > 3 and a.enttype not in (372,78,126) --For these enttypes data3 and data4 are coupled and handled farther down in the query
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data5 as data,       
       case when e.data5_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data5 
       end as value_as_number, 
       case when e.data5_lkup = 'Medical Dictionary' then m.read_code 
        when e.data5_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data5_lkup = 'dd/mm/yyyy' then a.data5
       end as value_as_date,
       '' as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data5_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data5
  left join meds m
  on m.medcode::text = a.data5
  and e.data5_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data5
  and e.data5_lkup = 'Product Dictionary'
where e.data_fields > 4 and a.enttype not in (78) --For this enttype data5 and data6 are coupled and handled farther down in the query
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data6 as data,       
       case when e.data6_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data6 
       end as value_as_number, 
       case when e.data6_lkup = 'Medical Dictionary' then m.read_code 
        when e.data6_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data6_lkup = 'dd/mm/yyyy' then a.data6
       end as value_as_date,
       '' as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data6_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data6
  left join meds m
  on m.medcode::text = a.data6
  and e.data6_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data6
  and e.data6_lkup = 'Product Dictionary'
where e.data_fields > 5 and a.enttype not in (78) --For this enttype data5 and data6 are coupled and handled farther down in the query
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data7 as data,       
       case when e.data7_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data7 
       end as value_as_number, 
       case when e.data7_lkup = 'Medical Dictionary' then m.read_code 
        when e.data7_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data7_lkup = 'dd/mm/yyyy' then a.data7
       end as value_as_date,
       '' as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data7_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data7
  left join meds m
  on m.medcode::text = a.data7
  and e.data7_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data7
  and e.data7_lkup = 'Product Dictionary'
where e.data_fields > 6
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data1 as data,       
       case when e.data1_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data1 
       end as value_as_number, 
       case when e.data1_lkup = 'Medical Dictionary' then m.read_code 
        when e.data1_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data1_lkup = 'dd/mm/yyyy' then a.data1
       end as value_as_date,
       lu2.text as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data1_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data1
  left join looktype lt2
  on e.data2_lkup = lt2.name
  left join looks lu2
  on lt2.lookup_type_id = lu2.lookup_type_id
  and lu2.code::text = a.data2
  left join meds m
  on m.medcode::text = a.data1
  and e.data1_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data1
  and e.data1_lkup = 'Product Dictionary'
where a.enttype in (72,116,78) --For these enttypes data1 is the value and data2 is the unit
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data3 as data,       
       case when e.data3_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data3 
       end as value_as_number, 
       case when e.data3_lkup = 'Medical Dictionary' then m.read_code 
        when e.data3_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data3_lkup = 'dd/mm/yyyy' then a.data3
       end as value_as_date,
       lu2.text as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data3_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data3
  left join looktype lt2
  on e.data4_lkup = lt2.name
  left join looks lu2
  on lt2.lookup_type_id = lu2.lookup_type_id
  and lu2.code::text = a.data4
  left join meds m
  on m.medcode::text = a.data3
  and e.data1_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data3
  and e.data1_lkup = 'Product Dictionary'
where a.enttype in (126,78) --For these datatypes data3 is the value and data4 is the unit
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid, 
       a.enttype, 
       e.category,
       e.description, 
       e.data5 as data,       
       case when e.data5_lkup in ('Medical Dictionary', 'Product Dictionary') then null
        else a.data5 
       end as value_as_number, 
       case when e.data5_lkup = 'Medical Dictionary' then m.read_code 
        when e.data5_lkup = 'Product Dictionary' then p.gemscriptcode
        else lu.text 
       end as value_as_string,
       case when e.data5_lkup = 'dd/mm/yyyy' then a.data5
       end as value_as_date,
       lu2.text as unit_source_value,
       '' as qualifier_source_value,
       m.desc as read_code_description,
       p.productname as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join looktype lt
  on e.data5_lkup = lt.name
  left join looks lu
  on lt.lookup_type_id = lu.lookup_type_id
  and lu.code::text = a.data5
  left join looktype lt2
  on e.data6_lkup = lt2.name
  left join looks lu2
  on lt2.lookup_type_id = lu2.lookup_type_id
  and lu2.code::text = a.data6
  left join meds m
  on m.medcode::text = a.data5
  and e.data1_lkup = 'Medical Dictionary'
  left join products p
  on p.prodcode::text = a.data5
  and e.data1_lkup = 'Product Dictionary'
where a.enttype in (78) --For this enttype data5 is the value and data6 is the unit
        
UNION

select a.patid,
       c.eventdate,
       c.constype,
       c.consid,
       c.staffid,  
       a.enttype, 
       e.category,
       e.description, 
       sm.scoring_method as data,       
       a.data1 as value_as_number, 
       '' as value_as_string,
       case when e.data1_lkup = 'dd/mm/yyyy' then a.data1
       end as value_as_date,
       '' as unit_source_value,
       lu4.text as qualifier_source_value,
       '' as read_code_description,
       '' as gemscript_description,
       e.data_fields         
from adds a
  left join clinic c
  on c.adid = a.adid
  and c.patid = a.patid
  join entities e
  on a.enttype = e.enttype
  left join native.scoringmethod sm
  on a.data3 = sm.code::text
  left join looktype lt4
  on e.data4_lkup = lt4.name
  left join looks lu4
  on lt4.lookup_type_id = lu4.lookup_type_id
  and lu4.code::text = a.data4
where a.enttype in (372) --This enttype is for the results of scores and questionnaires