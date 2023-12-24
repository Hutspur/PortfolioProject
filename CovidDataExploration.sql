/*
Covid 19 Data Exploration 

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
FROM covid-402009.PostfolioProject.CovidDeaths
Where continent is not null 
order by 3,4;


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
FROM covid-402009.PostfolioProject.CovidDeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covid-402009.PostfolioProject.CovidDeaths
Where location like '%Nigeria%'
and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of the population is infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
order by 1,2;


-- Countries with the Highest Infection Rate compared to the Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc;



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc;



-- GLOBAL NUMBERS
-- Showing the number of total cases, total deaths, and mortality percentage of COVID-19 globally

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
where continent is not null 
--Group By date
order by 1,2;



-- Total Population vs Vaccinations
-- Shows the Percentage of the Population that has received at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM covid-402009.PostfolioProject.CovidDeaths dea
Join covid-402009.PostfolioProject.CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;


-- Using CTE to perform Calculation on Partition By in the previous query

With PopvsVac as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM covid-402009.PostfolioProject.CovidDeaths dea
Join covid-402009.PostfolioProject.CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentageVacinated
From PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in the previous query
-- The calculations show the percentage of total number of people vaccinated each day

DROP TABLE if exists covid-402009.PostfolioProject.PercentPopulationVaccinated;
CREATE TABLE covid-402009.PostfolioProject.PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into covid-402009.PostfolioProject.PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM covid-402009.PostfolioProject.CovidDeaths dea
Join covid-402009.PostfolioProject.CovidVacinnations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3
;

Select *, (RollingPeopleVaccinated/Population)*100
From covid-402009.PostfolioProject.PercentPopulationVaccinated;




-- Creating View to store data for later visualizations
-- View 1.
-- Shows the number of people vaccinated and the rolling percentage of vaccination for each location

CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM covid-402009.PostfolioProject.CovidDeaths dea
Join covid-402009.PostfolioProject.CovidDeaths
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

-- View 2. 
-- Shows the total number of cases, death, and the mortality percentage

CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.PercentDeath as
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
where continent is not null 
--Group By date
order by 1,2

-- The query commented out below is to double-check the data obtained from view 2
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From covid-402009.PostfolioProject.CovidDeaths
----Where location like '%Nigeria%'
--where location = 'World'
----Group By date
--order by 1,2


-- View 3. 
-- Shows the total death count by location

-- We take these out as they are not included in the above queries and want to stay consistent
-- European Union is part of Europe

CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.TotalDeathCount as
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- View 4.
-- Show the highest infection rate and the percentage of the population affected for a different location

CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.MaxPercentPopulationInfected as
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid-402009.PostfolioProject.CovidDeaths
--Where location like '%Nigeria%'
Group by Location, Population
order by PercentPopulationInfected desc


-- View 5.
-- Show the highest infection rate and the percentage of the population affected for Nigeria
    

CREATE VIEW IF NOT EXISTS covid-402009.PostfolioProject.MaxPercentPopulationInfected_PerDay as
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From covid-402009.PostfolioProject.CovidDeaths
Where location like '%Nigeria%'
Group by Location, Population, date
order by PercentPopulationInfected desc