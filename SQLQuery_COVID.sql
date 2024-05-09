-- Viewing data
SELECT *
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
order by 3,4;

-- Displaying all the columns  that will be use for SQL data exploration
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
order by 1,2;

-- Looking at Total Cases VS. Total Deaths in Nepal
-- Shows the likelihood of dying if you contract COVID
SELECT location, date, total_cases, total_deaths, 
((CONVERT(float,total_deaths))/NULLIF(CONVERT(float,total_cases),0))*100 AS Death_Percentage 
FROM [COVID-19 ANALYSIS]..covid_deaths 
where location like '%Nepal%' and continent IS NOT NULL 
order by 1,2 DESC;

-- Total Cases VS. Population in Nepal
SELECT location, date, total_cases, population, 
((CONVERT(float,total_cases))/NULLIF(CONVERT(float,population),0))*100 AS Percentage_of_popn_affected 
FROM [COVID-19 ANALYSIS]..covid_deaths 
where location like '%Nepal%' and continent IS NOT NULL 
order by 1,2 DESC;

--Looking at countries with highest infection rates relative to their population
SELECT location,
       population,
	   date,
	   MAX(CAST(total_cases AS FLOAT)) AS Highest_Infection_Rate,
      MAX ((total_cases) / population) * 100 AS Percentage_affected 
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY Percentage_affected DESC;

--Looking at countries with highest death count relative to their population
SELECT location,
       population,
	   MAX(CAST(total_deaths AS FLOAT)) AS Total_deaths,
      MAX ((total_deaths) / population) * 100 AS Death_Percentage
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Death_Percentage DESC;

-- Analyzing data according to continent ( Death percentage)
SELECT continent,
       max(population) AS Population,
	   MAX(CAST(total_deaths AS FLOAT)) AS Total_deaths,
      MAX ((total_deaths) / population) * 100 AS Death_Percentage
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Death_Percentage DESC;

-- Analyzing data according to continent ( percentage of infected )
SELECT continent,
       max(population) AS Population,
	   MAX(CAST(total_cases AS FLOAT)) AS Total_infected,
      MAX ((total_cases) / population) * 100 AS Percentage_affected 
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Percentage_affected  DESC;

--Global population affected by COVID till today
SELECT    
	   SUM(new_cases) as Total_affected,
	   SUM(new_deaths) as Total_deaths,
	   (SUM(new_deaths)/SUM(new_cases))*100 as Death_Percentage
FROM [COVID-19 ANALYSIS]..covid_deaths ;

--Global population affected by COVID in each date
SELECT date,
	   sum(CAST(new_cases AS FLOAT)) as Total_affected,
	   SUM(CAST(new_deaths AS FLOAT)) as Total_deaths,
	  (SUM(CAST(total_deaths AS FLOAT))/SUM(CAST(total_cases AS FLOAT)))*100 as Death_Percentage
FROM [COVID-19 ANALYSIS]..covid_deaths 
WHERE continent IS NOT NULL
GROUP BY  date
ORDER BY date ;

--Looking at the Covid vaccinations data
SELECT * FROM [COVID-19 ANALYSIS]..covid_vaccinations;

--Joining two tables
SELECT * FROM [COVID-19 ANALYSIS]..covid_deaths d JOIN [COVID-19 ANALYSIS]..covid_vaccinations v ON d.location=v.location AND d.date=v.date;

--Comparing Total Population VS. Total Vaccinations
--Using CTE
WITH PopnVSVacc(continent, location, population,date,  new_vaccinations,RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location,d.population, d.date,v.new_vaccinations,
sum(convert(float,v.new_vaccinations)) OVER(
	PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated

FROM [COVID-19 ANALYSIS]..covid_deaths d JOIN [COVID-19 ANALYSIS]..covid_vaccinations v 
ON d.location=v.location AND d.date=v.date
GROUP BY d.continent, d.location,d.population, d.date,v.new_vaccinations
)
SELECT location,date,RollingPeopleVaccinated,
((RollingPeopleVaccinated)/population)*100 as PercentageVaccinated FROM PopnVSVacc
WHERE location like '%Nepal%' 

ORDER BY location, date;

--Creating a TEMP table to store the above data
CREATE TABLE #PercentPopulationVaccinated
(
	CONTINENT NVARCHAR(255),
	LOCATION NVARCHAR(255),
	DATE DATETIME,
	POPULATION NUMERIC,
	NEW_VACC NUMERIC,
	ROLLINGPEOPLEVACCINATED NUMERIC);

INSERT INTO #PercentPopulationVaccinated

SELECT d.continent, d.location,d.date,d.population,v.new_vaccinations,
sum(convert(float,v.new_vaccinations)) OVER(
	PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated

FROM [COVID-19 ANALYSIS]..covid_deaths d JOIN [COVID-19 ANALYSIS]..covid_vaccinations v 
ON d.location=v.location AND d.date=v.date
GROUP BY d.continent, d.location,d.population, d.date,v.new_vaccinations

SELECT location,date,RollingPeopleVaccinated,
((RollingPeopleVaccinated)/population)*100 as PercentageVaccinated FROM #PercentPopulationVaccinated


ORDER BY location, date;

--Creating a view to store data for later visualizations
CREATE VIEW percentPopulationVaccinated AS
SELECT d.continent, d.location,d.population, d.date,v.new_vaccinations,
sum(convert(float,v.new_vaccinations)) OVER(
	PARTITION BY d.location ORDER BY d.date) AS RollingPeopleVaccinated

FROM [COVID-19 ANALYSIS]..covid_deaths d JOIN [COVID-19 ANALYSIS]..covid_vaccinations v 
ON d.location=v.location AND d.date=v.date
GROUP BY d.continent, d.location,d.population, d.date,v.new_vaccinations

--Finding total affected in all continents
SELECT continent, SUM(CAST(new_deaths as float)) as TotalDeathCount
FROM [COVID-19 ANALYSIS]..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;