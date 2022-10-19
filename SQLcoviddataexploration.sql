/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
from project1..CovidDeaths$
where continent is not null
order by 3,4

select *
from project1..CovidVaccinations$
where continent is not null
order by 3,4

-- Select Data that we are going to be starting with
select location,date,total_cases,new_cases,total_deaths,population
from project1..CovidDeaths$
where continent is not null
order by 1,2

--Death percentage
-- Total Cases vs Total Deaths
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as deathpercentage
from project1..CovidDeaths$
where location like '%india%'
order by 1,2

--% of population infected
-- Total Cases vs Population
select location,date,population,total_cases,(total_cases/population)*100 as infected_percentage
from project1..CovidDeaths$
where location like '%India%'
order by 1,2

--countries with highest infection rate
select location,population,MAX(total_cases) as highestinfectioncount,MAX(total_cases/population)*100 as percentagepopulationinfected
from project1..CovidDeaths$
where continent is not null
group by location , population
order by percentagepopulationinfected desc

--contries with highest death count per population
select location,MAX(cast(total_deaths as int)) as Totaldeathcount
From project1..CovidDeaths$
where continent is not null
group by location
order by totaldeathcount desc

select location,MAX(cast(total_deaths as int)) as Totaldeathcount
From project1..CovidDeaths$
where continent is null
group by location
order by totaldeathcount desc


--based on continent highstdeathcount
select continent,MAX(cast(total_deaths as int)) as Totaldeathcount
From project1..CovidDeaths$
where continent is not null
group by continent
order by Totaldeathcount desc

--Global NUMBERS
select SUM(new_cases) as total_cases, SUM(cast(New_deaths as int)) as total_deaths, sum(cast(New_deaths as int))/Sum(New_cases)*100 as deathpercentage
From project1..CovidDeaths$
where continent is not null
--Group by date
order by 1,2

--joining two datasets
 select *
 from project1..CovidDeaths$ dea
 join project1..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date

--Total population vs vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
 , sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER by dea.location,dea.date) as addingupvacinations
 --, ()
 from project1..CovidDeaths$ dea
 join project1..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
with pop_vs_vac(continent,location,date,population,new_vaccinations, addingupvacinations)
as
(
 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
 , sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER by dea.location,dea.date) as addingupvacinations
 --, (addingupvacinations/population)
 from project1..CovidDeaths$ dea
 join project1..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * , (addingupvacinations/population) * 100
from pop_vs_vac


--temp table
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
ard numeric
)
insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER by dea.location,
   dea.date) as ard
from project1..CovidDeaths$ dea
join project1..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
select *, (ard/population)*100
from #percentpopulationvaccinated

--creating view to store data for later visualization

create view percent_population_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location ORDER by dea.location,
   dea.date) as ard
from project1..CovidDeaths$ dea
join project1..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
