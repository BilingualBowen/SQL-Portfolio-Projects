/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Test if data are saved in the database
select *
from [dbo].[CovidDeaths]
order by 3, 4

select *
from [dbo].[CovidVaccinations]
order by 3, 4

-- Select data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from [dbo].[CovidDeaths]
order by 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, 
	   convert (float, total_deaths)/convert (float, total_cases)*100 as DeathPercentage
from [dbo].[CovidDeaths]
where location like '%states%'
order by 1, 2

-- Looking at Total Vases vs Population
-- Shows what percentatge of population got COVID
select Location, date, total_cases, population, 
	   convert (float, total_cases)/population*100 as PercentPopulationInfected
from [dbo].[CovidDeaths]
--where location like '%states%'
order by 1, 2


-- Looking at Countries with Highest Infection Rate compared to Population
select Location, population, MAX(cast(total_cases as int)) as HighestInfectionCount,
	   MAX(convert (float, total_cases)/population*100) as PercentPopulationInfected
from [dbo].[CovidDeaths]
--where location like '%states%'
where continent is not null
group by Location, population
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population
select Location, MAX(cast(total_cases as int)) as TotalDeathCount
from [dbo].[CovidDeaths]
--where location like '%states%'
where continent is not null
group by Location
order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- below is more accurate than the other one below
select location, MAX(cast(total_cases as int)) as TotalDeathCount
from [dbo].[CovidDeaths]
--where location like '%states%'
where continent is null
group by location
order by TotalDeathCount desc

-- Showing continents with the highest death count per popucation

select continent, MAX(cast(total_cases as int)) as TotalDeathCount
from [dbo].[CovidDeaths]
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
	   sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from [dbo].[CovidDeaths]
where continent is not null
--group by date
order by 1, 2



-- Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations nvarchar(255),
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--	,(RollingPeopleVaccinated/population)*100
from [dbo].[CovidDeaths] dea
join [dbo].[CovidVaccinations] vac
on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


select *
from PercentPopulationVaccinated

