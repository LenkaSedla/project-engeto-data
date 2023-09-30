CREATE OR REPLACE TABLE t_lenka_sedlackova_project_SQL_primary_final AS 
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
SELECT 
	paa.payroll_year AS years,
	industry_branch,
	average_payroll,
	average_payroll_growth,
	category_code,
	category_name,
	category_unit,
	average_price,
	average_price_growth,
	GDP_growth
FROM payroll_average paa
LEFT JOIN price_averages pra
	ON paa.payroll_year = pra.years
LEFT JOIN economies_data ed	
	ON paa.payroll_year = ed.`year`
ORDER BY years
;

SELECT * FROM t_lenka_sedlackova_project_SQL_primary_final
;

-- 1. otázka
SELECT
	'industry declining' AS industry,
	count(DISTINCT aa.industry_branch) AS industry_count
FROM (
	SELECT 
		years,	
		industry_branch,
		average_payroll,
		average_payroll_growth,
		if(average_payroll_growth > 0, 1, 0) AS industry_payroll_growth
	FROM t_lenka_sedlackova_project_SQL_primary_final
	WHERE average_payroll_growth IS NOT NULL 
 	) aa
WHERE industry_payroll_growth = 0
UNION ALL 
SELECT
	'all industries' AS industry,
	count(DISTINCT industry_branch) AS industry_count
FROM t_lenka_sedlackova_project_SQL_primary_final
;

-- 2. otázka
SELECT
	pa2.years,
	pa2.category_name,
--	pa2.category_unit,
--	pa2.average_price,
--	round(avg(pa.average_payroll), 1) AS avg_payroll_rounded,
 	round(avg(pa.average_payroll) / pa2.average_price, 1) AS payroll_div_price
FROM t_lenka_sedlackova_project_SQL_primary_final pa
INNER JOIN t_lenka_sedlackova_project_SQL_primary_final pa2
	ON pa.years = pa2.years
WHERE (lower(pa2.category_name) LIKE lower('chl_b%') OR lower(pa2.category_name) LIKE lower('ml_ko%'))
	AND pa2.years IN (
		SELECT min(years) FROM t_lenka_sedlackova_project_SQL_primary_final
		WHERE average_price IS NOT NULL 
		UNION ALL 
		SELECT max(years) FROM t_lenka_sedlackova_project_SQL_primary_final
		WHERE average_price IS NOT NULL 
	)
GROUP BY 
	pa2.years,
	pa2.category_name,
--	pa2.category_unit,
--	pa2.average_price
;

-- 3. otázka
SELECT 
	cc.category_name,
	round(sum(cc.average_price_growth), 2) AS overall_price_growth
FROM (
	SELECT DISTINCT 
		category_name,
		years,
		average_price_growth
	FROM t_lenka_sedlackova_project_SQL_primary_final
	WHERE average_price_growth IS NOT NULL
	) cc
GROUP BY
	cc.category_name
ORDER BY overall_price_growth
LIMIT 1
;

-- 4. otázka
SELECT
	pa.years,
--	round(avg(pa.average_price_growth), 2) AS avg_price_growth,
--	round(avg(pav.average_payroll_growth), 2) AS avg_payroll_growth,
	round(avg(pa.average_price_growth) - avg(pav.average_payroll_growth), 2) AS growth_diff
FROM t_lenka_sedlackova_project_SQL_primary_final pa
LEFT JOIN t_lenka_sedlackova_project_SQL_primary_final pav
	ON pa.years = pav.years
WHERE pa.average_price_growth IS NOT NULL 
GROUP BY pa.years
HAVING round(avg(pa.average_price_growth) - avg(pav.average_payroll_growth), 2) > 10
;

-- 5. otázka
SELECT
	ed.years,
	ed.GDP_growth,
	bb.overall_price_growth,
	bb.overall_price_growth_next,
	cc.overall_payroll_growth,
	cc.overall_payroll_growth_next,
	CASE
		WHEN ed.GDP_growth > 5 AND (bb.overall_price_growth > 5 OR overall_price_growth_next > 5) THEN 'growth bigger then 5'
		WHEN ed.GDP_growth > 3 AND (bb.overall_price_growth > 3 OR overall_price_growth_next > 3) THEN 'growth bigger then 3'
		ELSE 'otherwise'
	END AS gdp_on_price_and_payroll_growth
FROM t_lenka_sedlackova_project_SQL_primary_final ed
JOIN (
	SELECT 
		pra.years,
		pra2.years - 1 AS year_next,
		round(avg(pra.average_price_growth), 2) AS overall_price_growth,
		round(avg(pra2.average_price_growth), 2) AS overall_price_growth_next
	FROM t_lenka_sedlackova_project_SQL_primary_final pra
	JOIN t_lenka_sedlackova_project_SQL_primary_final pra2
		ON pra.years = pra2.years - 1
	WHERE pra.average_price IS NOT NULL 
	GROUP BY  pra.years,
		pra2.years - 1
	) bb	
ON ed.years = bb.years
JOIN (
	SELECT 
		paa.years,
		paa2.years - 1 AS payroll_year_next,
		round(avg(paa.average_payroll_growth), 2) AS overall_payroll_growth,
		round(avg(paa2.average_payroll_growth), 2) AS overall_payroll_growth_next
	FROM t_lenka_sedlackova_project_SQL_primary_final paa
	JOIN t_lenka_sedlackova_project_SQL_primary_final paa2
		ON paa.years = paa2.years - 1
	WHERE paa.average_payroll_growth IS NOT NULL 
	GROUP BY paa.years,
		paa2.years - 1
	) cc
ON ed.years = cc.years
-- WHERE average_price_growth IS NOT NULL 
GROUP BY 
	ed.years,
	ed.GDP_growth
ORDER BY ed.years
;
----------------------------------------------------------------

CREATE OR REPLACE TABLE t_lenka_sedlackova_project_SQL_secondary_final AS 
SELECT 
	e2.country,
	e2.year,
	e2.GDP,
	round((e2.GDP - e3.GDP) / e3.GDP * 100, 2) AS GDP_growth_europe,
	e2.gini,
	e2.population
FROM (
	SELECT 
		ee.country,
		ee.year,
		ee.GDP,
		ee.gini,
		ee.population
	FROM economies ee
	WHERE ee.country IN (
		SELECT country
		FROM countries 
		WHERE continent = 'Europe'
		AND country != 'Czech Republic'
		) 
	AND ee.year IN (
		SELECT DISTINCT years
		FROM t_lenka_sedlackova_project_SQL_primary_final
		)
	) e2
JOIN economies e3
	ON e2.country = e3.country
	AND e2.year = e3.year + 1
ORDER BY e2.country, e2.year
;

SELECT * FROM t_lenka_sedlackova_project_SQL_secondary_final
;