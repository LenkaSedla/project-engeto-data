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
	GROUP BY cp.payroll_year, cpib.name
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
	GROUP BY cp.payroll_year, cpib.name
	) b 
ON a.industry_branch = b.industry_branch
AND a.payroll_year = b.payroll_year + 1
ORDER BY a.industry_branch, a.payroll_year
),
price_averages AS (
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
	ORDER BY cpc2.name, year(cp2.date_from)
),
economies_data AS (
	SELECT 
		e.country,
		e.`year`,
		e.GDP,
		e.population,
		e.gini
	FROM economies e
	WHERE lower(country) LIKE lower('%czech%')
		AND GDP IS NOT NULL
) 
SELECT 
count(DISTINCT aa.industry_branch) AS decrease_industry_count
FROM (
	SELECT 
		payroll_year,	
		industry_branch,
		if(average_payroll_growth > 0, 1, 0) AS industry_payroll_growth
	FROM payroll_average
	WHERE average_payroll_growth IS NOT NULL 
 	) aa
;