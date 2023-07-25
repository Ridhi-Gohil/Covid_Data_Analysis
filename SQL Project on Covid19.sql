select * from Portfolio.dbo.Coviddeaths

--the continent(s) with the highest number of total COVID-19 cases
SELECT TOP 1 continent, SUM(total_cases) AS max_cases
FROM Portfolio.dbo.Coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY max_cases DESC;

--the average number of new cases for each location
Select location, AVG(new_cases) 
from Portfolio.dbo.Coviddeaths
group by location
order by 2 DESC;

-- the total number of COVID-19 cases for each month and year
SELECT MONTH(date) AS month, YEAR(date) AS year, SUM(total_cases) AS total_cases
FROM Portfolio.dbo.Coviddeaths
GROUP BY MONTH(date), YEAR(date)
ORDER BY year, month;

--the average number of new COVID-19 cases for each continent for the year 2021
select continent, avg(new_cases) as average_new_cases
from Portfolio.dbo.Coviddeaths
where Year(date) = '2021'
group by continent
order by 2 desc

/*the top 5 locations with the highest number of total COVID-19 cases 
as of the latest date available*/
SELECT TOP 5 location, SUM(total_cases) AS total_cases
FROM Portfolio.dbo.Coviddeaths
WHERE date = (SELECT MAX(date) FROM CovidDeaths)
GROUP BY location
ORDER BY total_cases DESC;


select location, date, total_cases, new_cases ,total_deaths, population
from Portfolio.dbo.Coviddeaths
Where continent is not null 
order by 1,2

--Total Cases vs Total Deaths
Select Location, date, total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
From Portfolio.dbo.Coviddeaths
Where continent is not null 
order by 1,2

-- Total Cases in India
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio.dbo.Coviddeaths
Where continent is not null 
and location = 'India'
order by 1,2


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio.dbo.Coviddeaths
Where continent is not null 
--where location = 'India'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio.dbo.Coviddeaths
Where continent is null 
Group by Location
order by TotalDeathCount desc


-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio..Coviddeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS date wise

Select date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio..Coviddeaths
where continent is not null 
and new_cases is not null
Group By date
order by 1,2


-- total GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio..Coviddeaths
where continent is not null 
order by 1,2

--joining death table with vaccination table
select * 
from Portfolio..Coviddeaths dea
join Portfolio..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
order by 1,2

-- Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From Portfolio..Coviddeaths dea
Join Portfolio..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Total Population vs Vaccinations using partition by
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio..Coviddeaths dea
Join Portfolio..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..Coviddeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio..Coviddeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio..Coviddeaths dea
Join Portfolio..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


select * from PercentPopulationVaccinated