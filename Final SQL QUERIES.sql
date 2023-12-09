# 1. Calculate the total COVID-19 vaccine doses administered in California and Washington.
SELECT 
    st.StateName as State, vcr.TotalVaccinations as 'Total Vaccinations'
FROM 
    State st
JOIN 
    VaccinationRecord vcr ON st.StateId = vcr.StateId
JOIN 
    (SELECT 
         StateId, MAX(Date) AS RecentDate
     FROM 
         VaccinationRecord
     GROUP BY 
         StateId) AS latest_dt_vr ON vcr.StateId = latest_dt_vr.StateId AND vcr.Date = latest_dt_vr.RecentDate;

#------------------------------------------------------------------------------------------------------------------------------------

# 2. What are the latest recorded numbers of fully vaccinated and partially vaccinated individuals in each state 
# according to the most recent data available in the database? 

SELECT 
    st.StateName as State, pfvc.RecentFullyVaccinated as 'Fully Vaccinated', ppvc.RecentPartiallyVaccinated as 'Partially Vaccinated'
FROM State st
LEFT JOIN 
    (SELECT 
        StateId, FullyVaccinated AS RecentFullyVaccinated, Date AS FullyVaccinatedDate
     FROM PeopleFullyVaccinated pfvc1
     WHERE 
        pfvc1.Date = (SELECT MAX(pfvc2.Date) FROM PeopleFullyVaccinated pfvc2 WHERE pfvc2.StateId = pfvc1.StateId)
    ) AS pfvc ON st.StateId = pfvc.StateId
LEFT JOIN 
    (SELECT 
        StateId, PartiallyVaccinated AS RecentPartiallyVaccinated, Date AS PartiallyVaccinatedDate
     FROM 
        PeoplePartiallyVaccinated ppvc1
     WHERE 
        ppvc1.Date = (SELECT MAX(ppvc2.Date) FROM PeoplePartiallyVaccinated ppvc2 WHERE ppvc2.StateId = ppvc1.StateId)
    ) AS ppvc ON st.StateId = ppvc.StateId
ORDER BY st.StateName;
    
#------------------------------------------------------------------------------------------------------------------------------------

# 3. What are the percentages of the population that are fully vaccinated and partially vaccinated in the states of 
# California and Washington?
 
SELECT st.StateName as State,
    ROUND( IFNULL( (fvc.RecentFullyVaccinated / 
            CASE 
                WHEN st.StateName = 'California' THEN 39240000 
                WHEN st.StateName = 'Washington' THEN 7630000 
            END) * 100, 0), 2) AS 'Percentage Fully Vaccinated',
    ROUND( IFNULL(
            (pvc.RecentPartiallyVaccinated / 
            CASE 
                WHEN st.StateName = 'California' THEN 39240000 
                WHEN st.StateName = 'Washington' THEN 7630000 
            END) * 100, 0), 2) AS 'Percentage Partially Vaccinated' FROM State st
LEFT JOIN (
    SELECT StateId, MAX(FullyVaccinated) AS RecentFullyVaccinated FROM PeopleFullyVaccinated
    GROUP BY StateId) AS fvc ON st.StateId = fvc.StateId
LEFT JOIN (
    SELECT StateId, MAX(PartiallyVaccinated) AS RecentPartiallyVaccinated
    FROM PeoplePartiallyVaccinated
    GROUP BY StateId ) AS pvc ON st.StateId = pvc.StateId;

#------------------------------------------------------------------------------------------------------------------------------------

# 4. What is the average daily vaccination over a specific time period?

SELECT
    st.StateName as State,
    AVG(vdr.DailyVaccinations) AS 'Average Daily Vaccination'
FROM
    VaccinationsDailyRecord vdr
JOIN State as st ON vdr.StateId = st.StateId
WHERE
    vdr.Date BETWEEN '2022-03-18' AND '2022-05-26'
GROUP BY
    st.StateId, st.StateName;

#------------------------------------------------------------------------------------------------------------------------------------

# 5. What is the percentage of the population in California and Washington that has received a COVID-19 vaccine booster dose?

SELECT
    st.StateName as State, BoosterShotsData.TotalBoosterShotsAdministered as 'Total Administered Booster Shots', 
    ROUND((
        BoosterShotsData.TotalBoosterShotsAdministered / 
        CASE 
            WHEN st.StateName ='California' THEN 39240000
            WHEN st.StateName ='Washington' THEN 7630000
            ELSE 1
        END
    ) * 100, 2) AS 'Percentage Population Boostered'
FROM State st
JOIN (
    SELECT StateId, TotalBoosterShots AS TotalBoosterShotsAdministered, Date
    FROM People_BoosterShots
    WHERE (StateId, Date) IN (
        SELECT StateId, MAX(Date) FROM People_BoosterShots GROUP BY StateId
    )
) AS BoosterShotsData ON st.StateId = BoosterShotsData.StateId;

#------------------------------------------------------------------------------------------------------------------------------------

# 6. How has the total number of vaccinations changed from one date to another in both states?

SELECT 
    st.StateName as State,
    (EndDateVaccinations.TotalVaccinations - StartDateVaccinations.TotalVaccinations) AS 'Change In No. of Vaccinations'
FROM State st
JOIN 
    (SELECT StateId, TotalVaccinations FROM VaccinationRecord WHERE Date ='2021-09-16') AS EndDateVaccinations 
		ON st.StateId = EndDateVaccinations.StateId
JOIN 
    (SELECT StateId, TotalVaccinations FROM VaccinationRecord WHERE Date ='2021-08-13') AS StartDateVaccinations 
		ON st.StateId = StartDateVaccinations.StateId;
        
#------------------------------------------------------------------------------------------------------------------------------------

#7. What is the daily average number of vaccinations administered per million over the given time period in 
# California and Washington?

SELECT 
    st.StateName,
    AVG(vdr.DailyVaccinationPerMillion) AS 'Avg Daily Vaccinations Per Million'
FROM VaccinationsDailyRecord vdr
JOIN 
    State st ON vdr.StateId = st.StateId
WHERE 
    vdr.Date BETWEEN '2021-01-13' AND '2021-01-15'
GROUP BY 
    st.StateName;
    
#------------------------------------------------------------------------------------------------------------------------------------

# 8. How many vaccination doses were administered each year for each state?

SELECT vcr1.StateId, st.StateName,
  YEAR(vcr1.Date) as Year, (vcr1.TotalVaccinations - COALESCE(vcr2.TotalVaccinations, 0)) as YearlyDoses
FROM VaccinationRecord vcr1
LEFT JOIN
  VaccinationRecord vcr2 ON vcr1.StateId = vcr2.StateId AND vcr2.Date = (
    SELECT MAX(vcr3.Date)
    FROM VaccinationRecord vcr3
    WHERE YEAR(vcr3.Date) = YEAR(vcr1.Date) - 1 AND vcr3.StateId = vcr1.StateId
  )
JOIN State st ON vcr1.StateId = st.StateId
WHERE
  vcr1.Date IN (SELECT MAX(vcr4.Date) FROM VaccinationRecord vcr4 GROUP BY YEAR(vcr4.Date), vcr4.StateId)
ORDER BY vcr1.StateId, Year;

