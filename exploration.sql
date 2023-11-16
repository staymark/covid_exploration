-- Note: Some columns may not be properly formatted in the database so some null values might be '' (empty string)
-- Add the following so that locations entries such as 'World', continents and income are not selected:
-- where continent != ''



-- LOOKING AT DATA BY COUNTRY

-- Total cases vs total deaths
-- Case death rate (percentage of cases that resulted in death)

select location,
	date,
	population,
	total_cases,
	total_deaths,
	(total_deaths::decimal/total_cases) * 100 as death_percentage
from covid_deaths
where continent != ''
order by location, date;

-- Total cases vs population
-- Population infection rate (percentage of cases in the population)

select location,
	date,
	population,
	total_cases,
	(total_cases::decimal/population) * 100 as case_percentage
from covid_deaths
where continent != ''
order by location, date desc;

-- Countries with highest infection rate (cases in population) 

select location,
	population,
	max(total_cases) as max_case_count,
	max((total_cases::decimal/population))*100 as max_case_percentage
from covid_deaths
where continent != ''
group by location, population
order by max_case_percentage desc;

-- Countries with highest death count

select location,
	max(total_deaths) as max_death_count
from covid_deaths
where continent != ''
group by location
order by max_death_count desc;

-- Countries with highest population death rate (deaths in population)

select location,
	population,
	max(total_deaths) as max_death_count,
	max((total_deaths::decimal/population))*100 as max_death_percentage	
from covid_deaths
where continent != ''
group by location, population
order by max_death_percentage desc;


-- LOOKING AT DATA BY CONTINENT INSTEAD OF COUNTRY

-- Continents with highest population death rate

select continent, 
	max(total_deaths) as max_death_count,
	max((total_deaths::decimal/population))*100 as max_death_percentage	
from covid_deaths
where continent != ''
group by continent 
order by max_death_percentage desc;

-- LOOKING AT DATA GLOBALLY

-- Case death rate
-- Sum new_cases and new_deaths to get totals for the day only

select date,
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	(sum(new_deaths::decimal) / nullif(sum(new_cases), 0)) * 100 as daily_death_percentage
from covid_deaths
where continent != ''
group by date
order by date;

-- Population vaccination rate

-- METHOD 1: CTE

with vacc_total_cte as (
	select cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		sum(cv.new_vaccinations) over( 
			partition by cd.location
			order by cd.location, cd.date
		) as vacc_running_total
	from covid_deaths cd 
	inner join covid_vaccinations cv 
		on cv.date = cd.date
		and cv.location = cd.location
	where cd.continent != ''
)

select *, 
	(vacc_running_total/population) * 100 as pop_vacc_rate
from vacc_total_cte;

-- METHOD 2: TEMP TABLE

-- drop table if exists vacc_total_temp
create temp table vacc_total_temp as
	select cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		sum(cv.new_vaccinations) over( 
			partition by cd.location
			order by cd.location, cd.date
		) as vacc_running_total
	from covid_deaths cd 
	inner join covid_vaccinations cv 
		on cv.date = cd.date
		and cv.location = cd.location
	where cd.continent != ''
	
select *, 
	(vacc_running_total/population) * 100 as pop_vacc_rate
from vacc_total_temp;

-- VIEWS FOR VISUALIZATION

-- Population vaccination rate

create view pop_vacc_rate as
	select cd.continent, 
		cd.location, 
		cd.date, 
		cd.population, 
		cv.new_vaccinations,
		sum(cv.new_vaccinations) over( 
			partition by cd.location
			order by cd.location, cd.date
		) as vacc_running_total
	from covid_deaths cd 
	inner join covid_vaccinations cv 
		on cv.date = cd.date
		and cv.location = cd.location
	where cd.continent != ''

-- reorganize query so that we do things by query type and do two for countries, continent, globally, etc.
-- add more views to use for tableau	