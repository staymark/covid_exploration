-- Note: Some columns may not be properly formatted in the database so some null values might be '' (empty string)
-- Add the following clause so that locations entries such as 'World', continents, and income are not selected:
-- where continent != ''


-- EXPLORING DATA BY COUNTRY

-- Total cases vs total deaths
-- Case death rate (percentage of cases that resulted in death) by day

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
-- Population infection rate (percentage of population that has gotten covid) by day

select location,
	date,
	population,
	total_cases,
	(total_cases::decimal/population) * 100 as case_percentage
from covid_deaths
where continent != ''
order by location, date;

-- Peak population infection rate 

select location,
	population,
	max(total_cases) as max_case_count,
	max((total_cases::decimal/population)) * 100 as max_case_percentage
from covid_deaths
where continent != ''
group by location, population
order by max_case_percentage desc;

-- Death count

select location,
	max(total_deaths) as max_death_count
from covid_deaths
where continent != ''
group by location
order by max_death_count desc;

-- Peak population death rate (deaths in population)

select location,
	population,
	max(total_deaths) as max_death_count,
	max((total_deaths::decimal/population)) * 100 as max_death_percentage	
from covid_deaths
where continent != ''
group by location, population
order by max_death_percentage desc;


-- EXPLORING DATA BY CONTINENT

-- Case death rate by day

with continent_cdr_cte as ( -- total cases and deaths for each continent by day
	select continent,
		date,
		sum(total_cases) as total_cases,
		sum(total_deaths) as total_deaths
	from covid_deaths
	where continent != ''
	group by continent, date
	order by continent, date
)

select continent,
	date,
	total_cases,
	total_deaths,
	(total_deaths::decimal/total_cases) * 100 as death_percentage
from continent_cdr_cte;

-- Population infection rate by day

with continent_pir_cte as ( -- total population and cases for each continent by day
	select continent,
		date,
		sum(population) as total_population,
		sum(total_cases) as total_cases
	from covid_deaths
	where continent != ''
	group by continent, date
	order by continent, date
)

select continent,
	date,
	total_population,
	total_cases,
	(total_cases::decimal/total_population) * 100 as case_percentage
from continent_pir_cte;


-- Peak population infection rate
	
with country_peak_cases_cte as ( -- max cases for each country
	select location,
		continent, 
		population,
		max(total_cases) as peak_cases
	from covid_deaths
	where continent != ''
	group by location, continent, population 
),
continent_peak_cases_cte as ( -- max cases for each continent
	select continent,
		sum(population) as continent_population,
		sum(peak_cases) as continent_peak_cases
	from country_peak_cases_cte
	group by continent
)

select continent,
	continent_population,
	continent_peak_cases,
	(continent_peak_cases::decimal/continent_population) * 100 as peak_case_percentage
from continent_peak_cases_cte;

-- Death count

with country_deaths_cte as ( -- death count for each country
	select location,
		continent, 
		population,
		max(total_deaths) as death_count
	from covid_deaths
	where continent != ''
	group by location, continent, population
)

select continent,
	sum(death_count) as death_count
from country_deaths_cte
group by continent
order by death_count desc;

-- Peak population death rate

with country_deaths_cte as ( -- death count for each country
	select location,
		continent, 
		population,
		max(total_deaths) as death_count
	from covid_deaths
	where continent != ''
	group by location, continent, population
),
continent_deaths_cte as ( -- death count and total population for each continent
	select continent,
		sum(population) as continent_population,
		sum(death_count) as continent_death_count
	from country_deaths_cte
	group by continent
)

select continent,
	continent_death_count,
	continent_population,
	(continent_death_count::decimal/continent_population) * 100 as population_death_percentage
from continent_deaths_cte
order by population_death_percentage desc;


-- EXPLORING DATA GLOBALLY

-- Case death rate by day
-- Sum new_cases and new_deaths to get totals for the day only

select date,
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	(sum(new_deaths::decimal) / nullif(sum(new_cases), 0)) * 100 as daily_death_percentage
from covid_deaths
where continent != ''
group by date
order by date;

-- Population vaccination rate by day

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

-- Case death rate by day

-- drop view if exists global_case_death_rate
create view global_case_death_rate as (
	select date,
		sum(new_cases) as total_cases,
		sum(new_deaths) as total_deaths,
		(sum(new_deaths::decimal) / nullif(sum(new_cases), 0)) * 100 as daily_death_percentage
	from covid_deaths
	where continent != ''
	group by date
	order by date
)

-- Population vaccination rate by day

-- drop view if exists global_pop_vacc_rate 
create view global_pop_vacc_rate as (
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
	from vacc_total_cte
)
