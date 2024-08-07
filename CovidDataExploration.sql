/*
Covid-19 Data Exploration

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

/* Select all columns from CovidDeaths table for non-null continents */
SELECT *
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

/* Select initial data to work with */
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

/* 
Total Cases vs Total Deaths
Shows the likelihood of dying if you contract COVID in Nigeria 
*/
SELECT location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE location LIKE '%Nigeria%'
  AND continent IS NOT NULL 
ORDER BY location, date;

/* 
Total Cases vs Population
Shows what percentage of the population is infected with Covid 
*/
SELECT location, date, population, total_cases, 
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
ORDER BY location, date;

/* 
Countries with the Highest Infection Rate compared to the Population
Displays the highest infection count and percentage of the population infected
*/
SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

/* 
Countries with Highest Death Count per Population
Displays the highest death count per location 
*/
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;

/* 
Continents with the Highest Death Count per Population 
Displays the highest death count per continent 
*/
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

/* 
Global Numbers
Shows the number of total cases, total deaths, and mortality percentage of COVID-19 globally 
*/
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL;

/* 
Total Population vs Vaccinations
Shows the percentage of the population that has received at least one Covid vaccine 
*/
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM covid-402009.PostfolioProject.CovidDeaths dea
JOIN covid-402009.PostfolioProject.CovidVacinnations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date;

/* 
Using CTE to perform calculation on partition by in the previous query
Calculates the rolling sum of people vaccinated and percentage of population vaccinated
*/
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM covid-402009.PostfolioProject.CovidDeaths dea
    JOIN covid-402009.PostfolioProject.CovidVacinnations vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentageVaccinated
FROM PopvsVac;

/* 
Using Temp Table to perform calculation on partition by in the previous query
The calculations show the percentage of total number of people vaccinated each day
*/
DROP TABLE IF EXISTS covid-402009.PostfolioProject.PercentPopulationVaccinated;
CREATE TABLE covid-402009.PostfolioProject.PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM covid-402009.PostfolioProject.CovidDeaths dea
JOIN covid-402009.PostfolioProject.CovidVacinnations vac
    ON dea.location = vac.location
   AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentageVaccinated
FROM covid-402009.PostfolioProject.PercentPopulationVaccinated;

/* 
Creating Views for Later Visualizations
*/

/* 
View 1: Shows the number of people vaccinated and the rolling percentage of vaccination for each location 
*/
CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM covid-402009.PostfolioProject.CovidDeaths dea
JOIN covid-402009.PostfolioProject.CovidVacinnations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

/* 
View 2: Shows the total number of cases, deaths, and the mortality percentage 
*/
CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.PercentDeath AS
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NOT NULL;

/* 
View 3: Shows the total death count by location 
*/
CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.TotalDeathCount AS
SELECT location, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE continent IS NULL 
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;

/* 
View 4: Shows the highest infection rate and the percentage of the population affected for different locations 
*/
CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.MaxPercentPopulationInfected AS
SELECT location, population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

/* 
View 5: Shows the highest infection rate and the percentage of the population affected for Nigeria 
*/
CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.MaxPercentPopulationInfected_PerDay AS
SELECT location, population, date, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
WHERE location LIKE '%Nigeria%'
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;
