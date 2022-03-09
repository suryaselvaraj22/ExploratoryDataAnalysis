-- Looking at the data

SELECT * FROM CovidDeaths;

SELECT * FROM CovidVaccinations;

SELECT * FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Select data that we are going to be starting with (order by location & date) 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- Total cases vs total deaths 
-- Shows the likelihood of dying if you contract covid in your country AKA Death rate 
-- My country is Canada

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathRate 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
AND location LIKE '%canada%'
ORDER BY location, date;

-- Total cases vs population 
-- Shows what % of the population infected with Covid 

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
AND location LIKE '%canada%'
ORDER BY location, date;

-- Countries with highest infection rate compared to their population 

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS HighestInfectionRate 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
-- AND location LIKE '%canada%'
GROUP BY location, population
ORDER BY HighestInfectionRate desc;

-- Countries with highest death count compared to their population 

SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
-- AND location LIKE '%canada%'
GROUP BY location
ORDER BY HighestDeathCount desc;

-- Breaking down by continent 
-- Showing continents with highest death count 

SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
AND location NOT LIKE '%world%'
AND location NOT LIKE '%international%'
-- AND location LIKE '%canada%'
GROUP BY location
ORDER BY HighestDeathCount desc;

-- Ideally it would have been this way, but the data is built in a very non-intuitive way 
--SELECT continent, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL 
---- AND location LIKE '%canada%'
--GROUP BY continent
--ORDER BY HighestDeathCount desc;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS TotalCases, SUM(CONVERT(bigint, new_deaths)) AS TotalDeaths, (SUM(CONVERT(bigint, new_deaths))/SUM(new_cases))*100 AS TotalDeathRate 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

-- Total population vs Vaccinations
-- Shows Vaccination rate per country (% of population who received at least 1 vaccination dose) 

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2;

SELECT dea.location, dea.date, dea.population, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location) AS TotalVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2;

SELECT dea.location,
SUM(CONVERT(bigint, vac.new_vaccinations)) AS TotalVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location
ORDER BY dea.location;

-- Rolling Count of vaccinations over this period

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2;

-- Rolling Vaccination rate over this period 

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
-- , (RollingVaccinationCount/dea.population)*100 AS RollingVaccinationRate 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2;

-- Cannot use newly computed fields on the same query => Use CTEs, Temp tables, Views

-- Using CTEs for this

WITH VaccinationRate (Location, Date, Population, NewVaccinations, RollingVaccinationCount)
AS
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingVaccinationCount/Population)*100 AS RollingVaccinationRate
FROM VaccinationRate;

-- Using Temp Tables for this

DROP TABLE IF EXISTS #VaccinationRate;

CREATE TABLE #VaccinationRate 
(
Location nvarchar(255),
Date datetime,
Population numeric, 
NewVaccinations numeric,
RollingVaccinationCount numeric
);

INSERT INTO #VaccinationRate
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2;

SELECT *, (RollingVaccinationCount/Population)*100 AS RollingVaccinationRate 
FROM #VaccinationRate;

-- Creating a View to store data for later visualizations

CREATE VIEW RollingVaccinationCountView AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM RollingVaccinationCountView;

