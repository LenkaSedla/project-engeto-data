WITH payroll_average AS (
SELECT 
	a.payroll_year,
	b.payroll_year + 1 AS payroll_year_prev,
	a.industry_branch,
	a.average_payroll,
	b.average_payroll AS average_payroll_prev,
	round((a.average_payroll - b.average_payroll)/b.average_payroll * 100, 2) AS average_payroll_growth
FROM (
	SELECT
		cp.payroll_year,
		cpib.name AS industry_branch,
		cp.industry_branch_code,
		round(avg(cp.value), 2) AS average_payroll
	FROM czechia_payroll cp
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	LEFT JOIN czechia_payroll_value_type cpvt
		ON cp.value_type_code = cpvt.code
	WHERE cp.calculation_code = 100
		AND cp.unit_code = 200
		AND  cp.value_type_code = 5958
		AND cp.industry_branch_code IS NOT NULL
	GROUP BY 
		cp.payroll_year, 
		cpib.name
	) a 
LEFT JOIN (
	SELECT
		cp.payroll_year,
		cpib.name AS industry_branch,
		cp.industry_branch_code,
		round(avg(cp.value), 2) AS average_payroll
	FROM czechia_payroll cp
	LEFT JOIN czechia_payroll_calculation cpc
		ON cp.calculation_code = cpc.code
	LEFT JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	LEFT JOIN czechia_payroll_value_type cpvt
		ON cp.value_type_code = cpvt.code
	WHERE cp.calculation_code = 100
		AND cp.unit_code = 200
		AND  cp.value_type_code = 5958
		AND cp.industry_branch_code IS NOT NULL
	GROUP BY 
		cp.payroll_year, 
		cpib.name
	) b 
ON a.industry_branch = b.industry_branch
AND a.payroll_year = b.payroll_year + 1
ORDER BY a.industry_branch, a.payroll_year
),
price_averages AS (
SELECT 
	c.category_code,
	c.category_name,
	c.years,
	d.years + 1 AS years_prev,
	c.category_unit,
	c.average_price,
	d.average_price AS average_price_prev,
	(c.average_price - d.average_price) / d.average_price * 100 AS average_price_growth
FROM (
	SELECT 
		cp2.category_code,
		cpc2.name AS category_name, 	
		year(cp2.date_from) AS years,
		concat(cpc2.price_value, cpc2.price_unit) AS category_unit,
		round(avg(cp2.value), 2) AS average_price
	FROM czechia_price cp2
	LEFT JOIN czechia_price_category cpc2
		ON cp2.category_code = cpc2.code
	GROUP BY 
		cp2.category_code,
		cpc2.name,
		year(cp2.date_from),
		concat(cpc2.price_value, cpc2.price_unit)
	-- ORDER BY cpc2.name, year(cp2.date_from)
	) c
LEFT JOIN (
	SELECT 
		cp2.category_code,
		cpc2.name AS category_name, 	
		year(cp2.date_from) AS years,
		concat(cpc2.price_value, cpc2.price_unit) AS category_unit,
		round(avg(cp2.value), 2) AS average_price
	FROM czechia_price cp2
	LEFT JOIN czechia_price_category cpc2
		ON cp2.category_code = cpc2.code
	GROUP BY 
		cp2.category_code,
		cpc2.name,
		year(cp2.date_from),
		concat(cpc2.price_value, cpc2.price_unit)
	-- ORDER BY cpc2.name, year(cp2.date_from)
	) d
ON c.category_code = d.category_code
AND c.years = d.years + 1
ORDER BY c.category_name, c.years
),
economies_data AS (
SELECT 
	f.`year`,
	g.`year` + 1 AS year_prev,
	f.GDP,
	g.GDP AS GDP_prev,
	round((f.GDP - g.GDP) / g.GDP * 100, 2) AS GDP_growth
FROM (
	SELECT 
		e.`year`,
		e.country,
		e.GDP,
		e.population,
		e.gini
	FROM economies e
	WHERE lower(country) LIKE lower('%czech%')
		AND GDP IS NOT NULL
	) f
LEFT JOIN (
	SELECT 
		e.`year`,
		e.country,
		e.GDP,
		e.population,
		e.gini
	FROM economies e
	WHERE lower(country) LIKE lower('%czech%')
		AND GDP IS NOT NULL
	) g
ON f.`year` = g.`year` + 1
ORDER BY f.`year`
) 
-- 1. otázka
SELECT
	'industry declining' AS industry,
	count(DISTINCT aa.industry_branch) AS industry_count
