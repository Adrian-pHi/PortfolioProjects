 Select *
From PortfolioProject..CovidDeaths
WHERE continent IS NULL
Order by 3,4

Select *
From PortfolioProject..CovidDeaths
Where location = 'Costa Rica' AND continent IS NOT NULL
Order by 3,4

Select location, date, total_cases, new_cases, total_cases, population
From PortfolioProject..CovidDeaths
Order by 1,2

-- Oberservando el Total de casos vs Total de muertes

Select location, date, total_cases, total_deaths, CAST((TRY_CAST(total_cases AS numeric) / TRY_CAST(total_deaths AS numeric))*100 AS decimal(18,2)) AS DeathPercentage 
From PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL AND TRY_CAST(total_cases AS numeric) <> 0 AND total_deaths IS NOT NULL AND continent IS NOT NULL
--AND location like 'Costa%'
Order by 1,2

-- Oberservando el Total de casos vs Poblacion

Select location, date, total_cases, population, (TRY_CAST(total_cases AS numeric) / population)*100 AS InfectedPercentage
From PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL AND TRY_CAST(total_cases AS numeric) <> 0 AND continent IS NOT NULL
--AND location like 'Costa%'
Order by 1,2 

--Observando a los paises con la Mayor Tasa de Infeccion comparada a su Poblacion

Select location, population, MAX(TRY_CAST(total_cases AS numeric)) AS HighestInfectionCount,  MAX((TRY_CAST(total_cases AS numeric)/population))*100 AS HighestInfectedPercentage
From PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL AND TRY_CAST(total_cases AS numeric) <> 0 AND continent IS NOT NULL
--AND location like 'Costa%'
Group by location, population
Order by HighestInfectedPercentage desc

--Mostrando paises con el Mayor Recuento de Muertes por Poblacion

Select location, MAX(TRY_CAST(REPLACE(total_deaths, '.', '') AS INT)) AS TotalDeathCount 
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
Group by location
Order by TotalDeathCount desc

--Mostrando continentes con el Mayor Recuento de Muertes por Poblacion

Select continent, MAX(TRY_CAST(REPLACE(total_deaths, '.', '') AS INT)) AS TotalDeathCount 
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
Group by continent
Order by TotalDeathCount desc

--Estadisticas Globales por Fecha, muertes y casos nuevos 

SELECT 
  date,
  SUM(TRY_CAST(new_cases AS NUMERIC)) AS total_cases, 
  SUM(TRY_CAST(new_deaths AS NUMERIC)) AS total_deaths, 
  CASE 
    WHEN SUM(TRY_CAST(new_cases AS NUMERIC)) = 0 THEN 0
    ELSE SUM(TRY_CAST(new_deaths AS NUMERIC)) / SUM(TRY_CAST(new_cases AS NUMERIC)) * 100 
  END AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE 
  date IS NOT NULL AND 
  TRY_CAST(new_cases AS NUMERIC) IS NOT NULL AND 
  TRY_CAST(new_deaths AS NUMERIC) IS NOT NULL AND
  continent IS NOT NULL
GROUP BY date
ORDER BY date 

-- Población Total vs Vacunaciones
-- Muestra el porcentaje de población que ha recibido al menos una vacuna contra Covid

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(TRY_CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
order by 1,2,3


-- Usando CTE para realizar cálculos en Partition By en la consulta anterior.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(TRY_CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL 
)
Select *, (RollingPeopleVaccinated/TRY_CONVERT(float, Population))*100
From PopvsVac



-- Utilizando tabla temporal para realizar el cálculo en Partition By en la consulta anterior

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
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/TRY_CONVERT(float, Population))*100
From #PercentPopulationVaccinated


-- Creando una View para almacenar datos para visualizaciones posteriores

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


