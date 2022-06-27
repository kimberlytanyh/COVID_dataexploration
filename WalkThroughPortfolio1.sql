SELECT *
FROM PortfolioProject1_Covid..CovidDeaths
ORDER BY 3,4

-- DATA EXPLORATION --

--SELECT *
--FROM PortfolioProject1_Covid..CovidVaccinations
--ORDER BY 3,4

-- Reducing columns to the few we want to focus on --

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1_Covid..CovidDeaths
ORDER BY 1,2

-- COUNTRY-LEVEL ANALYSIS
-- Fatality Rate Over Time: Totals Cases VS Total Deaths, Likelihood of Dying after Contraction of COVID by Country From 2020-03-13 to 2022-06-23
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS FatalityRate
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL -- See notes below for why
ORDER BY 1,2

-- Taking a look at U.S --
---- Fatality Rate: Totals Cases VS Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS FatalityRate
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location LIKE '%States%' AND total_cases is NOT NULL
ORDER BY 1,2

---- Looking at Total Cases VS Population (Percentage of Population that Got Infected)
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location LIKE '%States%' AND total_cases is NOT NULL
ORDER BY 1,2

-- Countries with Highest Recorded Percentage-of-Population-Infected, Total Cases/Population
SELECT location, population, MAX(total_cases) AS HighestCaseCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL -- See notes below for why
GROUP BY location, population
ORDER BY 4 DESC

-- Death Counts by Country (Beginning with Highest) as of 2022-06-23
---- Notes: total_deaths column data type is varchar. Need to convert to int first for desired output.

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
GROUP BY location
ORDER BY 2 DESC

---- Discovered irrelevant income-level-based death counts among location under location column - "remove" from output by filtering them out with WHERE statement

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location NOT LIKE '%income%'
GROUP BY location
ORDER BY 2 DESC 

---- Investigate how to remove continents/regions from output.

SELECT *
FROM PortfolioProject1_Covid..CovidVaccinations
ORDER BY 2,3 

---- To filter out continents under location column, filter out data where continent data is NULL under continent column using WHERE statement.
---- Final Output for Death Counts by Country (Beginning with Highest) as of 2022-06-23

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location NOT LIKE '%income%' AND continent is NOT NULL
GROUP BY location
ORDER BY 2 DESC 

-- NOW, LET'S BREAK THINGS DOWN BY CONTINENT
-- Death Counts by Continent as of 2022-06-23

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC 

-- NEXT, LET'S BREAK THINGS DOWN BY INCOME LEVEL
-- Death Counts by Income Level as of 2022-06-23

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NULL AND location LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC 

-- GLOBAL NUMBERS

-- Daily Total New Cases, Total Deaths, and New Deaths Over New Cases Worldwide
SELECT date, SUM(new_cases) AS TotalCasesWorldwide, SUM(CAST(new_deaths as int)) AS TotalDeathsWorldwide, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Global_NewDeathtoNewCase_Percentage
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL 
GROUP BY date
ORDER BY 1

-- Total Cases, Deaths, and Fatality Rate as of 2022-06-23
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths as int)) AS TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS OverallFatalityRate
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL 

-- LOOKING AT VACCINATION STATS BY COUNTRY
---- Notes: CAN GET ROLLING COUNT BY DOING THIS: SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)

-- Rolling Total Number of Vaccines Administered and Rolling Number of People Fully Vaccinated by Country
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2, 3

-- Using CTE to get output with percentage of population fully vaccinated

