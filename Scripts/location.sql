WITH regions (
	SELECT 
	region::integer, 
	CASE region::integer 
		when 1 then 'North East'
		when 2 then 'North West'
		when 3 then 'Yorkshire  &amp; The Humber'
		when 4 then 'East Midlands'
		when 5 then 'West Midlands'
		when 6 then 'East of England'
		when 7 then 'South West'
		when 8 then 'South Central'
		when 9 then 'London'
		when 10 then 'South East Coast'
		when 11 then 'Northern Ireland'
		when 12 then 'Scotland'
		when 13 then 'Wales'
		ELSE 'Missing' 
	END AS source_value
	FROM SOURCE.region GROUP BY region)
INSERT INTO location (location_id, location_source_value)
	SELECT * FROM regions