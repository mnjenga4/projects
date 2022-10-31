SELECT *
FROM model..Covid_19_Deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM model..Covid_19_Vaccinations
ORDER BY 3,4

-- First, select data that we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM model..Covid_19_Deaths
ORDER BY 1,2

-- Comparing Total Cases vs Total Deaths
-- Below query displays the likelihood of dying should you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage 
FROM dbo.Covid_19_Deaths
WHERE location LIKE '%States%'
ORDER BY 1,2

--------------------------------------------------------------------------------------------------------------------------------------

--Looking at Total Cases vs Population
-- Shows what percentage of population has contracted Covid-19

SELECT location, date, population, total_cases, (total_cases / population)*100 AS DeathPercentage 
FROM dbo.Covid_19_Deaths
WHERE location LIKE '%States%'
ORDER BY 1,2
-- It can be seen that by July 13th, 2020, 1% of the US population (3,375,015 individuals) had tested positive for Covid-19.

--------------------------------------------------------------------------------------------------------------------------------------
--Looking at what countries have the HIGHEST infection rate with respect to their population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population))*100 AS PercentPopulationInfected
FROM dbo.Covid_19_Deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

/*As of October 2022, Cyprus has the highest % of its population infected at 66.5505%, and with a total population of 896,007. The United
States ranks #60 with 28.8546% of its entire population (336,997,624) having been infected at this point in time.*/

--------------------------------------------------------------------------------------------------------------------------------------

--Displaying the countries with the highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM dbo.Covid_19_Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Real quick, let's take a look at the death count by CONTINENT

SELECT [continent], MAX(total_deaths) AS TotalDeathCount
FROM dbo.Covid_19_Deaths
WHERE continent IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

/*If we compare the two queries above, we can see that the exact same death count number (576,232) is reported for both the United States AND North America.
This data error is due to some of the data entries having the location data point in the "continent" field (ex: both continent AND location say Asia, United
States, Europe, etc.). This is what is causing the data to be a bit skewered and not account for other North American countries such as Canada & Mexico. To
bypass this and get more accurate results, we have the query below:*/

SELECT [location], SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM dbo.Covid_19_Deaths
WHERE continent IS NULL
AND location NOT IN ('European Union', 'High income', 'World', 'Upper middle income', 'Low income', 'Lower middle income', 'International')
GROUP BY [location]
ORDER BY TotalDeathCount DESC

--------------------------------------------------------------------------------------------------------------------------------------

-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage 
FROM dbo.Covid_19_Deaths
WHERE continent IS NOT NULL
--GROUP BY [date]
ORDER BY 1,2

/*Overall throughout the world, there have been a total of 626,337,484 cases; and a total of 6,541,159 deaths. This brings us to a death %
of 1.0444%. */

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage 
FROM dbo.Covid_19_Deaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1,2
-- The first batch of reported cases globally occurred on 01-23-2020.

--------------------------------------------------------------------------------------------------------------------------------------

-- Viewing Total Population vs Vaccinations (Amount of people who have received at least one Covid-19 vaccine)

SELECT dea.continent, CAST(dea.[location] AS NVARCHAR(50)), dea.[date], dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY CAST(dea.[location] AS NVARCHAR(50)) ORDER BY CAST(dea.[location] AS NVARCHAR(50)),
dea.date) AS RollingPeopleVaccinated
FROM model..Covid_19_Deaths dea
JOIN model..Covid_19_Vaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

/* Because the RollingPeopleVaccinated column shows a continuation of the amount of individuals who are vaccinated day-by-day per country,
to find out the % of a country's population that is vaccinated, we want to look at the MAX number in the RollingPeopleVaccinated field, and 
divide this number by the population. In order to do this, we can either create a CTE or a temp table.*/

--------------------------------------------------------------------------------------------------------------------------------------

-- CTE METHOD
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, CAST(dea.[location] AS NVARCHAR(50)), dea.[date], dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY CAST(dea.[location] AS NVARCHAR(50)) ORDER BY CAST(dea.[location] AS NVARCHAR(50)),
dea.date) AS RollingPeopleVaccinated
FROM model..Covid_19_Deaths dea
JOIN model..Covid_19_Vaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentofPopVaccinated
FROM PopvsVac


/* When looking at the results for some of the countries (ex: United States, Indonesia, England, etc.), the percentage of the population that is vaccinated 
exceeds the total population of that country. Some possibilities for this could be that the vaccination count are taking into account individuals who had 
received the Pfizer or Moderna vaccination which required two rounds -- and each individual administration was being counted as a new vaccination (even if 
it was for the same individual). Another possibility could be that the data is also accounting for booster shots; however, the CDC did not officially 
announce the release for this until mid-late September 2021. */

--------------------------------------------------------------------------------------------------------------------------------------
-- TEMP Table method

DROP TABLE IF EXISTS #PercentPopulationVaccinated --function super helpful for when one wants to make multiple edits to their table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATE,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, CAST(dea.[location] AS NVARCHAR(50)), dea.[date], dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY CAST(dea.[location] AS NVARCHAR(50)) ORDER BY CAST(dea.[location] AS NVARCHAR(50)),
dea.date) AS RollingPeopleVaccinated
FROM model..Covid_19_Deaths dea
JOIN model..Covid_19_Vaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentofPopVaccinated
FROM #PercentPopulationVaccinated

--------------------------------------------------------------------------------------------------------------------------------------
-- Creating View to store data for later visualization

CREATE VIEW PercentofPopVaccinated AS
SELECT dea.continent, CAST(dea.[location] AS NVARCHAR(50)), dea.[date], dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY CAST(dea.[location] AS NVARCHAR(50)) ORDER BY CAST(dea.[location] AS NVARCHAR(50)),
dea.date) AS RollingPeopleVaccinated
FROM model..Covid_19_Deaths dea
JOIN model..Covid_19_Vaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

