-- I will analyze the data at 3 level, World, Continent and Countries
-- I will limit the scope to year 2020 to as this is a period of primary focus.
-- Firstly, I will study the covid deaths data,
-- World Level
SELECT total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS death_per
FROM covid_deaths
WHERE location LIKE '%World%'
	AND DATE = '2020-12-31'

-- Continent level
SELECT location
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS death_per
FROM covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE 'World'
	AND DATE = '2020-12-31'
ORDER BY 2 DESC

-- Country Level
SELECT location
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS death_per
FROM covid_deaths
WHERE continent IS NOT NULL
	AND total_cases IS NOT NULL
	AND location NOT LIKE 'World'
	AND DATE = '2020-12-31'
ORDER BY 2 DESC

SELECT location
	,total_cases
	,total_deaths
	,(total_deaths / total_cases) * 100 AS death_per
FROM covid_deaths
WHERE continent IS NOT NULL
	AND total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
	AND location NOT LIKE 'World'
	AND DATE = '2020-12-31'
ORDER BY 4 DESC


-- FOR visualization purposes, I will create a table highlighting the monthly data for cases and deaths for every country 
-- World Level
WITH t1 AS (
		SELECT location
			,DATE
			,total_cases
			,total_deaths
			,(total_deaths / total_cases) * 100 AS per_death
		FROM covid_deaths
		WHERE location LIKE '%World%'
			AND DATE BETWEEN '2020-01-01'
				AND '2020-12-31'
		ORDER BY 1
			,2
		)

SELECT DATE_TRUNC('month', t1.DATE) AS month
	,AVG(t1.per_death) AS avg_deathper_monthly
FROM t1
GROUP BY 1
ORDER BY 1


-- Continent Level
WITH t1 AS (
		SELECT location
			,DATE
			,total_cases
			,total_deaths
			,(total_deaths / total_cases) * 100 AS per_death
		FROM covid_deaths
		WHERE continent IS NULL
			AND location NOT LIKE 'World'
			AND DATE BETWEEN '2020-01-01'
				AND '2020-12-31'
		ORDER BY 1
			,2
		)

SELECT location
	,DATE_TRUNC('month', t1.DATE) AS month
	,AVG(t1.per_death) AS avg_deathper_monthly
FROM t1
GROUP BY 1
	,2
ORDER BY 1
	,2
	

-- Country Level
WITH t1 AS (
		SELECT location
			,DATE
			,total_cases
			,total_deaths
			,(total_deaths / total_cases) * 100 AS per_death
		FROM covid_deaths
		WHERE continent IS NOT NULL
			AND location NOT LIKE 'World'
			AND DATE BETWEEN '2020-01-01'
				AND '2020-12-31'
		ORDER BY 1
			,2
		)

SELECT location
	,DATE_TRUNC('month', t1.DATE) AS month
	,AVG(t1.per_death) AS avg_deathper_monthly
FROM t1
GROUP BY 1
	,2
ORDER BY 1
	,2



-- Vaccinations
--World Level
SELECT cd.location
	,cd.population
	,v.total_vaccinations
	,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
FROM vaccinations v
INNER JOIN covid_deaths cd
	ON cd.location = v.location
		AND cd.DATE = v.DATE
WHERE cd.location LIKE '%World%'
	AND cd.DATE = '2020-12-31'

-- Continent level
SELECT cd.location
	,cd.population
	,v.total_vaccinations
	,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
FROM vaccinations v
INNER JOIN covid_deaths cd
	ON cd.location = v.location
		AND cd.DATE = v.DATE
WHERE cd.continent IS NULL
	AND cd.location NOT LIKE 'World'
	AND cd.DATE = '2020-12-31'
ORDER BY 4 DESC



-- Country Level
SELECT cd.location
	,cd.population
	,v.total_vaccinations
	,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
FROM vaccinations v
INNER JOIN covid_deaths cd
	ON cd.location = v.location
		AND cd.DATE = v.DATE
WHERE cd.continent IS NOT NULL
	AND cd.location NOT LIKE 'World'
	AND cd.DATE = '2020-12-31'
ORDER BY 1



-- How many countries did not vaccinate in 2020
WITH t1 AS (
		SELECT cd.location
			,cd.population
			,v.total_vaccinations
			,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
		FROM vaccinations v
		INNER JOIN covid_deaths cd
			ON cd.location = v.location
				AND cd.DATE = v.DATE
		WHERE cd.continent IS NOT NULL
			AND cd.location NOT LIKE 'World'
			AND cd.DATE = '2020-12-31'
		ORDER BY 1
		)

SELECT COUNT(*)
FROM t1
WHERE total_vaccinations IS NULL
-- 164 countries did not vaccinate their population in 2020


-- Other Queries
-- LIST of MAXIMUM new_cases for each country and the date they occured on, 
WITH t1 AS (
		SELECT location
			,DATE
			,new_cases
			,ROW_NUMBER() OVER (
				PARTITION BY location ORDER BY new_cases DESC
				) AS rnk
		FROM covid_deaths
		WHERE continent IS NOT NULL
			AND location NOT LIKE 'World'
			AND new_cases IS NOT NULL
			AND DATE BETWEEN '2020-01-01'
				AND '2020-12-31'
		ORDER BY 1
		)

SELECT location
	,DATE
	,new_cases
FROM t1
WHERE rnk <= 1
ORDER BY 3 DESC


-- Country with maximum percentage of vaccination in 2020
SELECT cd.location
	,cd.population
	,v.total_vaccinations
	,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
FROM covid_deaths cd
INNER JOIN vaccinations v
	ON cd.location = v.location
		AND cd.DATE = v.DATE
WHERE cd.continent IS NOT NULL
	AND cd.location NOT LIKE 'World'
	AND v.total_vaccinations IS NOT NULL
	AND cd.DATE = '2020-12-31'
ORDER BY 4 DESC LIMIT 1

-- Testing data
-- Country with the highest percentage of population tested
SELECT t1.category_tested
	,COUNT(*)
FROM (
	SELECT cd.location
		,cd.population
		,v.total_tests
		,(v.total_tests / cd.population) * 100 AS per_tested
		,CASE 
			WHEN v.total_tests > 1000000
				THEN 'More than 1 Million'
			ELSE 'Below 1 Million'
			END AS category_tested
	FROM covid_deaths cd
	INNER JOIN vaccinations v
		ON cd.location = v.location
			AND cd.DATE = v.DATE
	WHERE cd.continent IS NOT NULL
		AND cd.location NOT LIKE 'World'
		AND v.total_tests IS NOT NULL
		AND cd.DATE = '2020-12-31'
	ORDER BY 4 DESC
	) AS t1
GROUP BY 1
-- 36 countries had performed less than a million tests while 59 countries had performed more than a million. 95 countries did not report testing



-- We want to see how many countries had over 100,000 people vaccinated in 2020
SELECT t1.category_vaccinated
	,COUNT(*)
FROM (
	SELECT cd.location
		,cd.population
		,v.total_vaccinations
		,(v.total_vaccinations / cd.population) * 100 AS per_vaccinated
		,CASE 
			WHEN v.total_vaccinations > 25000
				THEN 'More than 25K'
			ELSE 'Below 25K'
			END AS category_vaccinated
	FROM covid_deaths cd
	INNER JOIN vaccinations v
		ON cd.location = v.location
			AND cd.DATE = v.DATE
	WHERE cd.continent IS NOT NULL
		AND cd.location NOT LIKE 'World'
		AND v.total_vaccinations IS NOT NULL
		AND cd.DATE = '2020-12-31'
	ORDER BY 4 DESC
	) AS t1
GROUP BY 1


