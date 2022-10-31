-- Queries for Covid-19 Tableau visualization

--(1.)


SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage 
FROM dbo.Covid_19_Deaths
WHERE continent IS NOT NULL
--GROUP BY [date]
ORDER BY 1,2

--(2.)
SELECT [location], SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM dbo.Covid_19_Deaths
WHERE continent IS NULL
AND location NOT IN ('European Union', 'High income', 'World', 'Upper middle income', 'Low income', 'Lower middle income', 'International')
GROUP BY [location]
ORDER BY TotalDeathCount DESC

--(3.)
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases / population)*100 AS PercentPopulationInfected
FROM dbo.Covid_19_Deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--(4.)
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population))*100 AS PercentPopulationInfected
FROM dbo.Covid_19_Deaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC
