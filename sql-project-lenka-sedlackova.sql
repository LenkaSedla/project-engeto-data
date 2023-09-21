SELECT *
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
		AND unit_code = 200	
		AND  value_type_code = 5958	
		AND cp.industry_branch_code IS NOT NULL
	GROUP BY cp.payroll_year, cpib.name
) a
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
		cpc2.name,
		year(date_from),
		concat(cpc2.price_value, cpc2.price_unit)
) b
ON a.payroll_year = b.years
LEFT JOIN (
	SELECT 
		e.country,
		e.`year`,
		e.GDP,
		e.population,
		e.gini
	FROM economies e
	WHERE lower(country) LIKE lower('%czech%')
		AND GDP IS NOT NULL
) c
ON a.payroll_year = c.`year`
ORDER BY payroll_year
;