FROM (
	SELECT 
		payroll_year,	
		industry_branch,
		average_payroll,
		average_payroll_growth,
		if(average_payroll_growth > 0, 1, 0) AS industry_payroll_growth
	FROM payroll_average
	WHERE average_payroll_growth IS NOT NULL 
	-- ORDER BY industry_branch, payroll_year
 	) aa
WHERE industry_payroll_growth = 0
UNION ALL 
SELECT
	'all industries' AS industry,
	count(DISTINCT industry_branch) AS industry_count
FROM payroll_average
	-- tady byl kod viz na konci (možná uz nebude potřeba)
-- 2. otázka
/*	SELECT
		pa2.years,
	--	pa2.category_name,
	--	pa2.category_unit,
	--	pa2.average_price,
	--	round(avg(pa.average_payroll), 0) AS avg_payroll_rounded,
	 	round(avg(pa.average_payroll) / pa2.average_price, 0) AS payroll_div_price
	FROM payroll_average pa
	INNER JOIN price_averages pa2
		ON pa.payroll_year = pa2.years
	WHERE (lower(pa2.category_name) LIKE lower('chl_b%') OR lower(pa2.category_name) LIKE lower('ml_ko%'))
		AND pa2.years IN (
			SELECT min(years) FROM price_averages
			UNION ALL 
			SELECT max(years) FROM price_averages
		)
	GROUP BY pa.payroll_year,
		pa2.years,
		pa2.category_name,
		pa2.category_unit,
		pa2.average_price
-- 3. otázka
SELECT 
	category_name,
	sum(average_price_growth) AS overall_price_growth
FROM price_averages
WHERE average_price_growth IS NOT NULL
GROUP BY
	category_name
ORDER BY overall_price_growth
LIMIT 1
-- otázka 4
SELECT
	pa.years,
	avg(pa.average_price_growth) - avg(pav.average_payroll_growth) AS growth_diff
FROM price_averages pa
LEFT JOIN payroll_average pav
	ON pa.years = pav.payroll_year
WHERE pa.average_price_growth IS NOT NULL 
GROUP BY pa.years
HAVING avg(pa.average_price_growth) - avg(pav.average_payroll_growth) > 10
-- 5 otázka
SELECT
	ed.`year`,
	ed.GDP_growth,
	bb.overall_price_growth,
	bb.overall_price_growth_next,
	cc.overall_payroll_growth,
	cc.overall_payroll_growth_next
	CASE
		WHEN ed.GDP_growth > 5 AND (bb.overall_price_growth > 5 OR overall_price_growth_next > 5) THEN 'growth bigger then 5'
		WHEN ed.GDP_growth > 3 AND (bb.overall_price_growth > 3 OR overall_price_growth_next > 3) THEN 'growth bigger then 3'
		ELSE 'otherwise'
	END AS gdp_on_price_growth
FROM economies_data ed
JOIN (
	SELECT 
		pra.years,
		pra2.years - 1 AS year_next,
		round(avg(pra.average_price_growth), 2) AS overall_price_growth,
		round(avg(pra2.average_price_growth), 2) AS overall_price_growth_next
	FROM price_averages pra
	JOIN price_averages pra2
		ON pra.years = pra2.years - 1
	GROUP BY  pra.years,
		pra2.years - 1 
	) bb	
ON ed.`year` = bb.years
JOIN (
	SELECT 
		paa.payroll_year,
		paa2.payroll_year - 1 AS payroll_year_next,
		round(avg(paa.average_payroll_growth), 2) AS overall_payroll_growth,
		round(avg(paa2.average_payroll_growth), 2) AS overall_payroll_growth_next
	FROM payroll_average paa
	JOIN payroll_average paa2
	ON paa.payroll_year = paa2.payroll_year - 1
	GROUP BY paa.payroll_year,
		paa2.payroll_year - 1
	) cc
ON ed.`year` = cc.payroll_year
-- WHERE average_price_growth IS NOT NULL 
GROUP BY 
	ed.`year`,
	ed.GDP_growth
ORDER BY ed.`year`
*/
;