WITH PopvsFullVac (Continent, Location, Date, Population, TotalVaccinationCount, TotalVaccinesDistributed, FullVaccinationCount, RollingPeopleFullyVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location NOT LIKE '%income%'
) 
SELECT *, (RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM PopvsFullVac
WHERE Continent is NOT NULL
ORDER BY 2, 3

-- Using Temp Table to get output with percentage of population vaccinated

DROP TABLE IF EXISTS #PercentPopulationFullyVaccinated
CREATE TABLE #PercentPopulationFullyVaccinated
(Continent varchar(255), 
Location varchar(255), 
Date datetime, 
Population numeric, 
TotalVaccinationCount numeric, 
TotalVaccinesDistributed numeric, 
FullVaccinationCount numeric, 
RollingPeopleFullyVaccinated numeric)

INSERT INTO #PercentPopulationFullyVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location NOT LIKE '%income%'

SELECT *, (RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM #PercentPopulationFullyVaccinated
WHERE Continent is NOT NULL
ORDER BY 2, 3

-- Worldwide and Regional Full Vaccination Status as of 2022-06-23
---- Columns (Continent varchar(255), Location varchar(255), Date datetime, Population numeric, TotalVaccinationCount numeric, 
----TotalVaccinesDistributed numeric, FullVaccinationCount numeric, RollingPeopleFullyVaccinated numeric)

SELECT Location, MAX(RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM #PercentPopulationFullyVaccinated
WHERE Continent is NULL AND Location NOT LIKE '%International%'
GROUP BY Location
ORDER BY Location DESC

---------------------------------------------------------------------------------------------------------------------------------------------------

-- CREATE VIEWS TO STORE DATA FOR CREATING DASHBOARD IN TABLEAU

-- Worldwide and Regional Full Vaccination Status as of 2022-06-23
CREATE VIEW RegionalVaxStats AS 
WITH PopvsFullVac (Continent, Location, Date, Population, TotalVaccinationCount, TotalVaccinesDistributed, FullVaccinationCount, RollingPeopleFullyVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location NOT LIKE '%income%'
) 
SELECT Location, MAX(RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM PopvsFullVac
WHERE Continent is NULL AND Location NOT LIKE '%International%'
GROUP BY Location

GO

-- Percentage of Population Fully Vaccinated by Country as of 2022-06-23
CREATE VIEW CountryVaxStats AS 
WITH PopvsFullVac (Continent, Location, Date, Population, TotalVaccinationCount, TotalVaccinesDistributed, FullVaccinationCount, RollingPeopleFullyVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location NOT LIKE '%income%'
) 
SELECT Location, MAX(RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM PopvsFullVac
WHERE Continent is NOT NULL
GROUP BY Location

GO

-- Rolling Percentage of Population Fully Vaccinated by Country

CREATE VIEW RollingCountryVaxStats AS 
WITH PopvsFullVac (Continent, Location, Date, Population, TotalVaccinationCount, TotalVaccinesDistributed, FullVaccinationCount, RollingPeopleFullyVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.total_vaccinations as bigint) AS TotalVaccinations
, MAX(CONVERT(bigint, vac.total_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotalVaccinesDistributed
, CAST(vac.people_fully_vaccinated as bigint) AS FullVaccinationCount
, MAX(CONVERT(bigint, vac.people_fully_vaccinated)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleFullyVaccinated
FROM PortfolioProject1_Covid..CovidDeaths dea
JOIN PortfolioProject1_Covid..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.location NOT LIKE '%income%'
) 
SELECT *, (RollingPeopleFullyVaccinated/Population)*100 AS PercentofPopFullyVaccinated
FROM PopvsFullVac
WHERE Continent is NOT NULL

GO

-- Daily Total New Cases, Total Deaths, and New Deaths Over New Cases Worldwide

CREATE VIEW DailyCasesDeathsWorldwide AS
SELECT date, SUM(new_cases) AS TotalCasesWorldwide, SUM(CAST(new_deaths as int)) AS TotalDeathsWorldwide, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS Global_NewDeathtoNewCase_Percentage
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL 
GROUP BY date

-- Total Cases, Deaths, and Fatality Rate as of 2022-06-23

CREATE VIEW SummaryStatsCaseDeath AS
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths as int)) AS TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS OverallFatalityRate
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL 

-- Fatality Rate Over Time: Totals Cases VS Total Deaths, Likelihood of Dying after Contraction of COVID by Country From 2020-03-13 to 2022-06-23

CREATE VIEW FatalityRate AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS FatalityRate
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL -- See notes below for why
--ORDER BY 1,2

---- Looking at Total Cases VS Population (Percentage of Population that Got Infected)

CREATE VIEW USInfectionTrend AS 
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location LIKE '%States%' AND total_cases is NOT NULL
--ORDER BY 1,2

-- Countries with Highest Recorded Percentage-of-Population-Infected, Total Cases/Population

CREATE VIEW InfectionScalebyCountry AS
SELECT location, population, MAX(total_cases) AS HighestCaseCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NOT NULL 
GROUP BY location, population
--ORDER BY 4 DESC

---- Death Counts by Country (Beginning with Highest) as of 2022-06-23

CREATE VIEW DeathCountbyCountry AS
SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE location NOT LIKE '%income%' AND continent is NOT NULL
GROUP BY location
--ORDER BY 2 DESC 

-- NOW, LET'S BREAK THINGS DOWN BY CONTINENT
-- Death Counts by Continent as of 2022-06-23

SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC 

-- Death Counts by Income Level as of 2022-06-23

CREATE VIEW IncomeandCOVIDDeaths AS 
SELECT location, MAX(CAST(total_deaths AS bigint)) AS TotalDeathCount
FROM PortfolioProject1_Covid..CovidDeaths
WHERE continent is NULL AND location LIKE '%income%'
GROUP BY location
--ORDER BY TotalDeathCount DESC 